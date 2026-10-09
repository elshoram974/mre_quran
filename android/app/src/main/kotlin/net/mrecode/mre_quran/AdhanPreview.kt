package net.mrecode.mre_quran

import android.content.Context
import android.media.MediaPlayer
import android.net.Uri
import org.json.JSONObject

/** Plays a voice for the person to hear in the app. One at a time. */
internal class AdhanPreview(
    private val context: Context,
    private val onEnded: () -> Unit,
) {
    private var player: MediaPlayer? = null

    /** Starts [source] (kind: bundled, file or stream), replacing any preview. */
    fun start(source: JSONObject) {
        stop()
        val attributes = AdhanAudio.attributesForPreview()
        try {
            when (source.getString("kind")) {
                "bundled" -> begin(AdhanAudio.bundled(context, attributes))
                "file" -> begin(AdhanAudio.savedFile(context, source.getString("path"), attributes))
                else -> stream(source, attributes)
            }
        } catch (_: Exception) {
            stop()
            onEnded()
        }
    }

    private fun begin(prepared: MediaPlayer?) {
        if (prepared == null) {
            onEnded()
            return
        }
        prepared.setOnCompletionListener { stop(); onEnded() }
        prepared.start()
        player = prepared
    }

    private fun stream(source: JSONObject, attributes: android.media.AudioAttributes) {
        val next = MediaPlayer()
        next.setAudioAttributes(attributes)
        next.setDataSource(
            context,
            Uri.parse(source.getString("url")),
            mapOf("User-Agent" to source.optString("userAgent", "MREQuran")),
        )
        next.setOnPreparedListener { it.start() }
        next.setOnCompletionListener { stop(); onEnded() }
        next.setOnErrorListener { _, _, _ -> stop(); onEnded(); true }
        next.prepareAsync()
        player = next
    }

    fun stop() {
        player?.let {
            try {
                it.stop()
            } catch (_: IllegalStateException) {
            }
            it.release()
        }
        player = null
    }
}
