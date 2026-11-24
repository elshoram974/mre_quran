package net.mrecode.mre_quran

import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import org.json.JSONObject

/**
 * The reminder before a prayer: the prayer's name, when the adhan is, and the
 * time left as a large countdown to the second. The system redraws a
 * Chronometer itself, so nothing of the app runs while it counts. The notice
 * stays until the adhan and then goes by itself, and has a Remove button.
 */
internal object PrayerSoonNotice {
    /** The channel the reminder has always been in, so the person's choices for it stay. */
    private const val CHANNEL_ID = "prayer_soon"

    @SuppressLint("MissingPermission")
    fun post(context: Context, id: Int, alarm: JSONObject, config: JSONObject) {
        val left = alarm.getLong("adhan") - System.currentTimeMillis()
        val notifications = NotificationManagerCompat.from(context)
        if (left <= 0 || !notifications.areNotificationsEnabled()) return
        ensureChannel(context, config.optString("channelName", "Prayer"))
        val title = alarm.optString("title")
        val body = alarm.optString("body")
        val view = RemoteViews(context.packageName, R.layout.prayer_soon_notice).apply {
            setTextViewText(R.id.soon_title, title)
            setTextViewText(R.id.soon_body, body)
            setChronometer(R.id.soon_timer, SystemClock.elapsedRealtime() + left, null, true)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) setChronometerCountDown(R.id.soon_timer, true)
            // The notice follows the app's language, not the phone's.
            setInt(
                R.id.soon_root,
                "setLayoutDirection",
                if (config.optBoolean("rtl", true)) View.LAYOUT_DIRECTION_RTL else View.LAYOUT_DIRECTION_LTR,
            )
        }
        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            // The plain words stand in where a custom view is not shown.
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setCustomContentView(view)
            .setShowWhen(false)
            .setOngoing(true)
            .setAutoCancel(false)
            .setOnlyAlertOnce(true)
            .setTimeoutAfter(left)
            .setContentIntent(open(context, id, config.optString("payload")))
            .addAction(0, config.optString("dismissLabel", "Remove"), dismiss(context, id))
        config.optString("settingsLabel").takeIf { it.isNotEmpty() && it != "null" }?.let {
            builder.addAction(0, it, open(context, id + SETTINGS_OFFSET, config.optString("settingsPayload")))
        }
        notifications.notify(id, builder.build())
    }

    private fun ensureChannel(context: Context, name: String) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        context.getSystemService(NotificationManager::class.java).createNotificationChannel(
            NotificationChannel(CHANNEL_ID, name, NotificationManager.IMPORTANCE_DEFAULT),
        )
    }

    /** Opens the app at what [payload] names (see the reminder payloads in Dart). */
    private fun open(context: Context, requestCode: Int, payload: String): PendingIntent = PendingIntent.getActivity(
        context,
        requestCode,
        Intent(context, MainActivity::class.java)
            .putExtra(AdhanService.EXTRA_PAYLOAD, payload)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    private fun dismiss(context: Context, id: Int): PendingIntent = PendingIntent.getBroadcast(
        context,
        id,
        Intent(context, PrayerSoonReceiver::class.java)
            .setAction(PrayerSoonReceiver.ACTION_DISMISS)
            .putExtra(PrayerSoonScheduler.EXTRA_ID, id),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    /** Keeps the settings button's request code apart from the tap's and Remove's. */
    private const val SETTINGS_OFFSET = 1_000_000
}
