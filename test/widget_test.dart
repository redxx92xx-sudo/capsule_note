import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capsule_note/main.dart';
import 'package:capsule_note/models/capsule_model.dart';
import 'package:capsule_note/services/capsule_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Capsule Note main app renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CapsuleProvider()),
        ],
        child: const CapsuleNoteApp(),
      ),
    );

    await tester.pumpAndSettle();

    // 驗證標題與膠囊文字渲染
    expect(find.text('膠囊靈感'), findsOneWidget);
    expect(find.byIcon(Icons.mic_none_outlined), findsOneWidget);
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
