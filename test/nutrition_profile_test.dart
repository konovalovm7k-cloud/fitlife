import 'package:flutter_test/flutter_test.dart';
import 'package:fitlife/core/models/nutrition_profile.dart';
import 'package:fitlife/core/nutrition/nutrition_database.dart';

void main() {
  test('invalid portion cannot produce negative or non-finite totals', () {
    final profile = nutritionDatabase.first.profile;
    for (final grams in [-1.0, double.nan, double.infinity]) {
      expect(() => profile.portion(grams), throwsArgumentError);
    }
    expect(profile.portion(0).kcal, 0);
    expect(profile.portion(0.25).kcal, closeTo(1.685, 1e-12));
  });

  test('damaged stored nutrient values are rejected before aggregation', () {
    final json = nutritionDatabase.first.profile.toJson();
    for (final value in [-1, double.infinity, double.nan, 'bad']) {
      expect(
        () => NutritionProfile.fromJson({...json, 'kcal': value}),
        throwsFormatException,
      );
      expect(
        () => NutritionProfile.fromJson({
          ...json,
          'vitamins': {'C': value},
        }),
        throwsFormatException,
      );
    }
    expect(
      NutritionProfile.fromJson(json).portion(150.5).kcal,
      closeTo(1014.37, 1e-9),
    );
  });

  test('portion scales macros and micronutrients from 100 g', () {
    final source = nutritionDatabase.first.profile;
    final portion = source.portion(250);

    expect(portion.kcal, closeTo(1685, 0.001));
    expect(portion.protein, closeTo(20.5, 0.001));
    expect(portion.vitamins['B12, кобаламин (мкг)'], closeTo(1.825, 0.0001));
    expect(portion.minerals['Селен Se (мкг)'], closeTo(16.5, 0.0001));
    expect(portion.omega3, closeTo(2.675, 0.0001));
    expect(portion.cholesterol, closeTo(247.5, 0.0001));
  });

  test('profiles aggregate named micronutrients', () {
    const first = NutritionProfile(
      kcal: 100,
      protein: 10,
      fat: 2,
      carbs: 5,
      vitamins: {'C (мг)': 10},
      minerals: {'Mg (мг)': 40},
    );
    const second = NutritionProfile(
      kcal: 50,
      protein: 5,
      fat: 1,
      carbs: 3,
      vitamins: {'C (мг)': 4},
      minerals: {'Mg (мг)': 15, 'Zn (мг)': 1},
    );

    final total = first + second;
    expect(total.kcal, 150);
    expect(total.protein, 15);
    expect(total.vitamins['C (мг)'], 14);
    expect(total.minerals['Mg (мг)'], 55);
    expect(total.minerals['Zn (мг)'], 1);
  });

  test('source-linked seed matches the referenced product card', () {
    final item = nutritionDatabase.first;
    expect(item.id, 'healthdiet_17523');
    expect(item.profile.kcal, 674);
    expect(item.profile.protein, 8.2);
    expect(item.profile.fat, 70.9);
    expect(item.profile.vitamins['B12, кобаламин (мкг)'], 0.73);
    expect(item.profile.minerals['Селен Se (мкг)'], 6.6);
  });
}
