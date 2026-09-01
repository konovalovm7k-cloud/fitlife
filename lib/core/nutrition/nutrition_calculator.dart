import 'dart:math' as math;

class NutritionGoals {
  final int calories;
  final int protein;
  final int fat;
  final int carbs;

  const NutritionGoals({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
  });
}

/// Pure business logic for FitLife calorie and macro targets.
/// Keeping this outside widgets makes the calculation easy to test and reuse.
class NutritionCalculator {
  const NutritionCalculator();

  NutritionGoals calculate({
    required double weight,
    required int height,
    required int age,
    required String sex,
    required double activity,
    double deficit = 450,
  }) {
    final bmr = sex == 'Мужской'
        ? 10 * weight + 6.25 * height - 5 * age + 5
        : 10 * weight + 6.25 * height - 5 * age - 161;

    final calories = math.max(1200, (bmr * activity - deficit).round());
    final protein = math.max(90, (weight * 1.6).round());
    final fat = math.max(35, (calories * 0.30 / 9).round());
    final carbs = math.max(
      80,
      ((calories - protein * 4 - fat * 9) / 4).round(),
    );

    return NutritionGoals(
      calories: calories,
      protein: protein,
      fat: fat,
      carbs: carbs,
    );
  }
}
