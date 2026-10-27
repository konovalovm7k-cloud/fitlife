import 'dart:convert';
import 'package:fitlife/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'diary_flow_test.dart' show launch, dateKey;
import 'support/source_flow.dart';

void main() {
  testWidgets(
    'offline camera label flow confirms source then saves and survives root restart',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await launch(tester, size: const Size(360, 780));
      await tester.tap(find.text('Камера').last);
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Ввести состав с этикетки'));
      await tester.tap(find.text('Ввести состав с этикетки'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('source-grams')), '150.5');
      final name = find.widgetWithText(TextFormField, 'Название продукта');
      await reveal(tester, name);
      await tester.enterText(name, 'RiceLabel');
      final ref = find.widgetWithText(
        TextFormField,
        'Источник: марка и название на упаковке',
      );
      await reveal(tester, ref);
      await tester.enterText(ref, 'PackageTest');
      for (var i = 0; i < 4; i++) {
        final field = find.byKey(Key('source-nutrient-$i'));
        await reveal(tester, field);
        await tester.enterText(field, ['130', '2.7', '.3', '28'][i]);
      }
      await reveal(tester, find.byKey(const Key('source-confirm')));
      await tester.tap(find.byKey(const Key('source-confirm')));
      await tester.pumpAndSettle();
      expect(find.text('СОСТАВ ПРОДУКТОВ'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      final key = 'diary_${dateKey(DateTime.now())}';
      await prefs.reload();
      expect(prefs.containsKey(key), isFalse);
      await reveal(tester, find.byKey(const Key('photo-save')));
      await tester.tap(find.byKey(const Key('photo-save')));
      await tester.pumpAndSettle();
      await prefs.reload();
      final stored = (jsonDecode(prefs.getString(key)!) as List).single as Map;
      expect(stored['id'], startsWith('source_'));
      expect(stored['food']['nutritionSource']['reference'], 'PackageTest');
      expect(stored['food']['fiberKnown'], false);
      expect(stored['food']['photoEstimate'], isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(const FitLifeRoot());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Питание').last);
      await tester.pumpAndSettle();
      await reveal(tester, find.text('RiceLabel'));
      expect(find.textContaining('Состав: PackageTest'), findsOneWidget);
      expect(find.textContaining('Клетчатка не указана'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
