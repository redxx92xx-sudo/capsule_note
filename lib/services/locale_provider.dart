import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'transcription_service.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'capsule_user_locale';

  Locale? _locale;
  Locale? get locale => _locale;

  /// UI + STT-oriented locales. Flutter l10n falls back zh_TW/zh_CN → zh.
  static const List<Locale> supportedLocales = [
    Locale('zh', 'TW'),
    Locale('zh', 'CN'),
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
  ];

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_localeKey);
      if (code != null && code.isNotEmpty) {
        _locale = _parseLocaleTag(code);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading locale: $e');
    }
  }

  Future<void> setLocale(Locale? newLocale) async {
    _locale = newLocale;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (newLocale == null) {
        await prefs.remove(_localeKey);
      } else {
        await prefs.setString(_localeKey, _toLocaleTag(newLocale));
      }
    } catch (e) {
      debugPrint('Error saving locale: $e');
    }
  }

  /// Locale tag passed to [TranscriptionService] (`zh_TW` / `zh_CN` / `en`).
  String get transcriptionLocale {
    final loc = _locale;
    if (loc == null) return TranscriptionLocale.zhTw;
    return TranscriptionLocale.fromLanguageAndCountry(
      languageCode: loc.languageCode,
      countryCode: loc.countryCode,
      scriptCode: loc.scriptCode,
    );
  }

  String getLanguageName(Locale locale) {
    final tag = TranscriptionLocale.fromLanguageAndCountry(
      languageCode: locale.languageCode,
      countryCode: locale.countryCode,
      scriptCode: locale.scriptCode,
    );
    switch (tag) {
      case TranscriptionLocale.zhTw:
        return '繁體中文';
      case TranscriptionLocale.zhCn:
        return '简体中文';
      case TranscriptionLocale.en:
        return 'English';
      default:
        switch (locale.languageCode) {
          case 'ja':
            return '日本語';
          case 'ko':
            return '한국어';
          default:
            return locale.toLanguageTag();
        }
    }
  }

  bool isSameLocale(Locale? a, Locale b) {
    if (a == null) return false;
    return a.languageCode == b.languageCode &&
        (a.countryCode ?? '') == (b.countryCode ?? '');
  }

  static String _toLocaleTag(Locale locale) {
    if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
      return '${locale.languageCode}_${locale.countryCode}';
    }
    return locale.languageCode;
  }

  static Locale _parseLocaleTag(String code) {
    final normalized = code.replaceAll('-', '_');
    // Legacy: plain "zh" → Traditional
    if (normalized == 'zh') return const Locale('zh', 'TW');
    final parts = normalized.split('_');
    if (parts.length >= 2) {
      return Locale(parts[0], parts[1].toUpperCase());
    }
    return Locale(parts[0]);
  }
}
