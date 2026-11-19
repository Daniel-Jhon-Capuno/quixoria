package com.example.quixoria

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val widgetChannel = "com.example.quixoria/home_widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, widgetChannel)
            .setMethodCallHandler { call, result ->
                if (call.method == "updateStreakWidget") {
                    val prefs = getSharedPreferences(
                        QuixoriaStreakWidgetProvider.PREFS_NAME,
                        Context.MODE_PRIVATE
                    )
                    prefs.edit()
                        .putInt("streak_days", call.argument<Int>("streakDays") ?: 1)
                        .putBoolean("is_active_today", call.argument<Boolean>("isActiveToday") ?: false)
                        .putString("status_text", call.argument<String>("statusText") ?: "Read Today!")
                        .putString("active_book", call.argument<String>("activeBook") ?: "Don Quixote")
                        .putInt("minutes_today", call.argument<Int>("minutesToday") ?: 0)
                        .putInt("goal_minutes", call.argument<Int>("goalMinutes") ?: 15)
                        .apply()
                    QuixoriaStreakWidgetProvider.updateAllWidgets(applicationContext)
                    result.success(true)
                } else {
                    result.notImplemented()
                }
            }
    }
}
