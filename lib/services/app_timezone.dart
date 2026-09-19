import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Device IANA timezone helper. Call [ensureDatabase] then [applyNamed]
/// *before* any zoned notification is scheduled. Never assume [tz.local]
/// is correct after [initializeTimeZones] alone.
class AppTimezone {
  static const String taipei = 'Asia/Taipei';
  static const String kualaLumpur = 'Asia/Kuala_Lumpur';
  static const String fallback = taipei;

  static String currentIanaName = fallback;
  static bool databaseReady = false;

  static void ensureDatabase() {
    if (databaseReady) return;
    tzdata.initializeTimeZones();
    databaseReady = true;
  }

  static bool hasLocation(String name) {
    ensureDatabase();
    try {
      tz.getLocation(name);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Sets [tz.local] to [name] if present, otherwise walks a safe fallback
  /// chain. Never throws.
  static String applyNamed(String? name) {
    ensureDatabase();
    final candidates = <String>[
      if (name != null && name.trim().isNotEmpty) name.trim(),
      fallback,
      kualaLumpur,
      'UTC',
    ];
    for (final candidate in candidates) {
      try {
        final location = tz.getLocation(candidate);
        tz.setLocalLocation(location);
        currentIanaName = candidate;
        return candidate;
      } catch (_) {
        continue;
      }
    }
    return currentIanaName;
  }
}
