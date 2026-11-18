package net.mrecode.mre_quran

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.os.Build

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
