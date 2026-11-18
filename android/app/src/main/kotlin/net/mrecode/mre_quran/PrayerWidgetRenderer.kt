package net.mrecode.mre_quran

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.res.Configuration
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/** Draws the three prayer widgets from the data the app last sent. */
internal object PrayerWidgetRenderer {
    const val REFRESH_ACTION = "net.mrecode.mre_quran.PRAYER_WIDGET_REFRESH"

    private const val PREFERENCES = "prayer_widget"
    private const val PAYLOAD = "payload"
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

    private val remainingIds = intArrayOf(
        R.id.schedule_remaining_0, R.id.schedule_remaining_1, R.id.schedule_remaining_2,
        R.id.schedule_remaining_3, R.id.schedule_remaining_4, R.id.schedule_remaining_5,
    )
    private val secondsIds = intArrayOf(
        R.id.schedule_seconds_0, R.id.schedule_seconds_1, R.id.schedule_seconds_2,
        R.id.schedule_seconds_3, R.id.schedule_seconds_4, R.id.schedule_seconds_5,
    )

    private val cellIds = intArrayOf(
        R.id.card_cell_0, R.id.card_cell_1, R.id.card_cell_2, R.id.card_cell_3, R.id.card_cell_4, R.id.card_cell_5,
    )
    private val cellNameIds = intArrayOf(
        R.id.card_cell_name_0, R.id.card_cell_name_1, R.id.card_cell_name_2,
        R.id.card_cell_name_3, R.id.card_cell_name_4, R.id.card_cell_name_5,
    )
    private val cellTimeIds = intArrayOf(
        R.id.card_cell_time_0, R.id.card_cell_time_1, R.id.card_cell_time_2,
        R.id.card_cell_time_3, R.id.card_cell_time_4, R.id.card_cell_time_5,
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
            val (width, height) = WidgetScale.size(context, manager, id)
            val views = nextPrayerViews(context, model, now)
            HomeWidgets.applyBackground(context, views, R.id.prayer_widget_root)
            // A single launcher row belongs to the prayer and countdown.
            if (height in 1..85) {
                views.setViewVisibility(R.id.prayer_widget_date, View.GONE)
            }
            if (model?.nextAfter(now) != null) {
                val roomForLabel = width >= 140 && (height <= 0 || height > 85)
                views.setViewVisibility(R.id.prayer_widget_label, if (roomForLabel) View.VISIBLE else View.GONE)
            }
            // Base: two cells by one.
            val scale = WidgetScale.of(width, height, 140f, 60f)
            WidgetScale.text(views, R.id.prayer_widget_label, 11f, scale)
            WidgetScale.text(views, R.id.prayer_widget_name, 16f, scale)
            WidgetScale.text(views, R.id.prayer_widget_date, 9f, scale)
            WidgetScale.text(views, R.id.prayer_widget_time, 15f, scale)
            WidgetScale.text(views, R.id.prayer_widget_remaining, 11f, scale)
            WidgetScale.text(views, R.id.prayer_widget_seconds, 11f, scale)
            manager.updateAppWidget(id, views)
        }
        val scheduleOptions = HomeWidgets.prayerScheduleOptions(context)
        for (id in schedule) {
            val (width, height) = WidgetScale.size(context, manager, id)
            val views = scheduleWidgetViews(context, model, now, width, height, scheduleOptions)
            manager.updateAppWidget(id, views)
        }
        for (id in cards) {
            val (width, height) = WidgetScale.size(context, manager, id)
            val views = cardViews(context, model, now)
            HomeWidgets.applyBackground(context, views, R.id.card_root)
            if (width in 1..199 && model?.nextAfter(now) != null) {
                views.setViewVisibility(R.id.card_label, View.GONE)
            }
            // Base: three cells by two.
            val scale = WidgetScale.of(width, height, 210f, 150f)
            WidgetScale.text(views, R.id.card_label, 11f, scale)
            WidgetScale.text(views, R.id.card_name, 26f, scale)
            WidgetScale.text(views, R.id.card_time, 16f, scale)
            WidgetScale.text(views, R.id.card_remaining, 11f, scale)
            WidgetScale.text(views, R.id.card_seconds, 11f, scale)
            WidgetScale.text(views, R.id.card_date, 9f, scale)
            WidgetScale.text(views, R.id.card_hijri, 9f, scale)
            for (index in cellIds.indices) {
                WidgetScale.text(views, cellNameIds[index], 10f, scale)
                WidgetScale.text(views, cellTimeIds[index], 10f, scale)
            }
            manager.updateAppWidget(id, views)
        }
        scheduleRefresh(context, now)
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
            views.setViewVisibility(R.id.prayer_widget_label, View.VISIBLE)
            views.setTextViewText(R.id.prayer_widget_label, context.getString(R.string.prayer_widget_name))
            views.setTextViewText(R.id.prayer_widget_name, model?.labels?.empty ?: context.getString(R.string.prayer_widget_empty))
            views.setViewVisibility(R.id.prayer_widget_times, View.GONE)
            views.setViewVisibility(R.id.prayer_widget_time, View.GONE)
            views.setViewVisibility(R.id.prayer_widget_remaining, View.GONE)
            views.setViewVisibility(R.id.prayer_widget_seconds, View.GONE)
            views.setViewVisibility(R.id.prayer_widget_date, View.GONE)
        } else {
            views.setViewVisibility(R.id.prayer_widget_times, View.VISIBLE)
            views.setTextViewText(R.id.prayer_widget_label, model.labels.next)
            views.setTextViewText(R.id.prayer_widget_name, next.name)
            views.setTextViewText(R.id.prayer_widget_time, next.time)
            val day = model.dayAt(now)
            views.setViewVisibility(R.id.prayer_widget_date, if (day == null) View.GONE else View.VISIBLE)
            if (day != null) views.setTextViewText(R.id.prayer_widget_date, "${day.dateLabel} · ${day.hijriLabel}")
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
            listOf(R.id.card_time, R.id.card_remaining, R.id.card_seconds, R.id.card_date, R.id.card_hijri)
                .forEach { views.setViewVisibility(it, View.GONE) }
            cellIds.forEach { views.setViewVisibility(it, View.GONE) }
        } else {
            views.setTextViewText(R.id.card_label, model.labels.next)
            views.setTextViewText(R.id.card_name, next.name)
            views.setTextViewText(R.id.card_time, next.time)
            views.setTextViewText(R.id.card_date, day.dateLabel)
            views.setTextViewText(R.id.card_hijri, day.hijriLabel)
            views.setViewVisibility(R.id.card_time, View.VISIBLE)
            views.setViewVisibility(R.id.card_date, View.VISIBLE)
            views.setViewVisibility(R.id.card_hijri, View.VISIBLE)
            countdown(views, R.id.card_remaining, R.id.card_seconds, model, next, now)
            // After the day's last prayer the coming one is tomorrow's Fajr,
            // shown in Fajr's place with tomorrow's time.
            val tomorrow = day.rows.none { it.isPrayer && it.at > now }
            cellIds.forEachIndexed { index, cellId ->
                val row = day.rows.getOrNull(index)
                views.setViewVisibility(cellId, if (row == null) View.GONE else View.VISIBLE)
                if (row == null) return@forEachIndexed
                val coming = row.isPrayer && row.id == next.id && (tomorrow || row.at == next.at)
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

    /** Renders a schedule for the actual space and shared display preferences. */
    internal fun scheduleWidgetViews(
        context: Context,
        model: WidgetModel?,
        now: Long,
        width: Int,
        height: Int,
        options: Map<String, Boolean>,
    ): RemoteViews {
        val short = height in 1..89
        val largerText = options["largeText"] == true
        val showCountdown = options["showCountdown"] != false
        // Inline durations keep the complete day readable in the usual 2x2
        // space. For narrow, short or large-text layouts, give each row a
        // second line and show fewer upcoming prayers when necessary.
        val inline = showCountdown && width >= 130 && height >= 130 && !largerText &&
            !(model?.seconds == true && width < 170)
        val upcoming = short || options["upcomingOnly"] == true ||
            (showCountdown && !inline && height in 1..199) ||
            (largerText && height in 1..209)
        val showDate = options["showDate"] != false &&
            height >= if (showCountdown && !inline && !upcoming) 200 else 150
        val upcomingCount = if (height in 1..79 && (showCountdown || largerText)) 2 else 3
        val views = scheduleViews(context, model, now, width, inline, upcoming, upcomingCount, showDate, options)
        HomeWidgets.applyBackground(context, views, R.id.schedule_root)
        if (!showDate) WidgetScale.padding(context, views, R.id.schedule_body, 4f, 2f, 1f)
        val scale = WidgetScale.of(width, height, 140f, 150f)
        WidgetScale.text(views, R.id.schedule_date, 11f, scale)
        WidgetScale.text(views, R.id.schedule_hijri, 10f, scale)
        val rowSize = if (largerText) 14f else if (short) 11f else if (showDate && height <= 160) 11f else 12f
        for (index in rowIds.indices) {
            WidgetScale.text(views, nameIds[index], rowSize, scale)
            WidgetScale.text(views, timeIds[index], rowSize, scale)
            WidgetScale.text(views, remainingIds[index], if (upcoming) 11f else 10f, scale)
            WidgetScale.text(views, secondsIds[index], if (upcoming) 11f else 10f, scale)
        }
        return views
    }

    private fun scheduleViews(
        context: Context,
        model: WidgetModel?,
        now: Long,
        width: Int,
        inline: Boolean,
        upcoming: Boolean,
        upcomingCount: Int,
        showDate: Boolean,
        options: Map<String, Boolean>,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, if (inline) R.layout.prayer_schedule_inline_widget else R.layout.prayer_schedule_widget)
        val day = model?.dayAt(now)
        if (model == null || day == null) {
            views.setTextViewText(R.id.schedule_date, context.getString(R.string.prayer_widget_name))
            views.setTextViewText(R.id.schedule_hijri, model?.labels?.empty ?: context.getString(R.string.prayer_widget_empty))
            views.setViewVisibility(R.id.schedule_date, View.VISIBLE)
            views.setViewVisibility(R.id.schedule_hijri, View.VISIBLE)
            rowIds.forEach { views.setViewVisibility(it, View.GONE) }
        } else {
            val next = model.nextAfter(now)
            views.setViewVisibility(R.id.schedule_date, if (showDate) View.VISIBLE else View.GONE)
            views.setViewVisibility(R.id.schedule_hijri, if (showDate) View.VISIBLE else View.GONE)
            if (showDate) {
                views.setTextViewText(R.id.schedule_date, day.dateLabel)
                views.setTextViewText(R.id.schedule_hijri, day.hijriLabel)
            }
            val tomorrow = next != null && day.rows.none { it.isPrayer && it.at > now }
            val rows = if (upcoming) {
                model.days.flatMap { it.rows }.filter { it.isPrayer && it.at > now }.sortedBy { it.at }.take(upcomingCount)
            } else {
                day.rows.filter { it.isPrayer || options["showSunrise"] != false }
            }
            val compactTime = if (width in 1..139 || (inline && width < 200)) SimpleDateFormat("H:mm", Locale.ROOT) else null
            val locale = if (model.rtl) Locale.forLanguageTag("ar") else Locale.ENGLISH
            val configuration = Configuration(context.resources.configuration).apply { setLocale(locale) }
            val localized = context.createConfigurationContext(configuration)
            rowIds.forEachIndexed { index, rowId ->
                val row = rows.getOrNull(index)
                views.setViewVisibility(rowId, if (row == null) View.GONE else View.VISIBLE)
                if (row == null) return@forEachIndexed
                val coming = next != null && row.isPrayer && row.id == next.id &&
                    (row.at == next.at || (!upcoming && tomorrow))
                val at = if (coming) next!!.at else row.at
                val time = if (compactTime != null) {
                    digits(compactTime.format(Date(at)), model.arabicDigits)
                } else if (coming) next!!.time else row.time
                views.setTextViewText(nameIds[index], row.name)
                views.setTextViewText(timeIds[index], time)
                val textColor = context.getColor(if (row.isPrayer) R.color.widget_text else R.color.widget_text_muted)
                views.setTextColor(nameIds[index], textColor)
                views.setTextColor(timeIds[index], textColor)
                val remainingVisible = options["showCountdown"] != false && row.isPrayer && at > now
                if (remainingVisible) {
                    val target = if (coming) next!! else row
                    if (inline && !model.seconds) {
                        views.setViewVisibility(remainingIds[index], View.VISIBLE)
                        views.setViewVisibility(secondsIds[index], View.GONE)
                        views.setTextViewText(remainingIds[index], shortRemaining(localized, model, target.at - now))
                        views.setContentDescription(remainingIds[index], remaining(model, target.at - now))
                    } else {
                        countdown(views, remainingIds[index], secondsIds[index], model, target, now)
                    }
                } else {
                    views.setViewVisibility(remainingIds[index], View.GONE)
                    views.setViewVisibility(secondsIds[index], View.GONE)
                }
                views.setInt(rowId, "setBackgroundResource", if (coming) R.drawable.widget_row_next else 0)
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

    /** A compact duration for a row; its accessibility label stays explicit. */
    private fun shortRemaining(context: Context, model: WidgetModel, millis: Long): String {
        val minutes = (millis / MINUTE).coerceAtLeast(1)
        val hours = minutes / 60
        val minuteText = digits((minutes % 60).toString(), model.arabicDigits)
        return if (hours > 0) {
            context.getString(R.string.widget_short_hours, digits(hours.toString(), model.arabicDigits), minuteText)
        } else {
            context.getString(R.string.widget_short_minutes, minuteText)
        }
    }

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

    /** A tap always opens prayer times, including when the widget is stale. */
    private fun tapIntent(context: Context): PendingIntent = PendingIntent.getActivity(
        context,
        REQUEST_CODE,
        appIntent(context),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    private fun refreshIntent(context: Context): PendingIntent = PendingIntent.getBroadcast(
        context,
        REQUEST_CODE,
        Intent(context, PrayerWidgetProvider::class.java).setAction(REFRESH_ACTION),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
}
