import 'dart:convert';
import 'package:fitlife/app/state/fitlife_state.dart';
import 'package:fitlife/app/state/today_guidance.dart';
import 'package:fitlife/core/models/diary_item.dart';
import 'package:fitlife/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'diary_flow_test.dart' show dateKey, launch;

DiaryItem food({double grams = 100, bool fiberKnown = true}) => DiaryItem(
  id: 'today-meal',
  meal: 'Обед',
  grams: grams,
  time: '12:00',
  food: FoodItem(
    id: 'f',
    name: 'Продукт',
    kcal: 100,
    protein: 30,
    fat: 2,
    carbs: 9,
    fiber: 3,
    hasKnownFiber: fiberKnown,
  ),
);

void main() {
  final day = DateTime(2026, 10, 25);
  test('empty diary invites recording, never celebrates low intake', () {
    final guidance = TodayGuidance.forDay(
      FitLifeState(day: day),
      isToday: true,
    );
    expect(guidance.mood, CompanionMood.welcoming);
    expect(guidance.action, TodayAction.logMeal);
    expect(guidance.detail, contains('обычному приёму пищи'));
  });
  test(
    'above goal remains supportive and does not ask for more food or skipping meals',
    () {
      final guidance = TodayGuidance.forDay(
        FitLifeState(day: day, diary: [food(grams: 3000)]),
        isToday: true,
      );
      expect(guidance.mood, CompanionMood.encouraging);
      expect(guidance.action, TodayAction.reviewDiary);
      expect(guidance.detail, contains('пропускать еду'));
    },
  );
  test('missing fiber requests data, not a false deficiency judgement', () {
    final guidance = TodayGuidance.forDay(
      FitLifeState(day: day, diary: [food(fiberKnown: false)]),
      isToday: true,
    );
    expect(guidance.action, TodayAction.reviewSource);
    expect(guidance.detail, contains('известная часть'));
    expect(guidance.detail, contains('Продукт'));
  });
  test('history never receives today-specific eating instructions', () {
    final guidance = TodayGuidance.forDay(
      FitLifeState(day: day),
      isToday: false,
    );
    expect(guidance.action, TodayAction.reviewDiary);
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'empty Today shows real empty values and next action saves through restart',
    (tester) async {
      await launch(tester);
      await tester.scrollUntilVisible(find.text('Клетчатка'), 180);
      expect(find.text('Клетчатка'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Вода'), 150);
      expect(find.text('Нет записей'), findsOneWidget);
      expect(find.text('104.2 кг'), findsNothing);
      await tester.scrollUntilVisible(
        find.byKey(const Key('today-next-action')),
        150,
      );
      await tester.ensureVisible(find.text('Записать еду'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Записать еду'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Яйцо'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Добавить'));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      expect(
        jsonDecode(prefs.getString('diary_${dateKey(DateTime.now())}')!),
        hasLength(1),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(const FitLifeRoot());
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('today-next-action')),
        180,
      );
      expect(find.text('Идея для следующего приёма'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'partial fiber and action stay usable on a compact screen with larger text',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'diary_${dateKey(DateTime.now())}': jsonEncode([
          food(fiberKnown: false).toJson(),
        ]),
      });
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await launch(tester, size: const Size(320, 700));
      await tester.scrollUntilVisible(find.text('Состав неполный'), 180);
      expect(find.text('≥ 3 г'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('today-next-action')),
        180,
      );
      await tester.ensureVisible(find.text('Уточнить запись'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Уточнить запись'));
      await tester.pumpAndSettle();
      expect(find.text('В дневнике: Продукт'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
