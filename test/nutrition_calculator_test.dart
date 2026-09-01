import 'package:flutter_test/flutter_test.dart';
import 'package:fitlife/core/nutrition/nutrition_calculator.dart';

void main() {
  const calculator = NutritionCalculator();

  test('calculates male calorie and macro targets', () {
    final goals = calculator.calculate(
      weight: 92.4,
      height: 178,
      age: 35,
      sex: 'Мужской',
      activity: 1.45,
    );

    expect(goals.calories, 1815);
    expect(goals.protein, 148);
    expect(goals.fat, 61);
    expect(goals.carbs, 125);
  });

  test('uses female BMR formula', () {
    final goals = calculator.calculate(
      weight: 70,
      height: 165,
      age: 30,
      sex: 'Женский',
      activity: 1.2,
    );

    expect(goals.calories, 1200);
    expect(goals.protein, 112);
  });

  test('never returns calorie target below safety floor', () {
    final goals = calculator.calculate(
      weight: 45,
      height: 150,
      age: 80,
      sex: 'Женский',
      activity: 1.2,
    );

    expect(goals.calories, 1200);
    expect(goals.fat, greaterThanOrEqualTo(35));
    expect(goals.carbs, greaterThanOrEqualTo(80));
  });
}
