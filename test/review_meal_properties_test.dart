import 'dart:convert';
import 'package:fitlife/app/fitlife_theme.dart';
import 'package:fitlife/core/models/diary_item.dart';
import 'package:fitlife/core/models/nutrition_profile.dart';
import 'package:fitlife/core/nutrition/nutrition_engine.dart';
import 'package:fitlife/features/photo_analysis/photo_diary.dart';
import 'package:fitlife/features/photo_analysis/photo_models.dart';
import 'package:fitlife/features/photo_analysis/photo_review_page.dart';
import 'package:fitlife/features/satiety/satiety_estimate.dart';
import 'package:fitlife/features/satiety/satiety_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/source_flow.dart';

const rice = NutritionSource(
  name: 'Рис — подтверждённый состав',
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
  name: 'Фасоль — подтверждённый состав',
  provenance: NutritionProvenance(kind: 'label', reference: 'Этикетка фасоли'),
  fiberKnown: true,
  profile: NutritionProfile(kcal: 120, protein: 8, fat: 2, carbs: 16, fiber: 5),
);

void main() {
  final day = DateTime(2026, 10, 20);
  late SharedPreferences prefs;
  late Map<String, Object?> before;
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'diary_2026-10-20': '[]',
      'hunger_observations_v1': '[]',
      'saved_meals_v1': '[]',
      'weight_2026-10-20': 75.5,
    });
    prefs = await SharedPreferences.getInstance();
    before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
  });
  Future<void> unchanged() async {
    await prefs.reload();
    expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, before);
  }

  Future<void> open(
    WidgetTester tester, {
    required List<PhotoFood> items,
    MealEstimateSource source = MealEstimateSource.photo,
    Future<void> Function(PhotoMeal)? save,
    double scale = 1,
  }) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      MaterialApp(
        theme: fitLifeTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => PhotoReviewPage(
                    analysis: PhotoAnalysis(
                      requestId: 'd' * 32,
                      items: items,
                      warnings: const [],
                      source: source,
                    ),
                    day: day,
                    initialMeal: 'Обед',
                    onSave: save ?? (_) async => fail('Preview must not save'),
                  ),
                ),
              ),
              child: const Text('Открыть проверку'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Открыть проверку'));
    await tester.pumpAndSettle();
  }

  Future<SatietyPage> preview(WidgetTester tester) async {
    final button = find.byKey(const Key('review-meal-properties'));
    await reveal(tester, button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    final page = tester.widget<SatietyPage>(find.byType(SatietyPage));
    expect(page.preview, isTrue);
    expect(page.items, isEmpty); // No invented diary IDs or eating time.
    expect(page.day, day);
    expect(page.hungerRepository, isNull);
    expect(find.byKey(const Key('observe-hunger')), findsNothing);
    expect(find.text('Мои наблюдения голода'), findsNothing);
    return page;
  }

  testWidgets(
    'whole sourced draft uses chosen meal/date; preview and back do not write; explicit save keeps stable IDs',
    (tester) async {
      var saves = 0;
      PhotoMeal? saved;
      await open(
        tester,
        items: const [
          PhotoFood(
            name: 'Рис от модели',
            grams: 120.5,
            confidence: 'high',
            source: rice,
          ),
          PhotoFood(
            name: 'Фасоль от модели',
            grams: 80.25,
            confidence: 'medium',
            source: beans,
          ),
        ],
        save: (meal) async {
          saves++;
          saved = meal;
          await savePhotoMeal(meal);
        },
      );
      final mealField = find.byType(DropdownButtonFormField<String>);
      await reveal(tester, mealField);
      await tester.tap(mealField);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Перекус').last);
      await tester.pumpAndSettle();
      final page = await preview(tester);
      expect(page.meal, 'Перекус');
      expect(page.portions!.map((p) => p.grams), [120.5, 80.25]);
      expect(page.portions!.map((p) => p.source), [rice, beans]);
      await reveal(tester, find.text('Смешанная'));
      await tester.tap(find.text('Смешанная'));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('satiety-score')));
      final expected = SatietyEstimate.fromPortions([
        (source: rice, grams: 120.5),
        (source: beans, grams: 80.25),
      ], structure: FoodStructure.mixed);
      expect(
        tester.widget<Text>(find.byKey(const Key('satiety-score'))).data,
        expected.low == expected.high
            ? '${expected.low} из 10'
            : '${expected.low}–${expected.high} из 10',
      );
      await reveal(tester, find.text('Масса 200.8 г · 253 ккал · белок 9.7 г'));
      expect(find.text('Клетчатка: 5.2 г'), findsOneWidget);
      await tester.drag(find.byType(ListView).last, const Offset(0, 1000));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('recipe-preview-sources')));
      await tester.tap(find.byKey(const Key('recipe-preview-sources')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Этикетка риса'), findsOneWidget);
      expect(find.textContaining('Этикетка фасоли'), findsOneWidget);
      await unchanged();
      expect(saves, 0);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await unchanged();
      await reveal(tester, find.byKey(const Key('photo-save')));
      await tester.tap(find.byKey(const Key('photo-save')));
      await tester.pumpAndSettle();
      expect(saves, 1);
      expect(saved!.day, day);
      expect(saved!.meal, 'Перекус');
      expect(saved!.id, 'd' * 32);
      await prefs.reload();
      final stored = (jsonDecode(prefs.getString('diary_2026-10-20')!) as List)
          .map((j) => DiaryItem.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
      expect(stored.map((i) => i.id), [
        'photo_${'d' * 32}_0',
        'photo_${'d' * 32}_1',
      ]);
      expect(stored.map((i) => i.grams), [120.5, 80.25]);
      expect(stored.every((i) => i.food.isPhotoEstimate), isTrue);
      expect(stored.map((i) => i.food.provenance!.reference), [
        'Этикетка риса',
        'Этикетка фасоли',
      ]);
      expect(prefs.getString('hunger_observations_v1'), '[]');
      expect(prefs.getString('saved_meals_v1'), '[]');
    },
  );

  testWidgets(
    'unsourced draft has no preview; label then comma-portion edit recalculates with unknown fiber on narrow large text screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await open(
        tester,
        scale: 1.8,
        items: const [PhotoFood(name: 'Рис', grams: 200, confidence: 'high')],
      );
      await reveal(tester, find.byKey(const Key('photo-save')));
      expect(find.byKey(const Key('review-meal-properties')), findsNothing);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('photo-save')))
            .onPressed,
        isNull,
      );
      await tester.drag(find.byType(ListView), const Offset(0, 2500));
      await tester.pumpAndSettle();
      await confirmRiceLabel(tester);
      await tester.drag(find.byType(ListView), const Offset(0, 2500));
      await tester.pumpAndSettle();
      await preview(tester);
      await reveal(tester, find.text('Клетчатка: неизвестно'));
      expect(find.text('Клетчатка: 0.0 г'), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('food-source-0')));
      await tester.tap(find.byKey(const Key('food-source-0')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('source-grams')), '150,5');
      await reveal(tester, find.byKey(const Key('source-confirm')));
      await tester.tap(find.byKey(const Key('source-confirm')));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, 2500));
      await tester.pumpAndSettle();
      final page = await preview(tester);
      expect(page.portions!.single.grams, 150.5);
      expect(page.portions!.single.source.fiberKnown, isFalse);
      await reveal(tester, find.text('Масса 150.5 г · 196 ккал · белок 4.1 г'));
      expect(tester.takeException(), isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await unchanged();
    },
  );

  testWidgets(
    'text manual and Chef drafts share read-only properties; unsupported zero-energy and oversized drafts show no score',
    (tester) async {
      for (final source in [
        MealEstimateSource.text,
        MealEstimateSource.manual,
        MealEstimateSource.chef,
      ]) {
        await open(
          tester,
          source: source,
          items: const [
            PhotoFood(
              name: 'Рис',
              grams: 120.5,
              confidence: 'high',
              source: rice,
            ),
          ],
        );
        expect((await preview(tester)).portions!.single.grams, 120.5);
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
        await unchanged();
      }
      for (final items in [
        [
          const PhotoFood(
            name: 'Рис',
            grams: 1600,
            confidence: 'high',
            source: rice,
          ),
          const PhotoFood(
            name: 'Фасоль',
            grams: 1600,
            confidence: 'high',
            source: beans,
          ),
        ],
        [
          const PhotoFood(
            name: 'Вода',
            grams: 100,
            confidence: 'high',
            source: NutritionSource(
              name: 'Вода',
              provenance: NutritionProvenance(
                kind: 'label',
                reference: 'Этикетка воды',
              ),
              fiberKnown: true,
              profile: NutritionProfile(kcal: 0, protein: 0, fat: 0, carbs: 0),
            ),
          ),
        ],
      ]) {
        await open(tester, items: items);
        await preview(tester);
        await reveal(tester, find.byKey(const Key('satiety-unavailable')));
        expect(find.byKey(const Key('satiety-score')), findsNothing);
        await unchanged();
      }
    },
  );
}
