import 'dart:convert';

import 'package:fitlife/core/models/diary_item.dart';
import 'package:fitlife/data/repositories/diary_preferences.dart';
import 'package:fitlife/data/repositories/diary_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class DiaryDisk extends InMemorySharedPreferencesStore {
  DiaryDisk() : super.empty();
  bool fail = false;
  int writes = 0;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    writes++;
    return fail ? false : super.setValue(valueType, key, value);
  }
}

DiaryItem entry(String id, {double grams = 150.5}) => DiaryItem(
  id: id,
  meal: 'Обед',
  food: const FoodItem(
    id: 'rice',
    name: 'Рис',
    kcal: 344,
    protein: 7,
    fat: 0.7,
    carbs: 78,
    fiber: 2.4,
  ),
  grams: grams,
  time: '12:30',
);

void main() {
  late DiaryDisk disk;
  late SharedPreferences prefs;
  const key = 'diary_2026-10-21';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    disk = DiaryDisk();
    SharedPreferencesStorePlatform.instance = disk;
    prefs = await SharedPreferences.getInstance();
  });

  test(
    'concurrent repository instances preserve both entries and dates',
    () async {
      final first = DiaryRepository(prefs);
      final second = DiaryRepository(prefs);
      await Future.wait([
        first.upsert(key, entry('manual')),
        second.upsert(key, entry('catalog')),
        first.upsert('diary_2026-10-20', entry('yesterday')),
      ]);
      final stored = await DiaryPreferences(
        prefs,
      ).readRecords(key, DiaryItem.fromJson);
      expect(stored.map((item) => item.id), ['manual', 'catalog']);
      expect(stored.first.grams, 150.5);
      expect(stored.first.kcal, closeTo(517.72, 1e-9));
      expect(stored.first.fiber, closeTo(3.612, 1e-9));
      expect(
        (jsonDecode(prefs.getString('diary_2026-10-20')!) as List).single['id'],
        'yesterday',
      );
    },
  );

  test(
    'false writes clear optimistic cache; queue accepts retry without duplicates',
    () async {
      final repository = DiaryRepository(prefs);
      await repository.upsert(key, entry('old'));
      disk.fail = true;
      await expectLater(repository.upsert(key, entry('new')), throwsStateError);
      expect((jsonDecode(prefs.getString(key)!) as List).length, 1);
      disk.fail = false;
      await repository.upsert(key, entry('new'));
      await repository.upsert(key, entry('new', grams: 200.25));
      final stored = await DiaryPreferences(
        prefs,
      ).readRecords(key, DiaryItem.fromJson);
      expect(stored.map((item) => item.id), ['old', 'new']);
      expect(stored.last.grams, 200.25);
      expect(disk.writes, 4);
    },
  );

  test(
    'damaged records cannot be overwritten if recovery write fails',
    () async {
      final raw = jsonEncode([
        entry('valid').toJson(),
        {'broken': true},
      ]);
      await prefs.setString(key, raw);
      disk.fail = true;
      await expectLater(
        DiaryRepository(prefs).upsert(key, entry('new')),
        throwsStateError,
      );
      expect(prefs.getString(key), raw);
      expect(prefs.containsKey('recovery_$key'), isFalse);
      disk.fail = false;
      final saved = await DiaryRepository(prefs).upsert(key, entry('new'));
      expect(saved.map((item) => item.id), ['valid', 'new']);
      expect(prefs.getString('recovery_$key'), raw);
      await prefs.reload();
      expect(prefs.getString('recovery_$key'), raw);
    },
  );

  test('wrong typed source is backed up before a diary replacement', () async {
    await prefs.setInt(key, 42);
    await DiaryRepository(prefs).upsert(key, entry('new'));
    expect(prefs.getString('recovery_$key'), '42');
  });
}
