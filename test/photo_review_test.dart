import 'dart:async';
import 'package:fitlife/app/fitlife_theme.dart';
import 'package:fitlife/features/photo_analysis/photo_models.dart';
import 'package:fitlife/features/photo_analysis/photo_review_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'photo_service_test.dart' show sampleFood;
import 'support/confirmed_food.dart';
import 'support/source_flow.dart';

Widget review(
  Future<void> Function(PhotoMeal) save, {
  bool confirmed = false,
}) => MaterialApp(
  theme: fitLifeTheme(),
  home: PhotoReviewPage(
    analysis: PhotoAnalysis(
      requestId: 'a' * 32,
      items: [
        confirmed ? confirmedFood(sampleFood) : PhotoFood.fromJson(sampleFood),
      ],
      warnings: const [],
    ),
    day: DateTime(2026, 10, 20),
    initialMeal: 'Обед',
    onSave: save,
  ),
);

void main() {
  testWidgets(
    'unconfirmed model numbers are hidden; label and portion confirmed; failed save retries',
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
      expect(find.text('Нужен источник состава'), findsOneWidget);
      expect(find.textContaining('195 ккал'), findsNothing);
      await reveal(tester, find.byKey(const Key('photo-save')));
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('photo-save')))
            .onPressed,
        isNull,
      );
      expect(calls, 0);
      // Return to the ingredient above the confirmation button.
      await tester.drag(find.byType(ListView), const Offset(0, 700));
      await tester.pumpAndSettle();
      await confirmRiceLabel(tester);
      await tester.drag(find.byType(ListView), const Offset(0, 900));
      await tester.pumpAndSettle();
      expect(find.text('260 ккал'), findsOneWidget);
      expect(find.text('Клетчатка: состав неполный'), findsOneWidget);
      await reveal(tester, find.byKey(const Key('photo-save')));
      await tester.tap(find.byKey(const Key('photo-save')));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(saved!.items.single.grams, 200);
      expect(
        saved!.items.single.source!.provenance.reference,
        'Рис — тестовая этикетка',
      );
      expect(saved!.items.single.source!.fiberKnown, isFalse);
      expect(saved!.day, DateTime(2026, 10, 20));
      expect(find.textContaining('Не удалось сохранить'), findsOneWidget);
      await tester.tap(find.byKey(const Key('photo-save')));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(saved!.id, 'a' * 32);
    },
  );

  testWidgets('double tap saves once; deletion disables empty review', (
    tester,
  ) async {
    final pending = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(
      review((_) {
        calls++;
        return pending.future;
      }, confirmed: true),
    );
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('photo-save')));
    await tester.tap(find.byKey(const Key('photo-save')));
    await tester.tap(find.byKey(const Key('photo-save')));
    await tester.pump();
    expect(calls, 1);
    pending.completeError(StateError('disk'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 700));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('food-source-0')));
    await tester.tap(find.byKey(const Key('food-source-0')));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Удалить ингредиент'));
    await tester.tap(find.text('Удалить ингредиент'));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('photo-save')));
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('photo-save')))
          .onPressed,
      isNull,
    );
    expect(find.text('0 ккал'), findsNothing);
  });
}
