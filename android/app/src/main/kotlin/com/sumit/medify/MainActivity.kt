package com.sumit.medify

import android.os.Bundle
import android.speech.tts.TextToSpeech
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var tts: TextToSpeech? = null
    private var ttsReady = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        tts = TextToSpeech(this) { status -> ttsReady = status == TextToSpeech.SUCCESS }
    }

    override fun onDestroy() {
        tts?.shutdown()
        tts = null
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
