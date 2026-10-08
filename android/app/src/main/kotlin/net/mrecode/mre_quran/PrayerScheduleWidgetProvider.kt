package net.mrecode.mre_quran

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.widget.RemoteViews

class PrayerScheduleWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        PrayerWidgetProvider.updateSchedule(context, manager)
    }

    companion object {
        fun refresh(context: Context) = PrayerWidgetProvider.updateSchedule(
            context,
            AppWidgetManager.getInstance(context),
        )
    }
}
