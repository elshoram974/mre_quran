package net.mrecode.mre_quran

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject

/** Draws both prayer widgets from the data the app last sent. */
internal object PrayerWidgetRenderer {
    const val REFRESH_ACTION = "net.mrecode.mre_quran.PRAYER_WIDGET_REFRESH"

    private const val PREFERENCES = "prayer_widget"
    private const val PAYLOAD = "payload"
    private const val RENDERED_AT = "rendered_at"
    private const val PRAYER_TIMES = "prayer:times"
    private const val REQUEST_CODE = 401
    private const val MINUTE = 60_000L

    private val rowIds = intArrayOf(
        R.id.schedule_row_0, R.id.schedule_row_1, R.id.schedule_row_2,
        R.id.schedule_row_3, R.id.schedule_row_4, R.id.schedule_row_5,
    )
    private val nameIds = intArrayOf(
        R.id.schedule_name_0, R.id.schedule_name_1, R.id.schedule_name_2,
        R.id.schedule_name_3, R.id.schedule_name_4, R.id.schedule_name_5,
    )
    private val timeIds = intArrayOf(
        R.id.schedule_time_0, R.id.schedule_time_1, R.id.schedule_time_2,
        R.id.schedule_time_3, R.id.schedule_time_4, R.id.schedule_time_5,
    )

    private val leftIds = intArrayOf(
        R.id.schedule_left_0, R.id.schedule_left_1, R.id.schedule_left_2,
        R.id.schedule_left_3, R.id.schedule_left_4, R.id.schedule_left_5,
    )

