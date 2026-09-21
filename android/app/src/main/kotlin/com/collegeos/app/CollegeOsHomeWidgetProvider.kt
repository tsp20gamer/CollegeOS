package com.collegeos.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class CollegeOsHomeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        val savedDate = widgetData.getString("widget_date_key", null)
        appWidgetIds.forEach { widgetId ->
            render(context, appWidgetManager, widgetId, widgetData, today, savedDate)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        val widgetData = HomeWidgetPlugin.getData(context)
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        render(
            context,
            appWidgetManager,
            appWidgetId,
            widgetData,
            today,
            widgetData.getString("widget_date_key", null),
        )
    }

    private fun render(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        widgetData: SharedPreferences,
        today: String,
        savedDate: String?,
    ) {
        val minHeight = appWidgetManager.getAppWidgetOptions(widgetId)
            .getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 150)
        val showAttendance = minHeight >= 140
        val views = RemoteViews(context.packageName, R.layout.college_os_home_widget).apply {
                setOnClickPendingIntent(
                    R.id.widget_container,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
                setTextViewText(
                    R.id.widget_class_label,
                    widgetData.getString("widget_class_label", "NEXT CLASS"),
                )
                setTextViewText(
                    R.id.widget_class_title,
                    widgetData.getString("widget_class_title", "Open CollegeOS"),
                )
                setTextViewText(
                    R.id.widget_class_time,
                    widgetData.getString("widget_class_time", "View your timetable"),
                )
                setTextViewText(
                    R.id.widget_class_meta,
                    widgetData.getString("widget_class_meta", ""),
                )
                setViewVisibility(
                    R.id.widget_attendance_divider,
                    if (showAttendance) View.VISIBLE else View.GONE,
                )
                setViewVisibility(
                    R.id.widget_attendance_section,
                    if (showAttendance) View.VISIBLE else View.GONE,
                )
                setTextViewText(
                    R.id.widget_attendance_title,
                    widgetData.getString("widget_attendance_title", "TODAY'S ATTENDANCE"),
                )
                if (savedDate == today) {
                    setTextViewText(
                        R.id.widget_attendance_summary,
                        widgetData.getString("widget_attendance_summary", "Open CollegeOS"),
                    )
                    setTextViewText(
                        R.id.widget_attendance_meta,
                        widgetData.getString("widget_attendance_meta", "Tap to view"),
                    )
                    setTextViewText(
                        R.id.widget_attendance_status,
                        widgetData.getString("widget_attendance_status", "Today"),
                    )
                    setProgressBar(
                        R.id.widget_attendance_progress,
                        100,
                        widgetData.getString("widget_attendance_progress", "0")
                            ?.toIntOrNull()
                            ?.coerceIn(0, 100) ?: 0,
                        false,
                    )
                } else {
                    setTextViewText(R.id.widget_attendance_summary, "Open CollegeOS to refresh")
                    setTextViewText(R.id.widget_attendance_meta, "Today's data is not loaded yet")
                    setTextViewText(R.id.widget_attendance_status, "Refresh needed")
                    setProgressBar(R.id.widget_attendance_progress, 100, 0, false)
                }
        }
        appWidgetManager.updateAppWidget(widgetId, views)
    }
}
