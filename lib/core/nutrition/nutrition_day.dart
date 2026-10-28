import 'nutrition_database.dart';
import '../models/nutrition_profile.dart';

class NutritionDayEntry {
  final NutritionFoodRecord food;
  final double grams;

  const NutritionDayEntry({required this.food, required this.grams});

  NutritionProfile get profile => food.profile.portion(grams);
}

class NutritionDay {
  final List<NutritionDayEntry> entries;

  const NutritionDay({this.entries = const []});

  NutritionProfile get total => entries.fold(
    const NutritionProfile(kcal: 0, protein: 0, fat: 0, carbs: 0),
    (sum, entry) => sum + entry.profile,
  );

  NutritionDay add(NutritionFoodRecord food, double grams) => NutritionDay(
    entries: [
      ...entries,
      NutritionDayEntry(food: food, grams: grams),
    ],
  );

  NutritionDay removeAt(int index) {
    final copy = [...entries]..removeAt(index);
    return NutritionDay(entries: copy);
  }
}

class NutritionCatalog {
  const NutritionCatalog({this.records = nutritionDatabase});
  final List<NutritionFoodRecord> records;

  List<NutritionFoodRecord> search(String query) {
    String normalize(String value) => value.toLowerCase().replaceAll('ё', 'е');
    final q = normalize(query).trim();
    if (q.isEmpty) return records;
    final words = q.split(RegExp(r'[\s,;/()]+')).where((w) => w.isNotEmpty);
    return records
        .where((food) {
          final text = normalize('${food.name} ${food.source} ${food.id}');
          // Require every word: never discard an unmatched cooking state or
          // silently select a source on the user's behalf.
          return words.every(text.contains);
        })
        .toList(growable: false);
  }
}
