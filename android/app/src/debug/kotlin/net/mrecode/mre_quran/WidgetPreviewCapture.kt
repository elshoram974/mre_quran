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
        Shot(R.layout.prayer_schedule_compact_widget, "prayer_schedule_widget_preview", 140, 60),
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
            val preview = if (shot.layout == R.layout.prayer_schedule_compact_widget) {
                shot.copy(
                    layout = if (scheduleHeight >= 150) R.layout.prayer_schedule_widget else shot.layout,
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
        val views = RemoteViews(packageName, shot.layout)
        if (shot.layout == R.layout.prayer_schedule_compact_widget && shot.widthDp <= 120) {
            val ids = listOf(
                R.id.schedule_next_name, R.id.schedule_remaining, R.id.schedule_seconds,
                R.id.schedule_name_0, R.id.schedule_name_1, R.id.schedule_name_2,
                R.id.schedule_name_3, R.id.schedule_name_4, R.id.schedule_name_5,
                R.id.schedule_time_0, R.id.schedule_time_1, R.id.schedule_time_2,
                R.id.schedule_time_3, R.id.schedule_time_4, R.id.schedule_time_5,
            )
            ids.forEach { WidgetScale.text(views, it, 10f, 1f) }
            val names = listOf(
                R.string.widget_preview_fajr, R.string.widget_preview_sunrise,
                R.string.widget_preview_dhuhr, R.string.widget_preview_asr,
                R.string.widget_preview_maghrib, R.string.widget_preview_isha,
            )
            val nameIds = listOf(
                R.id.schedule_name_0, R.id.schedule_name_1, R.id.schedule_name_2,
                R.id.schedule_name_3, R.id.schedule_name_4, R.id.schedule_name_5,
            )
            val prayerIds = listOf("fajr", "sunrise", "dhuhr", "asr", "maghrib", "isha")
            names.forEachIndexed { index, name ->
                val label = PrayerWidgetRenderer.compactScheduleName(
                    context.getString(name), prayerIds[index], language == "ar", true,
                )
                views.setTextViewText(nameIds[index], label)
            }
        }
        if (shot.layout == R.layout.prayer_schedule_compact_widget && shot.heightDp >= 95) {
            views.setViewVisibility(R.id.schedule_dates_stacked, View.VISIBLE)
        }
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
