/// Reference daily nutrient targets used by the nutrition analysis UI.
/// Values are generic adult reference values, not medical advice.
class NutritionTargets {
  static const Map<String, double> vitamins = {
    'A': 900, 'B1': 1.2, 'B2': 1.3, 'B5': 5.0, 'B6': 1.3, 'B9': 400,
    'B12': 2.4, 'C': 90, 'D': 15, 'E': 15, 'K': 120, 'PP': 16,
    'H': 50, 'Холин': 550,
  };
  static const Map<String, double> minerals = {
    'K': 3500, 'Ca': 1000, 'Mg': 400, 'Na': 2300, 'P': 700, 'Cl': 2300,
    'Fe': 8, 'I': 150, 'Zn': 11, 'Cu': 0.9, 'Mn': 2.3, 'Se': 55,
    'Cr': 35, 'Mo': 45, 'F': 4,
  };
  static double? vitamin(String key) => vitamins[key.trim()];
  static double? mineral(String key) => minerals[key.trim()];
  static double percent(double amount, double? target) => target == null || target <= 0 ? 0 : amount / target * 100;
}
