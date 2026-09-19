package com.capsulenote.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val requestCode = intent?.getIntExtra(NativeAlarmScheduler.EXTRA_REQUEST_CODE, -1) ?: -1
        if (requestCode < 0) return
        val payload = AlarmStore.getScheduled(context, requestCode) ?: return
        Log.i(TAG, "alarm fire requestCode=$requestCode todoId=${payload.todoId}")
        AlarmStore.moveToRinging(context, payload)
        AlarmService.start(context)
    }

    companion object {
        private const val TAG = "RemindKathAlarm"
    }
}
