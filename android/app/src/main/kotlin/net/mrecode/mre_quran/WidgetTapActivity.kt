package net.mrecode.mre_quran

import android.app.Activity
import android.os.Bundle

/**
 * Where a tap on a prayer widget lands. It shows nothing.
 *
 * Widgets that fell behind the clock are brought up to date and the person
 * stays on the home screen: they tapped to see the right time, and now they
 * do. Widgets that are already right open the app on its prayer times.
 */
class WidgetTapActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (PrayerWidgetRenderer.needsRedraw(this, System.currentTimeMillis())) {
            PrayerWidgetRenderer.updateAll(this)
        } else {
            startActivity(PrayerWidgetRenderer.appIntent(this))
        }
        finish()
    }
}
