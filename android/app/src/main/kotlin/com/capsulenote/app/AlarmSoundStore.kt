package com.capsulenote.app

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.provider.OpenableColumns
import android.util.Log
import java.io.File
import java.io.FileOutputStream

/**
 * Alarm sound preference: system ringtone URI, copied audio file, or default.
 * Used by [AlarmService]; SharedPreferences survive APK updates.
 */
object AlarmSoundStore {
    private const val PREFS = "capsule_note_alarm_sound"
    private const val KEY_SOURCE = "ringtone_source"
    private const val KEY_FILE_NAME = "file_name"
    private const val KEY_DISPLAY_NAME = "display_name"
    private const val KEY_RINGTONE_URI = "ringtone_uri"
    private const val DIR_NAME = "alarm_sounds"
    private const val TAG = "RemindKathAlarmSound"

    const val SOURCE_DEFAULT = "default"
    const val SOURCE_SYSTEM = "system"
    const val SOURCE_FILE = "file"

    data class Info(
        val source: String,
        val fileName: String?,
        val displayName: String?,
        val ringtoneUri: String?,
        val exists: Boolean,
        val absolutePath: String?,
    ) {
        fun toMap(): Map<String, Any?> = mapOf(
            "source" to source,
            "fileName" to fileName,
            "displayName" to displayName,
            "ringtoneUri" to ringtoneUri,
            "exists" to exists,
        )
    }

    fun info(context: Context): Info {
        migrateLegacyIfNeeded(context)
        val prefs = prefs(context)
        val source = prefs.getString(KEY_SOURCE, SOURCE_DEFAULT) ?: SOURCE_DEFAULT
        val displayName = prefs.getString(KEY_DISPLAY_NAME, null)
        return when (source) {
            SOURCE_SYSTEM -> {
                val uri = prefs.getString(KEY_RINGTONE_URI, null)
                val valid = !uri.isNullOrBlank() && isUriReachable(context, Uri.parse(uri))
                Info(
                    source = SOURCE_SYSTEM,
                    fileName = null,
                    displayName = displayName,
                    ringtoneUri = uri,
                    exists = valid,
                    absolutePath = null,
                )
            }
            SOURCE_FILE -> {
                val fileName = prefs.getString(KEY_FILE_NAME, null)
                if (fileName.isNullOrBlank()) {
                    Info(SOURCE_DEFAULT, null, null, null, false, null)
                } else {
                    val file = File(soundsDir(context), fileName)
                    val ok = file.isFile && file.length() > 0L
                    Info(
                        source = SOURCE_FILE,
                        fileName = fileName,
                        displayName = displayName ?: fileName,
                        ringtoneUri = null,
                        exists = ok,
                        absolutePath = if (ok) file.absolutePath else null,
                    )
                }
            }
            else -> Info(SOURCE_DEFAULT, null, displayName, null, true, null)
        }
    }

    fun clear(context: Context) {
        stopPreview()
        val dir = soundsDir(context)
        if (dir.exists()) {
            dir.listFiles()?.forEach { runCatching { it.delete() } }
        }
        prefs(context).edit().clear().apply()
    }

    fun clearToDefault(context: Context) {
        stopPreview()
        clearPrivateFiles(context)
        prefs(context).edit().clear().apply()
    }

    /**
     * Copy [uri] into private storage as file source. On failure, previous setting is kept.
     */
    fun importFromUri(context: Context, uri: Uri): Map<String, Any?> {
        val resolver = context.contentResolver
        val displayName = queryDisplayName(context, uri) ?: "alarm_sound"
        val sanitized = sanitizeFileName(displayName)
        val dir = soundsDir(context)
        if (!dir.exists() && !dir.mkdirs()) {
            throw IllegalStateException("Cannot create alarm_sounds directory")
        }
        val dest = File(dir, sanitized)
        val temp = File(dir, ".$sanitized.tmp")
        val previous = snapshot(context)
        try {
            resolver.openInputStream(uri)?.use { input ->
                FileOutputStream(temp).use { output ->
                    input.copyTo(output)
                }
            } ?: throw IllegalStateException("Cannot open selected audio")
            if (temp.length() <= 0L) {
                throw IllegalStateException("Selected audio is empty")
            }
            dir.listFiles()?.forEach { existing ->
                if (existing.name != temp.name && existing.name != dest.name) {
                    runCatching { existing.delete() }
                }
            }
            if (dest.exists()) dest.delete()
            if (!temp.renameTo(dest)) {
                temp.copyTo(dest, overwrite = true)
                temp.delete()
            }
            prefs(context).edit()
                .putString(KEY_SOURCE, SOURCE_FILE)
                .putString(KEY_FILE_NAME, dest.name)
                .putString(KEY_DISPLAY_NAME, displayName)
                .remove(KEY_RINGTONE_URI)
                .apply()
            return info(context).toMap()
        } catch (error: Throwable) {
            runCatching { temp.delete() }
            restoreSnapshot(context, previous)
            Log.e(TAG, "importFromUri failed", error)
            throw error
        }
    }

