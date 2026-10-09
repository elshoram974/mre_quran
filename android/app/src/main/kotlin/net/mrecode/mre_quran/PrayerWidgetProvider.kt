package net.mrecode.mre_quran

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent

/**
 * The "next prayer" widget. It also receives the minute refresh and the clock
 * changes for both widgets, so the two stay in step.
 */
class PrayerWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) =
        PrayerWidgetRenderer.updateAll(context)

    override fun onDisabled(context: Context) = PrayerWidgetRenderer.updateAll(context)

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            PrayerWidgetRenderer.REFRESH_ACTION,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_DATE_CHANGED -> PrayerWidgetRenderer.updateAll(context)
        }
    }
}
