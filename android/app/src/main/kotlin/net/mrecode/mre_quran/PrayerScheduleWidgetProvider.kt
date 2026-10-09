package net.mrecode.mre_quran

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context

/** The widget with the day's times. [PrayerWidgetRenderer] draws it. */
class PrayerScheduleWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) =
        PrayerWidgetRenderer.updateAll(context)

    override fun onDisabled(context: Context) = PrayerWidgetRenderer.updateAll(context)
}
