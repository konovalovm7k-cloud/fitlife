/// Reference daily nutrient targets used by the nutrition analysis UI.
/// Values are generic adult reference values, not medical advice.
class NutritionTargets {
  static const Map<String, double> vitamins = {
    'A': 900,
    'B1': 1.2,
    'B2': 1.3,
    'B5': 5.0,
    'B6': 1.3,
    'B9': 400,
    'B12': 2.4,
    'C': 90,
    'D': 15,
    'E': 15,
    'K': 120,
    'PP': 16,
    'H': 50,
    'Холин': 550,
  };

  static const Map<String, double> minerals = {
    'K': 3500,
    'Ca': 1000,
    'Mg': 400,
    'Na': 2300,
    'P': 700,
    'Cl': 2300,
    'Fe': 8,
    'I': 150,
    'Zn': 11,
    'Cu': 0.9,
    'Mn': 2.3,
    'Se': 55,
    'Cr': 35,
    'Mo': 45,
    'F': 4,
  };

  static String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll('ё', 'е');

  static double? _resolve(
    Map<String, double> targets,
    String key,
    Set<String> micrograms,
  ) {
    final normalized = _normalize(key);
    double inLabelUnits(String reference, double value) {
      final isMicrograms = micrograms.contains(reference);
      if (normalized.endsWith('(мкг)') && !isMicrograms) return value * 1000;
      if (normalized.endsWith('(мг)') && isMicrograms) return value / 1000;
      return value;
    }

    final direct = targets.entries.where(
      (entry) => _normalize(entry.key) == normalized,
    );
    if (direct.isNotEmpty) {
      return inLabelUnits(direct.first.key, direct.first.value);
    }

    // Database labels contain units and, for minerals, Russian names:
    // e.g. "C (мг)", "B12 (мкг)", "Калий K (мг)".
    for (final entry in targets.entries) {
      final token = _normalize(entry.key);
      if (normalized == token ||
          normalized.startsWith('$token ') ||
          normalized.startsWith('$token(')) {
        return inLabelUnits(entry.key, entry.value);
      }
    }

    const aliases = <String, String>{
      'калий': 'K',
      'кальций': 'Ca',
      'магний': 'Mg',
      'натрий': 'Na',
      'фосфор': 'P',
      'хлор': 'Cl',
      'железо': 'Fe',
      'йод': 'I',
      'цинк': 'Zn',
      'медь': 'Cu',
      'марганец': 'Mn',
      'селен': 'Se',
      'хром': 'Cr',
      'молибден': 'Mo',
      'фтор': 'F',
      'тиамин': 'B1',
      'рибофлавин': 'B2',
      'холин': 'Холин',
    };

    for (final alias in aliases.entries) {
      if (normalized.startsWith(alias.key)) {
        final target = targets[alias.value];
        return target == null ? null : inLabelUnits(alias.value, target);
      }
    }
    return null;
  }

  static double? vitamin(String key) =>
      _resolve(vitamins, key, const {'A', 'B9', 'B12', 'D', 'K', 'H'});
  static double? mineral(String key) =>
      _resolve(minerals, key, const {'I', 'Se', 'Cr', 'Mo'});
  static double? forVitamin(String key) => vitamin(key);
  static double? forMineral(String key) => mineral(key);

  static double percent(double amount, double? target) =>
      target == null || target <= 0 ? 0 : amount / target * 100;
}
