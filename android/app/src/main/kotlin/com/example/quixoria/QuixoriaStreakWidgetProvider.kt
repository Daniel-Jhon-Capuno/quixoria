package com.example.quixoria

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews

class QuixoriaStreakWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        const val PREFS_NAME = "quixoria_widget_prefs"

        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, QuixoriaStreakWidgetProvider::class.java)
            val ids = manager.getAppWidgetIds(component)
            for (id in ids) {
                updateWidget(context, manager, id)
            }
        }

        private fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val streakDays = prefs.getInt("streak_days", 1)
            val isActiveToday = prefs.getBoolean("is_active_today", false)
            val statusText = prefs.getString(
                "status_text",
                if (isActiveToday) "Flame Secured ✓" else "Read Today!"
            ) ?: "Read Today!"
            val bookTitle = prefs.getString("active_book", "Don Quixote de la Mancha")
                ?: "Don Quixote de la Mancha"
            val minutesToday = prefs.getInt("minutes_today", 0)
            val goalMinutes = prefs.getInt("goal_minutes", 15)

            val views = RemoteViews(context.packageName, R.layout.quixoria_streak_widget)
            val dayLabel = if (streakDays == 1) "Day" else "Days"
            val flamePrefix = if (streakDays > 0) "🔥" else "🕯️"

            views.setTextViewText(R.id.widget_streak_value, "$flamePrefix $streakDays $dayLabel")
            views.setTextViewText(R.id.widget_status_pill, statusText)
            views.setTextColor(
                R.id.widget_status_pill,
                if (isActiveToday) Color.parseColor("#34D399") else Color.parseColor("#FBBF24")
            )
            views.setTextViewText(R.id.widget_book_title, bookTitle)
            views.setTextViewText(
                R.id.widget_goal_text,
                "Daily goal: $minutesToday/$goalMinutes min • Tap to read"
            )

            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
