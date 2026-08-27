import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'services/ad_service.dart';
import 'services/capsule_provider.dart';
import 'services/locale_provider.dart';
import 'services/monetization_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 intl 多國語言日期格式數據庫 (避免 Release 模式 LocaleDataException)
  try {
    await initializeDateFormatting();
  } catch (e) {
    debugPrint('Date formatting init error: ');
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 異步非阻塞初始化廣告服務
  AdService.instance.initialize().catchError((e) {
    debugPrint('AdService init error: ');
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CapsuleProvider()),
        ChangeNotifierProvider(create: (_) => MonetizationProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const CapsuleNoteApp(),
    ),
  );
}

class CapsuleNoteApp extends StatelessWidget {
  const CapsuleNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    final capsuleProvider = Provider.of<CapsuleProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      title: 'Capsule Note',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: capsuleProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      locale: localeProvider.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return const Locale('zh');
        for (final supported in supportedLocales) {
          if (supported.languageCode == locale.languageCode) {
            return supported;
          }
        }
        return const Locale('zh');
      },
      home: const HomeScreen(),
    );
  }
}
