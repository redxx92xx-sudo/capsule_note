package com.capsulenote.app

import android.app.ActivityOptions
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log

object NativeAlarmScheduler {
    const val ACTION_FIRE = "com.capsulenote.app.ALARM_FIRE"
    const val EXTRA_REQUEST_CODE = "request_code"
    private const val TAG = "RemindKathAlarm"

    fun canScheduleExactAlarms(context: Context): Boolean {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            alarmManager.canScheduleExactAlarms()
        } else {
            true
        }
    }

    fun canUseFullScreenIntent(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE)
                as android.app.NotificationManager
            nm.canUseFullScreenIntent()
        } else {
            true
        }
    }

    fun openExactAlarmSettings(context: Context) {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                data = Uri.parse("package:${context.packageName}")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        } else {
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:${context.packageName}")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        }
        context.startActivity(intent)
    }

    fun openFullScreenIntentSettings(context: Context) {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT).apply {
                data = Uri.parse("package:${context.packageName}")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        } else {
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:${context.packageName}")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        }
        context.startActivity(intent)
    }

    fun schedule(context: Context, payload: AlarmPayload): Boolean {
        if (payload.triggerAtMillis <= System.currentTimeMillis()) {
            return false
        }
        AlarmStore.putScheduled(context, payload)
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(fireBroadcastPendingIntent(context, payload.requestCode))
        val activityPi = firePendingIntent(context, payload.requestCode)
        try {
            if (canScheduleExactAlarms(context)) {
                alarmManager.setAlarmClock(
                    AlarmManager.AlarmClockInfo(payload.triggerAtMillis, activityPi),
                    activityPi,
                )
                // Sound backup if the activity PI is BAL-blocked; do not race the same millisecond.
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    payload.triggerAtMillis + 2_000L,
                    fireBroadcastPendingIntent(context, payload.requestCode),
                )
            } else {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    payload.triggerAtMillis,
                    activityPi,
                )
            }
            return true
        } catch (security: SecurityException) {
            Log.w(TAG, "exact alarm denied, falling back to inexact", security)
            try {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    payload.triggerAtMillis,
                    activityPi,
                )
                return true
            } catch (inner: Throwable) {
                Log.e(TAG, "inexact fallback failed", inner)
                return false
            }
        } catch (error: Throwable) {
            Log.e(TAG, "schedule failed", error)
            return false
        }
    }

    fun cancel(context: Context, requestCode: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(firePendingIntent(context, requestCode))
        alarmManager.cancel(fireBroadcastPendingIntent(context, requestCode))
        AlarmStore.removeScheduled(context, requestCode)
        AlarmStore.removeRinging(context, requestCode)
    }

    fun cancelForTodo(context: Context, todoId: String) {
        val removed = AlarmStore.removeScheduledForTodo(context, todoId)
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        removed.forEach {
            alarmManager.cancel(firePendingIntent(context, it.requestCode))
            alarmManager.cancel(fireBroadcastPendingIntent(context, it.requestCode))
        }
        AlarmService.refreshOrStop(context)
    }

    fun cancelAll(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        AlarmStore.allScheduled(context).forEach {
            alarmManager.cancel(firePendingIntent(context, it.requestCode))
            alarmManager.cancel(fireBroadcastPendingIntent(context, it.requestCode))
        }
        AlarmStore.ringingList(context).forEach {
            alarmManager.cancel(firePendingIntent(context, it.requestCode))
            alarmManager.cancel(fireBroadcastPendingIntent(context, it.requestCode))
        }
        AlarmStore.clearAll(context)
        AlarmService.stopAll(context)
    }

    fun restoreAll(context: Context) {
        val now = System.currentTimeMillis()
        AlarmStore.allScheduled(context).forEach { payload ->
            if (payload.triggerAtMillis <= now) {
                AlarmStore.moveToRinging(context, payload)
            } else {
                schedule(context, payload)
            }
        }
        if (AlarmStore.ringingList(context).isNotEmpty()) {
            AlarmService.start(context)
        }
    }

    fun snooze(context: Context, requestCode: Int, triggerAtMillis: Long) {
        val current = AlarmStore.ringingList(context).firstOrNull { it.requestCode == requestCode }
            ?: AlarmStore.getScheduled(context, requestCode)
            ?: return
        AlarmStore.removeRinging(context, requestCode)
        schedule(
            context,
            current.copy(triggerAtMillis = triggerAtMillis),
        )
        AlarmService.refreshOrStop(context)
    }

    fun firePendingIntent(context: Context, requestCode: Int): PendingIntent {
        val intent = Intent(context, AlarmActivity::class.java).apply {
            action = ACTION_FIRE
            data = Uri.parse("capsulenote://alarm/$requestCode")
            putExtra(EXTRA_REQUEST_CODE, requestCode)
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP,
            )
        }
        val flags = PendingIntent.FLAG_MUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        val options = AlarmLaunch.optionsBundle()
        return if (options != null) {
            PendingIntent.getActivity(context, requestCode, intent, flags, options)
        } else {
            PendingIntent.getActivity(context, requestCode, intent, flags)
        }
    }

    fun fireBroadcastPendingIntent(context: Context, requestCode: Int): PendingIntent {
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = ACTION_FIRE
            data = Uri.parse("capsulenote://alarm/$requestCode")
            putExtra(EXTRA_REQUEST_CODE, requestCode)
            addFlags(Intent.FLAG_RECEIVER_FOREGROUND)
        }
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }
}

object AlarmLaunch {
    fun intent(context: Context): Intent {
        return Intent(context, AlarmActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP,
            )
        }
    }

    fun optionsBundle(): Bundle? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return null
        return ActivityOptions.makeBasic().apply {
            val mode = if (Build.VERSION.SDK_INT >= 35) {
                ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOW_ALWAYS
            } else {
                @Suppress("DEPRECATION")
                ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED
            }
            setPendingIntentBackgroundActivityStartMode(mode)
            if (Build.VERSION.SDK_INT >= 35) {
                setPendingIntentCreatorBackgroundActivityStartMode(mode)
            }
        }.toBundle()
    }

    fun pendingIntent(context: Context, requestCode: Int): PendingIntent {
        val flags = PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        val options = optionsBundle()
        return if (options != null) {
            PendingIntent.getActivity(context, requestCode, intent(context), flags, options)
        } else {
            PendingIntent.getActivity(context, requestCode, intent(context), flags)
        }
    }

    fun launch(context: Context) {
        val ui = intent(context)
        val options = optionsBundle()
        try {
            if (options != null) {
                context.startActivity(ui, options)
            } else {
                context.startActivity(ui)
            }
            Log.i("RemindKathAlarm", "alarm ui startActivity issued")
        } catch (error: Throwable) {
            Log.w("RemindKathAlarm", "startActivity failed", error)
        }
        try {
            pendingIntent(context, AlarmService.FGS_NOTIFICATION_ID + 1)
                .send(context, 0, null, null, null, null, options)
            Log.i("RemindKathAlarm", "alarm ui pending intent send issued")
        } catch (error: Throwable) {
            Log.w("RemindKathAlarm", "pending intent send failed", error)
        }
    }
}
