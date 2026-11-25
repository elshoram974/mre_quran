package net.mrecode.mre_quran

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.media.VolumeProvider
import android.media.session.MediaSession
import android.media.session.PlaybackState
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import androidx.core.content.ContextCompat

/**
 * Calls [onPress] when a volume button is pressed while the adhan or a
 * notice's voice plays, as a press silences a ringing call, with the app open
 * or not and the screen on or off.
 *
 * With the screen off, Android hands the volume keys to the media that is
 * playing, or to nobody when none is: the adhan and the notices play as an
 * alarm or a notification, not as media, so on their own they never got the
 * keys. So, while listening:
 *
 * - a silent track plays as media, which makes this app the one playing
 *   media: the keys come to it with the screen off too;
 * - a media session that owns its volume gets each press, even at the end of
 *   the volume where nothing would change (a session hands a press to its
 *   volume only through its callback, so it has an empty one);
 * - the system's note that a volume changed catches a press any other way,
 *   and a media volume a press moved is put back where it was. A note that
 *   moved nothing, or that only says the volume was put back, is not a press.
 *
 * Presses in the first moment are ignored, so a key already held when the
 * sound began does not stop it.
 */
internal class VolumeKeyStopper(
    private val context: Context,
    private val onPress: () -> Unit,
) {
    private var session: MediaSession? = null
    private var silence: AudioTrack? = null
    private var registered = false
    private var since = 0L
    private var mediaVolume = -1

    private val audio = context.getSystemService(AudioManager::class.java)

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val stream = intent.getIntExtra(EXTRA_STREAM, -1)
            val value = intent.getIntExtra(EXTRA_VALUE, -1)
            if (value == intent.getIntExtra(EXTRA_PREVIOUS, -1)) return
            if (stream == AudioManager.STREAM_MUSIC && mediaVolume >= 0) {
                // Only the media volume being put back, below.
                if (value == mediaVolume) return
                // A press moved the media volume (the silent track made media
                // the stream the keys move): it goes back where it was.
                try {
                    audio.setStreamVolume(AudioManager.STREAM_MUSIC, mediaVolume, 0)
                } catch (_: SecurityException) {
                }
            }
            press()
        }
    }

    /**
     * Starts listening. Whatever part of it the phone refuses is let go, so
     * the sound it listens for goes on regardless.
     */
    fun start() {
        try {
            listen()
        } catch (_: RuntimeException) {
            stop()
        }
    }

    private fun listen() {
        since = SystemClock.elapsedRealtime()
        mediaVolume = audio.getStreamVolume(AudioManager.STREAM_MUSIC)
        silence = silentTrack()?.also {
            try {
                it.play()
            } catch (_: IllegalStateException) {
            }
        }
        session = MediaSession(context, "adhan").apply {
            setCallback(object : MediaSession.Callback() {}, Handler(Looper.getMainLooper()))
            setPlaybackToRemote(
                object : VolumeProvider(VOLUME_CONTROL_RELATIVE, STEPS, STEPS / 2) {
                    override fun onAdjustVolume(direction: Int) {
                        if (direction != 0) press()
                    }

                    override fun onSetVolumeTo(volume: Int) = press()
                },
            )
            setPlaybackState(
                PlaybackState.Builder()
                    .setState(PlaybackState.STATE_PLAYING, 0, 1f)
                    .build(),
            )
            isActive = true
        }
        ContextCompat.registerReceiver(
            context,
            receiver,
            IntentFilter(VOLUME_CHANGED),
            ContextCompat.RECEIVER_NOT_EXPORTED,
        )
        registered = true
    }

    /** Stops listening. */
    fun stop() {
        silence?.run {
            try {
                stop()
            } catch (_: IllegalStateException) {
            }
            release()
        }
        silence = null
        session?.run {
            isActive = false
            release()
        }
        session = null
        if (registered) {
            try {
                context.unregisterReceiver(receiver)
            } catch (_: IllegalArgumentException) {
            }
            registered = false
        }
    }

    private fun press() {
        if (SystemClock.elapsedRealtime() - since < SETTLE_MILLIS) return
        onPress()
    }

    /**
     * A second of silence that loops, played as media without asking for the
     * audio focus, so nothing else the person listens to pauses for it.
     */
    private fun silentTrack(): AudioTrack? {
        val rate = 8000
        val frames = rate
        return try {
            AudioTrack.Builder()
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_UNKNOWN)
                        .build(),
                )
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setSampleRate(rate)
                        .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                        .build(),
                )
                .setTransferMode(AudioTrack.MODE_STATIC)
                .setBufferSizeInBytes(frames * 2)
                .build()
                .apply {
                    write(ShortArray(frames), 0, frames)
                    setLoopPoints(0, frames, -1)
                }
        } catch (_: Exception) {
            null
        }
    }

    private companion object {
        /** The system's broadcast when a stream's volume changes. */
        const val VOLUME_CHANGED = "android.media.VOLUME_CHANGED_ACTION"

        /** Which stream it was, in that broadcast. */
        const val EXTRA_STREAM = "android.media.EXTRA_VOLUME_STREAM_TYPE"

        /** Its volume now, and before, in that broadcast. */
        const val EXTRA_VALUE = "android.media.EXTRA_VOLUME_STREAM_VALUE"
        const val EXTRA_PREVIOUS = "android.media.EXTRA_PREV_VOLUME_STREAM_VALUE"

        const val STEPS = 10
        const val SETTLE_MILLIS = 800L
    }
}
