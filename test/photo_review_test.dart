import 'dart:async';
import 'package:fitlife/app/fitlife_theme.dart';
import 'package:fitlife/features/photo_analysis/photo_models.dart';
import 'package:fitlife/features/photo_analysis/photo_review_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'photo_service_test.dart' show sampleFood;

Widget review(Future<void> Function(PhotoMeal) save) => MaterialApp(
  theme: fitLifeTheme(),
  home: PhotoReviewPage(
    analysis: PhotoAnalysis(
      requestId: 'a' * 32,
      items: [PhotoFood.fromJson(sampleFood)],
      warnings: const [],
    ),
    day: DateTime(2026, 10, 20),
    initialMeal: 'Обед',
    onSave: save,
  ),
);

void main() {
  testWidgets(
    'review never auto saves; portion edit updates total and failed save can retry',
    (tester) async {
      var calls = 0;
      PhotoMeal? saved;
      await tester.pumpWidget(
        review((meal) async {
          calls++;
          saved = meal;
          throw StateError('disk');
        }),
      );
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(find.text('≈ 195 ккал'), findsOneWidget);
      await tester.tap(find.text('Рис варёный'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Вес порции, г'),
        '200',
      );
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      expect(find.text('≈ 260 ккал'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('photo-save')));
      await tester.tap(find.byKey(const Key('photo-save')));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(saved!.items.single.grams, 200);
      expect(saved!.day, DateTime(2026, 10, 20));
      expect(find.textContaining('Не удалось сохранить'), findsOneWidget);
      await tester.tap(find.byKey(const Key('photo-save')));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(saved!.id, 'a' * 32);
    },
  );
  testWidgets('double tap only saves once; empty review disables save', (
    tester,
  ) async {
    final pending = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(
      review((_) {
        calls++;
        return pending.future;
      }),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('photo-save')));
    await tester.tap(find.byKey(const Key('photo-save')));
    await tester.tap(find.byKey(const Key('photo-save')));
    await tester.pump();
    expect(calls, 1);
    pending.completeError(StateError('disk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Рис варёный'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('photo-save')),
    );
    expect(button.onPressed, isNull);
    expect(find.text('≈ 0 ккал'), findsOneWidget);
  });
}
