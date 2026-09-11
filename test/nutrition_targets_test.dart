import 'package:flutter_test/flutter_test.dart';
import 'package:fitlife/core/nutrition/nutrition_targets.dart';

void main() {
  test('resolves reference targets by exact key', () {
    expect(NutritionTargets.forVitamin('C (мг)'), 90);
    expect(NutritionTargets.forMineral('Калий K (мг)'), 3500);
    expect(NutritionTargets.forMineral('Селен Se (мкг)'), 55);
  });

  test('resolves keys with normalized spelling', () {
    expect(NutritionTargets.forVitamin('C (МГ)'), 90);
    expect(NutritionTargets.forMineral('Калий K (мг)'), 3500);
  });

  test('returns null for nutrients without a configured reference', () {
    expect(NutritionTargets.forVitamin('Неизвестный витамин'), isNull);
    expect(NutritionTargets.forMineral('Неизвестный минерал'), isNull);
  });
}
