package net.mrecode.mre_quran

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.VolumeProvider
import android.media.session.MediaSession
import android.media.session.PlaybackState
import android.os.SystemClock
import androidx.core.content.ContextCompat

/**
 * Calls [onPress] when a volume button is pressed while the adhan plays, as a
 * press silences a ringing call.
 *
 * Two ways, because phones route the keys differently: a media session that
 * owns its volume gets the presses (even when the volume is already at its
 * end, where it would not change), and the system's note that a volume
 * changed catches the rest. Presses in the first moment are ignored, so the
 * adhan is not stopped by a key already held when it began.
 */
internal class VolumeKeyStopper(
    private val context: Context,
    private val onPress: () -> Unit,
) {
    private var session: MediaSession? = null
    private var registered = false
    private var since = 0L

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) = press()
    }

    /** Starts listening. */
    fun start() {
        since = SystemClock.elapsedRealtime()
        session = MediaSession(context, "adhan").apply {
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

    private companion object {
        /** The system's broadcast when a stream's volume changes. */
        const val VOLUME_CHANGED = "android.media.VOLUME_CHANGED_ACTION"

        const val STEPS = 10
        const val SETTLE_MILLIS = 800L
    }
}
