import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/nutrition_profile.dart';
import 'nutrition_database.dart';

/// Only an authorized export belongs in this asset; no runtime site scraping.
Future<List<NutritionFoodRecord>> loadAdditionalFoods() async =>
    parseFoodCatalog(
      await rootBundle.loadString('assets/data/food_catalog.json'),
    );

List<NutritionFoodRecord> parseFoodCatalog(String text) {
  final data = jsonDecode(text) as Map<String, dynamic>;
  if (data['schema'] != 1 || data['basis_grams'] != 100) {
    throw const FormatException('Unsupported catalogue or portion basis');
  }
  final source = data['source'] as String;
  final ids = <String>{};
  final output = <NutritionFoodRecord>[];
  for (final raw in data['foods'] as List) {
    final row = Map<String, dynamic>.from(raw as Map);
    final id = row['id'] as String;
    final name = row['name'] as String;
    final url = Uri.parse(row['source_url'] as String);
    if (id.trim().isEmpty ||
        name.trim().isEmpty ||
        source.trim().isEmpty ||
        !ids.add(id) ||
        url.scheme != 'https' ||
        url.host.isEmpty ||
        url.userInfo.isNotEmpty) {
      throw const FormatException('Invalid catalogue identity');
    }
    double value(String key) {
      final number = row[key];
      if (number is! num ||
          !number.isFinite ||
          number < 0 ||
          number > (key == 'kcal' ? 950 : 100)) {
        throw const FormatException('Invalid nutrition per 100 g');
      }
      return number.toDouble();
    }

    final kcal = value('kcal');
    final protein = value('protein');
    final fat = value('fat');
    final carbs = value('carbs');
    if (protein + fat + carbs > 105 ||
        (kcal == 0 && protein + fat + carbs > 0)) {
      throw const FormatException('Inconsistent nutrition');
    }
    output.add(
      NutritionFoodRecord(
        id: 'imported_$id',
        name: name,
        source: source,
        sourceUrl: url.toString(),
        macrosOnly: true,
        profile: NutritionProfile(
          kcal: kcal,
          protein: protein,
          fat: fat,
          carbs: carbs,
        ),
      ),
    );
  }
  return List.unmodifiable(output);
}
