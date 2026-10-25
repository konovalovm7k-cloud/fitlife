import 'dart:convert';

import '../../core/models/diary_item.dart';
import '../../data/repositories/diary_repository.dart';

const savedMealsKey = 'saved_meals_v1';
const mealNames = ['Завтрак', 'Обед', 'Ужин', 'Перекус'];

/// Ingredient snapshots retain source nutrients and AI estimate markers.
class SavedMeal {
  SavedMeal({
    required this.id,
    required this.name,
    required List<DiaryItem> items,
    this.servings = 1,
  }) : items = List.unmodifiable(items);

  final String id;
  final String name;
  final List<DiaryItem> items;
  final double servings;
  double total(double Function(DiaryItem) value) =>
      items.fold(0.0, (sum, item) => sum + value(item)) / servings;
  bool get estimated => items.any(
    (item) => item.food.isPhotoEstimate || item.food.isTextEstimate,
  );

  void validate() {
    if (id.trim().isEmpty ||
        name.trim().isEmpty ||
        name.length > 80 ||
        items.isEmpty ||
        items.length > 100 ||
        !servings.isFinite ||
        servings < 0.1 ||
        servings > 100) {
      throw const FormatException('Invalid saved meal');
    }
    for (final item in items) {
      DiaryItem.fromJson(item.toJson());
      if (item.grams > 100000) throw const FormatException('Invalid portion');
    }
    for (final value in [
      total((i) => i.kcal),
      total((i) => i.protein),
      total((i) => i.fat),
      total((i) => i.carbs),
      total((i) => i.fiber),
      total((i) => i.grams),
    ]) {
      if (!value.isFinite) throw const FormatException('Non-finite meal total');
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'servings': servings,
    'items': items.map((item) => item.toJson()).toList(),
  };

  factory SavedMeal.fromJson(Map<String, dynamic> json) {
    final result = SavedMeal(
      id: json['id'] as String,
      name: json['name'] as String,
      servings: (json['servings'] as num).toDouble(),
      items: (json['items'] as List)
          .map(
            (item) =>
                DiaryItem.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
    result.validate();
    return result;
  }

  List<DiaryItem> entries({
    required String operationId,
    required String meal,
    required double portions,
    required String time,
  }) {
    validate();
    if (operationId.isEmpty ||
        !mealNames.contains(meal) ||
        !portions.isFinite ||
        portions < 0.1 ||
        portions > 20) {
      throw const FormatException('Invalid meal portion');
    }
    return [
      for (var i = 0; i < items.length; i++)
        DiaryItem(
          id: 'saved_${operationId}_$i',
          meal: meal,
          food: items[i].food,
          grams: items[i].grams * portions / servings,
          time: time,
        ),
    ];
  }
}

class SavedMealsRepository {
  SavedMealsRepository(this.diary);
  final DiaryRepository diary;

  Future<({List<SavedMeal> meals, bool recovered})> load() => diary.run((
    store,
  ) async {
    final meals = await store.readRecords(savedMealsKey, SavedMeal.fromJson);
    return (meals: meals, recovered: store.recoveredData);
  });

  Future<void> save(SavedMeal meal) => diary.run((store) async {
    meal.validate();
    final current = await store.readRecords(savedMealsKey, SavedMeal.fromJson);
    await store.writeString(
      savedMealsKey,
      jsonEncode([
        for (final item in current)
          if (item.id != meal.id) item.toJson(),
        meal.toJson(),
      ]),
    );
  });

  Future<void> delete(String id) => diary.run((store) async {
    final current = await store.readRecords(savedMealsKey, SavedMeal.fromJson);
    await store.writeString(
      savedMealsKey,
      jsonEncode([
        for (final item in current)
          if (item.id != id) item.toJson(),
      ]),
    );
  });

  Future<({List<SavedMeal> meals, bool recovered})> previousDay(
    DateTime target,
  ) => diary.run((store) async {
    final previous = DateTime(target.year, target.month, target.day - 1);
    final items = await store.readRecords(
      'diary_${diaryDateKey(previous)}',
      DiaryItem.fromJson,
    );
    final groups = <String, List<DiaryItem>>{};
    for (final item in items) {
      groups.putIfAbsent(item.meal, () => []).add(item);
    }
    return (
      meals: [
        for (final entry in groups.entries)
          SavedMeal(
            id: '${diaryDateKey(previous)}_${entry.key}',
            name: entry.key,
            items: entry.value,
          ),
      ],
      recovered: store.recoveredData,
    );
  });

  Future<List<DiaryItem>> add({
    required SavedMeal recipe,
    required DateTime day,
    required String meal,
    required double portions,
    required String operationId,
    required String time,
  }) {
    final batch = recipe.entries(
      operationId: operationId,
      meal: meal,
      portions: portions,
      time: time,
    );
    final prefix = 'saved_${operationId}_';
    return diary.updateDay(
      day,
      (current) => [
        ...current.where((item) => !item.id.startsWith(prefix)),
        ...batch,
      ],
    );
  }
}
