import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 行動平台初始化 AdMob
  await AdService.instance.initialize();

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
      home: const HomeScreen(),
    );
  }
}
