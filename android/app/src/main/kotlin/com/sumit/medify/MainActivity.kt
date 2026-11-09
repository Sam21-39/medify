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

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "medify/paths")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "documentsDirectory" -> result.success(applicationContext.filesDir.absolutePath)
                    "temporaryDirectory" -> result.success(applicationContext.cacheDir.absolutePath)
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "medify/speech")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "speak" -> {
                        if (!ttsReady) {
                            result.error("TTS_UNAVAILABLE", "TextToSpeech not ready", null)
                            return@setMethodCallHandler
                        }
                        val text = call.argument<String>("text") ?: ""
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
