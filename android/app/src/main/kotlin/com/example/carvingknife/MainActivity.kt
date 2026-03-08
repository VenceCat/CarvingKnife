package com.example.carvingknife

import android.Manifest
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import androidx.core.content.ContextCompat
import com.oplus.flashbacksdk.FlashViewsManager
import com.oplus.pantanal.seedling.util.SeedlingTool
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        @Volatile
        private var liveTimerChannelRef: MethodChannel? = null

        fun sendLiveTimerAction(action: String, totalSeconds: Int, remainingSeconds: Int) {
            val channel = liveTimerChannelRef ?: return
            try {
                val args = mapOf(
                    "action" to action,
                    "totalSeconds" to totalSeconds,
                    "remainingSeconds" to remainingSeconds,
                )
                channel.invokeMethod("timerAction", args)
            } catch (_: Throwable) {
            }
        }
    }
    private val widgetChannel = "com.example.carvingknife/widget"
    private val liveTimerChannel = "com.example.carvingknife/live_timer"
    private var liveTimerTitle: String = "Habit Timer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        SeedlingTool.setInitSdkOnCreate(true)

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

        val liveTimer = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, liveTimerChannel)
        liveTimer.setMethodCallHandler { call, result ->
                when (call.method) {
                    "startLiveTimer" -> {
                        val title = call.argument<String>("title") ?: "Habit Timer"
                        val totalSeconds = call.argument<Int>("totalSeconds") ?: 0
                        val remainingSeconds =
                            call.argument<Int>("remainingSeconds") ?: totalSeconds
                        startOrUpdateLiveTimerExperience(title, totalSeconds, remainingSeconds)
                        result.success(null)
                    }
                    "updateLiveTimer" -> {
                        val totalSeconds = call.argument<Int>("totalSeconds") ?: 0
                        val remainingSeconds =
                            call.argument<Int>("remainingSeconds") ?: totalSeconds
                        startOrUpdateLiveTimerExperience(null, totalSeconds, remainingSeconds)
                        result.success(null)
                    }
                    "stopLiveTimer" -> {
                        stopLiveTimerExperience()
                        result.success(null)
                    }
                    "canPostPromotedNotifications" -> {
                        result.success(canPostPromotedNotifications())
                    }
                    "isFluidCloudSupported" -> {
                        result.success(isFluidCloudSupported())
                    }
                    "isFlashViewsEnabled" -> {
                        result.success(isFlashViewsEnabled())
                    }
                    "openNotificationSettings" -> {
                        openNotificationSettings()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        liveTimerChannelRef = liveTimer
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

    private fun startOrUpdateLiveTimerExperience(
        title: String?,
        totalSeconds: Int,
        remainingSeconds: Int
    ) {
        val safeTitle = if (title.isNullOrBlank()) liveTimerTitle else title
        liveTimerTitle = safeTitle
        if (!canPostNotifications()) {
            return
        }
        if (title.isNullOrBlank()) {
            LiveTimerForegroundService.update(this, safeTitle, totalSeconds, remainingSeconds)
        } else {
            LiveTimerForegroundService.start(this, safeTitle, totalSeconds, remainingSeconds)
        }
    }

    private fun stopLiveTimerExperience() {
        LiveTimerForegroundService.stop(this)
    }

    private fun canPostNotifications(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.POST_NOTIFICATIONS
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun isFluidCloudSupported(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        return try {
            SeedlingTool.isSupportFluidCloud(this)
        } catch (_: Throwable) {
            false
        }
    }

    private fun isFlashViewsEnabled(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        return try {
            FlashViewsManager.isSupportFlashViews(this) &&
                FlashViewsManager.isAppToggleOn(this)
        } catch (_: Throwable) {
            false
        }
    }

    private fun canPostPromotedNotifications(): Boolean {
        if (!canPostNotifications()) return false
        if (Build.VERSION.SDK_INT < 36) return false
        return ContextCompat.checkSelfPermission(
            this,
            "android.permission.POST_PROMOTED_NOTIFICATIONS"
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun openNotificationSettings() {
        val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
            putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }
}
