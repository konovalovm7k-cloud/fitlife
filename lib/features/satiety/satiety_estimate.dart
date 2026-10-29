import '../../core/models/diary_item.dart';
import '../../core/nutrition/nutrition_engine.dart';

enum FoodStructure { solid, soft, liquid, mixed }

typedef SourcedSatietyPortion = ({NutritionSource source, double grams});

/// A bounded, deliberately uncalibrated food-property heuristic, NOT Holt's
/// measured Satiety Index. Versioned formula and limitations: SMART_SATIETY.md.
class SatietyEstimate {
  const SatietyEstimate({
    required this.low,
    required this.high,
    required this.grams,
    required this.kcal,
    required this.protein,
    required this.fiber,
    required this.water,
    required this.missing,
  });
  static const formulaVersion = 1;
  final int low;
  final int high;
  final double grams;
  final double kcal;
  final double protein;
  final double? fiber;
  final double? water;
  final List<String> missing;
  double get energyDensity => kcal / grams;

  static SatietyEstimate calculate(
    List<DiaryItem> items, {
    FoodStructure? structure,
  }) => fromPortions([
    for (final item in items)
      (source: _diarySource(item.food), grams: item.grams),
  ], structure: structure);

  static NutritionSource _diarySource(FoodItem food) {
    final provenance = food.provenance;
    if (provenance == null) {
      throw const FormatException('Confirm each food source first');
    }
    return NutritionSource(
      name: food.name,
      profile: food.profile,
      provenance: provenance,
      fiberKnown: food.hasKnownFiber,
    );
  }

  /// Evaluate attributed portions without creating or saving a diary record.
  /// The same aggregation and formula are used before and after diary save.
  static SatietyEstimate fromPortions(
    List<SourcedSatietyPortion> portions, {
    FoodStructure? structure,
  }) {
    if (portions.isEmpty) throw const FormatException('Empty meal');
    var mass = 0.0;
    var kcal = 0.0;
    var protein = 0.0;
    var fiber = 0.0;
    var water = 0.0;
    var fiberKnown = true;
    var waterKnown = true;
    for (final portion in portions) {
      final source = portion.source;
      final p = NutritionEngine.portion(source, portion.grams);
      if (!p.water.isFinite || p.water < 0 || p.water > portion.grams) {
        throw const FormatException('Invalid food water');
      }
      mass += portion.grams;
      kcal += p.kcal;
      protein += p.protein;
      fiber += p.fiber;
      // Label entry does not ask for water. A legacy/default zero is unknown.
      waterKnown &= source.provenance.kind == 'catalogue' && p.water > 0;
      fiberKnown &= source.fiberKnown;
      water += p.water;
    }
    if (!mass.isFinite || !kcal.isFinite || mass > 3000 || kcal <= 0) {
      throw const FormatException('Outside meal evaluation scope');
    }
    double unit(double n) => n.clamp(0.0, 1.0).toDouble();
    // Aggregate nutrients and edible mass BEFORE scoring: splitting a food
    // into several rows cannot increase its score. Drinking-water logs never
    // enter this function. Water here means water incorporated into the food.
    final known =
        .25 * unit(protein / 30) +
        .20 * unit(mass / 400) +
        .15 * unit((4 - kcal / mass) / 3.5);
    final fiberTerm = fiberKnown ? .15 * unit(fiber / 10) : 0.0;
    final waterTerm = waterKnown ? .10 * unit(water / mass) : 0.0;
    final texture = switch (structure) {
      FoodStructure.solid => 1.0,
      FoodStructure.soft => .6,
      FoodStructure.liquid => .2,
      FoodStructure.mixed => .7,
      null => 0.0,
    };
    final base = known + fiberTerm + waterTerm + .15 * texture;
    final unknown =
        (fiberKnown ? 0.0 : .15) +
        (waterKnown ? 0.0 : .10) +
        (structure == null ? .15 : 0.0);
    // Prevent a tiny bite or zero-energy water from looking like a full meal.
    // 200 kcal is a model saturation parameter, NEVER a recommended meal size.
    final energyGate = unit(kcal / 200);
    int score(double v) => (1 + 9 * energyGate * v).round().clamp(1, 10);
    return SatietyEstimate(
      low: score(base),
      high: score(base + unknown),
      grams: mass,
      kcal: kcal,
      protein: protein,
      fiber: fiberKnown ? fiber : null,
      water: waterKnown ? water : null,
      missing: List.unmodifiable([
        if (!fiberKnown) 'клетчатка',
        if (!waterKnown) 'вода в продукте',
        if (structure == null) 'структура пищи',
      ]),
    );
  }
}
