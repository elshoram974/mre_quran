package net.mrecode.mre_quran

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.widget.RemoteViews

/**
 * Home-screen tasbih counter. A tap on the number adds one and the reset
 * button clears it. The count lives in this widget's own preferences, so it
 * works without opening the app.
 */
class TasbihWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) =
        redraw(context, manager, ids)

    /** Resized: everything is drawn again at the new size. */
    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: Bundle) =
        redraw(context, manager, intArrayOf(id))

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_COUNT -> count(context)
            ACTION_RESET -> change(context) { 0 }
            else -> super.onReceive(context, intent)
        }
    }

    internal fun count(context: Context) {
        tick(context)
        change(context) { it + 1 }
    }

    /**
     * The same short pulse as a count in the app (PlatformHaptics.tick: 14 ms
     * at amplitude 110), straight from the vibrator. Touch feedback is not
     * used: phones often have it switched off, which would silence the
     * widget while the app's own setting says to vibrate.
     */
    @Suppress("DEPRECATION")
    private fun tick(context: Context) {
        if (!context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).getBoolean(HAPTICS, true)) return
        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            context.getSystemService(VibratorManager::class.java)?.defaultVibrator
        } else context.getSystemService(Vibrator::class.java)
        if (vibrator == null || !vibrator.hasVibrator()) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val amplitude = if (vibrator.hasAmplitudeControl()) 110 else VibrationEffect.DEFAULT_AMPLITUDE
            vibrator.vibrate(VibrationEffect.createOneShot(14, amplitude))
        } else vibrator.vibrate(14)
    }

    private fun change(context: Context, next: (Int) -> Int) {
        val preferences = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        preferences.edit().putInt(COUNT, next(preferences.getInt(COUNT, 0))).apply()
        val manager = AppWidgetManager.getInstance(context)
        redraw(context, manager, manager.getAppWidgetIds(ComponentName(context, javaClass)))
    }

    private fun redraw(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val count = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).getInt(COUNT, 0)
        val settings = AdhkarWidgetRenderer.read(context)
        for (id in ids) {
            val views = RemoteViews(context.packageName, R.layout.tasbih_widget)
            val text = count.toString().let { value ->
                if (settings?.useArabicDigits == true) value.map { if (it in '0'..'9') '٠' + (it - '0') else it }.joinToString("") else value
            }
            views.setTextViewText(R.id.tasbih_widget_count, text)
            if (settings != null) {
                views.setInt(R.id.tasbih_widget_root, "setLayoutDirection", if (settings.rtl) android.view.View.LAYOUT_DIRECTION_RTL else android.view.View.LAYOUT_DIRECTION_LTR)
                settings.tasbihLabel?.let { views.setTextViewText(R.id.tasbih_widget_name, it) }
                settings.tasbihResetLabel?.let { views.setContentDescription(R.id.tasbih_widget_reset, it) }
            }
            val countTap = if (context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).getBoolean(HAPTICS, true)) {
                PendingIntent.getActivity(context, 1, Intent(context, WidgetTapActivity::class.java).setAction(ACTION_COUNT),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            } else broadcast(context, ACTION_COUNT, 1)
            val countLabel = settings?.tasbihCountLabel ?: context.getString(R.string.tasbih_widget_count_description)
            views.setContentDescription(R.id.tasbih_widget_count_area, "$countLabel · $text")
            views.setOnClickPendingIntent(R.id.tasbih_widget_count_area, countTap)
            views.setOnClickPendingIntent(R.id.tasbih_widget_reset, broadcast(context, ACTION_RESET, 2))
            // A bigger widget gets a bigger name and reset button; the count
            // sizes itself to fill what is left.
            HomeWidgets.applyBackground(context, views, R.id.tasbih_widget_root)
            val (width, height) = WidgetScale.size(context, manager, id)
            val scale = WidgetScale.of(width, height, BASE_WIDTH_DP, BASE_HEIGHT_DP)
            WidgetScale.text(views, R.id.tasbih_widget_name, 11f, scale.coerceAtMost(1.2f))
            WidgetScale.text(views, R.id.tasbih_widget_reset_icon, 14f, scale.coerceAtMost(1.2f))
            WidgetScale.padding(context, views, R.id.tasbih_widget_reset_icon, 8f, 2f, scale.coerceAtMost(1.2f))
            manager.updateAppWidget(id, views)
        }
    }

    private fun broadcast(context: Context, action: String, code: Int): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            code,
            Intent(context, TasbihWidgetProvider::class.java).setAction(action),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    companion object {
        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            TasbihWidgetProvider().redraw(context, manager, manager.getAppWidgetIds(ComponentName(context, TasbihWidgetProvider::class.java)))
        }
        fun setHapticsEnabled(context: Context, enabled: Boolean) {
            val preferences = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            if (preferences.getBoolean(HAPTICS, true) == enabled) return
            preferences.edit().putBoolean(HAPTICS, enabled).apply()
            refresh(context)
        }

        private const val HAPTICS = "haptics"
        /** The size the widget is drawn at before scaling: two cells by one. */
        const val BASE_WIDTH_DP = 140f
        const val BASE_HEIGHT_DP = 60f
        const val PREFERENCES = "tasbih_widget"
        const val COUNT = "count"
        const val ACTION_COUNT = "net.mrecode.mre_quran.TASBIH_COUNT"
        const val ACTION_RESET = "net.mrecode.mre_quran.TASBIH_RESET"
    }
}
