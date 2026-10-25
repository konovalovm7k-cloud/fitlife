import 'dart:convert';
import 'package:fitlife/core/models/diary_item.dart';
import 'package:fitlife/data/repositories/diary_repository.dart';
import 'package:fitlife/features/saved_meals/saved_meals.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'parallel_storage_test.dart' show ControlledDisk, entry;

void main() {
  late ControlledDisk disk;
  late SavedMealsRepository repository;
  final day = DateTime(2026, 10, 23);
  SavedMeal recipe(String id) => SavedMeal(
    id: id,
    name: 'Завтрак',
    items: [entry('oats', grams: 100), entry('more', grams: 200)],
    servings: 2,
  );
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    disk = ControlledDisk();
    SharedPreferencesStorePlatform.instance = disk;
    repository = SavedMealsRepository(DiaryRepository.withLoader());
  });
  test(
    'fractional servings scale all nutrients and preserve ingredient snapshots',
    () {
      final source = recipe('one');
      final result = source.entries(
        operationId: 'op',
        meal: 'Ужин',
        portions: 0.5,
        time: '18:00',
      );
      expect(result.map((e) => e.grams), [25, 50]);
      expect(
        result.fold(0.0, (sum, e) => sum + e.kcal),
        source.total((i) => i.kcal) * 0.5,
      );
      expect(
        result.fold(0.0, (sum, e) => sum + e.protein),
        source.total((i) => i.protein) * 0.5,
      );
      expect(
        result.fold(0.0, (sum, e) => sum + e.fiber),
        source.total((i) => i.fiber) * 0.5,
      );
      expect(result.first.food, same(source.items.first.food));
      expect(result.every((e) => e.meal == 'Ужин'), isTrue);
    },
  );
  test(
    'rejects corrupt portions and empty recipes instead of writing',
    () async {
      for (final count in [0.0, double.nan, double.infinity, 101.0]) {
        await expectLater(
          repository.save(
            SavedMeal(
              id: 'bad',
              name: 'test',
              items: [entry('e')],
              servings: count,
            ),
          ),
          throwsFormatException,
        );
      }
      await expectLater(
        repository.save(SavedMeal(id: 'empty', name: 'test', items: [])),
        throwsFormatException,
      );
      expect((await disk.getAll())['flutter.$savedMealsKey'], isNull);
      expect(
        () => recipe('a').entries(
          operationId: 'op',
          meal: 'Обед',
          portions: double.nan,
          time: '12:00',
        ),
        throwsFormatException,
      );
    },
  );
  test(
    'concurrent library edits preserve independent meals; edits do not touch diary',
    () async {
      await DiaryRepository.withLoader().upsertDay(day, entry('existing'));
      await Future.wait([
        repository.save(recipe('one')),
        SavedMealsRepository(DiaryRepository.withLoader()).save(recipe('two')),
      ]);
      expect((await repository.load()).meals.length, 2);
      await repository.delete('one');
      expect((await repository.load()).meals.single.id, 'two');
      expect(
        jsonDecode(
          (await disk.getAll())['flutter.diary_2026-10-23']! as String,
        ),
        hasLength(1),
      );
    },
  );
  test(
    'add retry changes the same batch, keeping unrelated writes and source day',
    () async {
      await DiaryRepository.withLoader().upsertDay(
        DateTime(2026, 10, 22),
        entry('source'),
      );
      Future<void> add(double portions) async {
        await repository.add(
          recipe: recipe('a'),
          day: day,
          meal: 'Обед',
          portions: portions,
          operationId: 'stable',
          time: '12:00',
        );
      }

      await Future.wait([
        add(1),
        DiaryRepository.withLoader().upsertDay(day, entry('manual')),
      ]);
      await add(2);
      final all = await disk.getAll();
      final saved =
          (jsonDecode(all['flutter.diary_2026-10-23']! as String) as List)
              .map((e) => DiaryItem.fromJson(e))
              .toList();
      expect(saved, hasLength(3));
      expect(
        saved.where((e) => e.id.startsWith('saved_')).map((e) => e.grams),
        [100, 200],
      );
      expect(
        jsonDecode(all['flutter.diary_2026-10-22']! as String),
        hasLength(1),
      );
    },
  );
  test(
    'failed save retains library; corrupt original must be backed up first',
    () async {
      await repository.save(recipe('original'));
      disk.failKey = 'flutter.$savedMealsKey';
      await expectLater(repository.save(recipe('new')), throwsStateError);
      expect((await repository.load()).meals.single.id, 'original');
      disk.failKey = null;
      await disk.setValue(
        'String',
        'flutter.$savedMealsKey',
        '[{"broken":true}]',
      );
      disk.failKey = 'flutter.recovery_$savedMealsKey';
      await expectLater(repository.save(recipe('new')), throwsStateError);
      expect(
        (await disk.getAll())['flutter.$savedMealsKey'],
        '[{"broken":true}]',
      );
      disk.failKey = null;
      await repository.save(recipe('new'));
      expect(
        (await disk.getAll())['flutter.recovery_$savedMealsKey'],
        '[{"broken":true}]',
      );
    },
  );
  test(
    'previous calendar day crosses month boundary without inventing meals',
    () async {
      await DiaryRepository.withLoader().upsertDay(
        DateTime(2026, 9, 30),
        entry('last'),
      );
      expect(
        (await repository.previousDay(DateTime(2026, 10, 1))).meals.single.name,
        'Обед',
      );
      expect(
        (await repository.previousDay(DateTime(2026, 10, 2))).meals,
        isEmpty,
      );
    },
  );
  test('AI markers and full nutrient profiles survive round trip', () {
    const food = FoodItem(
      id: 'ai',
      name: 'Оценка',
      kcal: 100,
      protein: 1,
      fat: 1,
      carbs: 10,
      fiber: 2,
      isTextEstimate: true,
    );
    final source = SavedMeal(
      id: 'ai',
      name: 'Блюдо',
      items: [
        const DiaryItem(
          id: 'i',
          meal: 'Обед',
          food: food,
          grams: 200,
          time: '12:00',
        ),
      ],
    );
    final loaded = SavedMeal.fromJson(jsonDecode(jsonEncode(source.toJson())));
    expect(loaded.estimated, isTrue);
    expect(
      loaded
          .entries(operationId: 'new', meal: 'Ужин', portions: 1, time: '20:00')
          .single
          .food
          .isTextEstimate,
      isTrue,
    );
  });
}
