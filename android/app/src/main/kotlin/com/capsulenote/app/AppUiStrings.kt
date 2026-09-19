package com.capsulenote.app

import android.content.Context
import android.content.res.Configuration
import android.os.Build
import java.util.Locale

/**
 * UI-only locale strings for AlarmActivity / alarm notification actions.
 * Preference is written by Flutter; does not affect scheduling logic.
 */
object AppUiStrings {
    const val PREFS = "capsule_note_ui"
    const val KEY_LOCALE = "app_locale"

    fun savePreference(context: Context, preference: String) {
        context.applicationContext
            .getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_LOCALE, preference)
            .apply()
    }

    fun preference(context: Context): String {
        return context.applicationContext
            .getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_LOCALE, "system") ?: "system"
    }

    fun resolvedTag(context: Context): String {
        val pref = preference(context)
        if (pref == "zh_TW" || pref == "zh_CN" || pref == "en") return pref
        val locales = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            context.resources.configuration.locales
        } else {
            @Suppress("DEPRECATION")
            null
        }
        if (locales != null && !locales.isEmpty) {
            val locale = locales[0]
            if (locale.language == "zh") {
                val country = locale.country.uppercase(Locale.ROOT)
                val script = if (Build.VERSION.SDK_INT >= 21) {
                    locale.script.lowercase(Locale.ROOT)
                } else {
                    ""
                }
                if (script == "hant" || country == "TW" || country == "HK" || country == "MO") {
                    return "zh_TW"
                }
                return "zh_CN"
            }
            if (locale.language == "en") return "en"
        } else {
            @Suppress("DEPRECATION")
            val legacy = context.resources.configuration.locale
            if (legacy.language == "zh") {
                return if (legacy.country.equals("TW", true) ||
                    legacy.country.equals("HK", true)
                ) {
                    "zh_TW"
                } else {
                    "zh_CN"
                }
            }
            if (legacy.language == "en") return "en"
        }
        return "en"
    }

    fun localizedContext(context: Context): Context {
        val tag = resolvedTag(context)
        val locale = when (tag) {
            "zh_TW" -> Locale.TRADITIONAL_CHINESE
            "zh_CN" -> Locale.SIMPLIFIED_CHINESE
            else -> Locale.ENGLISH
        }
        val config = Configuration(context.resources.configuration)
        config.setLocale(locale)
        return context.createConfigurationContext(config)
    }

    fun of(context: Context): Bundle {
        return when (resolvedTag(context)) {
            "zh_TW" -> zhTW
            "zh_CN" -> zhCN
            else -> en
        }
    }

    data class Bundle(
        val complete: String,
        val snooze: String,
        val snooze30: String,
        val snooze60: String,
        val snooze180: String,
        val snoozeTomorrow: String,
        val alarmDefaultBody: String,
        val alarmExtra: String,
        val alarmChip: String,
        val todoFallback: String,
        val channelName: String,
        val channelDesc: String,
        val minutes30: String,
        val hour1: String,
        val hours3: String,
        val previewTitle: String,
        val previewNotes: String,
    )

    private val en = Bundle(
        complete = "Complete",
        snooze = "Snooze",
        snooze30 = "Snooze 30 min",
        snooze60 = "Snooze 1 hour",
        snooze180 = "Snooze 3 hours",
        snoozeTomorrow = "Tomorrow 09:00",
        alarmDefaultBody = "Alarm time reached",
        alarmExtra = "Plus %d more due alarms",
        alarmChip = "Alarm",
        todoFallback = "Todo",
        channelName = "Alarms",
        channelDesc = "Todo alarm mode: full-screen ring and vibration",
        minutes30 = "30 min",
        hour1 = "1 hour",
        hours3 = "3 hours",
        previewTitle = "Remind Kath test alarm",
        previewNotes = "Alarm mode test — choose Complete to stop.",
    )

    private val zhTW = Bundle(
        complete = "完成",
        snooze = "稍後",
        snooze30 = "稍後30分鐘",
        snooze60 = "稍後1小時",
        snooze180 = "稍後3小時",
        snoozeTomorrow = "明天09:00",
        alarmDefaultBody = "鬧鐘時間到了",
        alarmExtra = "另外還有 %d 筆到期鬧鐘",
        alarmChip = "鬧鐘",
        todoFallback = "待辦事項",
        channelName = "鬧鐘",
        channelDesc = "待辦鬧鐘模式：全螢幕響鈴與持續震動",
        minutes30 = "30分鐘",
        hour1 = "1小時",
        hours3 = "3小時",
        previewTitle = "提醒Kath 測試鬧鐘",
        previewNotes = "這是鬧鐘模式測試，選擇完成即可停止。",
    )

    private val zhCN = Bundle(
        complete = "完成",
        snooze = "稍后",
        snooze30 = "稍后30分钟",
        snooze60 = "稍后1小时",
        snooze180 = "稍后3小时",
        snoozeTomorrow = "明天09:00",
        alarmDefaultBody = "闹钟时间到了",
        alarmExtra = "另外还有 %d 笔到期闹钟",
        alarmChip = "闹钟",
        todoFallback = "待办事项",
        channelName = "闹钟",
        channelDesc = "待办闹钟模式：全屏响铃与持续震动",
        minutes30 = "30分钟",
        hour1 = "1小时",
        hours3 = "3小时",
        previewTitle = "提醒Kath 测试闹钟",
        previewNotes = "这是闹钟模式测试，选择完成即可停止。",
    )
}
