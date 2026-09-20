import 'dart:async';

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

/// Startup must never block [runApp]: every await below either owns a
/// timeout or is deferred until after the first frame, and any exception
/// reaching this zone is logged instead of aborting startup silently.
void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    rkTrace('app.main binding ready');

    FlutterError.onError = (FlutterErrorDetails details) {
      rkTrace('FlutterError.onError: ${details.exceptionAsString()}');
      FlutterError.presentError(details);
    };
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      rkTrace('PlatformDispatcher.onError: $error');
      return true;
    };

    try {
      await initializeDateFormatting('zh');
    } catch (e) {
      debugPrint('日期本地化初始化警告：$e');
    }

    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } catch (e) {
      debugPrint('螢幕方向鎖定警告：$e');
    }

    final notifications = NotificationService();
    NotificationPort.instance = notifications;
    final alarms = AndroidAlarmScheduler();
    AlarmPort.instance = alarms;

    final scheduler = ReminderScheduler(
      notifService: notifications,
      alarmService: alarms,
    );
    ReminderScheduler.bindDefault(scheduler);
    // autoInitialize:false — loadTodos() runs after the first frame below,
    // never before runApp(), so a DB/migration failure can't blank the screen.
    final todoProvider = TodoProvider(
      scheduler: scheduler,
      autoInitialize: false,
    );

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<TodoProvider>.value(value: todoProvider),
          ChangeNotifierProvider(create: (_) => CapsuleProvider()),
          ChangeNotifierProvider(create: (_) => MonetizationProvider()),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ],
        child: CapsuleNoteApp(
          onResumed: () => _resyncAfterResume(
            notifications: notifications,
            alarms: alarms,
            scheduler: scheduler,
            todoProvider: todoProvider,
          ),
        ),
      ),
    );

    // Everything below runs after the first frame is on screen. Failures
    // here degrade individual features but never blank the main screen.
    unawaited(_initializeInBackground(
      notifications: notifications,
      alarms: alarms,
      scheduler: scheduler,
      todoProvider: todoProvider,
    ));
  }, (error, stack) {
    rkTrace('runZonedGuarded uncaught: $error');
    debugPrint('未捕捉的啟動例外：$error\n$stack');
  });
}

Future<void> _initializeInBackground({
  required NotificationService notifications,
  required AndroidAlarmScheduler alarms,
  required ReminderScheduler scheduler,
  required TodoProvider todoProvider,
}) async {
  AdService.instance.initialize().catchError((e) {
    debugPrint('AdService init error: $e');
  });

  // Core data first so the todo list appears as soon as possible.
  try {
    await todoProvider.loadTodos();
  } catch (e) {
    debugPrint('TodoProvider.loadTodos 背景載入失敗：$e');
  }

  try {
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
            await todoProvider.loadTodos();
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
    todoProvider.setAlarmCapability(
      exactAlarmsAllowed: exactAllowed,
      fullScreenIntentAllowed: fullScreenAllowed,
      timezoneName: AppTimezone.currentIanaName,
      lastScheduleUsedExact: notifications.lastScheduleUsedExact,
    );
    await processPendingAlarmActions();
    await scheduler.syncAllReminders();
  } catch (e) {
    debugPrint('背景初始化（通知／鬧鐘）失敗：$e');
    rkTrace('background init failed: $e');
  }
}

Future<void> _resyncAfterResume({
  required NotificationService notifications,
  required AndroidAlarmScheduler alarms,
  required ReminderScheduler scheduler,
  required TodoProvider todoProvider,
}) async {
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
