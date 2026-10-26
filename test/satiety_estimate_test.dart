import 'package:fitlife/core/models/diary_item.dart';
import 'package:fitlife/core/models/nutrition_profile.dart';
import 'package:fitlife/core/nutrition/nutrition_database.dart';
import 'package:fitlife/core/nutrition/nutrition_engine.dart';
import 'package:fitlife/features/satiety/satiety_estimate.dart';
import 'package:flutter_test/flutter_test.dart';

DiaryItem satietyItem({
  double grams = 200,
  bool source = true,
  bool fiberKnown = true,
  bool label = false,
  NutritionProfile? profile,
}) {
  final record = nutritionDatabase.firstWhere((r) => r.name == 'Яблоко');
  final p = profile ?? record.profile;
  return DiaryItem(
    id: 'a',
    meal: 'Обед',
    time: '12:00',
    grams: grams,
    food: FoodItem(
      id: record.id,
      name: record.name,
      kcal: p.kcal,
      protein: p.protein,
      fat: p.fat,
      carbs: p.carbs,
      fiber: fiberKnown ? p.fiber : 0,
      nutrition: !fiberKnown
          ? NutritionProfile(
              kcal: p.kcal,
              protein: p.protein,
              fat: p.fat,
              carbs: p.carbs,
              water: p.water,
            )
          : p,
      hasKnownFiber: fiberKnown,
      provenance: !source
          ? null
          : label
          ? const NutritionProvenance(kind: 'label', reference: 'Test label')
          : NutritionSource.catalogue(record).provenance,
    ),
  );
}

void main() {
  test('meal score does not depend on splitting ingredients into rows', () {
    final whole = SatietyEstimate.calculate([
      satietyItem(grams: 300),
    ], structure: FoodStructure.solid);
    final split = SatietyEstimate.calculate([
      satietyItem(grams: 100),
      satietyItem(grams: 200),
    ], structure: FoodStructure.solid);
    expect(split.low, whole.low);
    expect(split.high, whole.high);
    expect(split.grams, whole.grams);
    expect(split.fiber, closeTo(whole.fiber!, 1e-9));
    expect(whole.low, whole.high);
    expect(whole.missing, isEmpty);
  });
  test('unknown factors form a range without fabricated zero measurements', () {
    final result = SatietyEstimate.calculate([
      satietyItem(label: true, fiberKnown: false, grams: 400),
    ]);
    expect(result.fiber, isNull);
    expect(result.water, isNull);
    expect(
      result.missing,
      containsAll(['клетчатка', 'вода в продукте', 'структура пищи']),
    );
    expect(result.high, greaterThan(result.low));
    final chosen = SatietyEstimate.calculate([
      satietyItem(label: true, fiberKnown: false, grams: 400),
    ], structure: FoodStructure.soft);
    expect(chosen.low, greaterThanOrEqualTo(result.low));
    expect(chosen.high, lessThanOrEqualTo(result.high));
    expect(chosen.missing, isNot(contains('структура пищи')));
  });
  test(
    'legacy/model-only entries, empty or invalid portions cannot be scored',
    () {
      for (final items in <List<DiaryItem>>[
        [],
        [satietyItem(source: false)],
        [satietyItem(grams: double.nan)],
        [satietyItem(grams: -1)],
        [satietyItem(grams: 2000), satietyItem(grams: 2000)],
        [
          satietyItem(
            profile: const NutritionProfile(
              kcal: 0,
              protein: 0,
              fat: 0,
              carbs: 0,
              water: 100,
            ),
          ),
        ],
        [
          satietyItem(
            profile: const NutritionProfile(
              kcal: 100,
              protein: 1,
              fat: 1,
              carbs: 1,
              water: 101,
            ),
          ),
        ],
      ]) {
        expect(() => SatietyEstimate.calculate(items), throwsFormatException);
      }
    },
  );
  test(
    'same source retains score and unknown flags through storage serialization',
    () {
      final item = satietyItem(label: true, fiberKnown: false, grams: 150.5);
      final before = SatietyEstimate.calculate([item]);
      final after = SatietyEstimate.calculate([
        DiaryItem.fromJson(item.toJson()),
      ]);
      expect(after.low, before.low);
      expect(after.high, before.high);
      expect(after.missing, before.missing);
      expect(after.grams, 150.5);
    },
  );
  test(
    'tiny portions cannot earn a large score and supported scores stay bounded',
    () {
      final tiny = SatietyEstimate.calculate([
        satietyItem(grams: 1),
      ], structure: FoodStructure.solid);
      expect(tiny.high, 1);
      for (final mass in [10.0, 100.0, 400.0, 1500.0, 3000.0]) {
        for (final structure in FoodStructure.values) {
          final result = SatietyEstimate.calculate([
            satietyItem(grams: mass),
          ], structure: structure);
          expect(result.low, inInclusiveRange(1, 10));
          expect(result.high, inInclusiveRange(result.low, 10));
        }
      }
    },
  );
}
