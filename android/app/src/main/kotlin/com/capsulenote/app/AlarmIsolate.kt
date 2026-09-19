package com.capsulenote.app

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.view.FlutterCallbackInformation

object AlarmIsolate {
    private const val TAG = "RemindKathAlarm"

    fun start(context: Context) {
        val prefs = context.getSharedPreferences(ReminderResyncReceiver.PREFS, Context.MODE_PRIVATE)
        val handle = prefs.getLong(ReminderResyncReceiver.ALARM_HANDLE_KEY, -1L)
        if (handle == -1L) {
            Log.w(TAG, "alarm action dart handle missing")
            return
        }
        Thread {
            try {
                val loader = FlutterInjector.instance().flutterLoader()
                loader.startInitialization(context.applicationContext)
                loader.ensureInitializationComplete(context.applicationContext, null)
                val callbackInfo = FlutterCallbackInformation.lookupCallbackInformation(handle)
                    ?: return@Thread
                val engine = FlutterEngine(context.applicationContext)
                try {
                    val registrant = Class.forName("io.flutter.plugins.GeneratedPluginRegistrant")
                    registrant.getMethod("registerWith", FlutterEngine::class.java)
                        .invoke(null, engine)
                } catch (_: Throwable) {
                }
                AlarmBridge.register(context.applicationContext, engine)
                engine.dartExecutor.executeDartCallback(
                    DartExecutor.DartCallback(
                        context.assets,
                        loader.findAppBundlePath(),
                        callbackInfo,
                    ),
                )
                Handler(Looper.getMainLooper()).postDelayed({
                    try {
                        engine.destroy()
                    } catch (_: Throwable) {
                    }
                }, 15_000)
            } catch (error: Throwable) {
                Log.e(TAG, "alarm isolate failed", error)
            }
        }.start()
    }
}
