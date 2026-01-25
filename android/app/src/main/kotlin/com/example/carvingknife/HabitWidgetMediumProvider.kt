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
import java.util.Calendar
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
            context, appWidgetId, openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        try {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val habitsJson = prefs.getString("flutter.simple_habits", null)

            if (habitsJson != null && habitsJson.isNotEmpty() && habitsJson != "[]") {
                val habits = JSONArray(habitsJson)
                val habitCount = habits.length()
                val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
                val today = dateFormat.format(Date())

                var todayCompleted = 0
                val allCheckInDates = mutableSetOf<String>()

                for (i in 0 until habitCount) {
                    val habit = habits.getJSONObject(i)

                    // ===== 获取每日目标次数，默认为1 =====
                    val dailyTarget = habit.optInt("dailyTarget", 1)

                    val checkInRecords = habit.optJSONArray("checkInRecords")

                    // ===== 统计今日打卡次数 =====
                    var todayCheckInCount = 0

                    if (checkInRecords != null) {
                        for (j in 0 until checkInRecords.length()) {
                            val record = checkInRecords.getJSONObject(j)
                            val time = record.optString("time", "")
                            if (time.length >= 10) {
                                val dateStr = time.substring(0, 10)
                                allCheckInDates.add(dateStr)

                                // ===== 统计今天的打卡次数 =====
                                if (dateStr == today) {
                                    todayCheckInCount++
                                }
                            }
                        }
                    }

                    // ===== 只有当今日打卡次数 >= 每日目标时才算完成 =====
                    if (todayCheckInCount >= dailyTarget) {
                        todayCompleted++
                    }
                }

                val streak = calculateStreak(allCheckInDates, dateFormat)
                views.setTextViewText(R.id.widget_title, "雕刀")
                views.setTextViewText(R.id.widget_summary, "$todayCompleted/$habitCount")
                views.setTextViewText(R.id.widget_progress, "$todayCompleted/$habitCount")
                views.setTextViewText(R.id.widget_streak, "🔥 连续 $streak 天")
            } else {
                views.setTextViewText(R.id.widget_title, "雕刀")
                views.setTextViewText(R.id.widget_summary, "0/0")
                views.setTextViewText(R.id.widget_progress, "0/0")
                views.setTextViewText(R.id.widget_streak, "🔥 连续 0 天")
            }
        } catch (e: Exception) {
            views.setTextViewText(R.id.widget_title, "雕刀")
            views.setTextViewText(R.id.widget_summary, "0/0")
            views.setTextViewText(R.id.widget_progress, "0/0")
            views.setTextViewText(R.id.widget_streak, "🔥 连续 0 天")
        }

        views.setOnClickPendingIntent(R.id.widget_container, openAppPendingIntent)
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun calculateStreak(dates: Set<String>, dateFormat: SimpleDateFormat): Int {
        if (dates.isEmpty()) return 0
        var streak = 0
        val calendar = Calendar.getInstance()
        val today = dateFormat.format(calendar.time)
        if (!dates.contains(today)) calendar.add(Calendar.DAY_OF_YEAR, -1)
        while (dates.contains(dateFormat.format(calendar.time))) {
            streak++
            calendar.add(Calendar.DAY_OF_YEAR, -1)
        }
        return streak
    }
}