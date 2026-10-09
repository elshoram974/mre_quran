package net.mrecode.mre_quran

import org.json.JSONObject

/** One line of a day's times. [at] is epoch milliseconds. */
internal data class WidgetRow(val id: String, val name: String, val time: String, val at: Long) {
    val isPrayer: Boolean get() = id != SUNRISE

    companion object {
        const val SUNRISE = "sunrise"
    }
}

/** A day of times, from [start] (inclusive) to [end] (exclusive). */
internal data class WidgetDay(
    val start: Long,
    val end: Long,
    val dateLabel: String,
    val hijriLabel: String,
    val rows: List<WidgetRow>,
)

/** Texts in the app's language, with `%1$s` / `%2$s` where numbers go. */
internal data class WidgetLabels(
    val next: String,
    val remaining: String,
    val hours: String,
    val minutes: String,
    val empty: String,
)

/**
 * What the widgets show, as the app sent it: a few days of times, so the widget
 * keeps moving to the next prayer without the app running.
 */
internal class WidgetModel(
    val days: List<WidgetDay>,
    val labels: WidgetLabels,
    val arabicDigits: Boolean,
    val rtl: Boolean,
) {
    /** The day [now] falls in, or null once the sent days have run out. */
    fun dayAt(now: Long): WidgetDay? = days.firstOrNull { now >= it.start && now < it.end }

    /** The next prayer after [now] (sunrise is not one), or null when none is left. */
    fun nextAfter(now: Long): WidgetRow? = days
        .flatMap { it.rows }
        .filter { it.isPrayer && it.at > now }
        .minByOrNull { it.at }

    companion object {
        fun parse(json: String?): WidgetModel? {
            if (json.isNullOrEmpty()) return null
            return try {
                val root = JSONObject(json)
                val labels = root.getJSONObject("labels")
                val days = root.getJSONArray("days")
                WidgetModel(
                    days = List(days.length()) { index ->
                        val day = days.getJSONObject(index)
                        val rows = day.getJSONArray("rows")
                        WidgetDay(
                            start = day.getLong("start"),
                            end = day.getLong("end"),
                            dateLabel = day.getString("dateLabel"),
                            hijriLabel = day.getString("hijriLabel"),
                            rows = List(rows.length()) { r ->
                                val row = rows.getJSONObject(r)
                                WidgetRow(
                                    id = row.getString("id"),
                                    name = row.getString("name"),
                                    time = row.getString("time"),
                                    at = row.getLong("at"),
                                )
                            },
                        )
                    },
                    labels = WidgetLabels(
                        next = labels.getString("next"),
                        remaining = labels.getString("remaining"),
                        hours = labels.getString("hours"),
                        minutes = labels.getString("minutes"),
                        empty = labels.getString("empty"),
                    ),
                    arabicDigits = root.optBoolean("useArabicDigits", true),
                    rtl = root.optBoolean("rtl", true),
                )
            } catch (_: Exception) {
                null
            }
        }
    }
}
