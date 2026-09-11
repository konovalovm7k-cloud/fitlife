import 'nutrition_profile.dart';

class Food {
  final String name;
  final int kcal;
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;
  final NutritionProfile? nutrition;

  const Food({
    required this.name,
    required this.kcal,
    required this.protein,
    required this.fat,
    required this.carbs,
    this.fiber = 0,
    this.nutrition,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      name: json['name'] as String? ?? '',
      kcal: (json['kcal'] as num?)?.round() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      fiber: (json['fiber'] as num?)?.toDouble() ?? 0,
      nutrition: json['nutrition'] is Map
          ? NutritionProfile.fromJson(
              Map<String, dynamic>.from(json['nutrition'] as Map),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'kcal': kcal,
        'protein': protein,
        'fat': fat,
        'carbs': carbs,
        'fiber': fiber,
        if (nutrition != null) 'nutrition': nutrition!.toJson(),
      };
}
