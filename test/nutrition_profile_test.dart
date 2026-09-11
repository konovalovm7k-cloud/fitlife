import 'package:flutter_test/flutter_test.dart';
import 'package:fitlife/core/models/nutrition_profile.dart';
import 'package:fitlife/core/nutrition/nutrition_database.dart';

void main() {
  test('portion scales macros and micronutrients from 100 g', () {
    final source = nutritionDatabase.single.profile;
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
    final item = nutritionDatabase.single;
    expect(item.id, 'healthdiet_17523');
    expect(item.profile.kcal, 674);
    expect(item.profile.protein, 8.2);
    expect(item.profile.fat, 70.9);
    expect(item.profile.vitamins['B12, кобаламин (мкг)'], 0.73);
    expect(item.profile.minerals['Селен Se (мкг)'], 6.6);
  });
}
