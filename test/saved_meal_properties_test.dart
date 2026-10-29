import 'dart:convert';
import 'package:fitlife/app/fitlife_theme.dart';
import 'package:fitlife/core/models/diary_item.dart';
import 'package:fitlife/core/models/nutrition_profile.dart';
import 'package:fitlife/core/nutrition/nutrition_engine.dart';
import 'package:fitlife/data/repositories/diary_repository.dart';
import 'package:fitlife/features/satiety/satiety_estimate.dart';
import 'package:fitlife/features/satiety/satiety_page.dart';
import 'package:fitlife/features/saved_meals/saved_meals.dart';
import 'package:fitlife/features/saved_meals/saved_meals_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/source_flow.dart' show reveal;

const rice = NutritionSource(
  name: 'Рис',
  provenance: NutritionProvenance(kind: 'label', reference: 'Этикетка риса'),
  fiberKnown: true,
  profile: NutritionProfile(
    kcal: 130,
    protein: 2.7,
    fat: .3,
    carbs: 28,
    fiber: 1,
  ),
);
const beans = NutritionSource(
  name: 'Фасоль',
  provenance: NutritionProvenance(kind: 'label', reference: 'Этикетка фасоли'),
  fiberKnown: true,
  profile: NutritionProfile(kcal: 120, protein: 8, fat: 2, carbs: 16, fiber: 5),
);

FoodItem food(NutritionSource source, {bool legacy = false}) => FoodItem(
  id: source.name,
  name: source.name,
  kcal: source.profile.kcal,
  protein: source.profile.protein,
  fat: source.profile.fat,
  carbs: source.profile.carbs,
  fiber: legacy ? 0 : source.profile.fiber,
  nutrition: legacy ? null : source.profile,
  hasKnownFiber: !legacy,
  provenance: legacy ? null : source.provenance,
);

