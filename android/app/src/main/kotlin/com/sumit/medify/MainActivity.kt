package com.sumit.medify

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import androidx.annotation.RequiresApi
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var tts: TextToSpeech? = null
    private var ttsReady = false

    // On-device speech-to-text state (medify/stt).
    private var sttSink: EventChannel.EventSink? = null
    private var sttRecognizer: SpeechRecognizer? = null
    private var sttLastText = ""
    private var pendingSttStart: MethodChannel.Result? = null

    companion object {
        private const val RECORD_AUDIO_REQUEST = 4201
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        tts = TextToSpeech(this) { status -> ttsReady = status == TextToSpeech.SUCCESS }
    }

    override fun onDestroy() {
        tts?.shutdown()
        tts = null
        sttRecognizer?.destroy()
        sttRecognizer = null
        sttSink = null
        pendingSttStart?.error("cancelled", "activity destroyed", null)
        pendingSttStart = null
        super.onDestroy()
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != RECORD_AUDIO_REQUEST) return
        val result = pendingSttStart ?: return
        pendingSttStart = null
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
            // This callback can run on any API level, so re-check the API 33 requirement before beginStt.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                beginStt(result)
            } else {
                result.error("unavailable", "on-device speech recognition needs Android 13", null)
            }
        } else {
            result.error("permission_denied", "microphone not authorized", null)
        }
    }

    private fun startStt(result: MethodChannel.Result) {
        cancelStt()
        // On-device only (privacy: health data). API 33+ with an on-device model, else manual entry.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.error("unavailable", "on-device speech recognition needs Android 13", null)
            return
        }
        if (!SpeechRecognizer.isOnDeviceRecognitionAvailable(this)) {
            result.error("unavailable", "on-device speech recognition not available", null)
            return
        }
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            pendingSttStart = result
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.RECORD_AUDIO), RECORD_AUDIO_REQUEST)
            return
        }
        beginStt(result)
    }

    // Only reached from startStt, after the API 33 and on-device checks pass.
    @RequiresApi(Build.VERSION_CODES.TIRAMISU)
    private fun beginStt(result: MethodChannel.Result) {
        val recognizer = SpeechRecognizer.createOnDeviceSpeechRecognizer(this)
        sttRecognizer = recognizer
        recognizer.setRecognitionListener(object : RecognitionListener {
            // Callbacks from a recognizer that was cancelled or replaced are ignored.
            override fun onPartialResults(bundle: Bundle?) {
                if (sttRecognizer !== recognizer) return
                val text = sttText(bundle) ?: return
                sttLastText = text
                sttSink?.success(mapOf("type" to "partial", "text" to text))
            }

            override fun onResults(bundle: Bundle?) {
                if (sttRecognizer !== recognizer) return
                sttText(bundle)?.let { sttLastText = it }
                finishStt()
            }

            override fun onError(error: Int) {
                if (sttRecognizer !== recognizer) return
                // Keep a partial transcript rather than discarding it on a late error.
                if (error == SpeechRecognizer.ERROR_NO_MATCH || error == SpeechRecognizer.ERROR_SPEECH_TIMEOUT || sttLastText.isNotBlank()) {
                    finishStt()
                } else {
                    releaseStt()
                    sttSink?.success(mapOf("type" to "error", "code" to "unavailable"))
                }
            }

            override fun onReadyForSpeech(params: Bundle?) {}
            override fun onBeginningOfSpeech() {}
            override fun onRmsChanged(rmsdB: Float) {}
            override fun onBufferReceived(buffer: ByteArray?) {}
            override fun onEndOfSpeech() {}
            override fun onEvent(eventType: Int, params: Bundle?) {}
        })
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
        }
        sttLastText = ""
        recognizer.startListening(intent)
        result.success(null)
    }

    /// Delivers the final transcript once, then releases the recognizer.
    private fun finishStt() {
        releaseStt()
        sttSink?.success(mapOf("type" to "final", "text" to sttLastText))
    }

    private fun releaseStt() {
        sttRecognizer?.destroy()
        sttRecognizer = null
    }

    /// Ends the session now, with no final result. A start still waiting on the permission prompt is cancelled.
    private fun cancelStt() {
        pendingSttStart?.error("cancelled", "start superseded", null)
        pendingSttStart = null
        releaseStt()
        sttLastText = ""
    }

    private fun sttText(bundle: Bundle?): String? =
        bundle?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "medify/stt")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> startStt(result)
                    "stop" -> {
                        // Stop while the permission prompt is open: cancel the pending start.
                        if (pendingSttStart != null) cancelStt() else sttRecognizer?.stopListening()
                        result.success(null)
                    }
                    "cancel" -> {
                        cancelStt()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "medify/stt/events")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    sttSink = events
                }

                override fun onCancel(arguments: Any?) {
                    sttSink = null
                }
            })
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "medify/paths")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "documentsDirectory" -> result.success(applicationContext.filesDir.absolutePath)
                    "legacyDocumentsDirectory" -> result.success(applicationContext.getDir("flutter", MODE_PRIVATE).absolutePath)
                    "temporaryDirectory" -> result.success(applicationContext.cacheDir.absolutePath)
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "medify/prefs")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "clearLegacyPrefs" -> {
                        val cleared = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
                            .edit().clear().commit()
                        if (cleared) result.success(null)
                        else result.error("PREFS_CLEAR_FAILED", "could not clear legacy prefs", null)
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "medify/timezone")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getLocalTimezone" -> result.success(java.util.TimeZone.getDefault().id)
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "medify/speech")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "speak" -> {
                        val text = call.argument<String>("text")
                        if (text == null) {
                            result.error("BAD_ARGS", "text is required", null)
                            return@setMethodCallHandler
                        }
                        if (!ttsReady) {
                            result.error("TTS_UNAVAILABLE", "TextToSpeech not ready", null)
                            return@setMethodCallHandler
                        }
                        tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, System.currentTimeMillis().toString())
                        result.success(null)
                    }
                    "stop" -> {
                        tts?.stop()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
