package com.example.carvingknife

import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

class HabitWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return HabitRemoteViewsFactory(applicationContext)
    }
}

data class HabitItem(
    val title: String,
    val isDone: Boolean,
    val streak: Int,
    val totalCheckIns: Int,
    val todayCount: Int,
    val dailyTarget: Int,
    val iconIndex: Int
)

class HabitRemoteViewsFactory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {

    private var habits: List<HabitItem> = emptyList()

    override fun onCreate() {
        loadData()
    }

    override fun onDataSetChanged() {
        loadData()
    }

    private fun loadData() {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val habitsJson = prefs.getString("flutter.simple_habits", null)
        val list = mutableListOf<HabitItem>()

        if (!habitsJson.isNullOrEmpty() && habitsJson != "[]") {
            try {
                val habitsArray = JSONArray(habitsJson)
                val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
                val today = dateFormat.format(Date())

                for (i in 0 until habitsArray.length()) {
                    val habit = habitsArray.getJSONObject(i)
                    val title = habit.optString("title", "")
                    val dailyTarget = habit.optInt("dailyTarget", 1)

                    var todayCheckInCount = 0
                    val checkInDates = mutableSetOf<String>()

                    val checkInRecords = habit.optJSONArray("checkInRecords")
                    if (checkInRecords != null) {
                        for (j in 0 until checkInRecords.length()) {
                            val record = checkInRecords.getJSONObject(j)
                            val time = record.optString("time", "")
                            if (time.length >= 10) {
                                val dateStr = time.substring(0, 10)
                                checkInDates.add(dateStr)
                                if (dateStr == today) {
                                    todayCheckInCount++
                                }
                            }
                        }
                    }

                    list.add(
                        HabitItem(
                            title = title,
                            isDone = todayCheckInCount >= dailyTarget,
                            streak = calculateStreak(checkInDates, dateFormat),
                            totalCheckIns = checkInDates.size,
                            todayCount = todayCheckInCount,
                            dailyTarget = dailyTarget,
                            iconIndex = habit.optInt("iconIndex", 0)
                        )
                    )
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        habits = list
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
            if (!dates.contains(dateStr)) {
                break
            }
            streak++
            calendar.add(Calendar.DAY_OF_YEAR, -1)
        }

        return streak
    }

    override fun onDestroy() {
        habits = emptyList()
    }

    override fun getCount(): Int = habits.size

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_habit_item)

        if (position < habits.size) {
            val habit = habits[position]
            val displayTitle = if (habit.dailyTarget > 1) {
                "${habit.title} (${habit.todayCount}/${habit.dailyTarget})"
            } else {
                habit.title
            }
            val streakText = if (habit.streak > 0) {
                "连续${habit.streak}天"
            } else {
                "累计${habit.totalCheckIns}次"
            }

            views.setTextViewText(R.id.item_title, displayTitle)
            views.setTextViewText(R.id.item_streak, streakText)

            if (habit.isDone) {
                views.setInt(R.id.item_title, "setTextColor", 0xFF4A5F68.toInt())
                views.setInt(R.id.item_streak, "setTextColor", 0xFF4C8B6E.toInt())
            } else {
                views.setInt(R.id.item_title, "setTextColor", 0xFF1F2A33.toInt())
                views.setInt(R.id.item_streak, "setTextColor", 0xFF647683.toInt())
            }

            val iconColor = if (habit.isDone) 0xFF5E917A.toInt() else 0xFF31424F.toInt()
            views.setImageViewBitmap(
                R.id.item_icon,
                HabitIconUtils.createIconBitmap(context, habit.iconIndex, iconColor)
            )

            val fillIntent = Intent()
            views.setOnClickFillInIntent(R.id.item_container, fillIntent)
            views.setOnClickFillInIntent(R.id.item_icon, fillIntent)
            views.setOnClickFillInIntent(R.id.item_title, fillIntent)
            views.setOnClickFillInIntent(R.id.item_streak, fillIntent)
        }

        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = true
}
