import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capsule_note/main.dart';
import 'package:capsule_note/models/capsule_model.dart';
import 'package:capsule_note/services/capsule_provider.dart';
import 'package:capsule_note/services/locale_provider.dart';
import 'package:capsule_note/services/monetization_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Capsule Note app renders correctly with i18n & providers', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CapsuleProvider()),
          ChangeNotifierProvider(create: (_) => MonetizationProvider()),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ],
        child: const CapsuleNoteApp(),
      ),
    );

    await tester.pumpAndSettle();

    // 驗證預設英文環境下 AppTitle 渲染
    expect(find.text('Capsule Note'), findsOneWidget);
    expect(find.byIcon(Icons.mic_none_outlined), findsOneWidget);
    expect(find.byIcon(Icons.workspace_premium), findsOneWidget);
    expect(find.byIcon(Icons.language), findsOneWidget);
  });

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

  test('LocaleProvider language switching test', () async {
    final loc = LocaleProvider();
    expect(loc.locale, null);

    await loc.setLocale(const Locale('en'));
    expect(loc.locale?.languageCode, 'en');

    await loc.setLocale(const Locale('ja'));
    expect(loc.locale?.languageCode, 'ja');
  });

  test('CapsuleModel serialization and copyWith test', () {
    final now = DateTime.now();
    final model = CapsuleModel(
      id: 'test-1',
      title: '測試膠囊',
      rawTranscript: '這是語音轉譯內容',
      summary: '這是摘要',
      actionItems: ['行動1', '行動2'],
      createdAt: now,
      isProcessed: false,
      tags: ['工作'],
    );

    final json = model.toJson();
    final restored = CapsuleModel.fromJson(json);

    expect(restored.id, 'test-1');
    expect(restored.title, '測試膠囊');
    expect(restored.tags, contains('工作'));
    expect(restored.actionItems.length, 2);

    final updated = model.copyWith(isProcessed: true);
    expect(updated.isProcessed, true);
    expect(updated.id, 'test-1');
  });
}
