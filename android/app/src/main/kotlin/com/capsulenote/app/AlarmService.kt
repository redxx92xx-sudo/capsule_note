package com.capsulenote.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.Uri
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import androidx.core.app.NotificationCompat

class AlarmService : Service() {
    private var mediaPlayer: MediaPlayer? = null
    private var audioFocusRequest: AudioFocusRequest? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopInternal()
            stopSelf()
            return START_NOT_STICKY
        }
        val ringing = AlarmStore.ringingList(this)
        if (ringing.isEmpty()) {
            stopInternal()
            stopSelf()
            return START_NOT_STICKY
        }
        val notification = buildNotification(ringing)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                FGS_NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK,
            )
        } else {
            startForeground(FGS_NOTIFICATION_ID, notification)
        }
        startSoundAndVibrate()
        return START_STICKY
    }

    override fun onDestroy() {
        stopInternal()
        super.onDestroy()
    }

    private fun startSoundAndVibrate() {
        if (mediaPlayer?.isPlaying == true) return
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val attrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                .setAudioAttributes(attrs)
                .build()
            audioFocusRequest = request
            audioManager.requestAudioFocus(request)
        } else {
            @Suppress("DEPRECATION")
            audioManager.requestAudioFocus(
                null,
                AudioManager.STREAM_ALARM,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT,
            )
        }
        try {
            mediaPlayer = AlarmSoundStore.createLoopingPlayer(this, attrs)?.also { it.start() }
        } catch (error: Throwable) {
            Log.e(TAG, "alarm media player failed", error)
        }
        vibrate(true)
    }

    private fun stopInternal() {
        AlarmSoundStore.stopPreview()
        try {
            mediaPlayer?.stop()
        } catch (_: Throwable) {
        }
        mediaPlayer?.release()
        mediaPlayer = null
        vibrate(false)
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
        } else {
            @Suppress("DEPRECATION")
            audioManager.abandonAudioFocus(null)
        }
        audioFocusRequest = null
    }

    private fun vibrate(start: Boolean) {
        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            manager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
        if (!start) {
            vibrator.cancel()
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(
                VibrationEffect.createWaveform(longArrayOf(0, 600, 400), 0),
                AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM).build(),
            )
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(longArrayOf(0, 600, 400), 0)
        }
    }

    private fun buildNotification(ringing: List<AlarmPayload>): Notification {
        ensureChannel()
        val ui = AppUiStrings.of(this)
        val current = ringing.first()
        val extraCount = ringing.size - 1
        val text = if (extraCount > 0) {
            val base = current.notes.ifBlank { current.title }
            "$base　${ui.alarmExtra.format(extraCount)}"
        } else {
            current.notes.ifBlank { ui.alarmDefaultBody }
        }
        val contentIntent = AlarmLaunch.pendingIntent(this, FGS_NOTIFICATION_ID)
        val fullScreen = AlarmLaunch.pendingIntent(this, FGS_NOTIFICATION_ID + 1)
        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_notify)
            .setContentTitle(current.title)
            .setContentText(text)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setSound(null)
            .setVibrate(null)
            .setDefaults(0)
            .setGroupAlertBehavior(NotificationCompat.GROUP_ALERT_ALL)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .setContentIntent(contentIntent)
            .setColor(0xFFC62828.toInt())
            .addAction(0, ui.complete, actionPi(this, ACTION_COMPLETE, current))
            .addAction(0, ui.snooze30, actionPi(this, ACTION_SNOOZE_30, current))
            .addAction(0, ui.snooze60, actionPi(this, ACTION_SNOOZE_60, current))
            .addAction(0, ui.snooze180, actionPi(this, ACTION_SNOOZE_180, current))
            .addAction(0, ui.snoozeTomorrow, actionPi(this, ACTION_SNOOZE_TOMORROW, current))
        builder.setFullScreenIntent(fullScreen, true)
        return builder.build()
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (nm.getNotificationChannel(CHANNEL_ID) != null) return
        val ui = AppUiStrings.of(this)
        val attrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val channel = NotificationChannel(
            CHANNEL_ID,
            ui.channelName,
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = ui.channelDesc
            setSound(null, attrs)
            enableVibration(true)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            setBypassDnd(false)
        }
        nm.createNotificationChannel(channel)
    }

    companion object {
        const val CHANNEL_ID = "capsule_note_alarms"
        const val FGS_NOTIFICATION_ID = 0x7A1A0001
        const val ACTION_STOP = "com.capsulenote.app.ALARM_STOP"
        const val ACTION_COMPLETE = "ACTION_COMPLETE"
        const val ACTION_SNOOZE_30 = "ACTION_SNOOZE_30"
        const val ACTION_SNOOZE_60 = "ACTION_SNOOZE_60"
        const val ACTION_SNOOZE_180 = "ACTION_SNOOZE_180"
        const val ACTION_SNOOZE_TOMORROW = "ACTION_SNOOZE_TOMORROW"
        const val EXTRA_TODO_ID = "todo_id"
        const val EXTRA_REQUEST_CODE = "request_code"
        private const val TAG = "RemindKathAlarm"

        fun start(context: Context) {
            val intent = Intent(context, AlarmService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun refreshOrStop(context: Context) {
            if (AlarmStore.ringingList(context).isEmpty()) {
                stopAll(context)
            } else {
                start(context)
            }
        }

        fun stopAll(context: Context) {
            context.stopService(Intent(context, AlarmService::class.java).apply {
                action = ACTION_STOP
            })
        }

        fun actionPi(context: Context, actionId: String, payload: AlarmPayload): PendingIntent {
            val intent = Intent(context, AlarmActionReceiver::class.java).apply {
                this.action = actionId
                data = Uri.parse("capsulenote://alarm-action/${payload.requestCode}/$actionId")
                putExtra(EXTRA_TODO_ID, payload.todoId)
                putExtra(EXTRA_REQUEST_CODE, payload.requestCode)
            }
            return PendingIntent.getBroadcast(
                context,
                payload.requestCode xor actionId.hashCode(),
                intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
        }
    }
}
