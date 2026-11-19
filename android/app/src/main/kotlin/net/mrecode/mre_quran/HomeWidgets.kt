package net.mrecode.mre_quran

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.os.Build
import android.widget.RemoteViews

/**
 * The app's home-screen widgets, by the names the app gives them
 * (HomeWidget in Dart): whether the launcher can be asked to add one, asking
 * it, and whether any is on the home screen.
 */
object HomeWidgets {
    private val providers = mapOf(
        "prayerCard" to PrayerCardWidgetProvider::class.java,
        "nextPrayer" to PrayerWidgetProvider::class.java,
        "prayerSchedule" to PrayerScheduleWidgetProvider::class.java,
        "tasbih" to TasbihWidgetProvider::class.java,
        "dhikr" to AdhkarWidgetProvider::class.java,
    )

    fun appearance(context: Context): String =
        context.getSharedPreferences("home_widgets", Context.MODE_PRIVATE)
            .getString("appearance", "automatic") ?: "automatic"

    fun setAppearance(context: Context, style: String?): Boolean {
        if (style !in setOf("automatic", "navy", "green")) return false
        context.getSharedPreferences("home_widgets", Context.MODE_PRIVATE).edit()
            .putString("appearance", style).apply()
        PrayerWidgetRenderer.updateAll(context)
        AdhkarWidgetRenderer.updateAll(context)
        TasbihWidgetProvider.refresh(context)
        return true
    }

    /** Options are shared by all placed schedule widgets. */
    fun prayerScheduleOptions(context: Context): Map<String, Boolean> {
        val prefs = context.getSharedPreferences("home_widgets", Context.MODE_PRIVATE)
        return mapOf(
            "upcomingOnly" to prefs.getBoolean("schedule_upcoming", false),
            "showSunrise" to prefs.getBoolean("schedule_sunrise", true),
            "showDate" to prefs.getBoolean("schedule_date", true),
            "showCountdown" to prefs.getBoolean("schedule_countdown", true),
            "largeText" to prefs.getBoolean("schedule_large_text", false),
        )
    }

    fun setPrayerScheduleOptions(context: Context, options: Map<*, *>?): Boolean {
        val keys = mapOf(
            "upcomingOnly" to "schedule_upcoming",
            "showSunrise" to "schedule_sunrise",
            "showDate" to "schedule_date",
            "showCountdown" to "schedule_countdown",
            "largeText" to "schedule_large_text",
        )
        if (options == null || keys.keys.any { options[it] !is Boolean }) return false
        val editor = context.getSharedPreferences("home_widgets", Context.MODE_PRIVATE).edit()
        keys.forEach { (key, preference) -> editor.putBoolean(preference, options[key] as Boolean) }
        editor.apply()
        PrayerWidgetRenderer.updateAll(context)
        return true
    }

    internal fun applyBackground(context: Context, views: RemoteViews, root: Int) {
        val background = when (appearance(context)) {
            "navy" -> R.drawable.widget_card_bg
            "green" -> R.drawable.widget_bg
            else -> if (root == R.id.card_root) R.drawable.widget_card_bg else R.drawable.widget_bg
        }
        views.setInt(root, "setBackgroundResource", background)
    }

    /** Android 8 and later, on a launcher that takes the request. */
    fun canPin(context: Context): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            AppWidgetManager.getInstance(context).isRequestPinAppWidgetSupported

    /**
     * Asks the launcher to add the widget [name]; the launcher shows it and
     * asks the person. False when it could not be asked.
     */
    fun pin(context: Context, name: String?): Boolean {
        val provider = providers[name] ?: return false
        if (!canPin(context)) return false
        return AppWidgetManager.getInstance(context)
            .requestPinAppWidget(ComponentName(context, provider), null, null)
    }

    /** Whether any of the app's widgets is on a home screen. */
    fun placed(context: Context): Boolean {
        val manager = AppWidgetManager.getInstance(context)
        return providers.values.any {
            manager.getAppWidgetIds(ComponentName(context, it)).isNotEmpty()
        }
    }
}
