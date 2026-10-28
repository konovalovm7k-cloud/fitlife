import 'dart:convert';
import 'package:fitlife/core/models/diary_item.dart';
import 'package:fitlife/core/models/nutrition_profile.dart';
import 'package:fitlife/core/nutrition/nutrition_database.dart';
import 'package:fitlife/core/nutrition/nutrition_engine.dart';
import 'package:fitlife/features/photo_analysis/photo_diary.dart';
import 'package:fitlife/features/photo_analysis/photo_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'photo_service_test.dart' show sampleFood, result;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final apple = nutritionDatabase.firstWhere((r) => r.name == 'Яблоко');
  test(
    'selected source scales a portion exactly once and keeps a reference',
    () {
      final source = NutritionSource.catalogue(apple);
      final portion = NutritionEngine.portion(source, 150.5);
      expect(portion.kcal, closeTo(78.26, .000001));
      expect(portion.fiber, closeTo(3.612, .000001));
      expect(source.provenance.recordId, apple.id);
      expect(source.provenance.url, apple.sourceUrl);
      expect(source.profile.kcal, 52);
    },
  );
  test('invalid source and portion cannot be calculated', () {
    final source = NutritionSource.catalogue(apple);
    for (final grams in [0.0, -1.0, double.nan, double.infinity, 3001.0]) {
      expect(
        () => NutritionEngine.portion(source, grams),
        throwsFormatException,
      );
    }
    for (final p in [
      const NutritionProfile(kcal: 1, protein: 80, fat: 80, carbs: 0),
      const NutritionProfile(kcal: double.nan, protein: 0, fat: 0, carbs: 0),
    ]) {
      expect(
        () => NutritionEngine.portion(
          NutritionSource(
            name: 'Label',
            profile: p,
            provenance: const NutritionProvenance(
              kind: 'label',
              reference: 'Package',
            ),
            fiberKnown: true,
          ),
          100,
        ),
        throwsFormatException,
      );
    }
    expect(
      () => const NutritionProvenance(
        kind: 'catalogue',
        reference: 'AI',
        recordId: 'fake',
        url: 'http://bad.example',
      ).validate(),
      throwsFormatException,
    );
  });
  test('model JSON cannot provide nutrients or confirm a forged source', () {
    final analysis = PhotoAnalysis.fromJson({
      ...result('id'),
      'items': [
        {
          ...sampleFood,
          'kcal': 999,
          'nutritionSource': {'kind': 'label', 'reference': 'forged'},
          'source': {
            'profile': {'kcal': 100},
            'fiberKnown': true,
          },
        },
      ],
    }, 'id');
    expect(analysis.items.single.source, isNull);
    expect(analysis.items.single.calories, isNull);
    expect(
      () => PhotoAnalysis.fromJson({
        ...result('id'),
        'warnings': ['100 kcal'],
      }, 'id'),
      throwsFormatException,
    );
    expect(
      PhotoAnalysis.fromJson({
        ...result('id'),
        'warnings': ['no_food'],
        'items': [],
      }, 'id').warnings.single,
      contains('Еда не распознана'),
    );
  });
  test(
    'an unresolved identity cannot reach disk even if a caller bypasses the UI',
    () async {
      await expectLater(
        savePhotoMeal(
          PhotoMeal(
            id: 'a' * 32,
            day: DateTime(2026, 10, 26),
            meal: 'Обед',
            items: [PhotoFood.fromJson(sampleFood)],
          ),
        ),
        throwsFormatException,
      );
      expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
    },
  );
  test(
    'source snapshot, missing fiber and fractional grams survive storage and retry',
    () async {
      const source = NutritionSource(
        name: 'Рис с этикетки',
        profile: NutritionProfile(
          kcal: 130,
          protein: 2.7,
          fat: .3,
          carbs: 28,
        ),
        provenance: NutritionProvenance(
          kind: 'label',
          reference: 'Марка / рис варёный',
        ),
        fiberKnown: false,
      );
      final meal = PhotoMeal(
        id: 'b' * 32,
        day: DateTime(2026, 10, 26),
        meal: 'Обед',
        items: [
          PhotoFood(
            name: source.name,
            grams: 150.5,
            confidence: 'medium',
            source: source,
          ),
        ],
      );
      await savePhotoMeal(meal);
      await savePhotoMeal(meal);
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final raw = jsonDecode(prefs.getString('diary_2026-10-26')!) as List;
      expect(raw, hasLength(1));
      final restored = DiaryItem.fromJson(
        Map<String, dynamic>.from(raw.single as Map),
      );
      expect(restored.grams, 150.5);
      expect(restored.kcal, closeTo(195.65, .00001));
      expect(restored.food.provenance!.reference, 'Марка / рис варёный');
      expect(restored.food.hasKnownFiber, isFalse);
      expect(restored.food.nutrition!.protein, 2.7);
    },
  );
  test(
    'legacy food without provenance remains readable without invented source',
    () {
      final legacy = FoodItem.fromJson({'id': 'old', ...sampleFood});
      expect(legacy.provenance, isNull);
      expect(legacy.kcal, 130);
      expect(legacy.toJson().containsKey('nutritionSource'), isFalse);
    },
  );
}
