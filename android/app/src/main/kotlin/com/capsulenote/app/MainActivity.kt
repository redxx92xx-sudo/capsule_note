package com.capsulenote.app

import android.app.Activity
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingSoundResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        AlarmBridge.register(
            activity = this,
            flutterEngine = flutterEngine,
            onPickAlarmFile = { result -> startPickFile(result) },
            onPickSystemRingtone = { result -> startPickSystemRingtone(result) },
        )
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveResyncHandle" -> {
                    val handle = (call.arguments as? Number)?.toLong()
                    if (handle == null) {
                        result.error("bad_args", "Missing callback handle", null)
                        return@setMethodCallHandler
                    }
                    val prefs = getSharedPreferences(
                        ReminderResyncReceiver.PREFS,
                        MODE_PRIVATE
                    )
                    prefs.edit().putLong(ReminderResyncReceiver.HANDLE_KEY, handle).apply()
                    result.success(null)
                }
                "saveAlarmActionHandle" -> {
                    val handle = (call.arguments as? Number)?.toLong()
                    if (handle == null) {
                        result.error("bad_args", "Missing callback handle", null)
                        return@setMethodCallHandler
                    }
                    val prefs = getSharedPreferences(
                        ReminderResyncReceiver.PREFS,
                        MODE_PRIVATE
                    )
                    prefs.edit().putLong(ReminderResyncReceiver.ALARM_HANDLE_KEY, handle).apply()
                    result.success(null)
                }
                "resyncFinished" -> {
                    ReminderResyncReceiver.finishPending()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startPickFile(result: MethodChannel.Result) {
        if (pendingSoundResult != null) {
            result.error("busy", "Another sound pick is in progress", null)
            return
        }
        AlarmSoundStore.stopPreview()
        pendingSoundResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "audio/*"
            putExtra(
                Intent.EXTRA_MIME_TYPES,
                arrayOf(
                    "audio/*",
                    "audio/mpeg",
                    "audio/mp4",
                    "audio/x-m4a",
                    "audio/wav",
                    "audio/x-wav",
                    "audio/ogg",
                    "application/ogg",
                ),
            )
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
            )
        }
        try {
            startActivityForResult(intent, REQ_PICK_ALARM_FILE)
        } catch (error: Throwable) {
            pendingSoundResult = null
            result.error("pick_failed", error.message, null)
        }
    }

    private fun startPickSystemRingtone(result: MethodChannel.Result) {
        if (pendingSoundResult != null) {
            result.error("busy", "Another sound pick is in progress", null)
            return
        }
        AlarmSoundStore.stopPreview()
        pendingSoundResult = result
        val existing = AlarmSoundStore.info(applicationContext).ringtoneUri
            ?.let { Uri.parse(it) }
            ?: AlarmSoundStore.defaultAlarmUri(applicationContext)
        val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
            putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, RingtoneManager.TYPE_ALARM)
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
            putExtra(
                RingtoneManager.EXTRA_RINGTONE_DEFAULT_URI,
                RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM),
            )
            putExtra(RingtoneManager.EXTRA_RINGTONE_EXISTING_URI, existing)
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
            putExtra(RingtoneManager.EXTRA_RINGTONE_TITLE, "Alarm")
        }
        try {
            startActivityForResult(intent, REQ_PICK_SYSTEM_RINGTONE)
        } catch (error: Throwable) {
            pendingSoundResult = null
            result.error("pick_failed", error.message, null)
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQ_PICK_ALARM_FILE && requestCode != REQ_PICK_SYSTEM_RINGTONE) {
            return
        }
        val pending = pendingSoundResult
        pendingSoundResult = null
        if (pending == null) return
        if (resultCode != Activity.RESULT_OK) {
            pending.success(null)
            return
        }
        when (requestCode) {
            REQ_PICK_ALARM_FILE -> handleFileResult(pending, data)
            REQ_PICK_SYSTEM_RINGTONE -> handleSystemRingtoneResult(pending, data)
        }
    }

    private fun handleFileResult(pending: MethodChannel.Result, data: Intent?) {
        val uri = data?.data
        if (uri == null) {
            pending.success(null)
            return
        }
        try {
            contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION,
            )
        } catch (_: SecurityException) {
        }
        try {
            val imported = AlarmSoundStore.importFromUri(applicationContext, uri)
            pending.success(imported)
        } catch (error: Throwable) {
            Log.e(TAG, "pick alarm sound copy failed", error)
            pending.error("copy_failed", error.message ?: "copy failed", null)
        }
    }

    private fun handleSystemRingtoneResult(pending: MethodChannel.Result, data: Intent?) {
        @Suppress("DEPRECATION")
        val picked = data?.getParcelableExtra<Uri>(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
        try {
            val saved = AlarmSoundStore.saveSystemRingtone(
                applicationContext,
                picked,
                picked?.let { AlarmSoundStore.ringtoneTitle(applicationContext, it) },
            )
            pending.success(saved)
        } catch (error: Throwable) {
            Log.e(TAG, "save system ringtone failed", error)
            pending.error("save_failed", error.message ?: "save failed", null)
        }
    }

    override fun onPause() {
        AlarmSoundStore.stopPreview()
        super.onPause()
    }

    companion object {
        private const val CHANNEL = "com.capsulenote.app/bg"
        private const val REQ_PICK_ALARM_FILE = 0xA11A
        private const val REQ_PICK_SYSTEM_RINGTONE = 0xA11B
        private const val TAG = "CapsuleNoteMain"
    }
}
