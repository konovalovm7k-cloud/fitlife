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
        entries: [...entries, NutritionDayEntry(food: food, grams: grams)],
      );

  NutritionDay removeAt(int index) {
    final copy = [...entries]..removeAt(index);
    return NutritionDay(entries: copy);
  }
}

class NutritionCatalog {
  const NutritionCatalog();

  List<NutritionFoodRecord> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return nutritionDatabase;
    return nutritionDatabase
        .where((food) => food.name.toLowerCase().contains(q))
        .toList(growable: false);
  }
}
