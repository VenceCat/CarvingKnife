package com.example.carvingknife

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val widgetChannel = "com.example.carvingknife/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, widgetChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "updateWidget" -> {
                        updateWidget()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun updateWidget() {
        val largeIntent = Intent(this, HabitWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
        }
        val largeIds = AppWidgetManager.getInstance(application)
            .getAppWidgetIds(ComponentName(application, HabitWidgetProvider::class.java))
        largeIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, largeIds)
        sendBroadcast(largeIntent)

        val mediumIntent = Intent(this, HabitWidgetMediumProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
        }
        val mediumIds = AppWidgetManager.getInstance(application)
            .getAppWidgetIds(ComponentName(application, HabitWidgetMediumProvider::class.java))
        mediumIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, mediumIds)
        sendBroadcast(mediumIntent)

        val checkInIntent = Intent(this, HabitCheckInWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
        }
        val checkInIds = AppWidgetManager.getInstance(application)
            .getAppWidgetIds(ComponentName(application, HabitCheckInWidgetProvider::class.java))
        checkInIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, checkInIds)
        sendBroadcast(checkInIntent)
    }
}
