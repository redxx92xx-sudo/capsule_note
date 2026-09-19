import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_strings.dart';

/// Flutter [LocalizationsDelegate] for [AppStrings] (zh_TW / zh_CN / en).
class AppStringsLocalizationsDelegate
    extends LocalizationsDelegate<AppStrings> {
  const AppStringsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppStrings> load(Locale locale) {
    return SynchronousFuture<AppStrings>(AppStrings.forLocale(locale));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppStrings> old) => false;
}

/// Holds the currently resolved app locale for services outside [BuildContext]
/// (notifications, alarm preview).
class AppLocaleHolder {
  AppLocaleHolder._();

  static String preference = AppLocaleOption.system;
  static Locale resolved = const Locale('en');

  static AppStrings get strings => AppStrings.forLocale(resolved);

  static void update({
    required String preferenceTag,
    required Locale resolvedLocale,
  }) {
    preference = preferenceTag;
    resolved = resolvedLocale;
  }
}
