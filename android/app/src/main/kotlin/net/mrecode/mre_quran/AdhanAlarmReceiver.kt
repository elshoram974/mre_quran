package net.mrecode.mre_quran

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import org.json.JSONObject

/**
 * Starts the adhan when its alarm fires, and re-arms the alarms after a restart.
 *
 * A prayer is never passed over in silence: an alarm the system hands over a
 * few minutes late still plays, and one later than that shows the prayer's
 * notice without sound.
 */
class AdhanAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            AdhanScheduler.ALARM_ACTION -> {
                val id = intent.getIntExtra(AdhanScheduler.EXTRA_ID, -1)
                // A test carries its own data; a real prayer is looked up.
                val own = intent.getStringExtra(AdhanService.EXTRA_ALARM)
                val (alarm, config) = if (own != null) {
                    JSONObject(own) to JSONObject(intent.getStringExtra(AdhanService.EXTRA_CONFIG) ?: "{}")
                } else {
                    val found = AdhanScheduler.find(context, id) ?: return
                    // A real prayer: arm the one after it before playing.
                    val at = found.first.getLong("at")
                    val now = System.currentTimeMillis()
                    AdhanScheduler.armAfter(context, now)
                    // Early (the clock was moved back): it is armed again.
                    if (now < at) return
                    val late = now - at
                    // Long past: a broadcast that outlived a clock change.
                    if (late > NOTICE_WITHIN_MILLIS) return
                    // Too late for the adhan, which would call a prayer
                    // whose time is not now: the notice says it is time.
                    if (late > PLAY_WITHIN_MILLIS) {
                        notice(context, id, found.first, found.second)
                        return
                    }
                    found
                }
                try {
                    AdhanService.start(context, alarm, config)
                } catch (_: Exception) {
                    // The system would not let a background service start (no
                    // exact-alarm permission): show the notice without sound.
                    notice(context, id, alarm, config)
                }
            }
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED -> AdhanScheduler.armAll(context)
        }
    }

    private fun notice(context: Context, id: Int, alarm: JSONObject, config: JSONObject) {
        val notice = AdhanService.notice(context, alarm, config, ongoing = false)
        context.getSystemService(NotificationManager::class.java).notify(id, notice)
    }

    private companion object {
        /** How late the system may hand an alarm over for the adhan still to play. */
        const val PLAY_WITHIN_MILLIS = 3 * 60_000L

        /** How late it may come for the prayer's notice still to show. */
        const val NOTICE_WITHIN_MILLIS = 60 * 60_000L
    }
}
