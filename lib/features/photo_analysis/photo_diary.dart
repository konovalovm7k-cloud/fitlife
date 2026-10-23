import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/diary_item.dart';
import '../../data/repositories/diary_repository.dart';
import 'photo_models.dart';

Future<List<DiaryItem>> savePhotoMeal(
  PhotoMeal meal, {
  Future<SharedPreferences> Function()? preferencesLoader,
}) async {
  if (!RegExp(r'^[a-f0-9]{32}$').hasMatch(meal.id) ||
      meal.items.isEmpty ||
      meal.items.length > 12 ||
      !photoMeals.contains(meal.meal)) {
    throw const FormatException('Invalid photo meal');
  }
  final entries = <DiaryItem>[];
  final kind = meal.source == MealEstimateSource.text ? 'text' : 'photo';
  for (var i = 0; i < meal.items.length; i++) {
    final item = meal.items[i];
    final id = '${kind}_${meal.id}_$i';
    final p = item.nutrition;
    entries.add(
      DiaryItem(
        id: id,
        meal: meal.meal,
        grams: item.grams,
        time:
            '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        food: FoodItem(
          id: id,
          name: item.name,
          kcal: p.kcal,
          protein: p.protein,
          fat: p.fat,
          carbs: p.carbs,
          fiber: p.fiber,
          isPhotoEstimate: meal.source == MealEstimateSource.photo,
          isTextEstimate: meal.source == MealEstimateSource.text,
        ),
      ),
    );
  }
  final prefix = '${kind}_${meal.id}_';
  // Replace the entire stable-ID batch on retry, including any edits/removals
  // after a failed write or a timeout whose disk operation completed late.
  return DiaryRepository(preferencesLoader: preferencesLoader).updateDay(
    meal.day,
    (current) => [
      ...current.where((entry) => !entry.id.startsWith(prefix)),
      ...entries,
    ],
  );
}
