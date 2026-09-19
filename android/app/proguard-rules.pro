# WorkManager / Room (google_mobile_ads, notifications)
-keep class androidx.work.** { *; }
-keep class androidx.room.** { *; }
-keep class * extends androidx.room.RoomDatabase
-dontwarn androidx.work.**
-dontwarn androidx.room.**

# Keep Flutter / Play Services used by ads
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# whisper_ggml / ffmpeg-kit (also has consumer-rules; reinforce)
-keep class com.arthenica.** { *; }
-keep class com.devac.** { *; }
-dontwarn com.arthenica.**
