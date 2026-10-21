class NutritionGoalSettings {
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

  void validate() {
    final values = [calories, protein, fat, fiber];
    final maxima = [10000, 1000, 1000, 1000];
    for (var i = 0; i < values.length; i++) {
      if (!values[i].isFinite || values[i] < 1 || values[i] > maxima[i]) {
        throw const FormatException('Invalid nutrition goal');
      }
    }
    if (protein * 4 + fat * 9 > calories) {
      throw const FormatException('Macros exceed calorie goal');
    }
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
