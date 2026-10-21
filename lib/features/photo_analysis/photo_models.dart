import '../../core/models/nutrition_profile.dart';

const photoMeals = ['Завтрак', 'Обед', 'Ужин', 'Перекус'];

class PhotoFood {
  const PhotoFood({
    required this.name,
    required this.grams,
    required this.nutrition,
    required this.confidence,
  });
  final String name;
  final double grams;
  final NutritionProfile nutrition;
  final String confidence;
  double get calories => nutrition.kcal * grams / 100;

  factory PhotoFood.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final confidence = json['confidence'];
    if (name is! String ||
        name.trim().isEmpty ||
        name.length > 80 ||
        RegExp(r'[\x00-\x1f]').hasMatch(name) ||
        !['low', 'medium', 'high'].contains(confidence)) {
      throw const FormatException('Invalid food text');
    }
    double value(String key, double min, double max) {
      final n = json[key];
      if (n is! num || !n.isFinite || n < min || n > max) {
        throw const FormatException('Invalid food value');
      }
      return n.toDouble();
    }

    final p = NutritionProfile(
      kcal: value('kcal', 0, 1000),
      protein: value('protein', 0, 100),
      fat: value('fat', 0, 100),
      carbs: value('carbs', 0, 100),
      fiber: value('fiber', 0, 100),
    );
    if (p.protein + p.fat + p.carbs > 105) {
      throw const FormatException('Invalid nutrient sum');
    }
    return PhotoFood(
      name: name.trim(),
      grams: value('grams', 1, 3000),
      nutrition: p,
      confidence: confidence as String,
    );
  }
}

class PhotoAnalysis {
  const PhotoAnalysis({
    required this.requestId,
    required this.items,
    required this.warnings,
  });
  final String requestId;
  final List<PhotoFood> items;
  final List<String> warnings;

  factory PhotoAnalysis.fromJson(Map<String, dynamic> json, String requestId) {
    final items = json['items'];
    final warnings = json['warnings'];
    if (json['version'] != 1 ||
        json['requestId'] != requestId ||
        items is! List ||
        items.length > 12 ||
        warnings is! List ||
        warnings.length > 5 ||
        warnings.any(
          (w) =>
              w is! String ||
              w.trim().isEmpty ||
              w.length > 240 ||
              RegExp(r'[\x00-\x1f]').hasMatch(w),
        )) {
      throw const FormatException('Invalid analysis');
    }
    return PhotoAnalysis(
      requestId: requestId,
      items: items
          .map((e) => PhotoFood.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      warnings: warnings.cast<String>(),
    );
  }
}

class PhotoMeal {
  const PhotoMeal({
    required this.id,
    required this.day,
    required this.meal,
    required this.items,
  });
  final String id;
  final DateTime day;
  final String meal;
  final List<PhotoFood> items;
}
