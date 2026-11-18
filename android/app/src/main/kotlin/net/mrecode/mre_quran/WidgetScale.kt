package net.mrecode.mre_quran

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.res.Configuration
import android.util.TypedValue
import android.widget.RemoteViews
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * Lets a home-screen widget grow with the room the launcher gives it: its
 * text, its buttons and its spacing are scaled by how much larger than its
 * base size the widget is. RemoteViews take text sizes and paddings at run
 * time on every Android version, so one layout serves every size.
 */
internal object WidgetScale {
    /** The most a widget is scaled up; past this it only gains room. */
    private const val MOST = 2.2f

    /**
     * How much bigger than [baseWidthDp] x [baseHeightDp] widget is
     * drawn: 1 at its base size or smaller, more when the person resized it.
     */
    fun of(width: Int, height: Int, baseWidthDp: Float, baseHeightDp: Float): Float {
        if (width <= 0 || height <= 0) return 1f
        return min(width / baseWidthDp, height / baseHeightDp).coerceIn(1f, MOST)
    }

    /** Launchers report a range across portrait and landscape orientations. */
    fun size(context: Context, manager: AppWidgetManager, id: Int): Pair<Int, Int> {
        val options = manager.getAppWidgetOptions(id)
        val landscape = context.resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE
        val widthKey = if (landscape) AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH else AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH
        val heightKey = if (landscape) AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT else AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT
        return options.getInt(widthKey, 0) to options.getInt(heightKey, 0)
    }

    /** Sets view [id]'s text to [sp] scaled by [scale]. */
    fun text(views: RemoteViews, id: Int, sp: Float, scale: Float) =
        views.setTextViewTextSize(id, TypedValue.COMPLEX_UNIT_SP, sp * scale)

    /** Sets the same padding, [dp] scaled by [scale], on all sides of [id]. */
    fun padding(context: Context, views: RemoteViews, id: Int, horizontalDp: Float, verticalDp: Float, scale: Float) {
        val density = context.resources.displayMetrics.density
        val h = (horizontalDp * scale * density).roundToInt()
        val v = (verticalDp * scale * density).roundToInt()
        views.setViewPadding(id, h, v, h, v)
    }
}
