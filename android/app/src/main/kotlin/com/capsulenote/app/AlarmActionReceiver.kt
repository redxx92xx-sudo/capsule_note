package com.capsulenote.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import java.util.Calendar

class AlarmActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val actionId = intent?.action ?: return
        val todoId = intent.getStringExtra(AlarmService.EXTRA_TODO_ID) ?: return
        val requestCode = intent.getIntExtra(AlarmService.EXTRA_REQUEST_CODE, -1)
        AlarmActions.apply(context, actionId, todoId, requestCode)
    }
}

object AlarmActions {
    fun apply(context: Context, actionId: String, todoId: String, requestCode: Int) {
        when (actionId) {
            AlarmService.ACTION_COMPLETE -> {
                if (requestCode >= 0) {
                    AlarmStore.removeRinging(context, requestCode)
                }
                NativeAlarmScheduler.cancelForTodo(context, todoId)
            }
            AlarmService.ACTION_SNOOZE_30 -> snoozeMinutes(context, requestCode, 30)
            AlarmService.ACTION_SNOOZE_60 -> snoozeMinutes(context, requestCode, 60)
            AlarmService.ACTION_SNOOZE_180 -> snoozeMinutes(context, requestCode, 180)
            AlarmService.ACTION_SNOOZE_TOMORROW -> snoozeTomorrowNine(context, requestCode)
            else -> return
        }
        AlarmStore.enqueuePending(context, actionId, todoId)
        AlarmService.refreshOrStop(context)
        AlarmIsolate.start(context)
        context.sendBroadcast(Intent(AlarmActivity.ACTION_QUEUE_CHANGED).setPackage(context.packageName))
    }

    private fun snoozeMinutes(context: Context, requestCode: Int, minutes: Int) {
        if (requestCode < 0) return
        NativeAlarmScheduler.snooze(
            context,
            requestCode,
            System.currentTimeMillis() + minutes * 60_000L,
        )
    }

    private fun snoozeTomorrowNine(context: Context, requestCode: Int) {
        if (requestCode < 0) return
        val calendar = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, 1)
            set(Calendar.HOUR_OF_DAY, 9)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        NativeAlarmScheduler.snooze(context, requestCode, calendar.timeInMillis)
    }
}
