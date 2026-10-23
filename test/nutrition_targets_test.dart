import 'package:flutter_test/flutter_test.dart';
import 'package:fitlife/core/nutrition/nutrition_targets.dart';

void main() {
  test('converts reference targets into the units used by source labels', () {
    expect(NutritionTargets.forMineral('Медь Cu (мкг)'), 900);
    expect(
      NutritionTargets.forMineral('Селен Se (мг)'),
      closeTo(0.055, 0.000001),
    );
    expect(NutritionTargets.forVitamin('D (мг)'), closeTo(0.015, 0.000001));
    expect(
      NutritionTargets.percent(
        28,
        NutritionTargets.forMineral('Медь Cu (мкг)'),
      ),
      closeTo(3.1111, 0.0001),
    );
  });
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
