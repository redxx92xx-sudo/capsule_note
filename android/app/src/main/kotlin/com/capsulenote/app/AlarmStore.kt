package com.capsulenote.app

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

data class AlarmPayload(
    val requestCode: Int,
    val todoId: String,
    val title: String,
    val notes: String,
    val scheduledTimeIso: String,
    val triggerAtMillis: Long,
) {
    fun toJson(): JSONObject = JSONObject().apply {
        put("requestCode", requestCode)
        put("todoId", todoId)
        put("title", title)
        put("notes", notes)
        put("scheduledTimeIso", scheduledTimeIso)
        put("triggerAtMillis", triggerAtMillis)
    }

    companion object {
        fun fromJson(obj: JSONObject): AlarmPayload = AlarmPayload(
            requestCode = obj.optInt("requestCode"),
            todoId = obj.optString("todoId"),
            title = obj.optString("title"),
            notes = obj.optString("notes"),
            scheduledTimeIso = obj.optString("scheduledTimeIso"),
            triggerAtMillis = obj.optLong("triggerAtMillis"),
        )
    }
}

data class AlarmPendingAction(
    val actionId: String,
    val todoId: String,
)

object AlarmStore {
    private const val PREFS = "capsule_note_alarms"
    private const val KEY_SCHEDULED = "scheduled"
    private const val KEY_RINGING = "ringing"
    private const val KEY_PENDING = "pending_actions"
    const val PREVIEW_TODO_ID = "__preview__"

    private fun prefs(context: Context) =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    @Synchronized
    fun putScheduled(context: Context, payload: AlarmPayload) {
        val map = scheduledMap(context)
        map[payload.requestCode] = payload
        saveScheduled(context, map)
    }

    @Synchronized
    fun getScheduled(context: Context, requestCode: Int): AlarmPayload? =
        scheduledMap(context)[requestCode]

    @Synchronized
    fun allScheduled(context: Context): List<AlarmPayload> =
        scheduledMap(context).values.sortedBy { it.triggerAtMillis }

    @Synchronized
    fun removeScheduled(context: Context, requestCode: Int) {
        val map = scheduledMap(context)
        map.remove(requestCode)
        saveScheduled(context, map)
    }

    @Synchronized
    fun removeScheduledForTodo(context: Context, todoId: String): List<AlarmPayload> {
        val map = scheduledMap(context)
        val removed = map.values.filter { it.todoId == todoId }
        removed.forEach { map.remove(it.requestCode) }
        saveScheduled(context, map)
        val ringing = ringingList(context).filterNot { it.todoId == todoId }
        saveRinging(context, ringing)
        return removed
    }

    @Synchronized
    fun clearAll(context: Context) {
        prefs(context).edit()
            .putString(KEY_SCHEDULED, JSONObject().toString())
            .putString(KEY_RINGING, JSONArray().toString())
            .apply()
    }

    @Synchronized
    fun moveToRinging(context: Context, payload: AlarmPayload) {
        removeScheduled(context, payload.requestCode)
        val ringing = ringingList(context).toMutableList()
        if (ringing.none { it.requestCode == payload.requestCode }) {
            ringing.add(payload)
            saveRinging(context, ringing)
        }
    }

    @Synchronized
    fun ringingList(context: Context): List<AlarmPayload> {
        val raw = prefs(context).getString(KEY_RINGING, "[]") ?: "[]"
        val array = JSONArray(raw)
        val items = mutableListOf<AlarmPayload>()
        for (i in 0 until array.length()) {
            items.add(AlarmPayload.fromJson(array.getJSONObject(i)))
        }
        return items
    }

    @Synchronized
    fun currentRinging(context: Context): AlarmPayload? = ringingList(context).firstOrNull()

    @Synchronized
    fun removeRinging(context: Context, requestCode: Int) {
        saveRinging(context, ringingList(context).filterNot { it.requestCode == requestCode })
    }

    @Synchronized
    fun enqueuePending(context: Context, actionId: String, todoId: String) {
        if (todoId == PREVIEW_TODO_ID || todoId.isBlank()) return
        val array = JSONArray(prefs(context).getString(KEY_PENDING, "[]") ?: "[]")
        array.put(
            JSONObject()
                .put("actionId", actionId)
                .put("todoId", todoId),
        )
        prefs(context).edit().putString(KEY_PENDING, array.toString()).apply()
    }

    @Synchronized
    fun drainPending(context: Context): List<AlarmPendingAction> {
        val raw = prefs(context).getString(KEY_PENDING, "[]") ?: "[]"
        prefs(context).edit().putString(KEY_PENDING, JSONArray().toString()).apply()
        val array = JSONArray(raw)
        val items = mutableListOf<AlarmPendingAction>()
        for (i in 0 until array.length()) {
            val obj = array.getJSONObject(i)
            items.add(
                AlarmPendingAction(
                    actionId = obj.optString("actionId"),
                    todoId = obj.optString("todoId"),
                ),
            )
        }
        return items.filter { it.actionId.isNotBlank() && it.todoId.isNotBlank() }
    }

    private fun scheduledMap(context: Context): MutableMap<Int, AlarmPayload> {
        val raw = prefs(context).getString(KEY_SCHEDULED, "{}") ?: "{}"
        val obj = JSONObject(raw)
        val map = mutableMapOf<Int, AlarmPayload>()
        val keys = obj.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            map[key.toInt()] = AlarmPayload.fromJson(obj.getJSONObject(key))
        }
        return map
    }

    private fun saveScheduled(context: Context, map: Map<Int, AlarmPayload>) {
        val obj = JSONObject()
        map.forEach { (code, payload) -> obj.put(code.toString(), payload.toJson()) }
        prefs(context).edit().putString(KEY_SCHEDULED, obj.toString()).apply()
    }

    private fun saveRinging(context: Context, items: List<AlarmPayload>) {
        val array = JSONArray()
        items.forEach { array.put(it.toJson()) }
        prefs(context).edit().putString(KEY_RINGING, array.toString()).apply()
    }
}
