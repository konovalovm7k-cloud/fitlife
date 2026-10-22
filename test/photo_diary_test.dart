import 'dart:convert';
import 'package:fitlife/features/photo_analysis/photo_diary.dart';
import 'package:fitlife/features/photo_analysis/photo_models.dart';
import 'package:fitlife/modern_app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'photo_service_test.dart' show sampleFood;

class FailingPhotoDisk extends InMemorySharedPreferencesStore {
  FailingPhotoDisk() : super.empty();
  bool fail = true;
  int writes = 0;
  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    writes++;
    return fail ? false : super.setValue(valueType, key, value);
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'confirmed photo batch preserves old entries, date and idempotent retry',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final old = DiaryItem(
        id: 'old',
        meal: 'Завтрак',
        food: builtInFoods.first,
        grams: 100,
        time: '09:00',
      );
      await prefs.setString('diary_2026-10-20', jsonEncode([old.toJson()]));
      final meal = PhotoMeal(
        id: 'a' * 32,
        day: DateTime(2026, 10, 20),
        meal: 'Обед',
        items: [
          PhotoFood.fromJson(sampleFood),
          PhotoFood.fromJson({...sampleFood, 'name': 'Салат', 'grams': 50}),
        ],
      );
      final saved = await savePhotoMeal(meal);
      expect(saved.length, 3);
      expect(saved.first.id, 'old');
      expect(saved[1].kcal, 195);
      expect(saved[1].food.isPhotoEstimate, isTrue);
      expect((await savePhotoMeal(meal)).length, 3);
      final corrected = PhotoMeal(
        id: meal.id,
        day: meal.day,
        meal: meal.meal,
        items: [
          PhotoFood.fromJson({...sampleFood, 'grams': 200}),
        ],
      );
      final replaced = await savePhotoMeal(corrected);
      expect(replaced.length, 2);
      expect(replaced.last.grams, 200);
      final stored = (jsonDecode(prefs.getString('diary_2026-10-20')!) as List)
          .map((j) => DiaryItem.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
      expect(stored[1].food.isPhotoEstimate, isTrue);
      expect(prefs.containsKey('custom_foods'), isFalse);
      expect(prefs.containsKey('diary_2026-10-21'), isFalse);
    },
  );
  test('storage failure propagates and an empty batch is rejected', () async {
    final meal = PhotoMeal(
      id: 'a' * 32,
      day: DateTime(2026),
      meal: 'Обед',
      items: [PhotoFood.fromJson(sampleFood)],
    );
    await expectLater(
      savePhotoMeal(
        meal,
        preferencesLoader: () async => throw StateError('disk'),
      ),
      throwsStateError,
    );
    await expectLater(
      savePhotoMeal(
        PhotoMeal(id: meal.id, day: meal.day, meal: meal.meal, items: []),
      ),
      throwsFormatException,
    );
  });
  test(
    'text estimates retain their source after reload and retry without photo labels',
    () async {
      final meal = PhotoMeal(
        id: 'c' * 32,
        day: DateTime(2026, 10, 22),
        meal: 'Обед',
        source: MealEstimateSource.text,
        items: [PhotoFood.fromJson(sampleFood)],
      );
      await savePhotoMeal(meal);
      final saved = await savePhotoMeal(meal);
      expect(saved.length, 1);
      expect(saved.single.id, startsWith('text_'));
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonDecode(prefs.getString('diary_2026-10-22')!) as List;
      final restored = DiaryItem.fromJson(
        Map<String, dynamic>.from(raw.single as Map),
      );
      expect(restored.food.isTextEstimate, isTrue);
      expect(restored.food.isPhotoEstimate, isFalse);
      expect(restored.kcal, 195);
    },
  );
  test(
    'false disk write retries real storage despite cached entries without duplicates',
    () async {
      final disk = FailingPhotoDisk();
      SharedPreferencesStorePlatform.instance = disk;
      final meal = PhotoMeal(
        id: 'b' * 32,
        day: DateTime(2026, 10, 20),
        meal: 'Обед',
        items: [PhotoFood.fromJson(sampleFood)],
      );
      await expectLater(savePhotoMeal(meal), throwsStateError);
      expect(disk.writes, 1);
      disk.fail = false;
      expect((await savePhotoMeal(meal)).length, 1);
      expect(disk.writes, 2);
      final raw = (await disk.getAll())['flutter.diary_2026-10-20']! as String;
      expect((jsonDecode(raw) as List).length, 1);
    },
  );
}
