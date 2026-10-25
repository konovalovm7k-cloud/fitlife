import 'nutrition_profile.dart';

class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.kcal,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.fiber,
    this.nutrition,
    this.isPhotoEstimate = false,
    this.isTextEstimate = false,
  });
  final String id;
  final String name;
  final double kcal;
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;
  final NutritionProfile? nutrition;
  final bool isPhotoEstimate;
  final bool isTextEstimate;
  NutritionProfile get profile =>
      nutrition ??
      NutritionProfile(
        kcal: kcal,
        protein: protein,
        fat: fat,
        carbs: carbs,
        fiber: fiber,
      );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'kcal': kcal,
    'protein': protein,
    'fat': fat,
    'carbs': carbs,
    'fiber': fiber,
    if (nutrition != null) 'nutrition': nutrition!.toJson(),
    if (isPhotoEstimate) 'photoEstimate': true,
    if (isTextEstimate) 'textEstimate': true,
  };
  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
    id: _requiredString(json['id']),
    name: _requiredString(json['name']),
    kcal: _storedNumber(json['kcal']),
    protein: _storedNumber(json['protein']),
    fat: _storedNumber(json['fat']),
    carbs: _storedNumber(json['carbs']),
    fiber: _storedNumber(json['fiber']),
    isPhotoEstimate: json['photoEstimate'] == true,
    isTextEstimate: json['textEstimate'] == true,
    nutrition: json['nutrition'] == null
        ? null
        : NutritionProfile.fromJson(
            Map<String, dynamic>.from(json['nutrition'] as Map),
          ),
  );
}

class DiaryItem {
  const DiaryItem({
    required this.id,
    required this.meal,
    required this.food,
    required this.grams,
    required this.time,
  });
  final String id;
  final String meal;
  final FoodItem food;
  final double grams;
  final String time;
  double get kcal => food.kcal * grams / 100;
  double get protein => food.protein * grams / 100;
  double get fat => food.fat * grams / 100;
  double get carbs => food.carbs * grams / 100;
  double get fiber => food.fiber * grams / 100;
  Map<String, dynamic> toJson() => {
    'id': id,
    'meal': meal,
    'food': food.toJson(),
    'grams': grams,
    'time': time,
  };
  factory DiaryItem.fromJson(Map<String, dynamic> json) => DiaryItem(
    id: _requiredString(json['id']),
    meal: _requiredString(json['meal']),
    food: FoodItem.fromJson(Map<String, dynamic>.from(json['food'] as Map)),
    grams: _storedNumber(json['grams'], positive: true),
    time: _requiredString(json['time']),
  );
}

String _requiredString(dynamic value) {
  if (value is! String || value.trim().isEmpty) {
    throw const FormatException('Missing record text');
  }
  return value;
}

double _storedNumber(dynamic value, {bool positive = false}) {
  if (value is! num || !value.isFinite || (positive ? value <= 0 : value < 0)) {
    throw const FormatException('Invalid nutrition value');
  }
  return value.toDouble();
}
