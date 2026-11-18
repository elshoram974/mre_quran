package net.mrecode.mre_quran

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import org.json.JSONObject

/** Starts the adhan when its alarm fires, and re-arms the alarms after a restart. */
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
                    // A broadcast may survive a clock change or be delivered
                    // late on wake. Play only in the scheduled minute.
                    AdhanScheduler.armAfter(context, now)
                    if (now < at || now / 60_000L != at / 60_000L) return
                    found
                }
                try {
                    AdhanService.start(context, alarm, config)
                } catch (_: Exception) {
                    // The system would not let a background service start (no
                    // exact-alarm permission): show the notice without sound.
                    val notice = AdhanService.notice(context, alarm, config, ongoing = false)
                    context.getSystemService(NotificationManager::class.java).notify(id, notice)
                }
            }
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED -> AdhanScheduler.armAll(context)
        }
    }
}
