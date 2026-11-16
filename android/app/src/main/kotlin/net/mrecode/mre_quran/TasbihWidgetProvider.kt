package net.mrecode.mre_quran

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/**
 * Home-screen tasbih counter. A tap on the number adds one and the reset
 * button clears it. The count lives in this widget's own preferences, so it
 * works without opening the app.
 */
class TasbihWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) =
        redraw(context, manager, ids)

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_COUNT -> change(context) { it + 1 }
            ACTION_RESET -> change(context) { 0 }
            else -> super.onReceive(context, intent)
        }
    }

    private fun change(context: Context, next: (Int) -> Int) {
        val preferences = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        preferences.edit().putInt(COUNT, next(preferences.getInt(COUNT, 0))).apply()
        val manager = AppWidgetManager.getInstance(context)
        redraw(context, manager, manager.getAppWidgetIds(ComponentName(context, javaClass)))
    }

    private fun redraw(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val count = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).getInt(COUNT, 0)
        val views = RemoteViews(context.packageName, R.layout.tasbih_widget)
        views.setTextViewText(R.id.tasbih_widget_count, String.format("%d", count))
        views.setOnClickPendingIntent(R.id.tasbih_widget_count_area, broadcast(context, ACTION_COUNT, 1))
        views.setOnClickPendingIntent(R.id.tasbih_widget_reset, broadcast(context, ACTION_RESET, 2))
        manager.updateAppWidget(ids, views)
    }

    private fun broadcast(context: Context, action: String, code: Int): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            code,
            Intent(context, TasbihWidgetProvider::class.java).setAction(action),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    private companion object {
        const val PREFERENCES = "tasbih_widget"
        const val COUNT = "count"
        const val ACTION_COUNT = "net.mrecode.mre_quran.TASBIH_COUNT"
        const val ACTION_RESET = "net.mrecode.mre_quran.TASBIH_RESET"
    }
}
