import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'capsule_user_locale';

  Locale? _locale;
  Locale? get locale => _locale;

  static const List<Locale> supportedLocales = [
    Locale('zh'),
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
        _locale = Locale(code);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading locale: ');
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
        await prefs.setString(_localeKey, newLocale.languageCode);
      }
    } catch (e) {
      debugPrint('Error saving locale: ');
    }
  }

  String getLanguageName(String code) {
    switch (code) {
      case 'zh':
        return '繁體中文';
      case 'en':
        return 'English';
      case 'ja':
        return '日本語';
      case 'ko':
        return '한국어';
      default:
        return code;
    }
  }
}
