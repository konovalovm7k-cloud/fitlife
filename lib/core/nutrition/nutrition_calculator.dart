import 'dart:math' as math;
import '../models/nutrition_goal_settings.dart';

// Compatibility name; calculated and manually edited goals use one model.
typedef NutritionGoals = NutritionGoalSettings;

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
    _range(weight, 30, 300, 'Вес, кг');
    _range(height, 100, 250, 'Рост, см');
    _range(age, 18, 120, 'Возраст');
    _range(activity, 1, 3, 'Коэффициент активности');
    _range(deficit, -2000, 2000, 'Дефицит, ккал');
    if (sex != 'Мужской' && sex != 'Женский') {
      throw const FormatException('Выбери пол для формулы расчёта.');
    }
    final bmr = sex == 'Мужской'
        ? 10 * weight + 6.25 * height - 5 * age + 5
        : 10 * weight + 6.25 * height - 5 * age - 161;

    final calories = math.max(1200, (bmr * activity - deficit).round());
    final protein = math.max(90, (weight * 1.6).round());
    final fat = math.max(35, (calories * 0.30 / 9).round());
    final goals = NutritionGoals(
      calories: calories.toDouble(),
      protein: protein.toDouble(),
      fat: fat.toDouble(),
    );
    goals.validate();
    return goals;
  }

  void _range(num value, num minimum, num maximum, String name) {
    if (!value.isFinite || value < minimum || value > maximum) {
      throw FormatException('$name: введи число от $minimum до $maximum.');
    }
  }
}
