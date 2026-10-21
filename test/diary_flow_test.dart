import 'dart:convert';

import 'package:fitlife/main.dart';
import 'package:fitlife/modern_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'diary_repository_test.dart' show DiaryDisk;

String dateKey(DateTime day) =>
    '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

Future<void> launch(
  WidgetTester tester, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const FitLifeRoot());
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'manual save failure retains form; retry stores one precise portion',
    (tester) async {
      final disk = DiaryDisk();
      SharedPreferencesStorePlatform.instance = disk;
      await launch(tester);
      await tester.tap(find.text('Добавить еду'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Яйцо'));
      await tester.enterText(find.widgetWithText(TextField, 'Граммы'), '150,5');
      disk.fail = true;
      await tester.tap(find.widgetWithText(FilledButton, 'Добавить'));
      await tester.pumpAndSettle();
      expect(
        find.text('Не удалось сохранить. Проверь свободное место и повтори.'),
        findsOneWidget,
      );
      expect(find.text('150,5'), findsOneWidget);
      final key = 'diary_${dateKey(DateTime.now())}';
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(key), isFalse);
      expect(tester.takeException(), isNull);

      disk.fail = false;
      await tester.enterText(
        find.widgetWithText(TextField, 'Граммы'),
        '200,25',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Добавить'));
      await tester.pumpAndSettle();
      await prefs.reload();
      final stored = (jsonDecode(prefs.getString(key)!) as List).single;
      expect(stored['grams'], 200.25);
      expect(find.widgetWithText(FilledButton, 'Добавить'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed edits and deletion retain drafts and allow retry', (
    tester,
  ) async {
    final disk = DiaryDisk();
    SharedPreferencesStorePlatform.instance = disk;
    final prefs = await SharedPreferences.getInstance();
    final key = 'diary_${dateKey(DateTime.now())}';
    final raw = jsonEncode([
      DiaryItem(
        id: 'old',
        meal: 'Обед',
        food: builtInFoods.first,
        grams: 150.5,
        time: '12:00',
      ).toJson(),
    ]);
    await prefs.setString(key, raw);
    await launch(tester);
    await tester.tap(find.text('Питание').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byTooltip('Изменить порцию'), 200);
    await tester.tap(find.byTooltip('Изменить порцию'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '250');
    disk.fail = true;
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(prefs.getString(key), raw);
    expect(
      find.text('Не удалось сохранить. Проверь свободное место и повтори.'),
      findsOneWidget,
    );
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      '250',
    );
    disk.fail = false;
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect((jsonDecode(prefs.getString(key)!) as List).single['grams'], 250);
    await tester.tap(find.byTooltip('Изменить порцию'));
    await tester.pumpAndSettle();
    disk.fail = true;
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();
    expect(
      find.text('Не удалось сохранить. Проверь свободное место и повтори.'),
      findsOneWidget,
    );
    expect((jsonDecode(prefs.getString(key)!) as List).single['grams'], 250);
    disk.fail = false;
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();
    expect(jsonDecode(prefs.getString(key)!), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'invalid portions are rejected; add, edit, delete and reload persist',
    (tester) async {
      await launch(tester);
      await tester.tap(find.text('Добавить еду'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Яйцо'));
      await tester.enterText(find.widgetWithText(TextField, 'Граммы'), 'NaN');
      await tester.tap(find.widgetWithText(FilledButton, 'Добавить'));
      await tester.pumpAndSettle();
      expect(find.text('Введи порцию от 0 до 10 000 г'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Граммы'), '150,5');
      await tester.tap(find.widgetWithText(FilledButton, 'Добавить'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      final key = 'diary_${dateKey(DateTime.now())}';
      expect(
        (jsonDecode(prefs.getString(key)!) as List).single['grams'],
        150.5,
      );

      await tester.tap(find.text('Питание').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byTooltip('Изменить порцию'), 200);
      await tester.tap(find.byTooltip('Изменить порцию'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '200');
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      expect((jsonDecode(prefs.getString(key)!) as List).single['grams'], 200);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(const FitLifeRoot());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Питание').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byTooltip('Изменить порцию'), 200);
      await tester.tap(find.byTooltip('Изменить порцию'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Удалить'));
      await tester.pumpAndSettle();
      expect(jsonDecode(prefs.getString(key)!), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'catalog additions reach the persistent diary and system back returns home',
    (tester) async {
      await launch(tester);
      await tester.tap(find.byTooltip('База продуктов'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Добавить в дневник').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '50');
      await tester.tap(find.widgetWithText(FilledButton, 'Добавить'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('FITLIFE'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      final records =
          jsonDecode(prefs.getString('diary_${dateKey(DateTime.now())}')!)
              as List;
      expect(records.single['food']['nutrition']['kcal'], 674);
      expect(records.single['grams'], 50);
      await tester.tap(find.byTooltip('База продуктов'));
      await tester.pumpAndSettle();
      expect(find.text('Ккал 337'), findsOneWidget);
    },
  );

  testWidgets(
    'damaged JSON preserves valid records and keeps a recovery copy',
    (tester) async {
      final valid = DiaryItem(
        id: 'valid',
        meal: 'Завтрак',
        food: builtInFoods.first,
        grams: 100,
        time: '08:00',
      );
      final raw = jsonEncode([
        valid.toJson(),
        {'bad': true},
      ]);
      final key = 'diary_${dateKey(DateTime.now())}';
      SharedPreferences.setMockInitialValues({
        key: raw,
        'custom_foods': '{broken',
      });
      await launch(tester);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('recovery_$key'), raw);
      expect(prefs.getString('recovery_custom_foods'), '{broken');
      expect(find.text('157'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('hydration uses a daily key and retains previous days', (
    tester,
  ) async {
    final today = dateKey(DateTime.now());
    final yesterday = dateKey(DateTime.now().subtract(const Duration(days: 1)));
    SharedPreferences.setMockInitialValues({
      'water_migrated': true,
      'water_$today': 0.25,
      'water_$yesterday': 1.5,
    });
    await launch(tester);
    await tester.scrollUntilVisible(find.text('Вода'), 150);
    expect(find.text('0.25 л'), findsOneWidget);
    await tester.tap(find.text('Вода'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble('water_$today'), 0.5);
    expect(prefs.getDouble('water_$yesterday'), 1.5);
  });

  testWidgets('goals can be changed and survive relaunch', (tester) async {
    await launch(tester);
    await tester.tap(find.text('Профиль').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Настроить цели'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '2200');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const FitLifeRoot());
    await tester.pumpAndSettle();
    expect(find.text('2200'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('food entry fits a compact screen with keyboard open', (
    tester,
  ) async {
    await launch(tester, size: const Size(360, 640));
    await tester.tap(find.text('Добавить еду'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    await tester.tap(find.widgetWithText(TextField, 'Поиск продукта'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Поиск продукта'),
      'несуществующий продукт',
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Ничего не найдено. Можно создать свой продукт.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('all tabs fit narrow screens and enlarged text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await launch(tester, size: const Size(320, 740));
    for (final tab in ['Питание', 'Камера', 'Прогресс', 'Профиль', 'Сегодня']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Layout on $tab');
    }
  });
}
