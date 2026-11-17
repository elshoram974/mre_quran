package net.mrecode.mre_quran

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.RemoteViews

/**
 * Home-screen tasbih counter. A tap on the number adds one and the reset
 * button clears it. The count lives in this widget's own preferences, so it
 * works without opening the app.
 */
class TasbihWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) =
        redraw(context, manager, ids)

    /** Resized: everything is drawn again at the new size. */
    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: Bundle) =
        redraw(context, manager, intArrayOf(id))

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
        for (id in ids) {
            val views = RemoteViews(context.packageName, R.layout.tasbih_widget)
            views.setTextViewText(R.id.tasbih_widget_count, String.format("%d", count))
            views.setOnClickPendingIntent(R.id.tasbih_widget_count_area, broadcast(context, ACTION_COUNT, 1))
            views.setOnClickPendingIntent(R.id.tasbih_widget_reset, broadcast(context, ACTION_RESET, 2))
            // A bigger widget gets a bigger name and reset button; the count
            // sizes itself to fill what is left.
            val scale = WidgetScale.of(manager, id, BASE_DP, BASE_DP)
            WidgetScale.text(views, R.id.tasbih_widget_name, 10f, scale)
            WidgetScale.text(views, R.id.tasbih_widget_reset, 13f, scale)
            WidgetScale.padding(context, views, R.id.tasbih_widget_reset, 6f, 1f, scale)
            manager.updateAppWidget(id, views)
        }
    }

    private fun broadcast(context: Context, action: String, code: Int): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            code,
            Intent(context, TasbihWidgetProvider::class.java).setAction(action),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    private companion object {
        /** One cell, the size the layout is drawn for. */
        const val BASE_DP = 64f
        const val PREFERENCES = "tasbih_widget"
        const val COUNT = "count"
        const val ACTION_COUNT = "net.mrecode.mre_quran.TASBIH_COUNT"
        const val ACTION_RESET = "net.mrecode.mre_quran.TASBIH_RESET"
    }
}
