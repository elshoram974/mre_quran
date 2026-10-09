package net.mrecode.mre_quran

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context

/** Home-screen widget for the suggested adhkar list and its saved progress. */
class AdhkarWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) =
        AdhkarWidgetRenderer.updateAll(context)
}
