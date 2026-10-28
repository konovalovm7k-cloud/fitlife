import 'dart:convert';
import 'package:fitlife/data/repositories/diary_repository.dart';
import 'package:fitlife/features/satiety/hunger_observation.dart';
import 'package:fitlife/features/satiety/satiety_estimate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'parallel_storage_test.dart' show ControlledDisk;
import 'satiety_estimate_test.dart' show satietyItem;

HungerObservation observation({String? id, int level = 3}) => HungerObservation(
  id: id ?? 'a' * 32,
  meal: 'Обед',
  mealAt: DateTime.utc(2026, 10, 27, 12),
  observedAt: DateTime.utc(2026, 10, 27, 14),
  level: level,
  foodSince: FoodSinceMeal.no,
  structure: FoodStructure.solid,
  items: [satietyItem(grams: 150.5, label: true, fiberKnown: false)],
);

void main() {
  late ControlledDisk disk;
  late HungerRepository repo;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    disk = ControlledDisk();
    SharedPreferencesStorePlatform.instance = disk;
    repo = HungerRepository(
      DiaryRepository.withLoader(),
      clock: () => DateTime.utc(2026, 10, 27, 15),
    );
  });
  test(
    'snapshots, real elapsed time and unknown nutrients survive native reload',
    () async {
      await repo.save(observation());
      final loaded = (await HungerRepository(
        DiaryRepository.withLoader(),
      ).load()).single;
      expect(loaded.elapsed.inMinutes, 120);
      expect(loaded.items.single.grams, 150.5);
      expect(loaded.items.single.food.hasKnownFiber, isFalse);
      expect(loaded.items.single.food.provenance!.reference, 'Test label');
      expect(loaded.structure, FoodStructure.solid);
      await DiaryRepository.withLoader().upsertDay(
        DateTime(2026, 10, 27),
        satietyItem(grams: 300),
      );
      expect((await repo.load()).single.items.single.grams, 150.5);
    },
  );
  test(
    'separate repositories serialize concurrent saves and retries replace their own ID',
    () async {
      final other = HungerRepository(
        DiaryRepository.withLoader(),
        clock: () => DateTime.utc(2026, 10, 27, 15),
      );
      await Future.wait(
        List.generate(
          20,
          (i) => (i.isEven ? repo : other).save(
            observation(id: i.toRadixString(16).padLeft(32, '0')),
          ),
        ),
      );
      await repo.save(observation(id: '0' * 32, level: 5));
      final all = await repo.load();
      expect(all.length, 20);
      expect(all.singleWhere((r) => r.id == '0' * 32).level, 5);
    },
  );
  test(
    'failed writes preserve previous observation and stable retry does not duplicate',
    () async {
      await repo.save(observation());
      disk.failKey = 'flutter.$hungerObservationsKey';
      await expectLater(repo.save(observation(level: 4)), throwsStateError);
      expect((await repo.load()).single.level, 3);
      disk.failKey = null;
      await repo.save(observation(level: 4));
      expect((await repo.load()).single.level, 4);
    },
  );
  test(
    'deletion and clearing do not touch diary, goals or connection keys',
    () async {
      await disk.setValue('String', 'flutter.diary_test', 'keep');
      await disk.setValue('Double', 'flutter.calorieTarget', 2200.5);
      await repo.save(observation());
      await repo.save(observation(id: 'b' * 32));
      await repo.delete('a' * 32);
      expect((await repo.load()).single.id, 'b' * 32);
      await repo.clear();
      expect(await repo.load(), isEmpty);
      expect((await disk.getAll())['flutter.diary_test'], 'keep');
      expect((await disk.getAll())['flutter.calorieTarget'], 2200.5);
      expect(
        (await disk.getAll()).keys.any((k) => k.contains('recovery_')),
        isFalse,
      );
    },
  );
  test(
    'damaged data blocks overwrite and is retained until explicit clear',
    () async {
      const raw = '[{"private":"damaged"}]';
      await disk.setValue('String', 'flutter.$hungerObservationsKey', raw);
      await expectLater(repo.load(), throwsA(anything));
      await expectLater(repo.save(observation()), throwsA(anything));
      expect((await disk.getAll())['flutter.$hungerObservationsKey'], raw);
      expect(
        (await disk.getAll()).keys.any((k) => k.contains('recovery_')),
        isFalse,
      );
      await repo.clear();
      await repo.save(observation());
      expect((await repo.load()).single.level, 3);
    },
  );
  test(
    'future, reversed, normalized dates and invalid ratings are rejected',
    () async {
      final valid = observation().toJson();
      for (final patch in [
        {'level': 0},
        {'level': 6},
        {'foodSince': 'maybe'},
        {'structure': 'AI'},
        {'mealAt': valid['observedAt']},
        {'mealAt': '2026-02-31T12:00:00.000Z'},
        {'items': []},
        {'id': 'bad'},
        {'version': 2},
      ]) {
        expect(
          () => HungerObservation.fromJson({...valid, ...patch}),
          throwsFormatException,
        );
      }
      final future = HungerObservation.fromJson({
        ...valid,
        'observedAt': '2026-10-28T14:00:00.000Z',
      });
      await expectLater(repo.save(future), throwsFormatException);
      expect(await repo.load(), isEmpty);
      expect(jsonDecode(jsonEncode(valid))['version'], 1);
    },
  );
}
