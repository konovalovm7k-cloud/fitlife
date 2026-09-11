/// Reference daily nutrient targets used for the day-analysis UI.
///
/// Values are generic adult reference targets, not medical prescriptions.
class NutritionTargets {
  const NutritionTargets._();

  static const vitamins = <String, double>{
    'A (мкг)': 900,
    'бета-каротин (мг)': 7,
    'B1, тиамин (мг)': 1.2,
    'B2, рибофлавин (мг)': 1.3,
    'Холин (мг)': 550,
    'B5, пантотеновая кислота (мг)': 5,
    'B6, пиридоксин (мг)': 1.3,
    'B9, фолаты (мкг)': 400,
    'B12, кобаламин (мкг)': 2.4,
    'C (мг)': 90,
    'D (мкг)': 15,
    'E (мг)': 15,
    'H, биотин (мкг)': 50,
    'K (мкг)': 120,
    'PP, ниацин (мг)': 16,
  };

  static const minerals = <String, double>{
    'Калий K (мг)': 3500,
    'Кальций Ca (мг)': 1000,
    'Кремний Si (мг)': 20,
    'Магний Mg (мг)': 400,
    'Натрий Na (мг)': 2300,
    'Фосфор P (мг)': 700,
    'Хлор Cl (мг)': 2300,
    'Железо Fe (мг)': 8,
    'Йод I (мкг)': 150,
    'Кобальт Co (мкг)': 5,
    'Марганец Mn (мг)': 2.3,
    'Медь Cu (мкг)': 900,
    'Молибден Mo (мкг)': 45,
    'Селен Se (мкг)': 55,
    'Фтор F (мг)': 4,
    'Хром Cr (мкг)': 35,
    'Цинк Zn (мг)': 11,
  };

  static double? forVitamin(String key) => _find(vitamins, key);
  static double? forMineral(String key) => _find(minerals, key);

  static double? _find(Map<String, double> targets, String key) {
    final exact = targets[key];
    if (exact != null) return exact;
    final normalized = _normalize(key);
    for (final entry in targets.entries) {
      if (_normalize(entry.key) == normalized) return entry.value;
    }
    return null;
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll('ё', 'е')
      .replaceAll(RegExp(r'[^a-zа-я0-9]+'), '');
}
