package net.mrecode.mre_quran

import android.content.Context
import android.content.Intent
import com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver
import org.json.JSONArray
import org.json.JSONObject
import java.time.DateTimeException
import java.time.LocalDateTime
import java.time.ZoneId

/** Prevents the notification fallback from ringing for yesterday's prayers (or fasts) on reboot. */
class ReminderBootReceiver : ScheduledNotificationBootReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // flutter_local_notifications 22 stores zoned one-shot and daily alerts
        // together. Keep the plugin's own boot/upgrade handling for future and
        // recurring entries, including recurring entries whose first date passed.
        val key = "scheduled_notifications"
        val preferences = context.getSharedPreferences(key, Context.MODE_PRIVATE)
        preferences.getString(key, null)?.let { json ->
            val records = JSONArray(json)
            val now = System.currentTimeMillis()
            val keep = JSONArray()
            for (index in 0 until records.length()) {
                val record = records.optJSONObject(index)
                if (record == null || !expiredPrayer(record, now)) keep.put(records.get(index))
            }
            if (keep.length() != records.length()) preferences.edit().putString(key, keep.toString()).apply()
        }
        super.onReceive(context, intent)
    }

    private fun expiredPrayer(record: JSONObject, now: Long): Boolean {
        if (record.optString("channelId") !in setOf("prayer_time", "prayer_soon", "prayer_iqama", "adhkar_reminders", "fasting_reminders")) return false
        if (!record.isNull("matchDateTimeComponents") || !record.isNull("repeatInterval") ||
            !record.isNull("scheduledNotificationRepeatFrequency") || !record.isNull("repeatIntervalMilliseconds")) return false
        return try {
            val at = LocalDateTime.parse(record.optString("scheduledDateTime"))
                .atZone(ZoneId.of(record.optString("timeZoneName"))).toInstant().toEpochMilli()
            at <= now
        } catch (_: DateTimeException) {
            false
        }
    }
}