    /** Persist a system alarm ringtone URI (TYPE_ALARM picker result). */
    fun saveSystemRingtone(context: Context, uri: Uri?, displayName: String?): Map<String, Any?> {
        stopPreview()
        if (uri == null) {
            clearToDefault(context)
            return info(context).toMap()
        }
        val title = displayName?.takeIf { it.isNotBlank() }
            ?: ringtoneTitle(context, uri)
            ?: uri.lastPathSegment
            ?: "Alarm"
        clearPrivateFiles(context)
        prefs(context).edit()
            .putString(KEY_SOURCE, SOURCE_SYSTEM)
            .putString(KEY_RINGTONE_URI, uri.toString())
            .putString(KEY_DISPLAY_NAME, title)
            .remove(KEY_FILE_NAME)
            .apply()
        return info(context).toMap()
    }

    /**
     * Apply backup metadata. Returns false when the restored preference cannot be used
     * (missing file / invalid URI) and default was applied.
     */
    fun applyBackup(
        context: Context,
        source: String?,
        fileName: String?,
        displayName: String?,
        ringtoneUri: String?,
    ): Boolean {
        stopPreview()
        val src = when (source) {
            SOURCE_SYSTEM, SOURCE_FILE, SOURCE_DEFAULT -> source
            else -> when {
                !ringtoneUri.isNullOrBlank() -> SOURCE_SYSTEM
                !fileName.isNullOrBlank() -> SOURCE_FILE
                else -> SOURCE_DEFAULT
            }
        }
        return when (src) {
            SOURCE_SYSTEM -> {
                if (ringtoneUri.isNullOrBlank()) {
                    clearToDefault(context)
                    return true
                }
                val uri = Uri.parse(ringtoneUri)
                if (!isUriReachable(context, uri)) {
                    clearToDefault(context)
                    return false
                }
                clearPrivateFiles(context)
                prefs(context).edit()
                    .putString(KEY_SOURCE, SOURCE_SYSTEM)
                    .putString(KEY_RINGTONE_URI, ringtoneUri)
                    .putString(KEY_DISPLAY_NAME, displayName ?: ringtoneTitle(context, uri) ?: ringtoneUri)
                    .remove(KEY_FILE_NAME)
                    .apply()
                true
            }
            SOURCE_FILE -> {
                if (fileName.isNullOrBlank()) {
                    clearToDefault(context)
                    return true
                }
                val file = File(soundsDir(context), fileName)
                if (!file.isFile || file.length() <= 0L) {
                    clearToDefault(context)
                    return false
                }
                prefs(context).edit()
                    .putString(KEY_SOURCE, SOURCE_FILE)
                    .putString(KEY_FILE_NAME, fileName)
                    .putString(KEY_DISPLAY_NAME, displayName ?: fileName)
                    .remove(KEY_RINGTONE_URI)
                    .apply()
                true
            }
            else -> {
                clearToDefault(context)
                true
            }
        }
    }

    /** Legacy applyBackupName for older channel args. */
    fun applyBackupName(context: Context, fileName: String?, displayName: String?): Boolean {
        return applyBackup(context, SOURCE_FILE, fileName, displayName, null)
    }

    fun defaultAlarmUri(context: Context): Uri {
        return RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
    }

    fun createLoopingPlayer(context: Context, attrs: AudioAttributes): MediaPlayer? {
        migrateLegacyIfNeeded(context)
        val current = info(context)
        when (current.source) {
            SOURCE_FILE -> {
                val path = current.absolutePath
                if (path != null) {
                    tryPlayFile(path, attrs)?.let { return it }
                    Log.w(TAG, "custom file failed, falling back to default")
                }
            }
            SOURCE_SYSTEM -> {
                val uriStr = current.ringtoneUri
                if (!uriStr.isNullOrBlank()) {
                    tryPlayUri(context, Uri.parse(uriStr), attrs)?.let { return it }
                    Log.w(TAG, "system uri failed, falling back to default")
                }
            }
        }
        return tryPlayUri(context, defaultAlarmUri(context), attrs)
    }

    private var previewPlayer: MediaPlayer? = null

