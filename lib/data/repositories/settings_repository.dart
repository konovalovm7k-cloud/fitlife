import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/diary_item.dart';
import '../../core/models/nutrition_goal_settings.dart';
import 'diary_preferences.dart';
import '../../features/progress/weight_history.dart';
import 'preferences_queue.dart';

class SavedSettings {
  const SavedSettings({
    required this.diary,
    required this.foods,
    required this.favorites,
    required this.recent,
    required this.goals,
    required this.water,
    required this.weight,
    required this.recoveredData,
  });
  final List<DiaryItem> diary;
  final List<FoodItem> foods;
  final List<String> favorites;
  final List<String> recent;
  final NutritionGoalSettings goals;
  final double water;
  final double? weight;
  final bool recoveredData;
}

class SettingsRepository {
  SettingsRepository(this.preferences);
  final SharedPreferences preferences;
  static const goalsKey = 'nutrition_goals_v1';

  Future<SavedSettings> load(
    String dayKey, {
    required String todayKey,
  }) => PreferencesQueue.run(preferences, () async {
    final store = DiaryPreferences(preferences);
    final diary = await store.readRecords('diary_$dayKey', DiaryItem.fromJson);
    final foods = await store.readRecords('custom_foods', FoodItem.fromJson);
    final favorites = await store.readStringList('favorites');
    final recent = await store.readStringList('recent');
    final goals = await _readGoals(store);
    if (preferences.get('water_migrated') != true) {
      // An undated legacy value belongs to today, even when opening history.
      if (!preferences.containsKey('water_$todayKey')) {
        final legacy = await _number(store, 'water', 0, allowZero: true);
        await PreferencesQueue.checked(
          preferences.setDouble('water_$todayKey', legacy),
        );
      }
      await PreferencesQueue.checked(
        preferences.setBool('water_migrated', true),
      );
    }
    final water = await _number(store, 'water_$dayKey', 0, allowZero: true);
    final weights = await WeightHistory.read(store);
    final weight = weights.latest;
    return SavedSettings(
      diary: diary,
      foods: foods,
      favorites: favorites,
      recent: recent,
      goals: goals,
      water: water,
      weight: weight,
      recoveredData: store.recoveredData,
    );
  });

  Future<NutritionGoalSettings> _readGoals(DiaryPreferences store) async {
    final raw = preferences.get(goalsKey);
    if (raw != null) {
      try {
        return NutritionGoalSettings.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw as String) as Map),
        );
      } catch (_) {
        await store.preserveValue(goalsKey, raw);
        return const NutritionGoalSettings();
      }
    }
    const defaults = NutritionGoalSettings();
    final legacy = <String, Object?>{
      for (final key in [
        'goal_calories',
        'goal_protein',
        'goal_fat',
        'goal_fiber',
      ])
        key: preferences.get(key),
    };
    double number(String key, double fallback) {
      final value = legacy[key];
      if (value == null) return fallback;
      if (value is! num) throw const FormatException('Invalid legacy goal');
      return value.toDouble();
    }

    NutritionGoalSettings goals;
    try {
      goals = NutritionGoalSettings(
        calories: number('goal_calories', defaults.calories),
        protein: number('goal_protein', defaults.protein),
        fat: number('goal_fat', defaults.fat),
        fiber: number('goal_fiber', defaults.fiber),
      );
      goals.validate();
    } catch (_) {
      await store.preserveValue('legacy_nutrition_goals', legacy);
      goals = defaults;
    }
    await PreferencesQueue.checked(
      preferences.setString(goalsKey, jsonEncode(goals.toJson())),
    );
    return goals;
  }

  Future<double> _number(
    DiaryPreferences store,
    String key,
    double fallback, {
    bool allowZero = false,
  }) async {
    final raw = preferences.get(key);
    if (raw == null) return fallback;
    if (raw is num && raw.isFinite && (allowZero ? raw >= 0 : raw > 0)) {
      return raw.toDouble();
    }
    await store.preserveValue(key, raw);
    return fallback;
  }

  Future<void> saveGoals(NutritionGoalSettings goals) =>
      PreferencesQueue.run(preferences, () async {
        goals.validate();
        // All related goals become visible together through this one value.
        await PreferencesQueue.checked(
          preferences.setString(goalsKey, jsonEncode(goals.toJson())),
        );
      });

  Future<double> addWater(String dayKey, double amount) =>
      PreferencesQueue.run(preferences, () async {
        if (!amount.isFinite || amount <= 0) throw ArgumentError.value(amount);
        final current = await _number(
          DiaryPreferences(preferences),
          'water_$dayKey',
          0,
          allowZero: true,
        );
        final next = current + amount;
        if (!next.isFinite) throw ArgumentError.value(next);
        await PreferencesQueue.checked(
          preferences.setDouble('water_$dayKey', next),
        );
        return next;
      });

  Future<void> saveWeight(double weight) =>
      PreferencesQueue.run(preferences, () async {
        if (!weight.isFinite || weight < 30 || weight > 300) {
          throw ArgumentError.value(weight);
        }
        await PreferencesQueue.checked(preferences.setDouble('weight', weight));
      });

  Future<List<String>> setFavorite(String id, bool selected) =>
      PreferencesQueue.run(preferences, () async {
        if (id.isEmpty) throw ArgumentError.value(id);
        final current = await DiaryPreferences(
          preferences,
        ).readStringList('favorites');
        final updated = {...current}..remove(id);
        if (selected) updated.add(id);
        await PreferencesQueue.checked(
          preferences.setStringList('favorites', updated.toList()),
        );
        return updated.toList();
      });

  Future<List<String>> rememberFood(String id) =>
      PreferencesQueue.run(preferences, () async {
        final current = await DiaryPreferences(
          preferences,
        ).readStringList('recent');
        final updated = [
          id,
          ...current.where((item) => item != id),
        ].take(10).toList();
        await PreferencesQueue.checked(
          preferences.setStringList('recent', updated),
        );
        return updated;
      });

  Future<List<FoodItem>> upsertFood(FoodItem food) =>
      PreferencesQueue.run(preferences, () async {
        FoodItem.fromJson(food.toJson());
        final current = await DiaryPreferences(
          preferences,
        ).readRecords('custom_foods', FoodItem.fromJson);
        final index = current.indexWhere((item) => item.id == food.id);
        final updated = [...current];
        if (index < 0) {
          updated.add(food);
        } else {
          updated[index] = food;
        }
        await PreferencesQueue.checked(
          preferences.setString(
            'custom_foods',
            jsonEncode(updated.map((item) => item.toJson()).toList()),
          ),
        );
        return updated;
      });
}