void main() {
  final day = DateTime(2026, 10, 29);
  const dayKey = 'diary_2026-10-29';
  late SharedPreferences prefs;
  late Map<String, Object?> before;
  SavedMeal recipe({bool legacy = false}) => SavedMeal(
    id: 'recipe-kept',
    name: 'Рис с фасолью',
    servings: 2,
    items: [
      DiaryItem(
        id: 'original-rice',
        meal: 'Обед',
        food: food(rice, legacy: legacy),
        grams: 300,
        time: '12:00',
      ),
      DiaryItem(
        id: 'original-beans',
        meal: 'Обед',
        food: food(beans),
        grams: 200,
        time: '12:00',
      ),
    ],
  );

  Future<void> open(WidgetTester tester, SavedMeal meal) async {
    final old = DiaryItem(
      id: 'kept',
      meal: 'Завтрак',
      food: food(rice),
      grams: 20,
      time: '08:00',
    );
    SharedPreferences.setMockInitialValues({
      savedMealsKey: jsonEncode([meal.toJson()]),
      dayKey: jsonEncode([old.toJson()]),
      'hunger_observations_v1': '[]',
    });
    prefs = await SharedPreferences.getInstance();
    before = {for (final k in prefs.getKeys()) k: prefs.get(k)};
    await tester.pumpWidget(
      MaterialApp(
        theme: fitLifeTheme().copyWith(platform: TargetPlatform.android),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => SavedMealsPage(
                    repository: SavedMealsRepository(
                      DiaryRepository.withLoader(),
                    ),
                    day: day,
                    initialMeal: 'Ужин',
                  ),
                ),
              ),
              child: const Text('Open library'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open library'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Выбрать порцию'));
    await tester.tap(find.text('Выбрать порцию'));
    await tester.pumpAndSettle();
  }

  Future<void> preview(WidgetTester tester) async {
    final button = find.byKey(const Key('saved-meal-satiety-preview'));
    await reveal(tester, button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Свойства порции блюда'), findsOneWidget);
    expect(find.byKey(const Key('observe-hunger')), findsNothing);
    expect(find.text('Мои наблюдения голода'), findsNothing);
  }

  testWidgets(
    'scaled whole-dish preview preserves ingredient sources, raw fraction, library and diary at large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final meal = recipe();
      await open(tester, meal);
      final count = find.widgetWithText(TextFormField, 'Количество порций');
      await reveal(tester, count);
      await tester.enterText(count, '0,5');
      await tester.pumpAndSettle();
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      expect(find.text('158 ккал'), findsOneWidget);
      expect(find.text('Клетчатка: 3.3 г'), findsOneWidget);
      await preview(tester);
      final page = tester.widget<SatietyPage>(find.byType(SatietyPage));
      expect(page.preview, isTrue);
      expect(page.items.map((i) => i.grams), [75, 50]);
      expect(page.items.map((i) => i.id), ['original-rice', 'original-beans']);
      expect(page.items.map((i) => i.time), ['12:00', '12:00']);
      expect(
        page.items.map((i) => i.food.toJson()),
        meal.items.map((i) => i.food.toJson()),
      );
      final sources = find.byKey(const Key('recipe-preview-sources'));
      await reveal(tester, sources);
      await tester.tap(sources);
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Рис · 75.0 г\nИсточник: Этикетка риса'));
      expect(
        find.text('Фасоль · 50.0 г\nИсточник: Этикетка фасоли'),
        findsOneWidget,
      );
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      await reveal(tester, sources);
      await tester.tap(sources);
      await tester.pumpAndSettle();
      await reveal(tester, find.widgetWithText(ChoiceChip, 'Нужно жевать'));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Нужно жевать'));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('satiety-score')));
      final expected = SatietyEstimate.fromPortions([
        (source: rice, grams: 75),
        (source: beans, grams: 50),
      ], structure: FoodStructure.solid);
      expect(
        tester.widget<Text>(find.byKey(const Key('satiety-score'))).data,
        expected.low == expected.high
            ? '${expected.low} из 10'
            : '${expected.low}–${expected.high} из 10',
      );
      expect({for (final k in prefs.getKeys()) k: prefs.get(k)}, before);
      await tester.pageBack();
      await tester.pumpAndSettle();
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      await reveal(tester, count);
      expect(tester.widget<TextFormField>(count).controller!.text, '0,5');
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect({for (final k in prefs.getKeys()) k: prefs.get(k)}, before);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'legacy ingredient keeps unknown fiber and no score; explicit add after back uses exact scaled ingredients once',
    (tester) async {
      await open(tester, recipe(legacy: true));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Количество порций'),
        '0.5',
      );
      await tester.pumpAndSettle();
      expect(find.text('Клетчатка: состав неполный'), findsOneWidget);
      await preview(tester);
      await reveal(tester, find.byKey(const Key('satiety-unavailable')));
      expect(find.byKey(const Key('satiety-score')), findsNothing);
      expect(find.byKey(const Key('observe-hunger')), findsNothing);
      expect({for (final k in prefs.getKeys()) k: prefs.get(k)}, before);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Добавить блюдо в дневник'));
      await tester.tap(find.text('Добавить блюдо в дневник'));
      await tester.pumpAndSettle();
      final entries = (jsonDecode(prefs.getString(dayKey)!) as List)
          .map((e) => DiaryItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      expect(entries, hasLength(3));
      expect(entries.first.id, 'kept');
      expect(entries.skip(1).map((i) => i.grams), [75, 50]);
      expect(entries.skip(1).map((i) => i.meal), ['Ужин', 'Ужин']);
      expect(entries.map((i) => i.id).toSet(), hasLength(3));
      expect(entries.skip(1).every((i) => i.id.startsWith('saved_')), isTrue);
      expect(prefs.getString(savedMealsKey), before[savedMealsKey]);
      expect(prefs.getString('hunger_observations_v1'), '[]');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'invalid portions do not show fabricated zero nutrition, preview or write',
    (tester) async {
      await open(tester, recipe());
      final count = find.widgetWithText(TextFormField, 'Количество порций');
      for (final value in ['0', 'NaN', '21']) {
        await reveal(tester, count);
        await tester.enterText(count, value);
        await tester.pumpAndSettle();
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .jumpTo(0);
        await tester.pumpAndSettle();
        expect(
          find.text('Укажите корректное количество порций для расчёта.'),
          findsOneWidget,
        );
        expect(find.text('0 ккал'), findsNothing);
        expect(
          find.byKey(const Key('saved-meal-satiety-preview')),
          findsNothing,
        );
        await reveal(tester, find.text('Добавить блюдо в дневник'));
        await tester.tap(find.text('Добавить блюдо в дневник'));
        await tester.pumpAndSettle();
        expect({for (final k in prefs.getKeys()) k: prefs.get(k)}, before);
      }
      expect(tester.takeException(), isNull);
    },
  );
}
