package com.capsulenote.app

import android.app.Activity
import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

object AlarmBridge {
    const val CHANNEL = "com.capsulenote.app/alarm"

    fun register(
        activity: Activity,
        flutterEngine: FlutterEngine,
        onPickAlarmFile: (MethodChannel.Result) -> Unit,
        onPickSystemRingtone: (MethodChannel.Result) -> Unit,
    ) {
        val app = activity.applicationContext
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canScheduleExactAlarms" ->
                        result.success(NativeAlarmScheduler.canScheduleExactAlarms(app))
                    "canUseFullScreenIntent" ->
                        result.success(NativeAlarmScheduler.canUseFullScreenIntent(app))
                    "openExactAlarmSettings" -> {
                        NativeAlarmScheduler.openExactAlarmSettings(activity)
                        result.success(null)
                    }
                    "openFullScreenIntentSettings" -> {
                        NativeAlarmScheduler.openFullScreenIntentSettings(activity)
                        result.success(null)
                    }
                    "scheduleAlarm" -> {
                        val args = call.arguments as? Map<*, *>
                        val payload = AlarmPayload(
                            requestCode = (args?.get("requestCode") as? Number)?.toInt() ?: -1,
                            todoId = args?.get("todoId") as? String ?: "",
                            title = args?.get("title") as? String ?: "",
                            notes = args?.get("notes") as? String ?: "",
                            scheduledTimeIso = args?.get("scheduledTimeIso") as? String ?: "",
                            triggerAtMillis = (args?.get("triggerAtMillis") as? Number)?.toLong() ?: 0L,
                        )
                        if (payload.requestCode < 0 || payload.todoId.isBlank()) {
                            result.success(false)
                        } else {
                            result.success(NativeAlarmScheduler.schedule(app, payload))
                        }
                    }
                    "cancelAlarm" -> {
                        val code = (call.argument<Number>("requestCode"))?.toInt()
                        if (code != null) NativeAlarmScheduler.cancel(app, code)
                        result.success(null)
                    }
                    "cancelAlarmsForTodo" -> {
                        val todoId = call.argument<String>("todoId")
                        if (!todoId.isNullOrBlank()) {
                            NativeAlarmScheduler.cancelForTodo(app, todoId)
                        }
                        result.success(null)
                    }
                    "cancelAll" -> {
                        NativeAlarmScheduler.cancelAll(app)
                        result.success(null)
                    }
                    "drainPendingActions" -> {
                        val items = AlarmStore.drainPending(app).map {
                            mapOf("actionId" to it.actionId, "todoId" to it.todoId)
                        }
                        result.success(items)
                    }
                    "previewAlarm" -> {
                        val args = call.arguments as? Map<*, *>
                        val ui = AppUiStrings.of(app)
                        val title = args?.get("title") as? String
                            ?: ui.previewTitle
                        val notes = args?.get("notes") as? String
                            ?: ui.previewNotes
                        val now = System.currentTimeMillis()
                        NativeAlarmScheduler.schedule(
                            app,
                            AlarmPayload(
                                requestCode = 0x7A1A00EE,
                                todoId = AlarmStore.PREVIEW_TODO_ID,
                                title = title,
                                notes = notes,
                                scheduledTimeIso = "",
                                triggerAtMillis = now + 45_000L,
                            ),
                        )
                        result.success(true)
                    }
                    "setAppLocale" -> {
                        val pref = call.argument<String>("preference") ?: "system"
                        AppUiStrings.savePreference(app, pref)
                        result.success(null)
                    }
                    "getAlarmSound" -> {
                        result.success(AlarmSoundStore.info(app).toMap())
                    }
                    "pickAlarmSound", "pickAlarmSoundFile" -> onPickAlarmFile(result)
                    "pickSystemRingtone" -> onPickSystemRingtone(result)
                    "clearAlarmSound" -> {
                        AlarmSoundStore.clearToDefault(app)
                        result.success(AlarmSoundStore.info(app).toMap())
                    }
                    "previewAlarmSound" -> {
                        result.success(AlarmSoundStore.preview(app))
                    }
                    "stopAlarmSoundPreview" -> {
                        AlarmSoundStore.stopPreview()
                        result.success(null)
                    }
                    "applyAlarmSoundBackup" -> {
                        val source = call.argument<String>("source")
                        val fileName = call.argument<String>("fileName")
                        val displayName = call.argument<String>("displayName")
                        val ringtoneUri = call.argument<String>("ringtoneUri")
                        val ok = AlarmSoundStore.applyBackup(
                            app,
                            source,
                            fileName,
                            displayName,
                            ringtoneUri,
                        )
                        result.success(ok)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    fun register(context: Context, flutterEngine: FlutterEngine) {
        if (context is Activity) {
            register(
                context,
                flutterEngine,
                onPickAlarmFile = { result ->
                    result.error("unavailable", "pickAlarmSound requires MainActivity", null)
                },
                onPickSystemRingtone = { result ->
                    result.error("unavailable", "pickSystemRingtone requires MainActivity", null)
                },
            )
        }
    }
}
