import 'dart:convert';

import 'package:fitlife/core/nutrition/nutrition_engine.dart';
import 'package:fitlife/modern_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'diary_flow_test.dart' show launch, dateKey;
import 'support/settings_disk.dart';

const sourced = FoodItem(
  id: 'label-yogurt',
  name: 'Йогурт с мёдом',
  kcal: 85,
  protein: 5,
  fat: 3,
  carbs: 9,
  fiber: 0,
  hasKnownFiber: false,
  provenance: NutritionProvenance(
    kind: 'label',
    reference: 'Личная этикетка йогурта',
  ),
);

void main() {
  late SettingsDisk disk;
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    disk = SettingsDisk();
    SharedPreferencesStorePlatform.instance = disk;
    prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_foods', jsonEncode([sourced.toJson()]));
    await prefs.setStringList('recent', [
      'missing',
      sourced.id,
      'egg',
      sourced.id,
    ]);
    await prefs.setStringList('favorites', ['missing', sourced.id]);
  });

  Finder filter(String value) => find.byKey(Key('food-filter-$value'));
  List<String> names(WidgetTester tester) => tester
      .widgetList<ListTile>(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(ListTile),
        ),
      )
      .map((tile) => (tile.title! as Text).data!)
      .toList();
  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('Добавить еду'));
    await tester.pumpAndSettle();
  }

  Future<void> select(WidgetTester tester, String value) async {
    await tester.ensureVisible(filter(value));
    await tester.tap(filter(value));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Today filters reuse persisted IDs and query without writes, including large text',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await launch(tester, size: const Size(320, 700));
      disk.writes.clear();
      await open(tester);
      await select(tester, 'recent');
      final list = tester.widget<ListView>(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(ListView),
        ),
      );
      expect(list.childrenDelegate.estimatedChildCount, 2);
      expect(names(tester).first, sourced.name);
      await tester.scrollUntilVisible(
        find.text('Яйцо'),
        100,
        scrollable: find.descendant(
          of: find.descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(ListView),
          ),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text('Яйцо'), findsOneWidget);
      await select(tester, 'favorites');
      expect(names(tester), [sourced.name]);
      await tester.enterText(
        find.widgetWithText(TextField, 'Поиск продукта'),
        ' МЕД ',
      );
      await tester.pumpAndSettle();
      expect(names(tester), [sourced.name]);
      await tester.enterText(
        find.widgetWithText(TextField, 'Поиск продукта'),
        'Рис',
      );
      await tester.pumpAndSettle();
      expect(names(tester), isEmpty);
      await select(tester, 'all');
      expect(names(tester), ['Рис']);
      Navigator.of(tester.element(find.byType(BottomSheet))).pop();
      await tester.pumpAndSettle();
      expect(disk.writes, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'filter changes retain selected food and precise draft; explicit retry stores it once',
    (tester) async {
      final key = 'diary_${dateKey(DateTime.now())}';
      final old = DiaryItem(
        id: 'kept',
        meal: 'Обед',
        food: builtInFoods.first,
        grams: 80,
        time: '12:34',
      );
      await prefs.setString(key, jsonEncode([old.toJson()]));
      await prefs.setString('unrelated', 'keep');
      await launch(tester);
      await open(tester);
      await select(tester, 'favorites');
      await tester.tap(find.text(sourced.name));
      await tester.enterText(find.widgetWithText(TextField, 'Граммы'), '150,5');
      await select(tester, 'recent');
      expect(find.text('Выбрано: ${sourced.name}'), findsOneWidget);
      expect(find.text('150,5'), findsOneWidget);
      disk.failedKeys.add(key);
      final add = find.widgetWithText(FilledButton, 'Добавить');
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(jsonDecode(prefs.getString(key)!), [old.toJson()]);
      expect(find.text('150,5'), findsOneWidget);
      disk.failedKeys.clear();
      await tester.tap(add);
      await tester.pumpAndSettle();
      final saved = jsonDecode(prefs.getString(key)!) as List;
      expect(saved, hasLength(2));
      expect(saved.first, old.toJson());
      expect(saved.last['food'], sourced.toJson());
      expect(saved.last['grams'], 150.5);
      expect(prefs.getStringList('favorites'), ['missing', sourced.id]);
      expect(prefs.getString('unrelated'), 'keep');
      await tester.pumpWidget(const SizedBox.shrink());
      await launch(tester);
      await open(tester);
      await select(tester, 'recent');
      expect(names(tester).first, sourced.name);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'favorite removal failure retains confirmed filter; retry has an actionable empty state',
    (tester) async {
      await launch(tester);
      await open(tester);
      await select(tester, 'favorites');
      disk.failedKeys.add('favorites');
      await tester.tap(find.byTooltip('Убрать из избранного'));
      await tester.pumpAndSettle();
      expect(names(tester), [sourced.name]);
      expect(prefs.getStringList('favorites'), ['missing', sourced.id]);
      disk.failedKeys.clear();
      await tester.tap(find.byTooltip('Убрать из избранного'));
      await tester.pumpAndSettle();
      expect(names(tester), isEmpty);
      expect(
        find.text(
          'В избранном пока нет продуктов. Нажмите звёздочку в общем списке.',
        ),
        findsOneWidget,
      );
      await select(tester, 'all');
      expect(names(tester), isNotEmpty);
      expect(prefs.getString('diary_${dateKey(DateTime.now())}'), isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
