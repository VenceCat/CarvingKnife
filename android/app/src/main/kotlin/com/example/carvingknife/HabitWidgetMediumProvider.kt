package com.example.carvingknife

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class HabitWidgetMediumProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, HabitWidgetMediumProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            for (appWidgetId in appWidgetIds) {
                updateWidget(context, appWidgetManager, appWidgetId)
            }
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.habit_widget_layout_medium)

        val openAppIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openAppPendingIntent = PendingIntent.getActivity(
            context,
            appWidgetId,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        var habitCount = 0
        var todayCompleted = 0

        try {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val habitsJson = prefs.getString("flutter.simple_habits", null)

            if (!habitsJson.isNullOrEmpty() && habitsJson != "[]") {
                val habits = JSONArray(habitsJson)
                habitCount = habits.length()
                val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
                val today = dateFormat.format(Date())

                for (i in 0 until habitCount) {
                    val habit = habits.getJSONObject(i)
                    val dailyTarget = habit.optInt("dailyTarget", 1)
                    val checkInRecords = habit.optJSONArray("checkInRecords")

                    var todayCheckInCount = 0
                    if (checkInRecords != null) {
                        for (j in 0 until checkInRecords.length()) {
                            val record = checkInRecords.getJSONObject(j)
                            val time = record.optString("time", "")
                            if (time.length >= 10 && time.substring(0, 10) == today) {
                                todayCheckInCount++
                            }
                        }
                    }

                    if (todayCheckInCount >= dailyTarget) {
                        todayCompleted++
                    }
                }
            }
        } catch (_: Exception) {
            habitCount = 0
            todayCompleted = 0
        }

        val progressText = "$todayCompleted/$habitCount"
        val progressRatio = if (habitCount > 0) {
            todayCompleted.toFloat() / habitCount.toFloat()
        } else {
            0f
        }

        views.setTextViewText(R.id.widget_title, "雕刀")
        views.setTextViewText(R.id.widget_summary, progressText)
        views.setTextViewText(R.id.widget_progress, progressText)
        views.setImageViewBitmap(
            R.id.widget_progress_ring,
            WidgetBitmapUtils.createProgressRingBitmap(context, progressRatio, sizeDp = 72f, strokeDp = 8f)
        )

        views.setOnClickPendingIntent(R.id.widget_container, openAppPendingIntent)
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
