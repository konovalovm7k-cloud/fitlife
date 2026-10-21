import 'dart:convert';

import 'package:fitlife/app/app.dart' as legacy;
import 'package:fitlife/core/models/nutrition_goal_settings.dart';
import 'package:fitlife/data/repositories/settings_repository.dart';
import 'package:fitlife/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'diary_flow_test.dart' show launch;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<void> openGoals(WidgetTester tester) async {
    await tester.tap(find.text('Профиль').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Настроить цели'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Настроить цели'));
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester, List<String> values) async {
    for (var i = 0; i < values.length; i++) {
      await tester.enterText(find.byType(TextFormField).at(i), values[i]);
    }
    await tester.pump();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Сохранить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
  }

  const preview = 'Углеводы: 281,25 г. Рассчитаны из оставшихся калорий.';

  testWidgets('live carb preview and fractional goals survive a cold launch', (
    tester,
  ) async {
    await launch(tester);
    await openGoals(tester);
    expect(find.textContaining('Углеводы: 148,75 г.'), findsOneWidget);
    await fill(tester, ['2400,5', '160,25', '70,5', '35,25']);
    expect(find.text(preview), findsOneWidget);
    await save(tester);
    final prefs = await SharedPreferences.getInstance();
    final goals = NutritionGoalSettings.fromJson(
      jsonDecode(prefs.getString(SettingsRepository.goalsKey)!)
          as Map<String, dynamic>,
    );
    expect(goals.carbs, 281.25);
    expect(goals.macroCalories, 2400.5);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const FitLifeRoot());
    await tester.pumpAndSettle();
    expect(find.text('2400,5'), findsOneWidget);
    expect(find.text('из 281,25 г'), findsOneWidget);
    await tester.tap(find.text('Профиль').last);
    await tester.pumpAndSettle();
    for (final text in [
      '2400,5 ккал',
      '160,25 г',
      '70,5 г',
      '281,25 г',
      '35,25 г',
    ]) {
      expect(find.text(text), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('inconsistent macros keep the draft and the last saved goal', (
    tester,
  ) async {
    await launch(tester);
    final prefs = await SharedPreferences.getInstance();
    final original = prefs.getString(SettingsRepository.goalsKey);
    await openGoals(tester);
    await fill(tester, ['1000', '300', '70', '35']);
    expect(find.textContaining('Углеводы:'), findsNothing);
    await save(tester);
    expect(
      find.text('Калории из белков и жиров превышают дневную цель.'),
      findsOneWidget,
    );
    expect(find.byType(TextFormField), findsNWidgets(4));
    expect(prefs.getString(SettingsRepository.goalsKey), original);
    await fill(tester, ['2400.5', '160.25', '70.5', '35.25']);
    expect(find.text(preview), findsOneWidget);
    await save(tester);
    expect(find.text('281,25 г'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty and non-finite drafts never display calculated carbs', (
    tester,
  ) async {
    await launch(tester);
    await openGoals(tester);
    final prefs = await SharedPreferences.getInstance();
    final original = prefs.getString(SettingsRepository.goalsKey);
    for (final invalid in ['', 'NaN', 'Infinity', '-1', '10001']) {
      await tester.enterText(find.byType(TextFormField).first, invalid);
      await tester.pump();
      expect(find.textContaining('Углеводы:'), findsNothing);
      await save(tester);
      expect(find.text('Введи число от 1.0 до 10000.0'), findsOneWidget);
      expect(prefs.getString(SettingsRepository.goalsKey), original);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('zero carb goal saves and draws a finite progress indicator', (
    tester,
  ) async {
    await launch(tester);
    await openGoals(tester);
    await fill(tester, ['13', '1', '1', '1']);
    expect(find.textContaining('Углеводы: 0 г.'), findsOneWidget);
    await save(tester);
    await tester.tap(find.text('Сегодня').last);
    await tester.pumpAndSettle();
    expect(find.text('из 0 г'), findsOneWidget);
    for (final widget in tester.widgetList<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    )) {
      expect(widget.value, isNotNull);
      expect(widget.value!.isFinite, isTrue);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'decimal equality uses the same tolerance in form and repository',
    (tester) async {
      await launch(tester);
      await openGoals(tester);
      await fill(tester, ['23,3', '1,1', '2,1', '1']);
      expect(find.textContaining('Углеводы: 0 г.'), findsOneWidget);
      await save(tester);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('23,3 ккал'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'goal preview fits a narrow screen with larger text and keyboard',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await launch(tester, size: const Size(320, 740));
      await openGoals(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      addTearDown(tester.view.resetViewInsets);
      await fill(tester, ['2400,5', '160,25', '70,5', '35,25']);
      await save(tester);
      expect(find.byType(TextFormField), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'legacy invalid profile renders a fallback and can be corrected',
    (tester) async {
      SharedPreferences.setMockInitialValues({'age': 0});
      await tester.pumpWidget(const legacy.FitLifeApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Профиль').last);
      await tester.pumpAndSettle();
      expect(
        find.text('Проверь данные профиля: показаны базовые цели.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Изменить данные'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Возраст'), '17');
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      expect(find.text('Возраст: введи число от 18 до 120.'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Возраст'), '35');
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      expect(
        find.text('Проверь данные профиля: показаны базовые цели.'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
