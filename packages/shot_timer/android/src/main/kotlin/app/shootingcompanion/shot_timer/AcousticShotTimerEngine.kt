package app.shootingcompanion.shot_timer

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.AudioTimestamp
import android.media.AudioTrack
import android.media.MediaRecorder
import android.os.Handler
import android.os.HandlerThread
import android.os.Build
import android.os.SystemClock
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.PI
import kotlin.math.sin
import kotlin.random.Random

internal class AcousticShotTimerEngine(
    private val context: Context,
    private val listener: (Map<String, Any?>) -> Unit,
) {
    private val controlThread = HandlerThread("shooting-companion-shot-timer").apply { start() }
    private val controlHandler = Handler(controlThread.looper)
    private val captureRunning = AtomicBoolean(false)
    private val stateLock = Any()
    private var configuration: NativeTimerConfiguration? = null
    private var detector: ImpulseDetector? = null
    private var audioRecord: AudioRecord? = null
    private var audioTrack: AudioTrack? = null
    private var audioExecutor: ExecutorService? = null
    private var runStartNanos: Long? = null
    private var lastShotNanos: Long? = null
    private var sequenceNumber = 0
    private var disposed = false
    private var levelLastSentNanos = Long.MIN_VALUE
    private val beginRunnable =
        Runnable {
            try {
                beginSignal()
            } catch (error: Throwable) {
                synchronized(stateLock) { stopInternal(emitReviewing = false) }
                emitError("start_signal_failed", error.message ?: error.javaClass.simpleName)
            }
        }
    private val inactivityRunnable =
        Runnable {
            synchronized(stateLock) { stopInternal(emitReviewing = true) }
        }

    fun prepare(value: NativeTimerConfiguration): Map<String, Any?> {
        synchronized(stateLock) {
            check(!disposed) { "The native shot timer has been disposed." }
            requireMicrophonePermission()
            stopInternal(emitReviewing = false)
            configuration = value
            val selectedSampleRate = value.sampleRate ?: nativeInputSampleRate()
            verifyAudioInput(selectedSampleRate)
            detector =
                ImpulseDetector(
                    ImpulseDetectorConfiguration(
                        sensitivity = value.sensitivity,
                        echoLockoutNanos = value.echoLockoutMicros * 1_000,
                    ),
                )
            listener(stateEvent("ready"))
            return mapOf(
                "sampleRate" to selectedSampleRate,
                "needsCalibration" to false,
                "detectorVersion" to DETECTOR_VERSION,
            )
        }
    }

    fun start(): Long {
        synchronized(stateLock) {
            check(!disposed) { "The native shot timer has been disposed." }
            requireMicrophonePermission()
            val value = checkNotNull(configuration) { "Prepare the timer first." }
            check(!captureRunning.get()) { "A timer run is already active." }
            val delayMicros = value.actualDelayMicros(Random.Default::nextLong)
            sequenceNumber = 0
            runStartNanos = null
            lastShotNanos = null
            levelLastSentNanos = Long.MIN_VALUE
            detector?.reset(Long.MAX_VALUE)
            startCapture(value)
            controlHandler.postDelayed(beginRunnable, delayMicros / 1_000)
            listener(stateEvent("startDelay"))
            return delayMicros
        }
    }

    fun stop() {
        synchronized(stateLock) {
            check(!disposed) { "The native shot timer has been disposed." }
            stopInternal(emitReviewing = true)
        }
    }

    fun testSignals(outputs: Set<String>) {
        synchronized(stateLock) {
            check(!disposed) { "The native shot timer has been disposed." }
            require(outputs.all { it in setOf("sound", "haptic", "flash") }) {
                "Unknown timer output signal."
            }
            check(!captureRunning.get()) { "Stop the active timer before testing signals." }
            if ("sound" in outputs) playTestBeep()
            if ("haptic" in outputs) vibrate()
        }
    }

    fun abort(reason: String) {
        synchronized(stateLock) {
            if (disposed) return
            stopInternal(emitReviewing = false)
            listener(stateEvent("interrupted", mapOf("reason" to reason)))
        }
    }

    fun dispose() {
        synchronized(stateLock) {
            if (disposed) return
            stopInternal(emitReviewing = false)
            disposed = true
        }
        controlThread.quitSafely()
    }

    private fun startCapture(value: NativeTimerConfiguration) {
        val sampleRate = value.sampleRate ?: nativeInputSampleRate()
        val minBytes =
            AudioRecord.getMinBufferSize(
                sampleRate,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
            )
        check(minBytes > 0) { "AudioRecord reported an invalid buffer size." }
        val record = buildAudioRecord(sampleRate, maxOf(minBytes * 2, sampleRate / 5 * 2))
        var executor: ExecutorService? = null
        runAudioStartupWithCleanup(
            cleanup = {
                captureRunning.set(false)
                if (audioRecord === record) audioRecord = null
                if (audioExecutor === executor) audioExecutor = null
                executor?.shutdownNow()
                runCatching { record.stop() }
                runCatching { record.release() }
            },
        ) {
            check(record.state == AudioRecord.STATE_INITIALIZED) {
                "The microphone could not be initialized."
            }
            record.startRecording()
            audioRecord = record
            captureRunning.set(true)
            executor = Executors.newSingleThreadExecutor { runnable ->
                Thread(runnable, "shooting-companion-audio-capture").apply {
                    priority = Thread.MAX_PRIORITY
                }
            }
            audioExecutor = executor
            checkNotNull(executor).execute {
                captureLoop(record, sampleRate, maxOf(minBytes / 2, 1024))
            }
        }
    }

    private fun buildAudioRecord(sampleRate: Int, bufferBytes: Int): AudioRecord {
        fun create(source: Int): AudioRecord =
            AudioRecord.Builder()
                .setAudioSource(source)
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setSampleRate(sampleRate)
                        .setChannelMask(AudioFormat.CHANNEL_IN_MONO)
                        .build(),
                ).setBufferSizeInBytes(bufferBytes)
                .build()

        val unprocessed = try {
            create(MediaRecorder.AudioSource.UNPROCESSED)
        } catch (_: IllegalArgumentException) {
            null
        } catch (_: UnsupportedOperationException) {
            null
        }

        if (unprocessed?.state == AudioRecord.STATE_INITIALIZED) {
            return unprocessed
        }
        unprocessed?.release()

        // Some devices accept UNPROCESSED in the builder but return an
        // uninitialised AudioRecord. Treat that exactly like an unsupported
        // source and fall back to the broadly available low-processing input.
        return create(MediaRecorder.AudioSource.VOICE_RECOGNITION)
    }

    /**
     * Opens the selected input route once during the guided device check.
     * This verifies more than permission presence: Android must initialize and
     * start the actual AudioRecord source before the UI reports it as ready.
     * No frames are read or persisted during this short probe.
     */
    private fun verifyAudioInput(sampleRate: Int) {
        val minBytes =
            AudioRecord.getMinBufferSize(
                sampleRate,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
            )
        check(minBytes > 0) { "AudioRecord reported an invalid buffer size." }
        val record = buildAudioRecord(sampleRate, maxOf(minBytes * 2, sampleRate / 5 * 2))
        try {
            check(record.state == AudioRecord.STATE_INITIALIZED) {
                "The microphone could not be initialized."
            }
            record.startRecording()
            check(record.recordingState == AudioRecord.RECORDSTATE_RECORDING) {
                "The microphone could not start recording."
            }
        } finally {
            runCatching { record.stop() }
            runCatching { record.release() }
        }
    }

    private fun captureLoop(
        record: AudioRecord,
        sampleRate: Int,
        bufferSamples: Int,
    ) {
        val buffer = ShortArray(bufferSamples)
        var framesRead = 0L
        try {
            while (captureRunning.get()) {
                val read = record.read(buffer, 0, buffer.size, AudioRecord.READ_BLOCKING)
                when (classifyAudioRead(read)) {
                    AudioReadAction.retry -> continue
                    AudioReadAction.fail -> {
                        stopCaptureAfterFailure(
                            "audio_read_failed",
                            "AudioRecord read failed: $read",
                        )
                        return
                    }
                    AudioReadAction.process -> Unit
                }
                val bufferStartNanos = captureBufferStartNanos(record, framesRead, read, sampleRate)
                framesRead += read
                emitAudioLevel(buffer, read)
                val detections = detector?.process(buffer, read, bufferStartNanos, sampleRate).orEmpty()
                for (detection in detections) handleDetection(detection)
            }
        } catch (error: Throwable) {
            stopCaptureAfterFailure(
                "audio_capture_failed",
                error.message ?: error.javaClass.simpleName,
            )
        }
    }

    private fun stopCaptureAfterFailure(
        code: String,
        message: String,
    ) {
        val stopped =
            synchronized(stateLock) {
                if (!captureRunning.get()) {
                    false
                } else {
                    stopInternal(emitReviewing = false)
                    true
                }
            }
        if (stopped) emitError(code, message)
    }

    private fun captureBufferStartNanos(
        record: AudioRecord,
        framesRead: Long,
        read: Int,
        sampleRate: Int,
    ): Long {
        val timestamp = AudioTimestamp()
        return if (
            record.getTimestamp(timestamp, AudioTimestamp.TIMEBASE_MONOTONIC) == AudioRecord.SUCCESS
        ) {
            timestamp.nanoTime +
                ((framesRead - timestamp.framePosition) * 1_000_000_000L / sampleRate)
        } else {
            SystemClock.elapsedRealtimeNanos() - read * 1_000_000_000L / sampleRate
        }
    }

    private fun beginSignal() {
        synchronized(stateLock) {
            if (!captureRunning.get() || disposed) return
            val value = configuration ?: return
            val fallbackStart = SystemClock.elapsedRealtimeNanos()
            var signalStart = fallbackStart
            var beepNanos = 0L
            if ("sound" in value.outputSignals) {
                val sampleRate = nativeOutputSampleRate()
                val beep = createBeep(sampleRate)
                val track = buildAudioTrack(sampleRate, beep.size)
                audioTrack = track
                check(track.write(beep, 0, beep.size, AudioTrack.WRITE_BLOCKING) >= 0) {
                    "The start signal could not be loaded."
                }
                track.play()
                signalStart = resolvePlaybackStartNanos(track, sampleRate, fallbackStart)
                beepNanos = beep.size * 1_000_000_000L / sampleRate
            }
            if ("haptic" in value.outputSignals) vibrate()
            runStartNanos = signalStart
            detector?.setBlankUntil(
                signalStart + beepNanos + value.beepBlankingMicros * 1_000,
            )
            listener(
                stateEvent(
                    "running",
                    mapOf("runStartMonotonicMicros" to signalStart / 1_000),
                ),
            )
            resetInactivityTimeout(value)
        }
    }

    private fun playTestBeep() {
        val sampleRate = nativeOutputSampleRate()
        val beep = createBeep(sampleRate)
        val track = buildAudioTrack(sampleRate, beep.size)
        check(track.write(beep, 0, beep.size, AudioTrack.WRITE_BLOCKING) >= 0) {
            "The test signal could not be loaded."
        }
        track.play()
        controlHandler.postDelayed(
            {
                runCatching { track.stop() }
                runCatching { track.release() }
            },
            START_BEEP_DURATION_MILLIS + 100L,
        )
    }

    private fun buildAudioTrack(
        sampleRate: Int,
        sampleCount: Int,
    ): AudioTrack =
        AudioTrack.Builder()
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            ).setAudioFormat(
                AudioFormat.Builder()
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .setSampleRate(sampleRate)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                    .build(),
            ).setTransferMode(AudioTrack.MODE_STATIC)
            .setBufferSizeInBytes(sampleCount * 2)
            .build()

    @Suppress("DEPRECATION")
    private fun vibrate() {
        val vibrator =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                context.getSystemService(VibratorManager::class.java)?.defaultVibrator
            } else {
                context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            }
        if (vibrator?.hasVibrator() != true) return
        vibrator.vibrate(
            VibrationEffect.createOneShot(70, VibrationEffect.DEFAULT_AMPLITUDE),
        )
    }

    private fun resolvePlaybackStartNanos(
        track: AudioTrack,
        sampleRate: Int,
        fallback: Long,
    ): Long {
        val timestamp = AudioTimestamp()
        repeat(10) {
            if (track.getTimestamp(timestamp)) {
                return timestamp.nanoTime - timestamp.framePosition * 1_000_000_000L / sampleRate
            }
            Thread.sleep(2)
        }
        return fallback
    }

    private fun handleDetection(detection: ImpulseDetection) {
        synchronized(stateLock) {
            val start = runStartNanos ?: return
            val elapsedNanos = detection.timestampNanos - start
            if (elapsedNanos < 0) return
            val previous = lastShotNanos
            val splitNanos = if (previous == null) elapsedNanos else detection.timestampNanos - previous
            sequenceNumber += 1
            lastShotNanos = detection.timestampNanos
            listener(
                mapOf(
                    "type" to "shot",
                    "id" to "native-$sequenceNumber-${detection.timestampNanos}",
                    "sequenceNumber" to sequenceNumber,
                    "elapsedMicros" to elapsedNanos / 1_000,
                    "splitMicros" to splitNanos / 1_000,
                    "source" to "acoustic",
                    "disposition" to "counted",
                    "normalizedPeak" to detection.normalizedPeak,
                    "detectionQuality" to detection.quality,
                    "exclusionReason" to null,
                    "saturated" to detection.saturated,
                ),
            )
            val value = configuration ?: return
            resetInactivityTimeout(value)
            if (value.maximumShots != null && sequenceNumber >= value.maximumShots) {
                controlHandler.post {
                    synchronized(stateLock) { stopInternal(emitReviewing = true) }
                }
            }
        }
    }

    private fun emitAudioLevel(samples: ShortArray, count: Int) {
        val now = SystemClock.elapsedRealtimeNanos()
        if (levelLastSentNanos != Long.MIN_VALUE && now - levelLastSentNanos < 100_000_000) return
        var peak = 0
        for (index in 0 until count) {
            peak = maxOf(peak, kotlin.math.abs(samples[index].toInt()).coerceAtMost(32767))
        }
        levelLastSentNanos = now
        listener(
            mapOf(
                "type" to "audioLevel",
                "normalizedLevel" to peak / 32768.0,
            ),
        )
    }

    private fun resetInactivityTimeout(value: NativeTimerConfiguration) {
        controlHandler.removeCallbacks(inactivityRunnable)
        val timeout = value.inactivityTimeoutMicros ?: return
        controlHandler.postDelayed(inactivityRunnable, timeout / 1_000)
    }

    private fun stopInternal(emitReviewing: Boolean) {
        controlHandler.removeCallbacks(beginRunnable)
        controlHandler.removeCallbacks(inactivityRunnable)
        captureRunning.set(false)
        val record = audioRecord
        audioRecord = null
        if (record != null) {
            runCatching { record.stop() }
            runCatching { record.release() }
        }
        val executor = audioExecutor
        audioExecutor = null
        runCatching { executor?.shutdownNow() }
        audioTrack?.let { track ->
            runCatching { track.stop() }
            runCatching { track.release() }
        }
        audioTrack = null
        runStartNanos = null
        if (emitReviewing) listener(stateEvent("reviewing"))
    }

    private fun nativeInputSampleRate(): Int = nativeOutputSampleRate()

    private fun nativeOutputSampleRate(): Int {
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        return audioManager.getProperty(AudioManager.PROPERTY_OUTPUT_SAMPLE_RATE)?.toIntOrNull() ?: 48_000
    }

    private fun createBeep(sampleRate: Int): ShortArray {
        val durationSamples = sampleRate * START_BEEP_DURATION_MILLIS / 1_000
        return ShortArray(durationSamples) { index ->
            val attack = (index.toDouble() / (sampleRate * 0.005)).coerceIn(0.0, 1.0)
            val remaining = durationSamples - index
            val release = (remaining.toDouble() / (sampleRate * 0.008)).coerceIn(0.0, 1.0)
            val envelope = minOf(attack, release)
            (sin(2 * PI * START_BEEP_FREQUENCY_HZ * index / sampleRate) *
                Short.MAX_VALUE * 0.72 * envelope).toInt().toShort()
        }
    }

    private fun stateEvent(
        state: String,
        extra: Map<String, Any?> = emptyMap(),
    ): Map<String, Any?> = mapOf("type" to "state", "state" to state) + extra

    private fun emitError(code: String, message: String) {
        listener(mapOf("type" to "error", "code" to code, "message" to message))
    }

    private fun requireMicrophonePermission() {
        check(context.checkSelfPermission(Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) {
            "Microphone permission is required for acoustic timing."
        }
    }

    companion object {
        const val DETECTOR_VERSION = "impulse-v1"
        private const val START_BEEP_FREQUENCY_HZ = 1_000.0
        private const val START_BEEP_DURATION_MILLIS = 120
    }
}

internal enum class AudioReadAction {
    process,
    retry,
    fail,
}

internal fun classifyAudioRead(read: Int): AudioReadAction =
    when {
        read > 0 -> AudioReadAction.process
        read == 0 -> AudioReadAction.retry
        else -> AudioReadAction.fail
    }

internal fun <T> runAudioStartupWithCleanup(
    cleanup: () -> Unit,
    block: () -> T,
): T =
    try {
        block()
    } catch (error: Throwable) {
        runCatching(cleanup)
        throw error
    }
