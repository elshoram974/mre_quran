package net.mrecode.mre_quran

import android.app.Activity
import android.os.Bundle

/** Handles a launcher gesture in the foreground without displaying a window. */
class WidgetTapActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (savedInstanceState == null) {
            if (intent.action == TasbihWidgetProvider.ACTION_COUNT) {
                TasbihWidgetProvider().count(this)
            } else {
                val now = System.currentTimeMillis()
                val drawn = intent.getLongExtra(DRAWN_AT, 0)
                val expires = intent.getLongExtra(EXPIRES_AT, 0)
                if (now < drawn || now >= expires) {
                    PrayerWidgetRenderer.updateAll(this)
                } else {
                    startActivity(PrayerWidgetRenderer.appIntent(this))
                }
            }
        }
        finish()
    }

    companion object {
        internal const val DRAWN_AT = "drawnAt"
        internal const val EXPIRES_AT = "expiresAt"
    }
}
