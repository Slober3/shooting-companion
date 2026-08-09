package app.shootingcompanion.shot_timer

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioManager
import android.os.Handler
import android.os.Looper
import android.view.WindowManager
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class ShootingCompanionShotTimerPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler,
    ActivityAware,
    PluginRegistry.RequestPermissionsResultListener {
    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null
    private var engine: AcousticShotTimerEngine? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var pendingPrepare: Pair<NativeTimerConfiguration, MethodChannel.Result>? = null
    private var keepScreenOnRequested = false

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL)
        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL)
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
        engine = AcousticShotTimerEngine(context, ::emit)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        setKeepScreenOn(false)
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        eventSink = null
        engine?.dispose()
        engine = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
        applyKeepScreenOnFlag(keepScreenOnRequested)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        detachActivity(
            "Activity changed while requesting microphone permission.",
            preserveKeepScreenOnRequest = true,
        )
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        detachActivity(
            "Activity detached while requesting microphone permission.",
            preserveKeepScreenOnRequest = false,
        )
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "getCapabilities" -> result.success(capabilities())
                "testSignals" -> {
                    val outputs =
                        (argumentsMap(call.arguments)["outputSignals"] as? List<*>)
                            ?.mapNotNull { it as? String }
                            ?.toSet()
                            ?: setOf("sound")
                    requireEngine().testSignals(outputs)
                    result.success(null)
                }
                "prepare" -> {
                    val configuration = NativeTimerConfiguration.fromMap(argumentsMap(call.arguments))
                    prepareWithPermission(configuration, result)
                }
                "start" -> {
                    val delayMicros = requireEngine().start()
                    result.success(mapOf("actualStartDelayMicros" to delayMicros))
                }
                "stop" -> {
                    requireEngine().stop()
                    result.success(mapOf("state" to "reviewing"))
                }
                "abort" -> {
                    val reason = argumentsMap(call.arguments)["reason"] as? String ?: "aborted"
                    requireEngine().abort(reason)
                    result.success(null)
                }
                "dispose" -> {
                    setKeepScreenOn(false)
                    engine?.dispose()
                    engine = AcousticShotTimerEngine(context, ::emit)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (error: SecurityException) {
            result.error("microphone_permission_denied", error.message, null)
        } catch (error: IllegalStateException) {
            val permissionMissing =
                context.checkSelfPermission(Manifest.permission.RECORD_AUDIO) !=
                    PackageManager.PERMISSION_GRANTED
            result.error(
                if (permissionMissing) "microphone_permission_denied" else "invalid_state",
                error.message,
                null,
            )
        } catch (error: IllegalArgumentException) {
            result.error("invalid_configuration", error.message, null)
        } catch (error: Throwable) {
            result.error("native_timer_error", error.message ?: error.javaClass.simpleName, null)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != MICROPHONE_PERMISSION_REQUEST) return false
        val pending = pendingPrepare ?: return true
        pendingPrepare = null
        val granted = grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
        if (!granted) {
            pending.second.error(
                "microphone_permission_denied",
                "Microphone permission was denied.",
                null,
            )
            return true
        }
        completePrepare(pending.first, pending.second)
        return true
    }

    private fun capabilities(): Map<String, Any?> {
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val sampleRate =
            audioManager.getProperty(AudioManager.PROPERTY_OUTPUT_SAMPLE_RATE)?.toIntOrNull() ?: 48_000
        return mapOf(
            "acousticSupported" to true,
            "microphonePermissionGranted" to
                (context.checkSelfPermission(Manifest.permission.RECORD_AUDIO) ==
                    PackageManager.PERMISSION_GRANTED),
            "nativeSampleRate" to sampleRate,
            "detectorVersion" to AcousticShotTimerEngine.DETECTOR_VERSION,
            "storesRawAudio" to false,
            "supportsBackgroundCapture" to false,
        )
    }

    private fun requireEngine(): AcousticShotTimerEngine =
        checkNotNull(engine) { "The native shot timer is not attached." }

    private fun prepareWithPermission(
        configuration: NativeTimerConfiguration,
        result: MethodChannel.Result,
    ) {
        if (
            context.checkSelfPermission(Manifest.permission.RECORD_AUDIO) ==
                PackageManager.PERMISSION_GRANTED
        ) {
            completePrepare(configuration, result)
            return
        }
        if (pendingPrepare != null) {
            result.error(
                "permission_request_in_progress",
                "A microphone permission request is already active.",
                null,
            )
            return
        }
        val activity = activityBinding?.activity
        if (activity == null) {
            result.error(
                "activity_unavailable",
                "Microphone permission can only be requested from the visible timer screen.",
                null,
            )
            return
        }
        pendingPrepare = configuration to result
        activity.requestPermissions(
            arrayOf(Manifest.permission.RECORD_AUDIO),
            MICROPHONE_PERMISSION_REQUEST,
        )
    }

    private fun completePrepare(
        configuration: NativeTimerConfiguration,
        result: MethodChannel.Result,
    ) {
        try {
            result.success(requireEngine().prepare(configuration))
        } catch (error: Throwable) {
            val permissionMissing =
                context.checkSelfPermission(Manifest.permission.RECORD_AUDIO) !=
                    PackageManager.PERMISSION_GRANTED
            result.error(
                if (permissionMissing) "microphone_permission_denied" else "native_timer_error",
                error.message ?: error.javaClass.simpleName,
                null,
            )
        }
    }

    private fun detachActivity(
        reason: String,
        preserveKeepScreenOnRequest: Boolean,
    ) {
        applyKeepScreenOnFlag(false)
        if (!preserveKeepScreenOnRequest) keepScreenOnRequested = false
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
        pendingPrepare?.second?.error("activity_unavailable", reason, null)
        pendingPrepare = null
    }

    private fun emit(event: Map<String, Any?>) {
        mainHandler.post {
            KeepScreenOnPolicy.keepScreenOnFor(event)?.let(::setKeepScreenOn)
            eventSink?.success(event)
        }
    }

    private fun setKeepScreenOn(enabled: Boolean) {
        keepScreenOnRequested = enabled
        applyKeepScreenOnFlag(enabled)
    }

    private fun applyKeepScreenOnFlag(enabled: Boolean) {
        val window = activityBinding?.activity?.window ?: return
        if (enabled) {
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
    }

    private fun argumentsMap(arguments: Any?): Map<String, Any?> {
        val raw = arguments as? Map<*, *> ?: return emptyMap()
        return raw.entries.associate { (key, value) -> key.toString() to value }
    }

    companion object {
        private const val METHOD_CHANNEL = "shooting_companion/shot_timer/methods"
        private const val EVENT_CHANNEL = "shooting_companion/shot_timer/events"
        private const val MICROPHONE_PERMISSION_REQUEST = 7012
    }
}

internal object KeepScreenOnPolicy {
    fun keepScreenOnFor(event: Map<String, Any?>): Boolean? {
        if (event["type"] == "error") return false
        if (event["type"] != "state") return null
        return event["state"] == "startDelay" || event["state"] == "running"
    }
}
