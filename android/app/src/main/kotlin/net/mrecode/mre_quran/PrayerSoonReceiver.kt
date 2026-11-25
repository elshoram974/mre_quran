package net.mrecode.mre_quran

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import org.json.JSONObject

/**
 * Shows a prayer notice when its alarm fires (the reminder before a prayer
 * with its countdown, or a plain one: see [PrayerSoonNotice]), takes a
 * countdown away when its Remove button is pressed, and arms the alarms again
 * after a restart.
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
        // Too late to be of use: the adhan has come (nothing left to count
        // down to), or a plain notice's moment has passed.
        val until = if (alarm.has("until")) alarm.getLong("until") else alarm.getLong("adhan")
        if (now >= until) return
        // The iqama has come: an adhan still playing stops, so it does not go
        // on over the iqama's voice or come back after it.
        if (alarm.optBoolean("endsAdhan")) AdhanService.stopIfPlaying()
        PrayerSoonNotice.post(context, id, alarm, config)
        listenToSilence(context, id, alarm, config)
    }

    /**
     * While a notice's voice plays, turning the phone face down or pressing a
     * volume button silences it, as they stop the adhan (when the person
     * chose so). The notice stays, without its sound.
     */
    private fun listenToSilence(context: Context, id: Int, alarm: JSONObject, config: JSONObject) {
        val flip = config.optBoolean("stopWhenFlipped", true)
        val keys = config.optBoolean("stopWithVolumeKeys", true)
        if (!PrayerSoonNotice.sounds(alarm, config) || (!flip && !keys)) return
        val pending = goAsync()
        val main = Handler(Looper.getMainLooper())
        var done = false
        var flipDetector: FlipDetector? = null
        var volumeKeys: VolumeKeyStopper? = null
        fun end(silence: Boolean) {
            if (done) return
            done = true
            flipDetector?.stop()
            volumeKeys?.stop()
            main.removeCallbacksAndMessages(null)
            if (silence) PrayerSoonNotice.silence(context, id, alarm, config)
            pending.finish()
        }
        if (flip) flipDetector = FlipDetector(context) { main.post { end(true) } }.also { it.start() }
        if (keys) volumeKeys = VolumeKeyStopper(context) { main.post { end(true) } }.also { it.start() }
        // The longest voice lasts about nine seconds.
        main.postDelayed({ end(false) }, LISTEN_MILLIS)
    }

    companion object {
        const val ACTION_DISMISS = "net.mrecode.mre_quran.PRAYER_SOON_DISMISS"

        /** How early the system may hand an alarm over. */
        private const val EARLY_MILLIS = 60_000L

        /** How long a notice's voice can be silenced after it comes. */
        private const val LISTEN_MILLIS = 12_000L
    }
}