    fun preview(context: Context): Boolean {
        stopPreview()
        val attrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val player = createLoopingPlayer(context, attrs) ?: return false
        previewPlayer = player
        return try {
            player.start()
            true
        } catch (error: Throwable) {
            Log.e(TAG, "preview failed", error)
            stopPreview()
            false
        }
    }

    fun stopPreview() {
        try {
            previewPlayer?.stop()
        } catch (_: Throwable) {
        }
        previewPlayer?.release()
        previewPlayer = null
    }

    fun ringtoneTitle(context: Context, uri: Uri): String? {
        return try {
            RingtoneManager.getRingtone(context, uri)?.getTitle(context)
        } catch (_: Throwable) {
            null
        }
    }

    fun sanitizeFileName(raw: String): String {
        val trimmed = raw.trim().ifBlank { "alarm_sound" }
        val dot = trimmed.lastIndexOf('.')
        val baseRaw = if (dot > 0) trimmed.substring(0, dot) else trimmed
        val extRaw = if (dot > 0 && dot < trimmed.length - 1) {
            trimmed.substring(dot + 1)
        } else {
            "mp3"
        }
        val base = baseRaw
            .replace(Regex("[^A-Za-z0-9._-]"), "_")
            .trim('_')
            .ifBlank { "alarm_sound" }
            .take(48)
        val ext = extRaw.lowercase().replace(Regex("[^a-z0-9]"), "").ifBlank { "mp3" }
        return "${base}_${System.currentTimeMillis()}.$ext"
    }

    private fun tryPlayFile(path: String, attrs: AudioAttributes): MediaPlayer? {
        return try {
            MediaPlayer().apply {
                setAudioAttributes(attrs)
                setDataSource(path)
                isLooping = true
                setVolume(1f, 1f)
                prepare()
            }
        } catch (error: Throwable) {
            Log.w(TAG, "tryPlayFile failed", error)
            null
        }
    }

    private fun tryPlayUri(context: Context, uri: Uri, attrs: AudioAttributes): MediaPlayer? {
        return try {
            MediaPlayer().apply {
                setAudioAttributes(attrs)
                setDataSource(context, uri)
                isLooping = true
                setVolume(1f, 1f)
                prepare()
            }
        } catch (error: Throwable) {
            Log.w(TAG, "tryPlayUri failed", error)
            null
        }
    }

    private fun isUriReachable(context: Context, uri: Uri): Boolean {
        return try {
            context.contentResolver.openInputStream(uri)?.use { true } ?: false
        } catch (_: Throwable) {
            try {
                RingtoneManager.getRingtone(context, uri) != null
            } catch (_: Throwable) {
                false
            }
        }
    }

    private fun migrateLegacyIfNeeded(context: Context) {
        val prefs = prefs(context)
        if (prefs.contains(KEY_SOURCE)) return
        val fileName = prefs.getString(KEY_FILE_NAME, null)
        if (!fileName.isNullOrBlank()) {
            prefs.edit().putString(KEY_SOURCE, SOURCE_FILE).apply()
        }
    }

    private fun clearPrivateFiles(context: Context) {
        val dir = soundsDir(context)
        if (dir.exists()) {
            dir.listFiles()?.forEach { runCatching { it.delete() } }
        }
    }

    private data class Snapshot(
        val source: String?,
        val fileName: String?,
        val displayName: String?,
        val ringtoneUri: String?,
    )

    private fun snapshot(context: Context): Snapshot {
        val p = prefs(context)
        return Snapshot(
            source = p.getString(KEY_SOURCE, null),
            fileName = p.getString(KEY_FILE_NAME, null),
            displayName = p.getString(KEY_DISPLAY_NAME, null),
            ringtoneUri = p.getString(KEY_RINGTONE_URI, null),
        )
    }

    private fun restoreSnapshot(context: Context, snap: Snapshot) {
        val editor = prefs(context).edit().clear()
        if (snap.source != null) editor.putString(KEY_SOURCE, snap.source)
        if (snap.fileName != null) editor.putString(KEY_FILE_NAME, snap.fileName)
        if (snap.displayName != null) editor.putString(KEY_DISPLAY_NAME, snap.displayName)
        if (snap.ringtoneUri != null) editor.putString(KEY_RINGTONE_URI, snap.ringtoneUri)
        editor.apply()
    }

    private fun soundsDir(context: Context): File =
        File(context.filesDir, DIR_NAME)

    private fun prefs(context: Context) =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun queryDisplayName(context: Context, uri: Uri): String? {
        val resolver = context.contentResolver
        resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (index >= 0) {
                        val name = cursor.getString(index)
                        if (!name.isNullOrBlank()) return name
                    }
                }
            }
        return uri.lastPathSegment
    }
}
