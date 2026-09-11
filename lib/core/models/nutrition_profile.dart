/// Full nutritional profile stored per 100 g of edible product.
///
/// Mirrors the structure shown by health-diet.ru: macros, vitamins,
/// minerals, amino acids, fatty acids and cholesterol.
class NutritionProfile {
  final double kcal;
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;
  final double water;
  final double ash;
  final Map<String, double> vitamins;
  final Map<String, double> minerals;
  final Map<String, double> aminoAcids;
  final Map<String, double> fattyAcids;
  final double? omega3;
  final double? omega6;
  final double? cholesterol;

  const NutritionProfile({
    required this.kcal,
    required this.protein,
    required this.fat,
    required this.carbs,
    this.fiber = 0,
    this.water = 0,
    this.ash = 0,
    this.vitamins = const {},
    this.minerals = const {},
    this.aminoAcids = const {},
    this.fattyAcids = const {},
    this.omega3,
    this.omega6,
    this.cholesterol,
  });

  NutritionProfile portion(double grams) {
    final factor = grams / 100;
    Map<String, double> scaleMap(Map<String, double> source) =>
        source.map((key, value) => MapEntry(key, value * factor));

    return NutritionProfile(
      kcal: kcal * factor,
      protein: protein * factor,
      fat: fat * factor,
      carbs: carbs * factor,
      fiber: fiber * factor,
      water: water * factor,
      ash: ash * factor,
      vitamins: scaleMap(vitamins),
      minerals: scaleMap(minerals),
      aminoAcids: scaleMap(aminoAcids),
      fattyAcids: scaleMap(fattyAcids),
      omega3: omega3 == null ? null : omega3! * factor,
      omega6: omega6 == null ? null : omega6! * factor,
      cholesterol: cholesterol == null ? null : cholesterol! * factor,
    );
  }

  NutritionProfile operator +(NutritionProfile other) {
    Map<String, double> addMaps(Map<String, double> a, Map<String, double> b) {
      final result = <String, double>{...a};
      for (final entry in b.entries) {
        result[entry.key] = (result[entry.key] ?? 0) + entry.value;
      }
      return result;
    }

    double? addNullable(double? a, double? b) =>
        a == null && b == null ? null : (a ?? 0) + (b ?? 0);

    return NutritionProfile(
      kcal: kcal + other.kcal,
      protein: protein + other.protein,
      fat: fat + other.fat,
      carbs: carbs + other.carbs,
      fiber: fiber + other.fiber,
      water: water + other.water,
      ash: ash + other.ash,
      vitamins: addMaps(vitamins, other.vitamins),
      minerals: addMaps(minerals, other.minerals),
      aminoAcids: addMaps(aminoAcids, other.aminoAcids),
      fattyAcids: addMaps(fattyAcids, other.fattyAcids),
      omega3: addNullable(omega3, other.omega3),
      omega6: addNullable(omega6, other.omega6),
      cholesterol: addNullable(cholesterol, other.cholesterol),
    );
  }

  Map<String, dynamic> toJson() => {
        'kcal': kcal,
        'protein': protein,
        'fat': fat,
        'carbs': carbs,
        'fiber': fiber,
        'water': water,
        'ash': ash,
        'vitamins': vitamins,
        'minerals': minerals,
        'aminoAcids': aminoAcids,
        'fattyAcids': fattyAcids,
        'omega3': omega3,
        'omega6': omega6,
        'cholesterol': cholesterol,
      };

  factory NutritionProfile.fromJson(Map<String, dynamic> json) {
    Map<String, double> readMap(String key) {
      final value = json[key];
      if (value is! Map) return const {};
      return value.map(
        (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
      );
    }

    double? readNullable(String key) => (json[key] as num?)?.toDouble();

    return NutritionProfile(
      kcal: (json['kcal'] as num?)?.toDouble() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      fiber: (json['fiber'] as num?)?.toDouble() ?? 0,
      water: (json['water'] as num?)?.toDouble() ?? 0,
      ash: (json['ash'] as num?)?.toDouble() ?? 0,
      vitamins: readMap('vitamins'),
      minerals: readMap('minerals'),
      aminoAcids: readMap('aminoAcids'),
      fattyAcids: readMap('fattyAcids'),
      omega3: readNullable('omega3'),
      omega6: readNullable('omega6'),
      cholesterol: readNullable('cholesterol'),
    );
  }
}
