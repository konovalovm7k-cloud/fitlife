import 'dart:convert';
import 'package:flutter/services.dart';
import '../../core/nutrition/food_catalog_import.dart';
import '../../core/nutrition/nutrition_database.dart';
import '../../core/nutrition/nutrition_engine.dart';
import '../photo_analysis/photo_models.dart';

const chefCatalogueVersion = 'cofid-2021-ready-v1';
const chefWarningText = {
  'check_portions': 'AI предложил массу. Проверьте свою порцию.',
  'check_labels':
      'Проверьте состав и аллергены на упаковках. Масло и соусы добавьте отдельно.',
  'no_match': 'Для этих продуктов в справочнике не нашлось готового сочетания.',
  'pantry_unclear':
      'Уточните продукты и их состояние: сырые или уже приготовленные.',
};

Future<ChefCatalogue> loadChefCatalogue() async => ChefCatalogue.parse(
  await rootBundle.loadString('shared/chef_catalogue.json'),
  await loadAdditionalFoods(),
);

class ChefCatalogue {
  ChefCatalogue._(this._sources);
  final Map<String, NutritionSource> _sources;

  factory ChefCatalogue.parse(String text, List<NutritionFoodRecord> records) {
    final data = jsonDecode(text) as Map<String, dynamic>;
    if (data['version'] != chefCatalogueVersion ||
        data['foods'] is! List ||
        (data['foods'] as List).length != 18) {
      throw const FormatException('Unsupported Chef catalogue');
    }
    final sources = <String, NutritionSource>{};
    for (final raw in data['foods'] as List) {
      final row = Map<String, dynamic>.from(raw as Map);
      final id = row['recordId'];
      final name = row['name'];
      if (id is! String ||
          name is! String ||
          sources.containsKey(id) ||
          !RegExp(r'^imported_cofid_2021_\d{2}-\d{3}$').hasMatch(id) ||
          id.endsWith('11-857') ||
          id.endsWith('11-788')) {
        throw const FormatException('Invalid Chef identity');
      }
      final matches = records
          .where((r) => r.id == id && r.name == name)
          .toList();
      if (matches.length != 1) {
        throw const FormatException('Missing local Chef source');
      }
      final source = NutritionSource.catalogue(matches.single);
      NutritionEngine.portion(source, 100);
      sources[id] = source;
    }
    return ChefCatalogue._(Map.unmodifiable(sources));
  }

  PhotoAnalysis resolve(Map<String, dynamic> data, String requestId) {
    final items = data['items'];
    final warnings = data['warnings'];
    if (data['version'] != 1 ||
        data['kind'] != 'chef' ||
        data['catalogueVersion'] != chefCatalogueVersion ||
        data['requestId'] != requestId ||
        !RegExp(r'^[a-f0-9]{32}$').hasMatch(requestId) ||
        items is! List ||
        items.length > 12 ||
        warnings is! List ||
        warnings.length > 4 ||
        warnings.any((w) => !chefWarningText.containsKey(w))) {
      throw const FormatException('Invalid Chef contract');
    }
    final seen = <String>{};
    var mass = 0.0;
    final foods = <PhotoFood>[];
    for (final raw in items) {
      final row = Map<String, dynamic>.from(raw as Map);
      final id = row['recordId'];
      final grams = row['grams'];
      final source = _sources[id];
      if (id is! String ||
          source == null ||
          !seen.add(id) ||
          grams is! num ||
          !grams.isFinite ||
          grams < 1 ||
          grams > 3000) {
        throw const FormatException('Invalid Chef ingredient');
      }
      mass += grams;
      NutritionEngine.portion(source, grams.toDouble());
      foods.add(
        PhotoFood(
          name: source.name,
          grams: grams.toDouble(),
          confidence: 'low',
          source: source,
        ),
      );
    }
    if (mass > 3000 ||
        (foods.isNotEmpty && warnings.contains('no_match')) ||
        (foods.isEmpty &&
            !warnings.any((w) => w == 'no_match' || w == 'pantry_unclear'))) {
      throw const FormatException('Inconsistent Chef proposal');
    }
    return PhotoAnalysis(
      requestId: requestId,
      items: List.unmodifiable(foods),
      warnings: warnings.toSet().map((w) => chefWarningText[w]!).toList(),
      source: MealEstimateSource.chef,
    );
  }
}
