package net.mrecode.mre_quran

import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import org.json.JSONObject

/**
 * A prayer notice. Most often the reminder before a prayer, with the voice
 * that says «اقتربت صلاة …»: the prayer's name, when the adhan is, and the
 * time left as a large countdown to the second. The system redraws a
 * Chronometer itself, so nothing of the app runs while it counts. The notice
 * stays until the adhan and then goes by itself, and has a Remove button.
 *
 * An alarm with `countdown: false` is a plain notice instead (at the prayer
 * time, at the iqama, the adhkar after a prayer, or the reminder before a
 * prayer without its countdown), made as the notifications plugin makes them
 * on the same channels (`ReminderScheduler.scheduleOnce` in Dart).
 */
internal object PrayerSoonNotice {
    @SuppressLint("MissingPermission")
    fun post(context: Context, id: Int, alarm: JSONObject, config: JSONObject, quiet: Boolean = false) {
        if (!alarm.optBoolean("countdown", true)) return postPlain(context, id, alarm, config, quiet)
        val left = alarm.getLong("adhan") - System.currentTimeMillis()
        val notifications = NotificationManagerCompat.from(context)
        if (left <= 0 || !notifications.areNotificationsEnabled()) return
        // A channel for each prayer, because its voice says that prayer's name
        // and a channel keeps the sound it was made with (the ids are
        // ReminderChannel.prayerSoon* in Dart).
        val channel = alarm.getString("channel")
        ensureChannel(context, channel, alarm.optString("channelName", "Prayer"), alarm.optSound(), alarm.optBoolean("urgent"))
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
        val builder = NotificationCompat.Builder(context, channel)
            .setSmallIcon(R.drawable.ic_stat_mre)
            // The plain words stand in where a custom view is not shown.
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setCustomContentView(view)
            .setShowWhen(false)
            .setOngoing(true)
            .setAutoCancel(false)
            .setOnlyAlertOnce(true)
            .setSilent(quiet || silent(alarm, config))
            .setTimeoutAfter(left)
            .setContentIntent(open(context, id, payload(alarm, config)))
            .addAction(0, config.optString("dismissLabel", "Remove"), dismiss(context, id))
        addSettings(context, id, builder, alarm, config)
        notifications.notify(id, builder.build())
    }

    /** A notice that shows and is swiped away like any other. */
    @SuppressLint("MissingPermission")
    private fun postPlain(context: Context, id: Int, alarm: JSONObject, config: JSONObject, quiet: Boolean) {
        val notifications = NotificationManagerCompat.from(context)
        if (!notifications.areNotificationsEnabled()) return
        val channel = alarm.getString("channel")
        val urgent = alarm.optBoolean("urgent")
        ensureChannel(context, channel, alarm.optString("channelName", "Prayer"), alarm.optSound(), urgent)
        val body = alarm.optString("body")
        val builder = NotificationCompat.Builder(context, channel)
            .setSmallIcon(R.drawable.ic_stat_mre)
            .setContentTitle(alarm.optString("title"))
            .setContentText(body)
            // A long body reads whole when the notice is opened.
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(if (urgent) NotificationCompat.PRIORITY_HIGH else NotificationCompat.PRIORITY_DEFAULT)
            .setWhen(alarm.getLong("at"))
            .setAutoCancel(true)
            .setSilent(quiet || silent(alarm, config))
            .setContentIntent(open(context, id, payload(alarm, config)))
        addSettings(context, id, builder, alarm, config)
        notifications.notify(id, builder.build())
    }

    /** Whether [alarm] makes a sound when it comes. */
    fun sounds(alarm: JSONObject, config: JSONObject): Boolean = !silent(alarm, config)

    /**
     * Stops [id]'s sound and keeps the notice: taking a notice away stops its
     * sound, and it is shown again at once without one.
     */
    fun silence(context: Context, id: Int, alarm: JSONObject, config: JSONObject) {
        NotificationManagerCompat.from(context).cancel(id)
        post(context, id, alarm, config, quiet = true)
    }

    /** Whether [alarm] comes without its sound: its own say, else the config's. */
    private fun silent(alarm: JSONObject, config: JSONObject): Boolean =
        if (alarm.has("silent")) alarm.getBoolean("silent") else !config.optBoolean("sound", true)

    /** What a tap on [alarm] opens: its own payload, else the config's. */
    private fun payload(alarm: JSONObject, config: JSONObject): String =
        alarm.optText("payload") ?: config.optString("payload")

    private fun addSettings(
        context: Context,
        id: Int,
        builder: NotificationCompat.Builder,
        alarm: JSONObject,
        config: JSONObject,
    ) {
        val label = config.optText("settingsLabel") ?: return
        val target = alarm.optText("settingsPayload") ?: config.optString("settingsPayload")
        builder.addAction(0, label, open(context, id + SETTINGS_OFFSET, target))
    }

    /** The text at [key], or null when it is missing, empty or null. */
    private fun JSONObject.optText(key: String): String? =
        optString(key).takeIf { it.isNotEmpty() && it != "null" }

    /** The name of the channel's raw sound, or null for the phone's own. */
    private fun JSONObject.optSound(): String? = optText("sound")

    /**
     * Makes the channel as the plugin makes the same channel: urgent ones (the
     * prayer time, the iqama) at high importance, with [sound] (a raw
     * resource) or the phone's notification sound. A channel that exists keeps
     * its sound and importance and only takes the new [name], so it follows
     * the app's language.
     */
    private fun ensureChannel(context: Context, id: String, name: String, sound: String?, urgent: Boolean) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java)
        val importance = if (urgent) NotificationManager.IMPORTANCE_HIGH else NotificationManager.IMPORTANCE_DEFAULT
        val channel = NotificationChannel(id, name, importance).apply {
            if (sound != null) {
                setSound(
                    Uri.parse("android.resource://${context.packageName}/raw/$sound"),
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build(),
                )
            }
        }
        manager.createNotificationChannel(channel)
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
