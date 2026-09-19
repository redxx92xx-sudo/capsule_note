import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'l10n/app_strings.dart';
import 'l10n/app_strings_delegate.dart';
import 'screens/main_navigation_screen.dart';
import 'services/ad_service.dart';
import 'services/alarm_port.dart';
import 'services/android_alarm_scheduler.dart';
import 'services/app_timezone.dart';
import 'services/background_entry.dart';
import 'services/capsule_provider.dart';
import 'services/locale_provider.dart';
import 'services/monetization_provider.dart';
import 'services/notification_port.dart';
import 'services/notification_service.dart';
import 'services/reminder_scheduler.dart';
import 'services/todo_provider.dart';
import 'theme/app_theme.dart';
import 'utils/rk_trace.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  rkTrace('app.main binding ready');

  try {
    await initializeDateFormatting('zh');
  } catch (e) {
    debugPrint('日期本地化初始化警告：$e');
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Default STT provider (local Whisper) is created lazily by the locator.
  AdService.instance.initialize().catchError((e) {
    debugPrint('AdService init error: $e');
  });

  final notifications = NotificationService();
  NotificationPort.instance = notifications;
  final alarms = AndroidAlarmScheduler();
  AlarmPort.instance = alarms;
  TodoProvider? providerRef;

  await notifications.initialize(
    onNotificationAction: (actionId, payload) {
      Future<void>(() async {
        try {
          if (actionId == null ||
              actionId.isEmpty ||
              payload == null ||
              payload.isEmpty ||
              payload == 'daily_summary') {
            return;
          }
          await ReminderScheduler.instance.handleNotificationAction(
            actionId,
            payload,
          );
          await providerRef?.loadTodos();
        } catch (e) {
          debugPrint('前景通知動作處理失敗：$e');
        }
      });
    },
  );
  await registerBackgroundResyncCallback();
  await registerBackgroundAlarmActionCallback();
  await notifications.requestPermissions();
  final exactAllowed = await alarms.canScheduleExactAlarms();
  final fullScreenAllowed = await alarms.canUseFullScreenIntent();

  final scheduler = ReminderScheduler(
    notifService: notifications,
    alarmService: alarms,
  );
  ReminderScheduler.bindDefault(scheduler);
  final todoProvider = TodoProvider(
    scheduler: scheduler,
    autoInitialize: false,
  );
  providerRef = todoProvider;
  todoProvider.setAlarmCapability(
    exactAlarmsAllowed: exactAllowed,
    fullScreenIntentAllowed: fullScreenAllowed,
    timezoneName: AppTimezone.currentIanaName,
    lastScheduleUsedExact: notifications.lastScheduleUsedExact,
  );
  await todoProvider.loadTodos();
  await processPendingAlarmActions();
  await scheduler.syncAllReminders();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<TodoProvider>.value(value: todoProvider),
        ChangeNotifierProvider(create: (_) => CapsuleProvider()),
        ChangeNotifierProvider(create: (_) => MonetizationProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: CapsuleNoteApp(
        onResumed: () async {
          try {
            await notifications.refreshDeviceTimezone();
            todoProvider.setAlarmCapability(
              exactAlarmsAllowed: await alarms.canScheduleExactAlarms(),
              fullScreenIntentAllowed: await alarms.canUseFullScreenIntent(),
              timezoneName: AppTimezone.currentIanaName,
              lastScheduleUsedExact: notifications.lastScheduleUsedExact,
            );
            await processPendingAlarmActions();
            await todoProvider.loadTodos();
            await scheduler.syncAllReminders();
          } catch (e) {
            debugPrint('前景恢復處理失敗：$e');
          }
        },
      ),
    ),
  );
}

class CapsuleNoteApp extends StatefulWidget {
  final Future<void> Function()? onResumed;

  const CapsuleNoteApp({super.key, this.onResumed});

  @override
  State<CapsuleNoteApp> createState() => _CapsuleNoteAppState();
}

class _CapsuleNoteAppState extends State<CapsuleNoteApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.onResumed?.call();
    }
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    final provider = context.read<TodoProvider>();
    if (provider.localePreference == AppLocaleOption.system) {
      provider.refreshResolvedLocale();
    }
  }

  @override
  Widget build(BuildContext context) {
    final todoProvider = context.watch<TodoProvider>();
    final preferred = AppLocaleOption.toLocale(todoProvider.localePreference);

    return MaterialApp(
      onGenerateTitle: (ctx) => AppStrings.of(ctx).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: todoProvider.themePreference.themeMode,
      locale: preferred,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (deviceLocale, supported) {
        return AppLocaleOption.resolve(
          preferred,
          WidgetsBinding.instance.platformDispatcher.locales,
        );
      },
      localizationsDelegates: const [
        AppStringsLocalizationsDelegate(),
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final strings = AppStrings.of(context);
        return AppStringsScope(
          strings: strings,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const MainNavigationScreen(),
    );
  }
}
