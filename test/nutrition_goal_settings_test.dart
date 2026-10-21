import 'package:fitlife/core/models/nutrition_goal_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'default and fractional goals balance energy without rounding carbs',
    () {
      const initial = NutritionGoalSettings();
      expect(initial.carbs, 148.75);
      expect(initial.macroCalories, 1900);
      const fractional = NutritionGoalSettings(
        calories: 2400.5,
        protein: 160.25,
        fat: 70.5,
        fiber: 35.25,
      );
      expect(fractional.carbs, 281.25);
      expect(fractional.macroCalories, 2400.5);
    },
  );

  test('zero remaining energy is a valid zero carb target', () {
    const goals = NutritionGoalSettings(
      calories: 13,
      protein: 1,
      fat: 1,
      fiber: 1,
    );
    expect(goals.validationError, isNull);
    expect(goals.carbs, 0);
    expect(goals.macroCalories, 13);
  });

  test('decimal binary noise does not reject a balanced goal', () {
    const goals = NutritionGoalSettings(calories: 23.3, protein: 1.1, fat: 2.1);
    expect(goals.proteinFatCalories, greaterThan(goals.calories));
    expect(goals.validationError, isNull);
    expect(goals.carbs, 0);
    expect(goals.macroCalories, closeTo(23.3, 1e-8));
  });

  test(
    'meaningful excess is rejected rather than clamped to a false balance',
    () {
      const goals = NutritionGoalSettings(
        calories: 26.399,
        protein: 2.1,
        fat: 2,
      );
      expect(goals.validationError, contains('превышают'));
      expect(goals.validate, throwsFormatException);
      expect(() => goals.carbs, throwsFormatException);
    },
  );

  test('each editable field rejects non-finite and out of range values', () {
    for (var field = 0; field < 4; field++) {
      for (final invalid in [
        double.nan,
        double.infinity,
        double.negativeInfinity,
        -1.0,
        0.0,
        0.999,
        field == 0 ? 10000.01 : 1000.01,
      ]) {
        final values = [1900.0, 180.0, 65.0, 30.0];
        values[field] = invalid;
        final goals = NutritionGoalSettings(
          calories: values[0],
          protein: values[1],
          fat: values[2],
          fiber: values[3],
        );
        expect(
          goals.validate,
          throwsFormatException,
          reason: '$field: $invalid',
        );
      }
    }
  });

  test('existing range boundaries remain accepted', () {
    for (final goals in [
      const NutritionGoalSettings(
        calories: 10000,
        protein: 1,
        fat: 1,
        fiber: 1000,
      ),
      const NutritionGoalSettings(calories: 10000, protein: 1000, fat: 1),
      const NutritionGoalSettings(calories: 10000, protein: 1, fat: 1000),
    ]) {
      expect(goals.validationError, isNull);
      expect(goals.macroCalories, closeTo(goals.calories, 1e-8));
    }
  });

  test(
    'version 1 snapshot round trip preserves decimals and derives carbs',
    () {
      const goals = NutritionGoalSettings(
        calories: 2400.123456,
        protein: 160.123456,
        fat: 70.123456,
        fiber: 35.123456,
      );
      final json = goals.toJson();
      expect(json.containsKey('carbs'), isFalse);
      final restored = NutritionGoalSettings.fromJson({
        ...json,
        'carbs': 99999,
      });
      expect(restored.toJson(), json);
      expect(restored.carbs, goals.carbs);
      expect(restored.macroCalories, closeTo(goals.calories, 1e-8));
    },
  );
}
