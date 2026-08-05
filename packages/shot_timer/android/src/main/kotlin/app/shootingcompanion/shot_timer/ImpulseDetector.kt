package app.shootingcompanion.shot_timer

import kotlin.math.abs
import kotlin.math.max
import kotlin.math.sqrt

internal data class ImpulseDetectorConfiguration(
    val sensitivity: Double = 0.6,
    val echoLockoutNanos: Long = 80_000_000,
    val minimumCrestFactor: Double = 2.2,
    val windowSamples: Int = 48,
    val noiseSmoothing: Double = 0.04,
) {
    init {
        require(sensitivity in 0.0..1.0)
        require(echoLockoutNanos >= 0)
        require(minimumCrestFactor > 1)
        require(windowSamples >= 8)
        require(noiseSmoothing in 0.0..1.0)
    }
}

internal data class ImpulseDetection(
    val timestampNanos: Long,
    val normalizedPeak: Double,
    val quality: String,
    val saturated: Boolean,
)

/**
 * Stateful, allocation-light impulse detector for mono PCM16 input.
 *
 * It intentionally returns only timing and signal diagnostics. PCM data is
 * never retained after [process] returns.
 */
internal class ImpulseDetector(
    private val configuration: ImpulseDetectorConfiguration,
) {
    private var noiseRms = 0.004
    private var lastDetectionNanos = Long.MIN_VALUE
    private var blankUntilNanos = Long.MIN_VALUE

    fun reset(blankUntilNanos: Long = Long.MIN_VALUE) {
        noiseRms = 0.004
        lastDetectionNanos = Long.MIN_VALUE
        this.blankUntilNanos = blankUntilNanos
    }

    fun setBlankUntil(timestampNanos: Long) {
        blankUntilNanos = timestampNanos
    }

    fun currentNoiseRms(): Double = noiseRms

    fun process(
        samples: ShortArray,
        validSampleCount: Int,
        bufferStartNanos: Long,
        sampleRate: Int,
    ): List<ImpulseDetection> {
        require(validSampleCount in 0..samples.size)
        require(sampleRate > 0)
        if (validSampleCount == 0) return emptyList()

        val detections = mutableListOf<ImpulseDetection>()
        var offset = 0
        while (offset < validSampleCount) {
            val end = minOf(offset + configuration.windowSamples, validSampleCount)
            var peak = 0
            var peakIndex = offset
            var sumSquares = 0.0
            for (index in offset until end) {
                val absolute = abs(samples[index].toInt()).coerceAtMost(32767)
                if (absolute > peak) {
                    peak = absolute
                    peakIndex = index
                }
                val normalized = absolute / 32768.0
                sumSquares += normalized * normalized
            }
            val count = end - offset
            val rms = sqrt(sumSquares / count)
            val normalizedPeak = peak / 32768.0
            val crest = if (rms <= 1e-9) 0.0 else normalizedPeak / rms
            val thresholdMultiplier = 11.0 - 7.5 * configuration.sensitivity
            val absoluteFloor = 0.22 - 0.17 * configuration.sensitivity
            val threshold = max(absoluteFloor, noiseRms * thresholdMultiplier)
            val peakTimestamp =
                bufferStartNanos + (peakIndex * 1_000_000_000L / sampleRate)
            val isImpulse =
                peakTimestamp >= blankUntilNanos &&
                    normalizedPeak >= threshold &&
                    crest >= configuration.minimumCrestFactor

            if (isImpulse) {
                val outsideEchoWindow =
                    lastDetectionNanos == Long.MIN_VALUE ||
                        peakTimestamp - lastDetectionNanos >= configuration.echoLockoutNanos
                if (outsideEchoWindow) {
                    val strength = normalizedPeak / threshold
                    val quality =
                        when {
                            strength >= 2.0 && crest >= 4.0 -> "high"
                            strength >= 1.35 && crest >= 2.8 -> "medium"
                            else -> "low"
                        }
                    detections +=
                        ImpulseDetection(
                            timestampNanos = peakTimestamp,
                            normalizedPeak = normalizedPeak.coerceIn(0.0, 1.0),
                            quality = quality,
                            saturated = peak >= 32760,
                        )
                    lastDetectionNanos = peakTimestamp
                }
            } else {
                noiseRms += (rms - noiseRms) * configuration.noiseSmoothing
            }
            offset = end
        }
        return detections
    }
}
