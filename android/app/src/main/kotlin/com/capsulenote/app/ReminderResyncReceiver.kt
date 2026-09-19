package com.capsulenote.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.view.FlutterCallbackInformation

class ReminderResyncReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        NativeAlarmScheduler.restoreAll(context)
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val handle = prefs.getLong(HANDLE_KEY, -1L)
        if (handle == -1L) return

        val pending = goAsync()
        pendingResult = pending
        Thread {
            try {
                val loader = FlutterInjector.instance().flutterLoader()
                loader.startInitialization(context)
                loader.ensureInitializationComplete(context, null)
                val callbackInfo =
                    FlutterCallbackInformation.lookupCallbackInformation(handle)
                        ?: return@Thread
                val engine = FlutterEngine(context.applicationContext)
                try {
                    val registrant = Class.forName(
                        "io.flutter.plugins.GeneratedPluginRegistrant"
                    )
                    registrant.getMethod(
                        "registerWith",
                        FlutterEngine::class.java
                    ).invoke(null, engine)
                } catch (_: Throwable) {
                }
                AlarmBridge.register(context.applicationContext, engine)
                val bundlePath = loader.findAppBundlePath()
                engine.dartExecutor.executeDartCallback(
                    DartExecutor.DartCallback(
                        context.assets,
                        bundlePath,
                        callbackInfo
                    )
                )
    Handler(Looper.getMainLooper()).postDelayed({
                    try {
                        engine.destroy()
                    } catch (_: Throwable) {
                    }
                    finishPending()
                }, 20_000)
            } catch (_: Throwable) {
                finishPending()
            }
        }.start()
    }

    companion object {
        const val PREFS = "capsule_note_bg"
        const val HANDLE_KEY = "resync_callback_handle"
        const val ALARM_HANDLE_KEY = "alarm_action_callback_handle"

        @Volatile
        private var pendingResult: PendingResult? = null

        fun finishPending() {
            try {
                pendingResult?.finish()
            } catch (_: Throwable) {
            } finally {
                pendingResult = null
            }
        }
    }
}