    /** Keeps the app's data (or clears it when null) and redraws. */
    fun save(context: Context, values: Map<String, Any?>?) {
        val editor = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).edit()
        if (values == null) editor.clear() else editor.putString(PAYLOAD, JSONObject(values).toString())
        editor.apply()
        updateAll(context)
    }

    /** Redraws every widget and sets the next minute's refresh. */
    fun updateAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val next = manager.getAppWidgetIds(ComponentName(context, PrayerWidgetProvider::class.java))
        val schedule = manager.getAppWidgetIds(ComponentName(context, PrayerScheduleWidgetProvider::class.java))
        if (next.isEmpty() && schedule.isEmpty()) {
            cancelRefresh(context)
            return
        }
        val model = WidgetModel.parse(
            context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).getString(PAYLOAD, null),
        )
        val now = System.currentTimeMillis()
        if (next.isNotEmpty()) manager.updateAppWidget(next, nextPrayerViews(context, model, now))
        if (schedule.isNotEmpty()) manager.updateAppWidget(schedule, scheduleViews(context, model, now))
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).edit().putLong(RENDERED_AT, now).apply()
        scheduleRefresh(context, now)
    }

    /**
     * Whether a tap should redraw the widgets instead of opening the app: they
     * hold times that still cover [now], but were last drawn in an earlier
     * minute, so the next prayer or the time left on screen may be out of date.
     * The system can hold the minute refresh back while the phone sleeps.
     *
     * Without times that cover [now] only the app can help, so the tap opens it.
     */
    fun needsRedraw(context: Context, now: Long): Boolean {
        val preferences = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        val model = WidgetModel.parse(preferences.getString(PAYLOAD, null)) ?: return false
        if (model.nextAfter(now) == null) return false
        return preferences.getLong(RENDERED_AT, 0) / MINUTE != now / MINUTE
    }

    /** Opens the app on its prayer times. */
    fun appIntent(context: Context): Intent = Intent(context, MainActivity::class.java).apply {
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        putExtra(AdhanService.EXTRA_PAYLOAD, PRAYER_TIMES)
    }

    private fun nextPrayerViews(context: Context, model: WidgetModel?, now: Long): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.prayer_widget)
        val next = model?.nextAfter(now)
        if (model == null || next == null) {
            views.setTextViewText(R.id.prayer_widget_label, context.getString(R.string.prayer_widget_name))
            views.setTextViewText(R.id.prayer_widget_name, model?.labels?.empty ?: context.getString(R.string.prayer_widget_empty))
            views.setViewVisibility(R.id.prayer_widget_time, View.GONE)
            views.setViewVisibility(R.id.prayer_widget_remaining, View.GONE)
        } else {
            views.setTextViewText(R.id.prayer_widget_label, model.labels.next)
            views.setTextViewText(R.id.prayer_widget_name, next.name)
            views.setTextViewText(R.id.prayer_widget_time, next.time)
            views.setTextViewText(R.id.prayer_widget_remaining, remaining(model, next.at - now))
            views.setViewVisibility(R.id.prayer_widget_time, View.VISIBLE)
            views.setViewVisibility(R.id.prayer_widget_remaining, View.VISIBLE)
        }
        direction(views, R.id.prayer_widget_root, model)
        views.setOnClickPendingIntent(R.id.prayer_widget_root, tapIntent(context))
        return views
    }

    private fun scheduleViews(context: Context, model: WidgetModel?, now: Long): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.prayer_schedule_widget)
        val day = model?.dayAt(now)
        if (model == null || day == null) {
            views.setTextViewText(R.id.schedule_date, context.getString(R.string.prayer_widget_name))
            views.setTextViewText(R.id.schedule_hijri, model?.labels?.empty ?: context.getString(R.string.prayer_widget_empty))
            rowIds.forEach { views.setViewVisibility(it, View.GONE) }
        } else {
            val next = model.nextAfter(now)
            views.setTextViewText(R.id.schedule_date, day.dateLabel)
            views.setTextViewText(R.id.schedule_hijri, day.hijriLabel)
            rowIds.forEachIndexed { index, rowId ->
                val row = day.rows.getOrNull(index)
                views.setViewVisibility(rowId, if (row == null) View.GONE else View.VISIBLE)
                if (row == null) return@forEachIndexed
                views.setTextViewText(nameIds[index], row.name)
                views.setTextViewText(timeIds[index], row.time)
                // The coming prayer is lit, under a line saying how long is
                // left; once today's are done, none is.
                val coming = next != null && row.id == next.id && row.at == next.at
                views.setInt(rowId, "setBackgroundResource", if (coming) R.drawable.widget_row_next else 0)
                views.setViewVisibility(leftIds[index], if (coming) View.VISIBLE else View.GONE)
                if (coming) views.setTextViewText(leftIds[index], remaining(model, row.at - now))
            }
        }
        direction(views, R.id.schedule_root, model)
        views.setOnClickPendingIntent(R.id.schedule_root, tapIntent(context))
        return views
    }

    /** The widget follows the app's language, not the phone's. */
    private fun direction(views: RemoteViews, rootId: Int, model: WidgetModel?) {
        if (model == null) return
        views.setInt(rootId, "setLayoutDirection", if (model.rtl) View.LAYOUT_DIRECTION_RTL else View.LAYOUT_DIRECTION_LTR)
    }

    private fun remaining(model: WidgetModel, millis: Long): String =
        String.format(model.labels.remaining, span(model, millis))

    /** A length of time in hours and minutes, in the app's words and digits. */
    private fun span(model: WidgetModel, millis: Long): String {
        val minutes = (millis / MINUTE).coerceAtLeast(1)
        val hours = minutes / 60
        val digits = { value: Long -> digits(value.toString(), model.arabicDigits) }
        return if (hours > 0) {
            String.format(model.labels.hours, digits(hours), digits(minutes % 60))
        } else {
            String.format(model.labels.minutes, digits(minutes))
        }
    }

    private fun digits(value: String, arabic: Boolean): String =
        if (!arabic) value else value.map { if (it in '0'..'9') '٠' + (it - '0') else it }.joinToString("")

    private fun scheduleRefresh(context: Context, now: Long) {
        val alarm = context.getSystemService(AlarmManager::class.java)
        // Not exact: a few seconds late is fine for a countdown in minutes.
        alarm.setAndAllowWhileIdle(AlarmManager.RTC, now - now % MINUTE + MINUTE, refreshIntent(context))
    }

    fun cancelRefresh(context: Context) {
        context.getSystemService(AlarmManager::class.java).cancel(refreshIntent(context))
    }

    /** A tap goes to [WidgetTapActivity], which redraws stale widgets or opens the app. */
    private fun tapIntent(context: Context): PendingIntent = PendingIntent.getActivity(
        context,
        REQUEST_CODE,
        Intent(context, WidgetTapActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    private fun refreshIntent(context: Context): PendingIntent = PendingIntent.getBroadcast(
        context,
        REQUEST_CODE,
        Intent(context, PrayerWidgetProvider::class.java).setAction(REFRESH_ACTION),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
}
