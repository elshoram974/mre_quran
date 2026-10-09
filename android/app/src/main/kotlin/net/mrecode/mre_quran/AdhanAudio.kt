package net.mrecode.mre_quran

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.PowerManager
import java.io.File

/** Builds the players for the adhan and for previews. */
internal object AdhanAudio {
    /**
     * A prepared player for the saved file at [path], or for the bundled
     * recording when [path] is null, missing, or cannot be played.
     */
    fun alarmPlayer(context: Context, path: String?): MediaPlayer? {
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
            .build()
        return savedFile(context, path, attributes) ?: bundled(context, attributes)
    }

    fun attributesForPreview(): AudioAttributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_MEDIA)
        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
        .build()

    fun bundled(context: Context, attributes: AudioAttributes): MediaPlayer? = try {
        val player = MediaPlayer()
        player.setAudioAttributes(attributes)
        context.resources.openRawResourceFd(R.raw.adhan_default).use {
            player.setDataSource(it.fileDescriptor, it.startOffset, it.length)
        }
        player.setWakeMode(context, PowerManager.PARTIAL_WAKE_LOCK)
        player.prepare()
        player
    } catch (_: Exception) {
        null
    }

    fun savedFile(context: Context, path: String?, attributes: AudioAttributes): MediaPlayer? {
        if (path.isNullOrEmpty() || !File(path).exists()) return null
        return try {
            val player = MediaPlayer()
            player.setAudioAttributes(attributes)
            player.setDataSource(path)
            player.setWakeMode(context, PowerManager.PARTIAL_WAKE_LOCK)
            player.prepare()
            player
        } catch (_: Exception) {
            null
        }
    }
}
