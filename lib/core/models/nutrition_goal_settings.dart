class NutritionGoalSettings {
  static const minValue = 1.0;
  static const maxCalories = 10000.0;
  static const maxGrams = 1000.0;
  static const proteinEnergyFactor = 4.0;
  static const fatEnergyFactor = 9.0;
  static const carbEnergyFactor = 4.0;
  // Only accommodates binary floating-point noise, in kcal.
  static const energyTolerance = 1e-8;
  const NutritionGoalSettings({
    this.calories = 1900,
    this.protein = 180,
    this.fat = 65,
    this.fiber = 30,
  });

  final double calories;
  final double protein;
  final double fat;
  final double fiber;

  double get proteinFatCalories =>
      protein * proteinEnergyFactor + fat * fatEnergyFactor;

  /// Carbs consume the remaining goal energy; they are never rounded in storage.
  double get carbs {
    validate();
    final remaining = calories - proteinFatCalories;
    return remaining < 0 ? 0 : remaining / carbEnergyFactor;
  }

  double get macroCalories => proteinFatCalories + carbs * carbEnergyFactor;

  String? get validationError {
    final values = [calories, protein, fat, fiber];
    final maxima = [maxCalories, maxGrams, maxGrams, maxGrams];
    const names = ['Калории', 'Белок', 'Жиры', 'Клетчатка'];
    for (var i = 0; i < values.length; i++) {
      if (!values[i].isFinite ||
          values[i] < minValue ||
          values[i] > maxima[i]) {
        return '${names[i]}: введи число от 1 до ${maxima[i].round()}.';
      }
    }
    if (proteinFatCalories - calories > energyTolerance) {
      return 'Калории из белков и жиров превышают дневную цель.';
    }
    return null;
  }

  void validate() {
    final error = validationError;
    if (error != null) throw FormatException(error);
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'calories': calories,
    'protein': protein,
    'fat': fat,
    'fiber': fiber,
  };

  factory NutritionGoalSettings.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) {
      throw const FormatException('Unsupported nutrition goal version');
    }
    double number(String key) {
      final value = json[key];
      if (value is! num) throw const FormatException('Missing nutrition goal');
      return value.toDouble();
    }

    final goals = NutritionGoalSettings(
      calories: number('calories'),
      protein: number('protein'),
      fat: number('fat'),
      fiber: number('fiber'),
    );
    goals.validate();
    return goals;
  }
}
