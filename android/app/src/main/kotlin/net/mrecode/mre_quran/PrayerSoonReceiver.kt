package net.mrecode.mre_quran

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Shows the reminder before a prayer when its alarm fires, takes it away when
 * its Remove button is pressed, and arms the alarms again after a restart.
 */
class PrayerSoonReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            PrayerSoonScheduler.ALARM_ACTION -> fire(context, intent.getIntExtra(PrayerSoonScheduler.EXTRA_ID, -1))
            ACTION_DISMISS -> context.getSystemService(NotificationManager::class.java)
                .cancel(intent.getIntExtra(PrayerSoonScheduler.EXTRA_ID, -1))
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED -> PrayerSoonScheduler.armAll(context)
        }
    }

    private fun fire(context: Context, id: Int) {
        val (alarm, config) = PrayerSoonScheduler.find(context, id) ?: return
        val at = alarm.getLong("at")
        val now = System.currentTimeMillis()
        // Early by more than the system's slack (the clock was moved back):
        // armed again for its time.
        if (now < at - EARLY_MILLIS) {
            PrayerSoonScheduler.armAll(context)
            return
        }
        // Arm the one after it before showing this one.
        PrayerSoonScheduler.armAfter(context, at)
        // The adhan has come: there is nothing left to count down to.
        if (now >= alarm.getLong("adhan")) return
        PrayerSoonNotice.post(context, id, alarm, config)
    }

    companion object {
        const val ACTION_DISMISS = "net.mrecode.mre_quran.PRAYER_SOON_DISMISS"

        /** How early the system may hand an alarm over. */
        private const val EARLY_MILLIS = 60_000L
    }
}
