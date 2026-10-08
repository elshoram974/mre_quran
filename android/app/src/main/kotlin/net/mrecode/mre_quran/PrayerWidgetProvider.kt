package net.mrecode.mre_quran

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.widget.RemoteViews
import java.util.concurrent.TimeUnit

class PrayerWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        updateAll(context, manager)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == refreshAction) {
            updateAll(context, AppWidgetManager.getInstance(context))
        }
    }

    companion object {
        private const val preferences = "prayer_widget"
        private const val refreshAction = "net.mrecode.mre_quran.PRAYER_WIDGET_REFRESH"
        private const val requestCode = 401

        fun save(context: Context, values: Map<String, Any?>?) {
            val editor = context.getSharedPreferences(preferences, Context.MODE_PRIVATE).edit()
            if (values == null) {
                editor.clear().apply()
            } else {
                editor.putString("title", values["title"] as? String)
                editor.putString("label", values["label"] as? String)
                editor.putString("time", values["time"] as? String)
                editor.putLong("at", (values["at"] as Number).toLong())
                editor.putBoolean("arabicDigits", values["useArabicDigits"] as? Boolean ?: true)
                editor.apply()
            }
            updateAll(context, AppWidgetManager.getInstance(context))
        }

        fun refresh(context: Context) {
            updateAll(context, AppWidgetManager.getInstance(context))
        }

        private fun updateAll(context: Context, manager: AppWidgetManager) {
            val ids = manager.getAppWidgetIds(ComponentName(context, PrayerWidgetProvider::class.java))
            if (ids.isEmpty()) return
            val store = context.getSharedPreferences(preferences, Context.MODE_PRIVATE)
            val at = store.getLong("at", 0)
            val hasData = at > 0 && store.contains("title")
            val views = RemoteViews(context.packageName, R.layout.prayer_widget)
            if (hasData) {
                views.setTextViewText(R.id.prayer_widget_label, store.getString("label", context.getString(R.string.prayer_widget_label)))
                views.setTextViewText(R.id.prayer_widget_name, store.getString("title", ""))
                views.setTextViewText(R.id.prayer_widget_time, store.getString("time", ""))
                views.setTextViewText(
                    R.id.prayer_widget_remaining,
                    context.getString(
                        R.string.prayer_widget_remaining,
                        duration(at - System.currentTimeMillis(), store.getBoolean("arabicDigits", true)),
                    ),
                )
                scheduleRefresh(context, at)
            } else {
                views.setTextViewText(R.id.prayer_widget_label, context.getString(R.string.prayer_widget_name))
                views.setTextViewText(R.id.prayer_widget_name, context.getString(R.string.prayer_widget_empty))
                views.setTextViewText(R.id.prayer_widget_time, "")
                views.setTextViewText(R.id.prayer_widget_remaining, "")
            }
            views.setOnClickPendingIntent(R.id.prayer_widget_root, openAppIntent(context))
            manager.updateAppWidget(ids, views)
        }

        private fun scheduleRefresh(context: Context, at: Long) {
            val alarm = context.getSystemService(AlarmManager::class.java)
            alarm.setAndAllowWhileIdle(
                AlarmManager.RTC,
                at + 1_000,
                refreshIntent(context),
            )
        }

        private fun openAppIntent(context: Context): PendingIntent = PendingIntent.getActivity(
            context,
            requestCode,
            Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        private fun refreshIntent(context: Context): PendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            Intent(context, PrayerWidgetProvider::class.java).setAction(refreshAction),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        private fun duration(milliseconds: Long, arabicDigits: Boolean): String {
            val minutes = TimeUnit.MILLISECONDS.toMinutes(milliseconds.coerceAtLeast(0))
            val hours = minutes / 60
            val parts = if (arabicDigits) {
                if (hours > 0) "$hours س ${minutes % 60} د" else "$minutes د"
            } else {
                if (hours > 0) "$hours h ${minutes % 60} m" else "$minutes m"
            }
            return if (arabicDigits) parts.map { char ->
                if (char in '0'..'9') '٠' + (char - '0') else char
            }.joinToString("") else parts
        }
    }
}
