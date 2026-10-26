import '../../core/models/nutrition_profile.dart';
import '../../core/nutrition/nutrition_engine.dart';

const photoMeals = ['Завтрак', 'Обед', 'Ужин', 'Перекус'];

enum MealEstimateSource { photo, text, manual }

const identificationWarnings = {
  'uncertain_portion': 'Уточните массу порции.',
  'hidden_ingredients': 'Проверьте масло, соусы и скрытые ингредиенты.',
  'ambiguous_food': 'Проверьте, какой именно продукт распознан.',
  'preparation_unknown':
      'Уточните состояние продукта: сырой или приготовленный.',
  'no_food': 'Еда не распознана. Можно добавить продукт вручную.',
};

class PhotoFood {
  const PhotoFood({
    required this.name,
    required this.grams,
    required this.confidence,
    this.source,
  });
  final String name;
  final double grams;
  final String confidence;
  final NutritionSource? source;
  NutritionProfile? get nutrition => source?.profile;
  NutritionProfile? get portion =>
      source == null ? null : NutritionEngine.portion(source!, grams);
  double? get calories => portion?.kcal;

  /// A server response can identify food, but can never confirm its nutrients.
  factory PhotoFood.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final confidence = json['confidence'];
    final grams = json['grams'];
    if (name is! String ||
        name.trim().isEmpty ||
        name.length > 80 ||
        RegExp(r'[\x00-\x1f]').hasMatch(name) ||
        !['low', 'medium', 'high'].contains(confidence) ||
        grams is! num ||
        !grams.isFinite ||
        grams < 1 ||
        grams > 3000) {
      throw const FormatException('Invalid food identity');
    }
    return PhotoFood(
      name: name.trim(),
      grams: grams.toDouble(),
      confidence: confidence as String,
    );
  }
}

class PhotoAnalysis {
  const PhotoAnalysis({
    required this.requestId,
    required this.items,
    required this.warnings,
    this.source = MealEstimateSource.photo,
  });
  final String requestId;
  final List<PhotoFood> items;
  final List<String> warnings;
  final MealEstimateSource source;
  factory PhotoAnalysis.fromJson(
    Map<String, dynamic> json,
    String requestId, {
    MealEstimateSource source = MealEstimateSource.photo,
  }) {
    final items = json['items'];
    final warnings = json['warnings'];
    if (json['version'] != 2 ||
        json['requestId'] != requestId ||
        items is! List ||
        items.length > 12 ||
        warnings is! List ||
        warnings.length > 5 ||
        warnings.any((w) => !identificationWarnings.containsKey(w))) {
      throw const FormatException('Invalid identification contract');
    }
    return PhotoAnalysis(
      requestId: requestId,
      items: List.unmodifiable(
        items.map(
          (e) => PhotoFood.fromJson(Map<String, dynamic>.from(e as Map)),
        ),
      ),
      warnings: List.unmodifiable(
        warnings.map((w) => identificationWarnings[w]!),
      ),
      source: source,
    );
  }
}

class PhotoMeal {
  const PhotoMeal({
    required this.id,
    required this.day,
    required this.meal,
    required this.items,
    this.source = MealEstimateSource.photo,
  });
  final String id;
  final DateTime day;
  final String meal;
  final List<PhotoFood> items;
  final MealEstimateSource source;
}
