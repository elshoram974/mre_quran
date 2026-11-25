package net.mrecode.mre_quran

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject

/**
 * Keeps the reminders that come a while before a prayer and arms them with
 * the system. Like [AdhanScheduler], it stores the list and arms only the next
 * one; when that fires, the one after it is armed, so a month of reminders
 * holds a single system alarm and they come back after a restart without the
 * app running.
 *
 * Besides those reminders it keeps every other prayer notice on Android (at
 * the prayer time, at the iqama, the adhkar after a prayer), so a month of
 * them costs one write instead of hundreds of notifications handed over one
 * by one. Each alarm is `{id, at, title, body, channel, channelName, sound?}`
 * with either `adhan` (a countdown to that time) or `until` and
 * `countdown: false` (a plain notice, not shown after that time); see
 * [PrayerSoonNotice].
 */
internal object PrayerSoonScheduler {
    const val ALARM_ACTION = "net.mrecode.mre_quran.PRAYER_SOON_ALARM"
    const val EXTRA_ID = "id"

    private const val PREFERENCES = "prayer_soon_alarms"
    private const val STORED = "stored"

    /** The id of the one alarm armed with the system, so it alone is cancelled. */
    private const val ARMED = "armed"

    /** Replaces every reminder with [alarms] (a JSON array) sharing [config]. */
    fun schedule(context: Context, alarms: JSONArray, config: JSONObject) {
        cancelAll(context)
        val now = System.currentTimeMillis()
        val future = JSONArray()
        for (index in 0 until alarms.length()) {
            val alarm = alarms.getJSONObject(index)
            if (alarm.getLong("at") > now) future.put(alarm)
        }
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).edit()
            .putString(STORED, JSONObject().put("alarms", future).put("config", config).toString())
            .apply()
        armAll(context)
    }

    /** Arms the next stored reminder that is still ahead. */
    fun armAll(context: Context) = armAfter(context, System.currentTimeMillis())

    /** Arms the first stored reminder after [after]. */
    fun armAfter(context: Context, after: Long) {
        val stored = read(context) ?: return
        val alarms = stored.getJSONArray("alarms")
        var next: JSONObject? = null
        for (index in 0 until alarms.length()) {
            val alarm = alarms.getJSONObject(index)
            if (alarm.getLong("at") > after && (next == null || alarm.getLong("at") < next.getLong("at"))) next = alarm
        }
        next?.let { arm(context, it.getInt("id"), it.getLong("at")) }
    }

    /** Removes every stored reminder and the alarm that is armed. */
    fun cancelAll(context: Context) {
        val preferences = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        val manager = context.getSystemService(AlarmManager::class.java)
        if (preferences.contains(ARMED)) {
            // Only the next one is ever armed: one call, not one per alarm,
            // which kept the app's start waiting.
            manager.cancel(pending(context, preferences.getInt(ARMED, 0)))
        } else {
            // Stored before the armed one was noted: each is cancelled, once.
            val alarms = read(context)?.getJSONArray("alarms")
            if (alarms != null) {
                for (index in 0 until alarms.length()) {
                    manager.cancel(pending(context, alarms.getJSONObject(index).getInt("id")))
                }
            }
        }
        preferences.edit().clear().apply()
    }

    /** The stored reminder [id] and the shared config, or null once it is gone. */
    fun find(context: Context, id: Int): Pair<JSONObject, JSONObject>? {
        val stored = read(context) ?: return null
        val alarms = stored.getJSONArray("alarms")
        for (index in 0 until alarms.length()) {
            val alarm = alarms.getJSONObject(index)
            if (alarm.getInt("id") == id) return alarm to stored.getJSONObject("config")
        }
        return null
    }

    private fun read(context: Context): JSONObject? {
        val raw = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).getString(STORED, null)
        return raw?.let { JSONObject(it) }
    }

    /**
     * Arms [id] at [at], to the minute when the phone allows it: every one,
     * even a notice that could come late, because only one is armed at a time
     * and one held back would hold back the ones after it.
     */
    private fun arm(context: Context, id: Int, at: Long) {
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).edit().putInt(ARMED, id).apply()
        val manager = context.getSystemService(AlarmManager::class.java)
        val exact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || manager.canScheduleExactAlarms()
        val intent = pending(context, id)
        // Without the permission the notice may come a few minutes late.
        if (exact) manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, intent)
        else manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, intent)
    }

    private fun pending(context: Context, id: Int): PendingIntent = PendingIntent.getBroadcast(
        context,
        id,
        Intent(context, PrayerSoonReceiver::class.java)
            .setAction(ALARM_ACTION)
            .setData(Uri.parse("prayersoon://alarm/$id"))
            .putExtra(EXTRA_ID, id),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
}
