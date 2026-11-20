package net.mrecode.mre_quran

import android.app.Activity
import android.content.Context
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.os.Bundle
import android.view.View
import android.widget.FrameLayout
import android.widget.RemoteViews
import java.io.File
import java.util.Locale

/**
 * Debug builds only: draws each home-screen widget from its real layout,
 * with the layout's own sample text, in English and in Arabic, and saves the
 * pictures. They become the widgets' `previewImage`, so a launcher that
 * cannot draw the layout itself shows exactly what the widget looks like.
 *
 * Run `tool/capture_widget_previews.sh`; it starts this, then copies the
 * pictures into res/drawable-nodpi (English) and res/drawable-ar-nodpi.
 */
class WidgetPreviewCapture : Activity() {
    /** A widget's layout, its name in res, and the size it is shown at. */
    private data class Shot(val layout: Int, val name: String, val widthDp: Int, val heightDp: Int)

    private val shots = listOf(
        Shot(R.layout.prayer_widget, "prayer_widget_preview", 140, 60),
        Shot(R.layout.prayer_schedule_widget, "prayer_schedule_widget_preview", 148, 190),
        Shot(R.layout.adhkar_widget, "adhkar_widget_preview", 172, 72),
        Shot(R.layout.tasbih_widget, "tasbih_widget_preview", 172, 72),
        Shot(R.layout.prayer_card_widget, "prayer_card_widget_preview", 215, 160),
    )

    private val stage by lazy { FrameLayout(this) }
    private lateinit var out: File

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        out = File(filesDir, "widget_previews").apply { deleteRecursively(); mkdirs() }
        setContentView(stage)
        val jobs = ArrayDeque<Pair<String, Shot>>()
        // Optional size helps check narrow and expanded launcher widgets.
        val scheduleWidth = intent.getIntExtra("scheduleWidthDp", 0)
        val scheduleHeight = intent.getIntExtra("scheduleHeightDp", 0)
        for (language in listOf("en", "ar")) for (shot in shots) {
            val preview = if (shot.layout == R.layout.prayer_schedule_widget) {
                shot.copy(
                    layout = shot.layout,
                    widthDp = if (scheduleWidth > 0) scheduleWidth else shot.widthDp,
                    heightDp = if (scheduleHeight > 0) scheduleHeight else shot.heightDp,
                )
            } else shot
            jobs.add(language to preview)
        }
        next(jobs)
    }

    /**
     * Draws the next widget once it is on screen and has been through a whole
     * frame: a text view only settles where its line starts (the end of the
     * line, for one-line text in Arabic) after a frame on a window.
     */
    private fun next(jobs: ArrayDeque<Pair<String, Shot>>) {
        val job = jobs.removeFirstOrNull()
        if (job == null) {
            File(out, "done").writeText("ok")
            finish()
            return
        }
        val (language, shot) = job
        val context = localized(language)
        val density = context.resources.displayMetrics.density
        val width = (shot.widthDp * density).toInt()
        val height = (shot.heightDp * density).toInt()
        stage.removeAllViews()
        val liveSchedule = shot.layout == R.layout.prayer_schedule_widget &&
            intent.getBooleanExtra("scheduleLive", false)
        val views = if (liveSchedule) {
            val sampleTime = java.util.Calendar.getInstance().apply {
                set(java.util.Calendar.HOUR_OF_DAY, 11)
                set(java.util.Calendar.MINUTE, 20)
                set(java.util.Calendar.SECOND, 0)
                set(java.util.Calendar.MILLISECOND, 0)
            }
            val now = sampleTime.timeInMillis
            val rows = listOf(
                Triple("fajr", R.string.widget_preview_fajr, R.string.widget_preview_fajr_time),
                Triple("sunrise", R.string.widget_preview_sunrise, R.string.widget_preview_sunrise_time),
                Triple("dhuhr", R.string.widget_preview_dhuhr, R.string.widget_preview_dhuhr_time),
                Triple("asr", R.string.widget_preview_asr, R.string.widget_preview_asr_time),
                Triple("maghrib", R.string.widget_preview_maghrib, R.string.widget_preview_maghrib_time),
                Triple("isha", R.string.widget_preview_isha, R.string.widget_preview_isha_time),
            ).mapIndexed { index, (id, name, time) ->
                val offset = listOf(-353L, -266L, 84L, 282L, 432L, 509L)[index]
                WidgetRow(id, context.getString(name), context.getString(time), now + offset * 60_000L)
            }
            val day = WidgetDay(now - 43_200_000L, now + 43_200_000L,
                context.getString(R.string.widget_preview_date), context.getString(R.string.widget_preview_hijri), rows)
            val ar = language == "ar"
            val labels = WidgetLabels("", if (ar) "بعد %1\$s" else "in %1\$s",
                if (ar) "%1\$s س %2\$s د" else "%1\$s h %2\$s min",
                if (ar) "%1\$s د" else "%1\$s min", context.getString(R.string.prayer_widget_empty))
            val model = WidgetModel(listOf(day), labels, ar, ar, intent.getBooleanExtra("scheduleSeconds", false))
            val options = mapOf(
                "upcomingOnly" to intent.getBooleanExtra("scheduleUpcoming", false),
                "showSunrise" to !intent.getBooleanExtra("scheduleHideSunrise", false),
                "showDate" to !intent.getBooleanExtra("scheduleHideDate", false),
                "showCountdown" to !intent.getBooleanExtra("scheduleHideCountdown", false),
                "largeText" to intent.getBooleanExtra("scheduleLargeText", false),
            )
            PrayerWidgetRenderer.scheduleWidgetViews(context, model, now, shot.widthDp, shot.heightDp, options)
        } else RemoteViews(packageName, shot.layout)
        val view = views.apply(context, stage)
        view.layoutDirection = if (language == "ar") View.LAYOUT_DIRECTION_RTL else View.LAYOUT_DIRECTION_LTR
        stage.addView(view, FrameLayout.LayoutParams(width, height))
        view.postDelayed({
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            view.draw(Canvas(bitmap))
            val folder = File(out, language).apply { mkdirs() }
            File(folder, "${shot.name}.png").outputStream().use {
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)
            }
            next(jobs)
        }, 300)
    }

    private fun localized(language: String): Context {
        val configuration = Configuration(resources.configuration)
        configuration.setLocale(Locale.forLanguageTag(language))
        configuration.setLayoutDirection(Locale.forLanguageTag(language))
        return createConfigurationContext(configuration)
    }
}
