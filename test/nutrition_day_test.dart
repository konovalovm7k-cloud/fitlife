import 'package:flutter_test/flutter_test.dart';

import 'package:fitlife/core/models/nutrition_profile.dart';
import 'package:fitlife/core/nutrition/nutrition_database.dart';
import 'package:fitlife/core/nutrition/nutrition_day.dart';

void main() {
  test('portion scales all nutrition values', () {
    const profile = NutritionProfile(
      kcal: 100,
      protein: 20,
      fat: 5,
      carbs: 10,
      fiber: 2,
      vitamins: {'C (мг)': 10},
      minerals: {'Mg (мг)': 20},
      omega3: 1,
    );

    final p = profile.portion(250);
    expect(p.kcal, 250);
    expect(p.protein, 50);
    expect(p.fiber, 5);
    expect(p.vitamins['C (мг)'], 25);
    expect(p.minerals['Mg (мг)'], 50);
    expect(p.omega3, 2.5);
  });

  test('daily total combines portions from different foods', () {
    final day = NutritionDay()
        .add(nutritionDatabase.first, 100)
        .add(nutritionDatabase.first, 50);

    expect(day.total.kcal, closeTo(1011, 0.0001));
    expect(day.total.protein, closeTo(12.3, 0.0001));
    expect(day.total.fat, closeTo(106.35, 0.0001));
    expect(day.total.vitamins['B12, кобаламин (мкг)'], closeTo(1.095, 0.0001));
  });

  test('catalog search is case insensitive and returns all on empty query', () {
    const catalog = NutritionCatalog();
    expect(catalog.search('жир').single.name, 'Жир говяжий, сырой');
    expect(catalog.search('ЖИР').single.name, 'Жир говяжий, сырой');
    expect(catalog.search('').length, nutritionDatabase.length);
  });
}
