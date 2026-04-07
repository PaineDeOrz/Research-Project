package com.example.musik_app

import android.content.Intent
import android.media.audiofx.AudioEffect
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "com.example.musik_app/equalizer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openEqualizer" -> {
                    val audioSessionId = call.argument<Int>("audioSessionId") ?: 0
                    val success = openSystemEqualizer(audioSessionId)
                    result.success(success)
                }
                "isEqualizerAvailable" -> {
                    result.success(isEqualizerAvailable())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun openSystemEqualizer(audioSessionId: Int): Boolean {
        return try {
            val intent = Intent(AudioEffect.ACTION_DISPLAY_AUDIO_EFFECT_CONTROL_PANEL).apply {
                putExtra(AudioEffect.EXTRA_AUDIO_SESSION, audioSessionId)
                putExtra(AudioEffect.EXTRA_PACKAGE_NAME, packageName)
                putExtra(AudioEffect.EXTRA_CONTENT_TYPE, AudioEffect.CONTENT_TYPE_MUSIC)
            }

            if (intent.resolveActivity(packageManager) != null) {
                startActivityForResult(intent, 0)
                true
            } else {
                false
            }
        } catch (exception: Exception) {
            false
        }
    }

    private fun isEqualizerAvailable(): Boolean {
        val intent = Intent(AudioEffect.ACTION_DISPLAY_AUDIO_EFFECT_CONTROL_PANEL)
        return intent.resolveActivity(packageManager) != null
    }
}
