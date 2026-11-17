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

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val out = File(filesDir, "widget_previews").apply { deleteRecursively(); mkdirs() }
        for (language in listOf("en", "ar")) {
            val context = localized(language)
            val folder = File(out, language).apply { mkdirs() }
            for (shot in shots) {
                File(folder, "${shot.name}.png").outputStream().use {
                    draw(context, shot, language == "ar").compress(Bitmap.CompressFormat.PNG, 100, it)
                }
            }
        }
        File(out, "done").writeText("ok")
        finish()
    }

    private fun localized(language: String): Context {
        val configuration = Configuration(resources.configuration)
        configuration.setLocale(Locale.forLanguageTag(language))
        configuration.setLayoutDirection(Locale.forLanguageTag(language))
        return createConfigurationContext(configuration)
    }

    private fun draw(context: Context, shot: Shot, rtl: Boolean): Bitmap {
        val density = context.resources.displayMetrics.density
        val width = (shot.widthDp * density).toInt()
        val height = (shot.heightDp * density).toInt()
        val host = FrameLayout(context)
        val view = RemoteViews(packageName, shot.layout).apply(context, host)
        view.layoutDirection = if (rtl) View.LAYOUT_DIRECTION_RTL else View.LAYOUT_DIRECTION_LTR
        view.measure(
            View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(height, View.MeasureSpec.EXACTLY),
        )
        view.layout(0, 0, width, height)
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        view.draw(Canvas(bitmap))
        return bitmap
    }
}
