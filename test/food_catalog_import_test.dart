import 'dart:convert';
import 'package:fitlife/core/nutrition/food_catalog_import.dart';
import 'package:fitlife/core/nutrition/nutrition_day.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> data() => {
    'schema': 1,
    'basis_grams': 100,
    'source': 'Authorized test fixture',
    'foods': [
      {
        'id': 'a',
        'name': 'Мёд тестовый',
        'kcal': 320,
        'protein': 1,
        'fat': 0,
        'carbs': 79,
        'source_url': 'https://example.com/food/a',
      },
    ],
  };
  test(
    'authorized data has explicit source and missing detailed nutrients',
    () {
      final records = parseFoodCatalog(jsonEncode(data()));
      expect(records.single.macrosOnly, isTrue);
      expect(records.single.sourceUrl, 'https://example.com/food/a');
      expect(NutritionCatalog(records: records).search('мед'), hasLength(1));
      expect(records.single.profile.portion(25).kcal, 80);
    },
  );
  test(
    'wrong basis, duplicate identifiers and invalid nutrients reject the whole import',
    () {
      expect(
        () => parseFoodCatalog(jsonEncode(data()..['basis_grams'] = 1)),
        throwsFormatException,
      );
      final duplicate = data();
      (duplicate['foods'] as List).add((duplicate['foods'] as List).single);
      expect(
        () => parseFoodCatalog(jsonEncode(duplicate)),
        throwsFormatException,
      );
      final invalid = data();
      (invalid['foods'] as List).single['fat'] = -10;
      expect(
        () => parseFoodCatalog(jsonEncode(invalid)),
        throwsFormatException,
      );
    },
  );
}
