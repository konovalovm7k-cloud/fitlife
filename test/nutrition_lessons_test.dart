import 'package:fitlife/data/repositories/diary_repository.dart';
import 'package:fitlife/features/learning/nutrition_lessons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'parallel_storage_test.dart' show ControlledDisk;

void main() {
  late ControlledDisk disk;
  late LearningRepository repo;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    disk = ControlledDisk();
    SharedPreferencesStorePlatform.instance = disk;
    repo = LearningRepository(DiaryRepository.withLoader());
  });
  test('FDA serving example scales once through the real nutrition engine', () {
    final single = teachingPortion(227);
    final half = teachingPortion(113.5);
    final twice = teachingPortion(454);
    expect(single.kcal, closeTo(280, 1e-9));
    expect(half.kcal, closeTo(140, 1e-9));
    expect(twice.kcal, closeTo(560, 1e-9));
    expect(twice.protein, closeTo(30, 1e-9));
    expect(twice.fat, closeTo(18, 1e-9));
    expect(twice.carbs, closeTo(68, 1e-9));
    expect(twice.fiber, closeTo(8, 1e-9));
    expect(() => teachingPortion(double.nan), throwsFormatException);
  });
  test(
    'concurrent marks preserve other lessons and IDs from later versions',
    () async {
      await disk.setValue('StringList', 'flutter.$lessonProgressKey', [
        'future_v2',
      ]);
      final other = LearningRepository(DiaryRepository.withLoader());
      await Future.wait([
        repo.mark('portions_v1', true),
        other.mark('nutrients_v1', true),
        repo.mark('sources_v1', true),
      ]);
      expect((await repo.load()).count, 3);
      await repo.mark('portions_v1', false);
      final loaded = await repo.load();
      expect(loaded.count, 2);
      expect(loaded.completed, contains('future_v2'));
      expect(loaded.completed, isNot(contains('portions_v1')));
      await expectLater(repo.mark('made_up', true), throwsFormatException);
    },
  );
  test(
    'native failure retains last committed progress and retry is idempotent',
    () async {
      await repo.mark('portions_v1', true);
      disk.failKey = 'flutter.$lessonProgressKey';
      await expectLater(repo.mark('sources_v1', true), throwsStateError);
      expect((await repo.load()).count, 1);
      disk.failKey = null;
      await repo.mark('sources_v1', true);
      await repo.mark('sources_v1', true);
      expect((await repo.load()).count, 2);
    },
  );
  test(
    'damaged progress is preserved without touching diary or goals',
    () async {
      await disk.setValue(
        'String',
        'flutter.$lessonProgressKey',
        'bad-progress',
      );
      await disk.setValue('String', 'flutter.diary_keep', 'keep');
      final restored = await repo.load();
      expect(restored.recovered, isTrue);
      expect(restored.count, 0);
      await repo.mark('sources_v1', true);
      expect((await repo.load()).count, 1);
      expect(
        (await disk.getAll())['flutter.recovery_$lessonProgressKey'],
        'bad-progress',
      );
      expect((await disk.getAll())['flutter.diary_keep'], 'keep');
    },
  );
}
