import 'dart:convert';
import 'package:fitlife/data/repositories/diary_repository.dart';
import 'package:fitlife/features/progress/weight_history.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'parallel_storage_test.dart' show ControlledDisk;

void main() {
  late ControlledDisk disk;
  late WeightRepository repository;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    disk = ControlledDisk();
    SharedPreferencesStorePlatform.instance = disk;
    repository = WeightRepository(DiaryRepository.withLoader());
  });
  test(
    'empty state has no fabricated weight; legacy weight has no invented date',
    () async {
      expect((await repository.load()).latest, isNull);
      await disk.setValue('Double', 'flutter.weight', 87.5);
      final old = await repository.load();
      expect(old.latest, 87.5);
      expect(old.entries, isEmpty);
    },
  );
  test(
    'concurrent measurements and same-day retry keep one value per date',
    () async {
      await Future.wait([
        repository.save(WeightEntry(DateTime(2026, 10, 22), 81)),
        WeightRepository(
          DiaryRepository.withLoader(),
        ).save(WeightEntry(DateTime(2026, 10, 23), 80.5)),
      ]);
      await repository.save(WeightEntry(DateTime(2026, 10, 22), 81.2));
      final loaded = await repository.load();
      expect(loaded.entries.map((e) => e.kg), [81.2, 80.5]);
      expect(loaded.latest, 80.5);
    },
  );
  test(
    'deleting all history does not resurrect undated legacy value',
    () async {
      await disk.setValue('Double', 'flutter.weight', 87.5);
      await repository.save(WeightEntry(DateTime(2026, 10, 22), 82));
      await repository.delete(DateTime(2026, 10, 22));
      expect((await repository.load()).latest, isNull);
      expect((await disk.getAll())['flutter.weight'], 87.5);
    },
  );
  test(
    'native failure preserves measurement and successful retry replaces it',
    () async {
      final date = DateTime(2026, 10, 22);
      await repository.save(WeightEntry(date, 82));
      disk.failKey = 'flutter.$weightHistoryKey';
      await expectLater(
        repository.save(WeightEntry(date, 81)),
        throwsStateError,
      );
      expect((await repository.load()).latest, 82);
      disk.failKey = null;
      await repository.save(WeightEntry(date, 81));
      expect((await repository.load()).entries.single.kg, 81);
    },
  );
  test(
    'invalid and normalized dates are rejected; damaged records are preserved',
    () async {
      expect(
        () => WeightEntry.fromJson({'date': '2026-02-31', 'kg': 80}),
        throwsFormatException,
      );
      await expectLater(
        repository.save(WeightEntry(DateTime(2026, 10, 22), double.nan)),
        throwsFormatException,
      );
      await expectLater(
        repository.save(
          WeightEntry(DateTime.now().add(const Duration(days: 2)), 80),
        ),
        throwsFormatException,
      );
      final raw = jsonEncode([
        {'date': '2026-02-31', 'kg': 80},
        {'date': '2026-10-22', 'kg': 81},
      ]);
      await disk.setValue('String', 'flutter.$weightHistoryKey', raw);
      final loaded = await repository.load();
      expect(loaded.recovered, isTrue);
      expect(loaded.entries.single.kg, 81);
      expect((await disk.getAll())['flutter.recovery_$weightHistoryKey'], raw);
    },
  );
}
