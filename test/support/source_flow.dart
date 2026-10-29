import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> reveal(WidgetTester tester, Finder finder) async {
  // Text edits can change the live portion card's height. Settle that layout
  // before choosing a scroll offset or tapping the confirmation below it.
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    finder,
    180,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> confirmRiceLabel(
  WidgetTester tester, {
  String grams = '200',
}) async {
  await reveal(tester, find.byKey(const Key('food-source-0')));
  await tester.tap(find.byKey(const Key('food-source-0')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('source-grams')), grams);
  await tester.tap(find.text('С этикетки'));
  await tester.pumpAndSettle();
  final reference = find.widgetWithText(
    TextFormField,
    'Источник: марка и название на упаковке',
  );
  await reveal(tester, reference);
  await tester.enterText(reference, 'Рис — тестовая этикетка');
  for (var i = 0; i < 4; i++) {
    final field = find.byKey(Key('source-nutrient-$i'));
    await reveal(tester, field);
    await tester.enterText(field, ['130', '2.7', '0.3', '28'][i]);
  }
  await reveal(tester, find.byKey(const Key('source-confirm')));
  await tester.tap(find.byKey(const Key('source-confirm')));
  await tester.pumpAndSettle();
}
