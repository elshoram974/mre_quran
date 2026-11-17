package net.mrecode.mre_quran

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.os.Bundle

/** Home-screen widget for the suggested adhkar list and its saved progress. */
class AdhkarWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) =
        AdhkarWidgetRenderer.updateAll(context)

    /** Resized: drawn again at the new size. */
    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: Bundle) =
        AdhkarWidgetRenderer.updateAll(context)
}
