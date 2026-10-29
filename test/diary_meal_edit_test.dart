import 'dart:async';
import 'dart:convert';
import 'package:fitlife/core/nutrition/nutrition_engine.dart';
import 'package:fitlife/modern_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'diary_flow_test.dart' show launch, dateKey;
import 'support/settings_disk.dart';

const entry = DiaryItem(
  id: 'original-entry',
  meal: 'Обед',
  grams: 150.5,
  time: '12:34',
  food: FoodItem(
    id: 'label',
    name: 'Мой йогурт',
    kcal: 85,
    protein: 5,
    fat: 3,
    carbs: 9,
    fiber: 0,
    hasKnownFiber: false,
    provenance: NutritionProvenance(
      kind: 'label',
      reference: 'Личная этикетка',
    ),
  ),
);
final kept = DiaryItem(
  id: 'keep',
  meal: 'Ужин',
  grams: 80,
  time: '19:00',
  food: builtInFoods.first,
);

void main() {
  late SettingsDisk disk;
  late SharedPreferences prefs;
  late String key;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    disk = SettingsDisk();
    SharedPreferencesStorePlatform.instance = disk;
    prefs = await SharedPreferences.getInstance();
    key = 'diary_${dateKey(DateTime.now())}';
    await prefs.setString(key, jsonEncode([entry.toJson(), kept.toJson()]));
    await prefs.setString('diary_2025-01-02', jsonEncode([entry.toJson()]));
    await prefs.setStringList('favorites', ['egg']);
    await prefs.setStringList('recent', ['egg']);
  });

  Future<void> open(WidgetTester tester) async {
    final edit = find.descendant(
      of: find.widgetWithText(ListTile, entry.food.name),
      matching: find.byTooltip('Изменить порцию'),
    );
    await tester.scrollUntilVisible(
      edit,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(edit);
    await tester.pumpAndSettle();
    await tester.tap(edit);
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, String value) async {
    final field = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(field);
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.tap(find.text(value).hitTestable().last);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'meal correction cancels without writes; failed save retries in place and survives restart',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await launch(tester, size: const Size(320, 700));
      final before = {for (final k in prefs.getKeys()) k: prefs.get(k)};
      disk.writes.clear();
      await open(tester);
      await choose(tester, 'Завтрак');
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      expect(disk.writes, isEmpty);
      expect({for (final k in prefs.getKeys()) k: prefs.get(k)}, before);
      await open(tester);
      await choose(tester, 'Завтрак');
      disk.failedKeys.add(key);
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      expect(prefs.getString(key), before[key]);
      expect(
        find.text('Не удалось сохранить. Проверь свободное место и повтори.'),
        findsOneWidget,
      );
      // The FormField's state holds the unsaved choice, even after write failure.
      expect(
        tester
            .state<FormFieldState<String>>(
              find.byType(DropdownButtonFormField<String>),
            )
            .value,
        'Завтрак',
      );
      disk.failedKeys.clear();
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      final saved = jsonDecode(prefs.getString(key)!) as List;
      expect(saved, [entry.toJson()..['meal'] = 'Завтрак', kept.toJson()]);
      for (final other in before.keys.where((k) => k != key)) {
        expect(prefs.get(other), before[other], reason: other);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await launch(tester);
      await open(tester);
      expect(
        tester
            .state<FormFieldState<String>>(
              find.byType(DropdownButtonFormField<String>),
            )
            .value,
        'Завтрак',
      );
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        '150.5',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'pending meal correction disables choice and back until the one write finishes',
    (tester) async {
      await launch(tester);
      await open(tester);
      await choose(tester, 'Завтрак');
      disk.blockedKey = key;
      disk.gate = Completer<void>();
      final writesBefore = disk.writes.where((x) => x == key).length;
      await tester.tap(find.text('Сохранить'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(
              find.byType(DropdownButtonFormField<String>),
            )
            .onChanged,
        isNull,
      );
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        (await disk.getAll())['flutter.$key'],
        jsonEncode([entry.toJson(), kept.toJson()]),
      );
      disk.gate!.complete();
      await tester.pumpAndSettle();
      expect(disk.writes.where((x) => x == key).length, writesBefore + 1);
      expect(jsonDecode(prefs.getString(key)!), [
        entry.toJson()..['meal'] = 'Завтрак',
        kept.toJson(),
      ]);
      expect(tester.takeException(), isNull);
    },
  );
}
