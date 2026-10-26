import 'dart:async';
import 'dart:convert';

import 'package:fitlife/data/repositories/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'diary_flow_test.dart' show launch, dateKey;
import 'support/settings_disk.dart';

const saveError = 'Не удалось сохранить. Проверь свободное место и повтори.';

void main() {
  late SettingsDisk disk;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    disk = SettingsDisk();
    SharedPreferencesStorePlatform.instance = disk;
  });

  Future<void> profile(WidgetTester tester) async {
    await tester.tap(find.text('Профиль').last);
    await tester.pumpAndSettle();
  }

  Future<void> relaunch(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await launch(tester);
  }

  testWidgets(
    'failed goals keep every draft field; retry survives cold launch',
    (tester) async {
      await launch(tester);
      final prefs = await SharedPreferences.getInstance();
      final old = prefs.getString(SettingsRepository.goalsKey);
      await profile(tester);
      await tester.tap(find.text('Настроить цели'));
      await tester.pumpAndSettle();
      final values = ['2400', '160', '70', '35'];
      for (var i = 0; i < values.length; i++) {
        await tester.enterText(find.byType(TextFormField).at(i), values[i]);
      }
      disk.failedKeys.add(SettingsRepository.goalsKey);
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      expect(find.text(saveError), findsOneWidget);
      expect(prefs.getString(SettingsRepository.goalsKey), old);
      for (var i = 0; i < values.length; i++) {
        expect(
          tester
              .widget<TextFormField>(find.byType(TextFormField).at(i))
              .controller!
              .text,
          values[i],
        );
      }
      disk.failedKeys.clear();
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      await relaunch(tester);
      await profile(tester);
      expect(find.text('2400 ккал'), findsOneWidget);
      expect(find.text('160 г'), findsOneWidget);
      expect(find.text('70 г'), findsOneWidget);
      expect(find.text('35 г'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'water failure changes no amount; rapid successful taps each persist once',
    (tester) async {
      await launch(tester);
      await tester.scrollUntilVisible(find.text('Вода'), 150);
      final key = 'water_${dateKey(DateTime.now())}';
      disk.failedKeys.add(key);
      await tester.tap(find.text('Вода'));
      await tester.pumpAndSettle();
      expect(find.text('Нет записей'), findsOneWidget);
      expect(
        find.text('Не удалось сохранить воду. Попробуй ещё раз.'),
        findsOneWidget,
      );
      disk.failedKeys.clear();
      await tester.tap(find.text('Вода'));
      await tester.tap(find.text('Вода'));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      expect(prefs.getDouble(key), 0.5);
      await relaunch(tester);
      await tester.scrollUntilVisible(find.text('Вода'), 150);
      expect(find.text('0.50 л'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'favorite add and removal failures retain the confirmed star state',
    (tester) async {
      await launch(tester);
      await tester.tap(find.text('Добавить еду'));
      await tester.pumpAndSettle();
      disk.failedKeys.add('favorites');
      await tester.tap(find.byTooltip('В избранное').first);
      await tester.pumpAndSettle();
      expect(
        find.text('Не удалось сохранить избранное. Попробуй ещё раз.'),
        findsOneWidget,
      );
      expect(find.byTooltip('Убрать из избранного'), findsNothing);
      disk.failedKeys.clear();
      await tester.tap(find.byTooltip('В избранное').first);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Убрать из избранного'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await relaunch(tester);
      await tester.tap(find.text('Добавить еду'));
      await tester.pumpAndSettle();
      disk.failedKeys.add('favorites');
      await tester.tap(find.byTooltip('Убрать из избранного'));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      expect(prefs.getStringList('favorites'), ['egg']);
      expect(find.byTooltip('Убрать из избранного'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'custom food keeps its draft after failure and retries without duplicate',
    (tester) async {
      await launch(tester);
      await tester.tap(find.text('Питание').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Создать свой продукт'));
      await tester.pumpAndSettle();
      final values = ['Тестовый творог', '125.5', '17', '5', '2', '0'];
      for (var i = 0; i < values.length; i++) {
        await tester.ensureVisible(find.byType(TextFormField).at(i));
        await tester.enterText(find.byType(TextFormField).at(i), values[i]);
      }
      disk.failedKeys.add('custom_foods');
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      expect(find.text(saveError), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        values.first,
      );
      disk.failedKeys.clear();
      await tester.tap(find.text('Сохранить'));
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final stored =
          (jsonDecode(prefs.getString('custom_foods')!) as List).single;
      expect(stored['name'], values.first);
      expect(stored['kcal'], 125.5);
      await relaunch(tester);
      await tester.tap(find.text('Добавить еду'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Поиск продукта'),
        values.first,
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, values.first), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'weight failure retains draft and retry persists before the dialog closes',
    (tester) async {
      await disk.setValue('Double', 'flutter.weight', 81.4);
      await launch(tester);
      await profile(tester);
      await tester.tap(find.text('Обновить вес'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '99,5');
      disk.failedKeys.add('weight_history_v1');
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      expect(find.text(saveError), findsOneWidget);
      expect(find.text('81.4 кг'), findsOneWidget);
      disk.failedKeys.clear();
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      await relaunch(tester);
      await profile(tester);
      expect(find.text('99.5 кг'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'pending save prevents double submit, cancellation and system back',
    (tester) async {
      await launch(tester);
      await profile(tester);
      await tester.tap(find.text('Настроить цели'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '2400');
      disk.blockedKey = SettingsRepository.goalsKey;
      disk.gate = Completer<void>();
      await tester.tap(find.text('Сохранить'));
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Сохраняем...'),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Отмена'))
            .onPressed,
        isNull,
      );
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('Цели питания'), findsOneWidget);
      disk.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Цели питания'), findsNothing);
      expect(
        disk.writes.where((key) => key == SettingsRepository.goalsKey).length,
        2,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failed startup migration shows retry and preserves legacy goals',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('goal_calories', 2200);
      disk.failedKeys.add(SettingsRepository.goalsKey);
      await launch(tester);
      expect(find.text('Не удалось открыть дневник'), findsOneWidget);
      expect(find.text('Добавить еду'), findsNothing);
      expect(prefs.getDouble('goal_calories'), 2200);
      disk.failedKeys.clear();
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();
      expect(find.text('FITLIFE'), findsOneWidget);
      expect(find.text('2200'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'recent failure closes a committed meal without requesting a duplicate save',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorites', ['egg']);
      await launch(tester);
      await tester.tap(find.text('Добавить еду'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Яйцо'));
      await tester.pumpAndSettle();
      disk.failedKeys.add('recent');
      await tester.tap(find.widgetWithText(FilledButton, 'Добавить'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Еда сохранена, но список последних продуктов обновить не удалось.',
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Добавить'), findsNothing);
      await prefs.reload();
      expect(
        (jsonDecode(prefs.getString('diary_${dateKey(DateTime.now())}')!)
                as List)
            .length,
        1,
      );
      expect(prefs.getStringList('favorites'), ['egg']);
      expect(tester.takeException(), isNull);
    },
  );
}
