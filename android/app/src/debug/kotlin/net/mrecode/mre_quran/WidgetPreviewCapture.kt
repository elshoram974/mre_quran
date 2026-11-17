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
        Shot(R.layout.prayer_widget, "prayer_widget_preview", 172, 72),
        Shot(R.layout.prayer_schedule_widget, "prayer_schedule_widget_preview", 172, 200),
        Shot(R.layout.adhkar_widget, "adhkar_widget_preview", 172, 72),
        Shot(R.layout.tasbih_widget, "tasbih_widget_preview", 76, 76),
    )

    private val stage by lazy { FrameLayout(this) }
    private lateinit var out: File

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        out = File(filesDir, "widget_previews").apply { deleteRecursively(); mkdirs() }
        setContentView(stage)
        val jobs = ArrayDeque<Pair<String, Shot>>()
        for (language in listOf("en", "ar")) for (shot in shots) jobs.add(language to shot)
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
        val view = RemoteViews(packageName, shot.layout).apply(context, stage)
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
