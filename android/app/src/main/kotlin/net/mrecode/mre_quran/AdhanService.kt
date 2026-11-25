package net.mrecode.mre_quran

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import org.json.JSONObject

/**
 * Plays the adhan with a notice that stays until it is stopped, as an
 * incoming call does: the announcement of the prayer, the adhan, and the
 * dua after it, one after another (see [AdhanAudio.steps]). It stops when
 * the last ends, when the person taps Stop, and (if chosen) when the phone
 * is turned face down or a volume button is pressed.
 */
class AdhanService : Service() {
    private var player: MediaPlayer? = null
    private var flip: FlipDetector? = null
    private var volumeKeys: VolumeKeyStopper? = null
    private var focus: AudioFocusRequest? = null
    private var legacyFocusAcquired = false
    private val legacyFocusListener = AudioManager.OnAudioFocusChangeListener { }
    private val steps = ArrayDeque<() -> MediaPlayer?>()
    private val main = Handler(Looper.getMainLooper())

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
        play(AdhanAudio.steps(this, alarm, config))
        if (config.optBoolean("stopWhenFlipped", true)) {
            flip = FlipDetector(this) { finish() }.also { it.start() }
        }
        if (config.optBoolean("stopWithVolumeKeys", true)) {
            volumeKeys = VolumeKeyStopper(this) { main.post { finish() } }.also { it.start() }
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

    private fun play(sequence: List<() -> MediaPlayer?>) {
        val audio = getSystemService(AudioManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focus = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                .setAudioAttributes(AdhanAudio.alarmAttributes())
                .build()
                .also { audio.requestAudioFocus(it) }
        } else {
            @Suppress("DEPRECATION")
            legacyFocusAcquired = audio.requestAudioFocus(
                legacyFocusListener,
                AudioManager.STREAM_ALARM,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT,
            ) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        }
        steps.clear()
        steps.addAll(sequence)
        playNext()
    }

    /** Plays the next step that has a recording, or ends when none is left. */
    private fun playNext() {
        while (steps.isNotEmpty()) {
            val next = steps.removeFirst().invoke() ?: continue
            next.setOnCompletionListener { done ->
                done.release()
                if (player === done) player = null
                // A breath between the parts, as a muezzin takes.
                main.postDelayed({ playNext() }, GAP_MILLIS)
            }
            next.setOnErrorListener { failed, _, _ ->
                failed.release()
                if (player === failed) player = null
                main.post { playNext() }
                true
            }
            next.start()
            player = next
            return
        }
        finish()
    }

    private fun release() {
        main.removeCallbacksAndMessages(null)
        steps.clear()
        flip?.stop()
        flip = null
        volumeKeys?.stop()
        volumeKeys = null
        player?.let {
            try {
                it.stop()
            } catch (_: IllegalStateException) {
            }
            it.release()
        }
        player = null
        val audio = getSystemService(AudioManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focus?.let { audio.abandonAudioFocusRequest(it) }
        } else if (legacyFocusAcquired) {
            @Suppress("DEPRECATION")
            audio.abandonAudioFocus(legacyFocusListener)
        }
        focus = null
        legacyFocusAcquired = false
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
        private const val GAP_MILLIS = 600L

        /** What the settings button opens: the same as ReminderPayload.adhanSettings in Dart. */
        private const val SETTINGS_PAYLOAD = "adhan:settings"

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
            // Opens the adhan's settings in the app; the adhan plays on.
            val settings = PendingIntent.getActivity(
                context,
                2,
                Intent(context, MainActivity::class.java)
                    .putExtra(EXTRA_PAYLOAD, SETTINGS_PAYLOAD)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP),
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
            config.optString("settingsLabel").takeIf { it.isNotEmpty() && it != "null" }?.let {
                builder.addAction(0, it, settings)
            }
            return builder.build()
        }
    }
}
