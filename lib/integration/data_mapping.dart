/// Data model mapping: CapsuleNote ↔ remind_kath (for integration).
///
/// CapsuleNote capsules (SharedPreferences `capsule_notes_data`):
/// - CapsuleModel { id, title, rawTranscript, summary, actionItems,
///   createdAt, isProcessed, tags, audioPath }
/// - Audio files: `{documents}/capsule_audio/capsule_{id}.m4a`
/// - NEVER deleted by todo/alarm migration
///
/// remind_kath todos (SQLite `remind_kath.db` → CapsuleNote `capsule_note.db`):
/// - TodoItem { id, title, notes, scheduled_date, reminder_time, ...
///   reminder_kind, is_persistent_reminder, ... }
///
/// Association:
/// - Optional `capsuleId` / note link when user explicitly "加入待辦"
/// - Voice capsules do NOT auto-create todos
///
/// Backup envelope (extended):
/// - Kath BackupData todos + appSettings
/// - Plus capsules JSON list + audioPath strings (not binary)
library;
