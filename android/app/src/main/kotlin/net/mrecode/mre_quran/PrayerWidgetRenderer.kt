package net.mrecode.mre_quran

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject

/** Draws the three prayer widgets from the data the app last sent. */
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

    private val cellIds = intArrayOf(
        R.id.card_cell_0, R.id.card_cell_1, R.id.card_cell_2, R.id.card_cell_3, R.id.card_cell_4,
    )
    private val cellNameIds = intArrayOf(
        R.id.card_cell_name_0, R.id.card_cell_name_1, R.id.card_cell_name_2,
        R.id.card_cell_name_3, R.id.card_cell_name_4,
    )
    private val cellTimeIds = intArrayOf(
        R.id.card_cell_time_0, R.id.card_cell_time_1, R.id.card_cell_time_2,
        R.id.card_cell_time_3, R.id.card_cell_time_4,
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
        val cards = manager.getAppWidgetIds(ComponentName(context, PrayerCardWidgetProvider::class.java))
        if (next.isEmpty() && schedule.isEmpty() && cards.isEmpty()) {
            cancelRefresh(context)
            return
        }
        val model = WidgetModel.parse(
            context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).getString(PAYLOAD, null),
        )
        val now = System.currentTimeMillis()
        for (id in next) {
            val views = nextPrayerViews(context, model, now)
            // Base: two cells by one.
            val scale = WidgetScale.of(manager, id, 140f, 60f)
            WidgetScale.text(views, R.id.prayer_widget_label, 11f, scale)
            WidgetScale.text(views, R.id.prayer_widget_name, 16f, scale)
            WidgetScale.text(views, R.id.prayer_widget_time, 15f, scale)
            WidgetScale.text(views, R.id.prayer_widget_remaining, 11f, scale)
            WidgetScale.text(views, R.id.prayer_widget_seconds, 11f, scale)
            manager.updateAppWidget(id, views)
        }
        for (id in schedule) {
            val views = scheduleViews(context, model, now)
            // Base: two cells by two.
            val scale = WidgetScale.of(manager, id, 140f, 150f)
            WidgetScale.text(views, R.id.schedule_date, 12f, scale)
            WidgetScale.text(views, R.id.schedule_hijri, 10f, scale)
            for (index in rowIds.indices) {
                WidgetScale.text(views, nameIds[index], 12f, scale)
                WidgetScale.text(views, timeIds[index], 12f, scale)
                WidgetScale.text(views, leftIds[index], 10f, scale)
            }
            manager.updateAppWidget(id, views)
        }
        for (id in cards) {
            val views = cardViews(context, model, now)
            // Base: four cells by two.
            val scale = WidgetScale.of(manager, id, 280f, 150f)
            WidgetScale.text(views, R.id.card_label, 11f, scale)
            WidgetScale.text(views, R.id.card_name, 26f, scale)
            WidgetScale.text(views, R.id.card_time, 18f, scale)
            WidgetScale.text(views, R.id.card_remaining, 13f, scale)
            WidgetScale.text(views, R.id.card_seconds, 13f, scale)
            WidgetScale.text(views, R.id.card_hijri, 10f, scale)
            for (index in cellIds.indices) {
                WidgetScale.text(views, cellNameIds[index], 11f, scale)
                WidgetScale.text(views, cellTimeIds[index], 12f, scale)
            }
            manager.updateAppWidget(id, views)
        }
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
            views.setViewVisibility(R.id.prayer_widget_seconds, View.GONE)
        } else {
            views.setTextViewText(R.id.prayer_widget_label, model.labels.next)
            views.setTextViewText(R.id.prayer_widget_name, next.name)
            views.setTextViewText(R.id.prayer_widget_time, next.time)
            views.setViewVisibility(R.id.prayer_widget_time, View.VISIBLE)
            countdown(views, R.id.prayer_widget_remaining, R.id.prayer_widget_seconds, model, next, now)
        }
        direction(views, R.id.prayer_widget_root, model)
        views.setOnClickPendingIntent(R.id.prayer_widget_root, tapIntent(context))
        return views
    }

    private fun cardViews(context: Context, model: WidgetModel?, now: Long): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.prayer_card_widget)
        val next = model?.nextAfter(now)
        val day = model?.dayAt(now)
        if (model == null || next == null || day == null) {
            views.setTextViewText(R.id.card_label, context.getString(R.string.prayer_widget_name))
            views.setTextViewText(R.id.card_name, model?.labels?.empty ?: context.getString(R.string.prayer_widget_empty))
            listOf(R.id.card_time, R.id.card_remaining, R.id.card_seconds, R.id.card_hijri)
                .forEach { views.setViewVisibility(it, View.GONE) }
            cellIds.forEach { views.setViewVisibility(it, View.GONE) }
        } else {
            views.setTextViewText(R.id.card_label, model.labels.next)
            views.setTextViewText(R.id.card_name, next.name)
            views.setTextViewText(R.id.card_time, next.time)
            views.setTextViewText(R.id.card_hijri, day.hijriLabel)
            views.setViewVisibility(R.id.card_time, View.VISIBLE)
            views.setViewVisibility(R.id.card_hijri, View.VISIBLE)
            countdown(views, R.id.card_remaining, R.id.card_seconds, model, next, now)
            // After the day's last prayer the coming one is tomorrow's Fajr,
            // shown in Fajr's place with tomorrow's time.
            val prayers = day.rows.filter { it.isPrayer }
            val tomorrow = prayers.none { it.at > now }
            cellIds.forEachIndexed { index, cellId ->
                val row = prayers.getOrNull(index)
                views.setViewVisibility(cellId, if (row == null) View.GONE else View.VISIBLE)
                if (row == null) return@forEachIndexed
                val coming = row.id == next.id && (tomorrow || row.at == next.at)
                views.setTextViewText(cellNameIds[index], row.name)
                views.setTextViewText(cellTimeIds[index], if (coming) next.time else row.time)
                views.setInt(cellId, "setBackgroundResource", if (coming) R.drawable.widget_card_cell_next else 0)
            }
        }
        direction(views, R.id.card_root, model)
        views.setOnClickPendingIntent(R.id.card_root, tapIntent(context))
        return views
    }

    /**
     * The time left until [next]: in hours and minutes, redrawn each minute;
     * or, when the person chose it, to the second by a chronometer that
     * counts down on its own while the widget is on screen, without waking
     * the app.
     */
    private fun countdown(
        views: RemoteViews,
        minutesId: Int,
        secondsId: Int,
        model: WidgetModel,
        next: WidgetRow,
        now: Long,
    ) {
        val seconds = model.seconds && Build.VERSION.SDK_INT >= Build.VERSION_CODES.N
        views.setViewVisibility(minutesId, if (seconds) View.GONE else View.VISIBLE)
        views.setViewVisibility(secondsId, if (seconds) View.VISIBLE else View.GONE)
        if (seconds) {
            views.setChronometer(
                secondsId,
                SystemClock.elapsedRealtime() + (next.at - now),
                model.labels.remaining,
                true,
            )
            views.setChronometerCountDown(secondsId, true)
        } else {
            views.setTextViewText(minutesId, remaining(model, next.at - now))
        }
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
            // After the day's last prayer the coming one is tomorrow's Fajr.
            // It takes today's Fajr row, with tomorrow's time, so the widget
            // always points at a prayer.
            val tomorrow = next != null && day.rows.none { it.isPrayer && it.at > now }
            views.setTextViewText(R.id.schedule_date, day.dateLabel)
            views.setTextViewText(R.id.schedule_hijri, day.hijriLabel)
            rowIds.forEachIndexed { index, rowId ->
                val row = day.rows.getOrNull(index)
                views.setViewVisibility(rowId, if (row == null) View.GONE else View.VISIBLE)
                if (row == null) return@forEachIndexed
                // The coming prayer is lit, under a line saying how long is left.
                val coming = next != null && row.id == next.id && (tomorrow || row.at == next.at)
                views.setTextViewText(nameIds[index], row.name)
                views.setTextViewText(timeIds[index], if (coming) next!!.time else row.time)
                views.setInt(rowId, "setBackgroundResource", if (coming) R.drawable.widget_row_next else 0)
                views.setViewVisibility(leftIds[index], if (coming) View.VISIBLE else View.GONE)
                if (coming) views.setTextViewText(leftIds[index], remaining(model, next!!.at - now))
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
