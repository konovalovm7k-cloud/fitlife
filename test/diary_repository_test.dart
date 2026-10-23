import 'dart:async';
import 'dart:convert';

import 'package:fitlife/data/repositories/diary_repository.dart';
import 'package:fitlife/features/photo_analysis/photo_diary.dart';
import 'package:fitlife/features/photo_analysis/photo_models.dart';
import 'package:fitlife/modern_app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'photo_service_test.dart' show sampleFood;

class ControlledDisk extends InMemorySharedPreferencesStore {
  ControlledDisk() : super.empty();
  String? failKey;
  String? pauseKey;
  Completer<void>? pause;
  bool throwOnFailure = false;
  final writes = <String>[];
  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    writes.add(key);
    if (key == pauseKey) {
      pauseKey = null;
      await pause!.future;
    }
    if (key == failKey) {
      if (throwOnFailure) throw StateError('Native disk failed');
      return false;
    }
    return super.setValue(valueType, key, value);
  }
}

DiaryItem entry(String id, {double grams = 100}) => DiaryItem(
  id: id,
  meal: 'Обед',
  food: builtInFoods.first,
  grams: grams,
  time: '12:00',
);

void main() {
  final date = DateTime(2026, 10, 23);
  const key = 'flutter.diary_2026-10-23';
  late ControlledDisk disk;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    disk = ControlledDisk();
    SharedPreferencesStorePlatform.instance = disk;
  });
  test(
    'separate repository instances serialize concurrent read-modify-write',
    () async {
      final a = DiaryRepository();
      final b = DiaryRepository();
      await Future.wait(
        List.generate(
          20,
          (i) => (i.isEven ? a : b).upsert(date, entry('id$i')),
        ),
      );
      final saved = jsonDecode((await disk.getAll())[key]! as String) as List;
      expect(saved.length, 20);
      expect(saved.map((value) => value['id']).toSet().length, 20);
    },
  );
  test(
    'photo and text batches cannot overwrite concurrent manual entries',
    () async {
      final repository = DiaryRepository();
      await Future.wait([
        repository.upsert(date, entry('manual')),
        for (final source in MealEstimateSource.values)
          savePhotoMeal(
            PhotoMeal(
              id: 'a' * 32,
              day: date,
              meal: 'Обед',
              source: source,
              items: [PhotoFood.fromJson(sampleFood)],
            ),
          ),
      ]);
      final saved = await repository.updateDay(date, (current) => current);
      expect(saved.length, 3);
      expect(saved.map((item) => item.id), contains('manual'));
      expect(saved.where((item) => item.food.isPhotoEstimate).length, 1);
      expect(saved.where((item) => item.food.isTextEstimate).length, 1);
    },
  );
  for (final throws in [false, true]) {
    test(
      'failed native write reloads cached state and releases queue (throw=$throws)',
      () async {
        final repository = DiaryRepository();
        await repository.upsert(date, entry('old'));
        disk
          ..failKey = key
          ..throwOnFailure = throws;
        await expectLater(
          repository.upsert(date, entry('new')),
          throwsStateError,
        );
        final preferences = await SharedPreferences.getInstance();
        final cached =
            jsonDecode(preferences.getString('diary_2026-10-23')!) as List;
        expect(cached.single['id'], 'old');
        disk.failKey = null;
        final saved = await DiaryRepository().upsert(date, entry('new'));
        expect(saved.map((item) => item.id), ['old', 'new']);
      },
    );
  }
  test(
    'a failed recovery backup never permits replacement of damaged originals',
    () async {
      await disk.setValue('String', key, '{broken');
      disk.failKey = 'flutter.recovery_diary_2026-10-23';
      await expectLater(
        DiaryRepository().upsert(date, entry('new')),
        throwsStateError,
      );
      expect((await disk.getAll())[key], '{broken');
      disk.failKey = null;
      expect((await DiaryRepository().upsert(date, entry('new'))).length, 1);
      expect(
        (await disk.getAll())['flutter.recovery_diary_2026-10-23'],
        '{broken',
      );
    },
  );
  test(
    'timed-out caller cannot bypass a late native write; same ID retry replaces it',
    () async {
      disk
        ..pauseKey = key
        ..pause = Completer<void>();
      final repository = DiaryRepository();
      final first = repository
          .upsert(date, entry('stable'))
          .timeout(const Duration(milliseconds: 20));
      await expectLater(first, throwsA(isA<TimeoutException>()));
      final retry = repository.upsert(date, entry('stable', grams: 200));
      final neighbor = DiaryRepository().upsert(date, entry('neighbor'));
      expect(disk.writes.where((value) => value == key).length, 1);
      disk.pause!.complete();
      await Future.wait([retry, neighbor]);
      final saved = await repository.updateDay(date, (current) => current);
      expect(saved.length, 2);
      expect(saved.firstWhere((item) => item.id == 'stable').grams, 200);
    },
  );
  test(
    'invalid caller-built records are rejected without replacing a valid day',
    () async {
      final repository = DiaryRepository();
      await repository.upsert(date, entry('old'));
      await expectLater(
        repository.upsert(date, entry('bad', grams: double.nan)),
        throwsFormatException,
      );
      await expectLater(
        repository.upsert(date, entry('')),
        throwsFormatException,
      );
      expect(
        (jsonDecode((await disk.getAll())[key]! as String) as List)
            .single['id'],
        'old',
      );
    },
  );
}
