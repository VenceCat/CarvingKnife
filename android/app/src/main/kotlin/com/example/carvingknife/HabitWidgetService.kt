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
    val totalCheckIns: Int
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

        if (habitsJson != null && habitsJson.isNotEmpty() && habitsJson != "[]") {
            try {
                val habitsArray = JSONArray(habitsJson)
                val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
                val today = dateFormat.format(Date())

                for (i in 0 until habitsArray.length()) {
                    val habit = habitsArray.getJSONObject(i)
                    val title = habit.optString("title", "")

                    var isDone = false
                    val checkInDates = mutableSetOf<String>()

                    val checkInRecords = habit.optJSONArray("checkInRecords")
                    if (checkInRecords != null) {
                        for (j in 0 until checkInRecords.length()) {
                            val record = checkInRecords.getJSONObject(j)
                            val time = record.optString("time", "")
                            if (time.length >= 10) {
                                val dateStr = time.substring(0, 10)
                                checkInDates.add(dateStr)
                                if (time.startsWith(today)) {
                                    isDone = true
                                }
                            }
                        }
                    }

                    val streak = calculateStreak(checkInDates, dateFormat)
                    val totalCheckIns = checkInDates.size

                    list.add(HabitItem(title, isDone, streak, totalCheckIns))
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
            if (dates.contains(dateStr)) {
                streak++
                calendar.add(Calendar.DAY_OF_YEAR, -1)
            } else {
                break
            }
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

            views.setTextViewText(R.id.item_title, habit.title)

            val streakText = if (habit.streak > 0) {
                "连续${habit.streak}天"
            } else {
                "共${habit.totalCheckIns}次"
            }
            views.setTextViewText(R.id.item_streak, streakText)

            if (habit.isDone) {
                views.setImageViewResource(R.id.item_icon, R.drawable.ic_done)
                views.setInt(R.id.item_title, "setTextColor", 0xFF9E9E9E.toInt())
                views.setInt(R.id.item_streak, "setTextColor", 0xFF4CAF50.toInt())
            } else {
                views.setImageViewResource(R.id.item_icon, R.drawable.ic_undone)
                views.setInt(R.id.item_title, "setTextColor", 0xFF424242.toInt())
                views.setInt(R.id.item_streak, "setTextColor", 0xFF999999.toInt())
            }

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