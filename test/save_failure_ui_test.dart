import 'dart:convert';
import 'package:fitlife/modern_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'parallel_storage_test.dart' show ControlledDisk;

void main() {
  late ControlledDisk disk;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    disk = ControlledDisk();
    SharedPreferencesStorePlatform.instance = disk;
    await disk.setValue('Bool', 'flutter.water_migrated', true);
  });
  Future<void> launch(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ModernFitLifeApp());
    await tester.pumpAndSettle();
  }

  testWidgets(
    'manual save failure retains portion; retry after secondary-list failure is idempotent',
    (tester) async {
      await launch(tester);
      disk.failKey = 'flutter.recent';
      await tester.tap(find.text('Добавить еду'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Яйцо'));
      await tester.enterText(find.widgetWithText(TextField, 'Граммы'), '150');
      await tester.tap(find.widgetWithText(FilledButton, 'Добавить'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Еда сохранена, но список последних'),
        findsOneWidget,
      );
      final key =
          'flutter.diary_${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
      final saved = jsonDecode((await disk.getAll())[key]! as String) as List;
      expect(saved.length, 1);
      expect(saved.single['grams'], 150);
      expect(find.text('Что было на тарелке?'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'failed water write does not pretend to save or inflate the next increment',
    (tester) async {
      await launch(tester);
      final date = DateTime.now();
      disk.failKey =
          'flutter.water_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      await tester.scrollUntilVisible(find.text('Вода'), 150);
      await tester.tap(find.text('Вода'));
      await tester.pumpAndSettle();
      expect(find.text('Нет записей'), findsOneWidget);
      expect(find.textContaining('Не удалось сохранить воду'), findsOneWidget);
      disk.failKey = null;
      await tester.tap(find.text('Вода'));
      await tester.pumpAndSettle();
      expect(find.text('0.25 л'), findsOneWidget);
    },
  );
  testWidgets(
    'failed goal write keeps entered values in the dialog and permits retry',
    (tester) async {
      await launch(tester);
      disk.failKey = 'flutter.nutrition_goals_v1';
      await tester.tap(find.text('Профиль').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Настроить цели'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '2200');
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Не удалось сохранить. Проверь свободное место'),
        findsOneWidget,
      );
      expect(find.text('2200'), findsOneWidget);
      disk.failKey = null;
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      expect(find.text('Цели питания'), findsNothing);
      expect(
        jsonDecode(
          (await disk.getAll())['flutter.nutrition_goals_v1']! as String,
        )['calories'],
        2200,
      );
    },
  );
  testWidgets('rapid water taps each apply one persisted increment', (
    tester,
  ) async {
    await launch(tester);
    await tester.scrollUntilVisible(find.text('Вода'), 150);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Вода'));
    }
    await tester.pumpAndSettle();
    expect(find.text('0.75 л'), findsOneWidget);
    final date = DateTime.now();
    final key =
        'flutter.water_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    expect((await disk.getAll())[key], 0.75);
  });
  testWidgets(
    'catalog failure retains the original batch for an explicit retry',
    (tester) async {
      await launch(tester);
      final date = DateTime.now();
      final key =
          'flutter.diary_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      disk.failKey = key;
      await tester.tap(find.byTooltip('База продуктов'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Добавить в дневник').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '50');
      await tester.tap(find.widgetWithText(FilledButton, 'Добавить'));
      await tester.pumpAndSettle();
      expect(find.text('Повторить сохранение'), findsOneWidget);
      expect((await disk.getAll())[key], isNull);
      disk.failKey = null;
      await tester.tap(find.text('Повторить сохранение'));
      await tester.pumpAndSettle();
      expect(
        (jsonDecode((await disk.getAll())[key]! as String) as List)
            .single['grams'],
        50,
      );
      expect(find.text('Повторить сохранение'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
