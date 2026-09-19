import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capsule_note/main.dart';
import 'package:capsule_note/services/alarm_port.dart';
import 'package:capsule_note/services/capsule_provider.dart';
import 'package:capsule_note/services/locale_provider.dart';
import 'package:capsule_note/services/monetization_provider.dart';
import 'package:capsule_note/services/notification_port.dart';
import 'package:capsule_note/services/reminder_scheduler.dart';
import 'package:capsule_note/services/todo_provider.dart';
import 'support/fake_alarm_scheduler.dart';
import 'support/fake_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeNotificationService notifications;
  late FakeAlarmScheduler alarms;
  late ReminderScheduler scheduler;
  late TodoProvider todoProvider;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    notifications = FakeNotificationService();
    alarms = FakeAlarmScheduler();
    NotificationPort.instance = notifications;
    AlarmPort.instance = alarms;
    scheduler = ReminderScheduler(
      notifService: notifications,
      alarmService: alarms,
    );
    ReminderScheduler.bindDefault(scheduler);
    todoProvider = TodoProvider(
      scheduler: scheduler,
      autoInitialize: false,
    );
  });

  testWidgets(
    'Capsule Note app renders with 4 navigation destinations',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: todoProvider),
            ChangeNotifierProvider(create: (_) => CapsuleProvider()),
            ChangeNotifierProvider(create: (_) => MonetizationProvider()),
            ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ],
          child: const CapsuleNoteApp(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(4));
      expect(find.byIcon(Icons.mic), findsOneWidget);
    },
  );

  test('MonetizationProvider quota and pro status test', () async {
    final mon = MonetizationProvider();
    await mon.initialized;

    expect(mon.isPro, false);
    expect(mon.remainingDailyQuota, 5);
    expect(mon.consumeQuota(), true);
    expect(mon.remainingDailyQuota, 4);
    await mon.addRewardQuota(3);
    expect(mon.remainingDailyQuota, 7);
    await mon.setProStatus(true);
    expect(mon.isPro, true);
    expect(mon.remainingDailyQuota, 999);
  });
}
