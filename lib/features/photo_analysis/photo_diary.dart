import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/diary_item.dart';
import '../../data/repositories/diary_preferences.dart';
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
  final prefs = await (preferencesLoader ?? SharedPreferences.getInstance)();
  final date =
      '${meal.day.year}-${meal.day.month.toString().padLeft(2, '0')}-${meal.day.day.toString().padLeft(2, '0')}';
  final key = 'diary_$date';
  await prefs.reload();
  final store = DiaryPreferences(prefs);
  final current = await store.readRecords(key, DiaryItem.fromJson);
  final entries = <DiaryItem>[];
  for (var i = 0; i < meal.items.length; i++) {
    final item = meal.items[i];
    final id = 'photo_${meal.id}_$i';
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
          isPhotoEstimate: true,
        ),
      ),
    );
  }
  final prefix = 'photo_${meal.id}_';
  final updated = [
    ...current.where((entry) => !entry.id.startsWith(prefix)),
    ...entries,
  ];
  // Replace the entire stable-ID batch on retry, including any edits/removals
  // after a failed write or a timeout whose disk operation completed late.
  final ok = await prefs.setString(
    key,
    jsonEncode(updated.map((item) => item.toJson()).toList()),
  );
  if (!ok) throw StateError('Could not save photo meal');
  return updated;
}
