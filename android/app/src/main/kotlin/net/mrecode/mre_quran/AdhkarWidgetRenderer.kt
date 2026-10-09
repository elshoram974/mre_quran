package net.mrecode.mre_quran

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject

/** Draws the suggested-dhikr widget from Flutter's last saved progress. */
internal object AdhkarWidgetRenderer {
    private const val PREFERENCES = "adhkar_widget"
    private const val PAYLOAD = "payload"
    private const val REQUEST_CODE = 402

    fun save(context: Context, values: Map<String, Any?>?) {
        val editor = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).edit()
        if (values == null) editor.clear() else editor.putString(PAYLOAD, JSONObject(values).toString())
        editor.apply()
        updateAll(context)
    }

    fun updateAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(ComponentName(context, AdhkarWidgetProvider::class.java))
        if (ids.isEmpty()) return
        val model = AdhkarWidgetModel.parse(
            context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).getString(PAYLOAD, null),
        )
        manager.updateAppWidget(ids, views(context, model))
    }

    private fun views(context: Context, model: AdhkarWidgetModel?): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.adhkar_widget)
        if (model == null) {
            views.setTextViewText(R.id.adhkar_widget_label, context.getString(R.string.adhkar_widget_name))
            views.setTextViewText(R.id.adhkar_widget_title, context.getString(R.string.adhkar_widget_empty))
            views.setViewVisibility(R.id.adhkar_widget_progress, View.GONE)
            views.setViewVisibility(R.id.adhkar_widget_count, View.GONE)
            views.setOnClickPendingIntent(R.id.adhkar_widget_root, openApp(context, ""))
            return views
        }
        views.setTextViewText(R.id.adhkar_widget_label, model.label)
        views.setTextViewText(R.id.adhkar_widget_title, model.title)
        views.setTextViewText(
            R.id.adhkar_widget_count,
            context.getString(R.string.adhkar_widget_progress, model.done, model.total),
        )
        views.setProgressBar(R.id.adhkar_widget_progress, model.total.coerceAtLeast(1), model.done.coerceAtLeast(0), false)
        views.setInt(
            R.id.adhkar_widget_root,
            "setLayoutDirection",
            if (model.rtl) View.LAYOUT_DIRECTION_RTL else View.LAYOUT_DIRECTION_LTR,
        )
        views.setOnClickPendingIntent(R.id.adhkar_widget_root, openApp(context, model.payload))
        return views
    }

    private fun openApp(context: Context, payload: String): PendingIntent = PendingIntent.getActivity(
        context,
        REQUEST_CODE,
        Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            if (payload.isNotEmpty()) putExtra(AdhanService.EXTRA_PAYLOAD, payload)
        },
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
}
