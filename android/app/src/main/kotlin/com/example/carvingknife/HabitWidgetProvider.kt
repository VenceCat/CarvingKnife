package com.example.carvingknife

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

class HabitWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val SIZE_2X2 = 146
        private const val SIZE_2X3_HEIGHT = 220
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            updateWidget(context, appWidgetManager, appWidgetId, options)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        updateWidget(context, appWidgetManager, appWidgetId, newOptions)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, HabitWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetIds, R.id.habit_list)

            for (appWidgetId in appWidgetIds) {
                val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
                updateWidget(context, appWidgetManager, appWidgetId, options)
            }
        }
    }

    private fun getLayoutId(options: Bundle): Int {
        val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)

        return when {
            // 小于 2x2：小布局
            minWidth < SIZE_2X2 || minHeight < SIZE_2X2 -> R.layout.habit_widget_layout_small
            // 宽度或高度任一 >= 220dp：大布局（如 2x3、3x2、3x3 等）
            minWidth >= SIZE_2X3_HEIGHT || minHeight >= SIZE_2X3_HEIGHT -> R.layout.habit_widget_layout
            // 2x2：中布局
            else -> R.layout.habit_widget_layout_medium
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        options: Bundle
    ) {
        val layoutId = getLayoutId(options)
        val views = RemoteViews(context.packageName, layoutId)

        val openAppIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openAppPendingIntent = PendingIntent.getActivity(
            context,
            appWidgetId,
            openAppIntent,
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
                    val checkInRecords = habit.optJSONArray("checkInRecords")

                    var habitDoneToday = false

                    if (checkInRecords != null) {
                        for (j in 0 until checkInRecords.length()) {
                            val record = checkInRecords.getJSONObject(j)
                            val time = record.optString("time", "")
                            if (time.length >= 10) {
                                val dateStr = time.substring(0, 10)
                                allCheckInDates.add(dateStr)

                                if (dateStr == today && !habitDoneToday) {
                                    habitDoneToday = true
                                    todayCompleted++
                                }
                            }
                        }
                    }
                }

                val streak = calculateStreak(allCheckInDates, dateFormat)

                // 正常有数据时
                when (layoutId) {
                    R.layout.habit_widget_layout_small -> {
                        views.setTextViewText(R.id.widget_summary, "$todayCompleted/$habitCount")
                        views.setTextViewText(R.id.widget_streak, "🔥 ${streak}天")
                    }
                    R.layout.habit_widget_layout_medium -> {
                        views.setTextViewText(R.id.widget_title, "雕刀")
                        views.setTextViewText(R.id.widget_summary, "$todayCompleted/$habitCount")
                        views.setTextViewText(R.id.widget_progress, "$todayCompleted/$habitCount")
                        views.setTextViewText(R.id.widget_streak, "🔥 连续 $streak 天")
                    }
                    else -> {
                        views.setTextViewText(R.id.widget_title, "雕刀")
                        views.setTextViewText(R.id.widget_summary, "$todayCompleted/$habitCount")
                        views.setTextViewText(R.id.widget_streak, "🔥 连续 $streak 天")

                        if (habitCount > 0) {
                            views.setViewVisibility(R.id.habit_list, View.VISIBLE)
                            views.setViewVisibility(R.id.empty_text, View.GONE)

                            val serviceIntent = Intent(context, HabitWidgetService::class.java).apply {
                                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
                            }
                            views.setRemoteAdapter(R.id.habit_list, serviceIntent)
                            views.setPendingIntentTemplate(R.id.habit_list, openAppPendingIntent)
                        } else {
                            showEmptyState(views)
                        }
                    }
                }
            } else {
                // ================================
                // 空数据时 - 已修改
                // ================================
                when (layoutId) {
                    R.layout.habit_widget_layout_small -> {
                        views.setTextViewText(R.id.widget_summary, "0/0")
                        views.setTextViewText(R.id.widget_streak, "🔥 0天")
                    }
                    R.layout.habit_widget_layout_medium -> {
                        views.setTextViewText(R.id.widget_title, "雕刀")
                        views.setTextViewText(R.id.widget_summary, "0/0")
                        views.setTextViewText(R.id.widget_progress, "0/0")
                        views.setTextViewText(R.id.widget_streak, "🔥 连续 0 天")
                    }
                    else -> {
                        views.setTextViewText(R.id.widget_title, "雕刀")
                        views.setTextViewText(R.id.widget_summary, "0/0")
                        views.setTextViewText(R.id.widget_streak, "🔥 连续 0 天")
                        showEmptyState(views)
                    }
                }
            }

        } catch (e: Exception) {
            // ================================
            // 异常处理时 - 已修改
            // ================================
            e.printStackTrace()
            when (layoutId) {
                R.layout.habit_widget_layout_small -> {
                    views.setTextViewText(R.id.widget_summary, "0/0")
                    views.setTextViewText(R.id.widget_streak, "🔥 0天")
                }
                R.layout.habit_widget_layout_medium -> {
                    views.setTextViewText(R.id.widget_title, "雕刀")
                    views.setTextViewText(R.id.widget_summary, "0/0")
                    views.setTextViewText(R.id.widget_progress, "0/0")
                    views.setTextViewText(R.id.widget_streak, "🔥 连续 0 天")
                }
                else -> {
                    views.setTextViewText(R.id.widget_title, "雕刀")
                    views.setTextViewText(R.id.widget_summary, "0/0")
                    views.setTextViewText(R.id.widget_streak, "🔥 连续 0 天")
                    showEmptyState(views)
                }
            }
        }

        // 设置点击事件
        views.setOnClickPendingIntent(R.id.widget_container, openAppPendingIntent)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun calculateStreak(dates: Set<String>, dateFormat: SimpleDateFormat): Int {
        if (dates.isEmpty()) return 0

        var streak = 0
        val calendar = Calendar.getInstance()
        val today = dateFormat.format(calendar.time)

        if (!dates.contains(today)) {
            calendar.add(Calendar.DAY_OF_YEAR, -1)
        }

        while (true) {
            val dateStr = dateFormat.format(calendar.time)
            if (dates.contains(dateStr)) {
                streak++
                calendar.add(Calendar.DAY_OF_YEAR, -1)
            } else {
                break
            }
        }

        return streak
    }

    private fun showEmptyState(views: RemoteViews) {
        views.setViewVisibility(R.id.habit_list, View.GONE)
        views.setViewVisibility(R.id.empty_text, View.VISIBLE)
    }
}