package net.mrecode.mre_quran

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import org.json.JSONObject

/**
 * Plays the adhan with a notice that stays until it is stopped, as an
 * incoming call does. It stops when the recording ends, when the person taps
 * Stop, and (if chosen) when the phone is turned face down.
 */
class AdhanService : Service() {
    private var player: MediaPlayer? = null
    private var flip: FlipDetector? = null
    private var focus: AudioFocusRequest? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null || intent.action == ACTION_STOP) {
            finish()
            return START_NOT_STICKY
        }
        val alarm = JSONObject(intent.getStringExtra(EXTRA_ALARM) ?: "{}")
        val config = JSONObject(intent.getStringExtra(EXTRA_CONFIG) ?: "{}")
        // A second adhan replaces the first.
        release()
        showNotice(alarm, config)
        play(config.optString("voicePath").takeIf { it.isNotEmpty() && it != "null" })
        if (config.optBoolean("stopWhenFlipped", true)) {
            flip = FlipDetector(this) { finish() }.also { it.start() }
        }
        return START_NOT_STICKY
    }

    private fun showNotice(alarm: JSONObject, config: JSONObject) {
        val notice = notice(this, alarm, config, ongoing = true)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTICE_ID, notice, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        } else {
            startForeground(NOTICE_ID, notice)
        }
    }

    private fun play(path: String?) {
        val audio = getSystemService(AudioManager::class.java)
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
            .build()
        focus = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
            .setAudioAttributes(attributes)
            .build()
            .also { audio.requestAudioFocus(it) }
        val next = AdhanAudio.alarmPlayer(this, path)
        if (next == null) {
            finish()
            return
        }
        next.setOnCompletionListener { finish() }
        next.setOnErrorListener { _, _, _ -> finish(); true }
        next.start()
        player = next
    }

    private fun release() {
        flip?.stop()
        flip = null
        player?.let {
            try {
                it.stop()
            } catch (_: IllegalStateException) {
            }
            it.release()
        }
        player = null
        focus?.let { getSystemService(AudioManager::class.java).abandonAudioFocusRequest(it) }
        focus = null
    }

    private fun finish() {
        release()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    override fun onDestroy() {
        release()
        super.onDestroy()
    }

    companion object {
        const val ACTION_STOP = "net.mrecode.mre_quran.ADHAN_STOP"
        const val EXTRA_ALARM = "alarm"
        const val EXTRA_CONFIG = "config"
        const val EXTRA_PAYLOAD = "adhan_payload"
        private const val CHANNEL_ID = "adhan_call"
        private const val NOTICE_ID = 7001

        /** Starts the adhan now. Throws if the system will not allow it. */
        fun start(context: Context, alarm: JSONObject, config: JSONObject) {
            val intent = Intent(context, AdhanService::class.java)
                .putExtra(EXTRA_ALARM, alarm.toString())
                .putExtra(EXTRA_CONFIG, config.toString())
            ContextCompat.startForegroundService(context, intent)
        }

        /** The notice: loud on screen, with Stop, and opening the app on a tap. */
        fun notice(context: Context, alarm: JSONObject, config: JSONObject, ongoing: Boolean): Notification {
            val manager = context.getSystemService(NotificationManager::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                // Sound is the player's, not the channel's.
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    config.optString("channelName", "Adhan"),
                    NotificationManager.IMPORTANCE_HIGH,
                ).apply { setSound(null, null) }
                manager.createNotificationChannel(channel)
            }
            val open = PendingIntent.getActivity(
                context,
                0,
                Intent(context, MainActivity::class.java)
                    .putExtra(EXTRA_PAYLOAD, config.optString("payload"))
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            val stop = PendingIntent.getService(
                context,
                1,
                Intent(context, AdhanService::class.java).setAction(ACTION_STOP),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            val builder = NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(alarm.optString("title"))
                .setContentText(alarm.optString("body"))
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setOngoing(ongoing)
                .setOnlyAlertOnce(true)
                .setContentIntent(open)
                .addAction(0, config.optString("stopLabel", "Stop"), stop)
                .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            return builder.build()
        }
    }
}
