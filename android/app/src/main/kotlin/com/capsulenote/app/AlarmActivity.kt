package com.capsulenote.app

import android.app.KeyguardManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.activity.ComponentActivity
import androidx.activity.OnBackPressedCallback
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class AlarmActivity : ComponentActivity() {
    private var snoozeExpanded = false

    private val queueReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            render()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        consumeFireIntent(intent)
        turnScreenOn()
        onBackPressedDispatcher.addCallback(
            this,
            object : OnBackPressedCallback(true) {
                override fun handleOnBackPressed() {
                    moveTaskToBack(true)
                }
            },
        )
        render()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        consumeFireIntent(intent)
        render()
    }

    private fun consumeFireIntent(intent: Intent?) {
        val requestCode = intent?.getIntExtra(NativeAlarmScheduler.EXTRA_REQUEST_CODE, -1) ?: -1
        val payload = when {
            requestCode >= 0 -> AlarmStore.getScheduled(this, requestCode)
                ?: AlarmStore.ringingList(this).firstOrNull { it.requestCode == requestCode }
            else -> AlarmStore.ringingList(this).firstOrNull()
        } ?: return
        Log.i(TAG, "activity fire requestCode=${payload.requestCode} todoId=${payload.todoId}")
        AlarmStore.moveToRinging(this, payload)
        AlarmService.start(this)
    }

    override fun onResume() {
        super.onResume()
        val filter = IntentFilter(ACTION_QUEUE_CHANGED)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(queueReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(queueReceiver, filter)
        }
        render()
    }

    override fun onPause() {
        try {
            unregisterReceiver(queueReceiver)
        } catch (_: Throwable) {
        }
        super.onPause()
    }

    private fun turnScreenOn() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
        @Suppress("DEPRECATION")
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD,
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val keyguard = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            keyguard.requestDismissKeyguard(this, null)
        }
    }

    private fun isDarkMode(): Boolean {
        val night = resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
        return night == Configuration.UI_MODE_NIGHT_YES
    }

    private fun render() {
        val ringing = AlarmStore.ringingList(this)
        if (ringing.isEmpty()) {
            finish()
            return
        }
        val current = ringing.first()
        val dark = isDarkMode()
        val bg = if (dark) 0xFF0D0D0D.toInt() else 0xFFFFFFFF.toInt()
        val textPrimary = if (dark) 0xFFF5F5F5.toInt() else 0xFF111111.toInt()
        val textSecondary = if (dark) 0xFFA6A6A6.toInt() else 0xFF666666.toInt()
        val accent = if (dark) 0xFFFF5A55.toInt() else 0xFFC62828.toInt()
        val onAccent = 0xFFFFFFFF.toInt()
        val divider = if (dark) 0xFF303030.toInt() else 0xFFE5E5E5.toInt()
        val accentSoft = if (dark) 0xFF351515.toInt() else 0xFFFDECEC.toInt()

        val scroll = ScrollView(this).apply {
            setBackgroundColor(bg)
            isFillViewport = true
        }
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(28), dp(56), dp(28), dp(40))
            setBackgroundColor(bg)
        }

        fun addText(
            value: String,
            sizeSp: Float,
            color: Int,
            bold: Boolean = false,
            maxLines: Int = Int.MAX_VALUE,
        ) {
            root.addView(
                TextView(this).apply {
                    text = value
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, sizeSp)
                    setTextColor(color)
                    gravity = Gravity.CENTER_HORIZONTAL
                    if (bold) {
                        typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
                    }
                    this.maxLines = maxLines
                    ellipsize = android.text.TextUtils.TruncateAt.END
                    setPadding(0, dp(4), 0, dp(4))
                },
            )
        }

        val ui = AppUiStrings.of(this)

        root.addView(
            TextView(this).apply {
                text = ui.alarmChip
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                setTextColor(accent)
                typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
                gravity = Gravity.CENTER_HORIZONTAL
                background = rounded(accentSoft, 8f)
                setPadding(dp(14), dp(6), dp(14), dp(6))
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                ).apply {
                    gravity = Gravity.CENTER_HORIZONTAL
                    bottomMargin = dp(16)
                }
            },
        )

        addText(formatTime(current.triggerAtMillis), 56f, textPrimary, bold = true)
        addText(current.title.ifBlank { ui.todoFallback }, 24f, textPrimary, bold = true, maxLines = 2)
        val note = current.notes.trim()
        if (note.isNotEmpty()) {
            addText(note, 15f, textSecondary, maxLines = 1)
        }
        if (ringing.size > 1) {
            addText(ui.alarmExtra.format(ringing.size - 1), 14f, textSecondary)
        }

        root.addView(View(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dp(24),
            )
        })

        addPrimaryButton(root, ui.complete, accent, onAccent) {
            snoozeExpanded = false
            AlarmActions.apply(this, AlarmService.ACTION_COMPLETE, current.todoId, current.requestCode)
            render()
        }

        root.addView(View(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dp(12),
            )
        })

        addSecondaryButton(root, ui.snooze, textPrimary, divider) {
            snoozeExpanded = !snoozeExpanded
            render()
        }

        if (snoozeExpanded) {
            root.addView(View(this).apply {
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    dp(16),
                )
            })
            addSecondaryButton(root, ui.minutes30, textPrimary, divider) {
                AlarmActions.apply(this, AlarmService.ACTION_SNOOZE_30, current.todoId, current.requestCode)
                snoozeExpanded = false
                render()
            }
            addSecondaryButton(root, ui.hour1, textPrimary, divider) {
                AlarmActions.apply(this, AlarmService.ACTION_SNOOZE_60, current.todoId, current.requestCode)
                snoozeExpanded = false
                render()
            }
            addSecondaryButton(root, ui.hours3, textPrimary, divider) {
                AlarmActions.apply(this, AlarmService.ACTION_SNOOZE_180, current.todoId, current.requestCode)
                snoozeExpanded = false
                render()
            }
            addSecondaryButton(root, ui.snoozeTomorrow, textPrimary, divider) {
                AlarmActions.apply(this, AlarmService.ACTION_SNOOZE_TOMORROW, current.todoId, current.requestCode)
                snoozeExpanded = false
                render()
            }
        }

        scroll.addView(root)
        setContentView(scroll)
    }

    private fun addPrimaryButton(
        root: LinearLayout,
        label: String,
        bg: Int,
        fg: Int,
        onClick: () -> Unit,
    ) {
        root.addView(
            Button(this).apply {
                text = label
                textSize = 18f
                typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
                setTextColor(fg)
                background = rounded(bg, 14f)
                elevation = 0f
                stateListAnimator = null
                isAllCaps = false
                setOnClickListener { onClick() }
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    dp(56),
                ).apply { topMargin = dp(4) }
            },
        )
    }

    private fun addSecondaryButton(
        root: LinearLayout,
        label: String,
        fg: Int,
        border: Int,
        onClick: () -> Unit,
    ) {
        root.addView(
            Button(this).apply {
                text = label
                textSize = 16f
                typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
                setTextColor(fg)
                background = outlined(border, 14f)
                elevation = 0f
                stateListAnimator = null
                isAllCaps = false
                setOnClickListener { onClick() }
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    dp(52),
                ).apply { topMargin = dp(8) }
            },
        )
    }

    private fun rounded(color: Int, radiusDp: Float): GradientDrawable {
        return GradientDrawable().apply {
            setColor(color)
            cornerRadius = TypedValue.applyDimension(
                TypedValue.COMPLEX_UNIT_DIP,
                radiusDp,
                resources.displayMetrics,
            )
        }
    }

    private fun outlined(border: Int, radiusDp: Float): GradientDrawable {
        return GradientDrawable().apply {
            setColor(Color.TRANSPARENT)
            setStroke(
                dp(1),
                border,
            )
            cornerRadius = TypedValue.applyDimension(
                TypedValue.COMPLEX_UNIT_DIP,
                radiusDp,
                resources.displayMetrics,
            )
        }
    }

    private fun dp(value: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            value.toFloat(),
            resources.displayMetrics,
        ).toInt()
    }

    private fun formatTime(triggerAt: Long): String {
        val formatter = SimpleDateFormat("HH:mm", Locale.TAIWAN)
        return formatter.format(Date(if (triggerAt > 0) triggerAt else System.currentTimeMillis()))
    }

    companion object {
        const val ACTION_QUEUE_CHANGED = "com.capsulenote.app.ALARM_QUEUE_CHANGED"
        private const val TAG = "RemindKathAlarm"
    }
}
