import 'dart:convert';
import 'package:fitlife/core/models/diary_item.dart';

import 'package:fitlife/core/models/nutrition_goal_settings.dart';
import 'package:fitlife/data/repositories/diary_repository.dart';
import 'package:fitlife/data/repositories/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'diary_repository_test.dart' show entry;
import 'support/settings_disk.dart';

void main() {
  late SettingsDisk disk;
  late SharedPreferences prefs;
  late SettingsRepository repo;
  const today = '2026-10-21';
  const yesterday = '2026-10-20';
  const changed = NutritionGoalSettings(
    calories: 2400,
    protein: 160,
    fat: 70,
    fiber: 35,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    disk = SettingsDisk();
    SharedPreferencesStorePlatform.instance = disk;
    prefs = await SharedPreferences.getInstance();
    repo = SettingsRepository(prefs);
  });

  test(
    'legacy goals migrate together once and old keys are retained',
    () async {
      await prefs.setDouble('goal_calories', 2200);
      await prefs.setDouble('goal_protein', 140);
      final loaded = await repo.load(today, todayKey: today);
      expect(loaded.goals.calories, 2200);
      expect(loaded.goals.protein, 140);
      expect(prefs.getDouble('goal_calories'), 2200);
      await repo.saveGoals(changed);
      await prefs.reload();
      expect(
        (await repo.load(today, todayKey: today)).goals.toJson(),
        changed.toJson(),
      );
      expect(
        disk.writes.where((key) => key == SettingsRepository.goalsKey).length,
        2,
      );
    },
  );

  test(
    'failed or thrown goal write preserves the entire old snapshot and allows retry',
    () async {
      await repo.load(today, todayKey: today);
      final old = prefs.getString(SettingsRepository.goalsKey);
      for (final throws in [false, true]) {
        if (throws) {
          disk.throwKey = SettingsRepository.goalsKey;
        } else {
          disk.failedKeys.add(SettingsRepository.goalsKey);
        }
        await expectLater(repo.saveGoals(changed), throwsStateError);
        expect(prefs.getString(SettingsRepository.goalsKey), old);
        await prefs.reload();
        expect(prefs.getString(SettingsRepository.goalsKey), old);
        disk.throwKey = null;
        disk.failedKeys.clear();
      }
      await repo.saveGoals(changed);
      expect(
        (await repo.load(today, todayKey: today)).goals.toJson(),
        changed.toJson(),
      );
    },
  );

  test(
    'water migration commits its marker only after water and retries without doubling',
    () async {
      await prefs.setDouble('water', 1.5);
      disk.failedKeys.add('water_$today');
      await expectLater(
        repo.load(yesterday, todayKey: today),
        throwsStateError,
      );
      expect(prefs.containsKey('water_migrated'), isFalse);
      expect(prefs.containsKey('water_$today'), isFalse);
      disk.failedKeys.clear();
      disk.failedKeys.add('water_migrated');
      await expectLater(
        repo.load(yesterday, todayKey: today),
        throwsStateError,
      );
      expect(prefs.getDouble('water_$today'), 1.5);
      expect(prefs.containsKey('water_migrated'), isFalse);
      disk.failedKeys.clear();
      final loaded = await repo.load(yesterday, todayKey: today);
      expect(loaded.water, 0);
      expect(prefs.getDouble('water_$today'), 1.5);
      expect(prefs.getBool('water_migrated'), isTrue);
      expect(prefs.containsKey('water_$yesterday'), isFalse);
      expect(prefs.getDouble('water'), 1.5);
    },
  );

  test(
    'concurrent water, favorites, diary and food writes retain every update',
    () async {
      await repo.load(today, todayKey: today);
      await Future.wait([
        repo.addWater(today, 0.25),
        repo.addWater(today, 0.25),
        repo.addWater(yesterday, 0.25),
        repo.setFavorite('egg', true),
        repo.setFavorite('rice', true),
        repo.upsertFood(entry('a').food),
        repo.upsertFood(
          FoodItem.fromJson({...entry('b').food.toJson(), 'id': 'other'}),
        ),
        DiaryRepository(prefs).upsert('diary_$today', entry('diary')),
      ]);
      final saved = await repo.load(today, todayKey: today);
      expect(saved.water, 0.5);
      expect(prefs.getDouble('water_$yesterday'), 0.25);
      expect(saved.favorites, ['egg', 'rice']);
      expect(saved.foods.map((food) => food.id), ['rice', 'other']);
      await repo.upsertFood(entry('a').food);
      expect((await repo.load(today, todayKey: today)).foods.length, 2);
      expect(saved.diary.single.id, 'diary');
    },
  );

  test(
    'false favorite, food, water and weight writes leave persisted values unchanged',
    () async {
      await repo.load(today, todayKey: today);
      final operations = <String, Future<dynamic> Function()>{
        'favorites': () => repo.setFavorite('egg', true),
        'custom_foods': () => repo.upsertFood(entry('a').food),
        'water_$today': () => repo.addWater(today, 0.25),
        'weight': () => repo.saveWeight(99.5),
      };
      for (final item in operations.entries) {
        final before = prefs.get(item.key);
        disk.failedKeys.add(item.key);
        await expectLater(item.value(), throwsStateError);
        expect(prefs.get(item.key), before);
        disk.failedKeys.clear();
        await item.value();
      }
      expect((await repo.load(today, todayKey: today)).water, 0.25);
    },
  );

  test(
    'recent failure cannot change favorites or erase a committed diary',
    () async {
      await repo.setFavorite('egg', true);
      await DiaryRepository(prefs).upsert('diary_$today', entry('meal'));
      disk.failedKeys.add('recent');
      await expectLater(repo.rememberFood('rice'), throwsStateError);
      expect(prefs.getStringList('favorites'), ['egg']);
      expect(
        (jsonDecode(prefs.getString('diary_$today')!) as List).single['id'],
        'meal',
      );
      disk.failedKeys.clear();
      await repo.rememberFood('rice');
      await repo.rememberFood('rice');
      expect(prefs.getStringList('recent'), ['rice']);
    },
  );

  test(
    'damaged goals retain each distinct recovery source and refuse unsafe overwrite',
    () async {
      await prefs.setString(SettingsRepository.goalsKey, '{broken');
      disk.failedKeys.add('recovery_${SettingsRepository.goalsKey}');
      await expectLater(repo.load(today, todayKey: today), throwsStateError);
      expect(prefs.getString(SettingsRepository.goalsKey), '{broken');
      disk.failedKeys.clear();
      expect((await repo.load(today, todayKey: today)).recoveredData, isTrue);
      await prefs.setString(SettingsRepository.goalsKey, '{broken-again');
      await repo.load(today, todayKey: today);
      expect(
        prefs.getString('recovery_${SettingsRepository.goalsKey}'),
        '{broken',
      );
      expect(
        prefs.getString('recovery_${SettingsRepository.goalsKey}_1'),
        '{broken-again',
      );
    },
  );

  test(
    'non-finite legacy values are preserved without breaking JSON recovery',
    () async {
      await prefs.setDouble('goal_protein', double.nan);
      await prefs.setDouble('water', double.infinity);
      final loaded = await repo.load(today, todayKey: today);
      expect(loaded.goals.calories, 1900);
      expect(loaded.water, 0);
      expect(loaded.recoveredData, isTrue);
      expect(
        prefs.getString('recovery_legacy_nutrition_goals'),
        contains('NaN'),
      );
      expect(prefs.getString('recovery_water'), contains('Infinity'));
    },
  );

  test(
    'goal validation rejects invalid ranges and inconsistent macro energy',
    () async {
      for (final goals in [
        const NutritionGoalSettings(calories: 1000),
        const NutritionGoalSettings(calories: double.infinity),
        const NutritionGoalSettings(fiber: -1),
        const NutritionGoalSettings(protein: 1001),
      ]) {
        await expectLater(repo.saveGoals(goals), throwsFormatException);
      }
      expect(prefs.containsKey(SettingsRepository.goalsKey), isFalse);
      await repo.saveGoals(changed);
    },
  );
}
