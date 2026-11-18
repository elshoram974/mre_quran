package net.mrecode.mre_quran

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.os.Bundle

/** The prayer card widget. [PrayerWidgetRenderer] draws it. */
class PrayerCardWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) =
        PrayerWidgetRenderer.updateAll(context)

    /** Resized: drawn again at the new size. */
    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: Bundle) =
        PrayerWidgetRenderer.updateAll(context)

    override fun onDisabled(context: Context) = PrayerWidgetRenderer.updateAll(context)
}
