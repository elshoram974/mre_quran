package net.mrecode.mre_quran

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.PowerManager
import org.json.JSONObject
import java.io.File

/** Builds the players for the adhan and for previews. */
internal object AdhanAudio {
    /** How the alert sounds: as an alarm, so it follows the alarm volume. */
    fun alarmAttributes(): AudioAttributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_ALARM)
        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
        .build()

    fun attributesForPreview(): AudioAttributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_MEDIA)
        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
        .build()

    /**
     * What plays at prayer time, in order: the announcement of the prayer
     * ("حان الآن موعد أذان الظهر"), the adhan (the Fajr one at Fajr, with
     * "الصلاة خير من النوم"), then the dua after the adhan. Each step makes
     * its player when its turn comes; a step whose recording the app does
     * not have gives null and is passed over.
     */
    fun steps(context: Context, alarm: JSONObject, config: JSONObject): List<() -> MediaPlayer?> {
        val attributes = alarmAttributes()
        val fajr = alarm.optBoolean("fajr", false)
        val steps = mutableListOf<() -> MediaPlayer?>()
        val announce = alarm.optString("announce")
        if (config.optBoolean("announce", true) && announce.isNotEmpty()) {
            steps += { raw(context, "announce_$announce", attributes) }
        }
        val path = config.optString(if (fajr) "fajrVoicePath" else "voicePath")
            .takeIf { it.isNotEmpty() && it != "null" }
        steps += { savedFile(context, path, attributes) ?: bundled(context, attributes, fajr) }
        if (config.optBoolean("duaAfter", true)) {
            steps += { raw(context, "dua_after_adhan", attributes) }
        }
        return steps
    }

    /** The adhan that ships with the app: the Fajr one when [fajr]. */
    fun bundled(context: Context, attributes: AudioAttributes, fajr: Boolean): MediaPlayer? =
        (if (fajr) raw(context, "adhan_fajr", attributes) else null)
            ?: raw(context, "adhan_default", attributes)

    /**
     * A prepared player of the raw recording [name], or null when the app
     * has none by that name. Names are looked up, so a recording can be
     * added or left out without a code change; `res/raw/keep.xml` keeps them
     * through resource shrinking.
     */
    fun raw(context: Context, name: String, attributes: AudioAttributes): MediaPlayer? {
        val id = context.resources.getIdentifier(name, "raw", context.packageName)
        if (id == 0) return null
        return try {
            val player = MediaPlayer()
            player.setAudioAttributes(attributes)
            context.resources.openRawResourceFd(id).use {
                player.setDataSource(it.fileDescriptor, it.startOffset, it.length)
            }
            player.setWakeMode(context, PowerManager.PARTIAL_WAKE_LOCK)
            player.prepare()
            player
        } catch (_: Exception) {
            null
        }
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
