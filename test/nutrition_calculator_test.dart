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

    expect(goals.calories, 2256);
    expect(goals.protein, 148);
    expect(goals.fat, 75);
    expect(goals.carbs, 247.25);
  });

  test('uses female BMR formula', () {
    final goals = calculator.calculate(
      weight: 70,
      height: 165,
      age: 30,
      sex: 'Женский',
      activity: 1.2,
    );

    expect(goals.calories, 1254);
    expect(goals.protein, 112);
  });

  test('preserves the existing calorie lower bound', () {
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

  test('low calorie calculation no longer invents an 80 gram carb minimum', () {
    final goals = calculator.calculate(
      weight: 100,
      height: 100,
      age: 100,
      sex: 'Мужской',
      activity: 1,
      deficit: 450,
    );
    expect(goals.calories, 1200);
    expect(goals.protein, 160);
    expect(goals.fat, 40);
    expect(goals.carbs, 50);
    expect(goals.protein * 4 + goals.fat * 9 + goals.carbs * 4, 1200);
  });

  test(
    'incompatible energy budget and excessive calorie output fail explicitly',
    () {
      expect(
        () => calculator.calculate(
          weight: 200,
          height: 100,
          age: 120,
          sex: 'Мужской',
          activity: 1,
          deficit: 2000,
        ),
        throwsFormatException,
      );
      expect(
        () => calculator.calculate(
          weight: 300,
          height: 250,
          age: 18,
          sex: 'Мужской',
          activity: 3,
          deficit: -2000,
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'invalid measurements cannot silently select a formula or default result',
    () {
      for (final changes in <Map<String, dynamic>>[
        {'weight': double.nan},
        {'weight': double.infinity},
        {'weight': 29.99},
        {'weight': 300.01},
        {'height': 99},
        {'height': 251},
        {'age': 17},
        {'age': 121},
        {'sex': ''},
        {'sex': 'unknown'},
        {'activity': double.nan},
        {'activity': double.infinity},
        {'activity': 0.99},
        {'activity': 3.01},
        {'deficit': double.nan},
        {'deficit': double.infinity},
        {'deficit': -2001.0},
        {'deficit': 2001.0},
      ]) {
        final args = <String, dynamic>{
          'weight': 70.0,
          'height': 175,
          'age': 35,
          'sex': 'Мужской',
          'activity': 1.2,
          'deficit': 450.0,
          ...changes,
        };
        expect(
          () => calculator.calculate(
            weight: args['weight'],
            height: args['height'],
            age: args['age'],
            sex: args['sex'],
            activity: args['activity'],
            deficit: args['deficit'],
          ),
          throwsFormatException,
          reason: '$changes',
        );
      }
    },
  );

  test('adult scenario grid always reconciles calories with macro energy', () {
    for (final weight in [45.0, 70.0, 100.0, 150.0]) {
      for (final height in [150, 175, 200]) {
        for (final age in [18, 40, 80]) {
          for (final sex in ['Мужской', 'Женский']) {
            for (final activity in [1.2, 1.45, 1.9, 2.5]) {
              for (final deficit in [0.0, 450.0]) {
                final goals = calculator.calculate(
                  weight: weight,
                  height: height,
                  age: age,
                  sex: sex,
                  activity: activity,
                  deficit: deficit,
                );
                expect(
                  goals.protein * 4 + goals.fat * 9 + goals.carbs * 4,
                  closeTo(goals.calories, 1e-8),
                );
                expect(goals.carbs, greaterThanOrEqualTo(0));
                expect(goals.toJson()['version'], 1);
              }
            }
          }
        }
      }
    }
  });
}
