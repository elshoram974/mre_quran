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
 * Keeps the adhan alarms and arms them with the system. The list is stored
 * here too, so it can be armed again after a restart without the app running.
 */
internal object AdhanScheduler {
    const val ALARM_ACTION = "net.mrecode.mre_quran.ADHAN_ALARM"
    const val EXTRA_ID = "id"

    private const val TEST_ID = 7009999
    private const val TEST_DELAY_MILLIS = 3_000L
    private const val PREFERENCES = "adhan_alarms"
    private const val STORED = "stored"

    /** Replaces every alarm with [alarms] (a JSON array) sharing [config]. */
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

    /** Arms the stored alarms that are still ahead. */
    fun armAll(context: Context) {
        val stored = read(context) ?: return
        val alarms = stored.getJSONArray("alarms")
        val now = System.currentTimeMillis()
        for (index in 0 until alarms.length()) {
            val alarm = alarms.getJSONObject(index)
            if (alarm.getLong("at") > now) arm(context, alarm.getInt("id"), alarm.getLong("at"))
        }
    }

    fun cancelAll(context: Context) {
        val stored = read(context)
        if (stored != null) {
            val alarms = stored.getJSONArray("alarms")
            val manager = context.getSystemService(AlarmManager::class.java)
            for (index in 0 until alarms.length()) {
                manager.cancel(pending(context, alarms.getJSONObject(index).getInt("id")))
            }
        }
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).edit().clear().apply()
    }

    /**
     * Fires [alarm] in a few seconds through the same alarm path as a real
     * prayer, so a test proves the alarm, the receiver and the player work.
     * Returns false (and does nothing) when exact alarms are not allowed.
     */
    fun test(context: Context, alarm: JSONObject, config: JSONObject): Boolean {
        val manager = context.getSystemService(AlarmManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !manager.canScheduleExactAlarms()) return false
        val intent = PendingIntent.getBroadcast(
            context,
            TEST_ID,
            Intent(context, AdhanAlarmReceiver::class.java)
                .setAction(ALARM_ACTION)
                .setData(Uri.parse("adhan://alarm/test"))
                .putExtra(EXTRA_ID, TEST_ID)
                .putExtra(AdhanService.EXTRA_ALARM, alarm.toString())
                .putExtra(AdhanService.EXTRA_CONFIG, config.toString()),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, System.currentTimeMillis() + TEST_DELAY_MILLIS, intent)
        return true
    }

    /** The stored alarm [id] and the shared config, or null once it is gone. */
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

    private fun arm(context: Context, id: Int, at: Long) {
        val manager = context.getSystemService(AlarmManager::class.java)
        val exact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || manager.canScheduleExactAlarms()
        val intent = pending(context, id)
        // Without the permission the time is approximate and the system may
        // not let the service start; the receiver then falls back to a notice.
        if (exact) manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, intent)
        else manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, intent)
    }

    private fun pending(context: Context, id: Int): PendingIntent = PendingIntent.getBroadcast(
        context,
        id,
        Intent(context, AdhanAlarmReceiver::class.java)
            .setAction(ALARM_ACTION)
            .setData(Uri.parse("adhan://alarm/$id"))
            .putExtra(EXTRA_ID, id),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
}
