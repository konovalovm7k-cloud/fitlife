import 'dart:convert';
import 'package:fitlife/core/models/diary_item.dart';
import 'package:fitlife/features/progress/weekly_summary_page.dart';
import 'package:fitlife/data/repositories/diary_repository.dart';
import 'package:fitlife/features/progress/weight_history.dart';
import 'package:fitlife/features/progress/weight_history_page.dart';
import 'package:fitlife/features/saved_meals/saved_meals.dart';
import 'package:fitlife/features/saved_meals/saved_meals_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CountingWeightRepository extends WeightRepository {
  CountingWeightRepository(super.diary);
  int saves = 0;
  @override
  Future<WeightHistory> save(WeightEntry entry) {
    saves++;
    return super.save(entry);
  }
}

class CountingSavedMealsRepository extends SavedMealsRepository {
  CountingSavedMealsRepository(super.diary);
  int deletes = 0;
  @override
  Future<void> delete(String id) {
    deletes++;
    return super.delete(id);
  }
}

void main() {
  testWidgets(
    'committed template deletion refreshes library without false failure or diary changes',
    (tester) async {
      const item = DiaryItem(
        id: 'kept',
        meal: 'Обед',
        grams: 100,
        time: '12:00',
        food: FoodItem(
          id: 'food',
          name: 'Продукт',
          kcal: 100,
          protein: 10,
          fat: 2,
          carbs: 12,
          fiber: 1,
        ),
      );
      final diaryRaw = jsonEncode([item.toJson()]);
      SharedPreferences.setMockInitialValues({
        savedMealsKey: jsonEncode([
          SavedMeal(
            id: 'saved',
            name: 'Сохранённый обед',
            items: [item],
          ).toJson(),
        ]),
        'diary_2026-10-28': diaryRaw,
      });
      final preferences = await SharedPreferences.getInstance();
      final repository = CountingSavedMealsRepository(
        DiaryRepository(preferences),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: SavedMealsPage(
            repository: repository,
            day: DateTime(2026, 10, 28),
            initialMeal: 'Обед',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Действия с блюдом'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Удалить блюдо'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Удалить'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Сохранённый обед'), findsNothing);
      expect(
        find.text('Не удалось удалить блюдо. Повторите попытку.'),
        findsNothing,
      );
      expect(repository.deletes, 1);
      expect((await repository.load()).meals, isEmpty);
      expect(preferences.getString('diary_2026-10-28'), diaryRaw);
    },
  );
  testWidgets(
    'committed weight edit closes once and refreshes visible history',
    (tester) async {
      final day = DateUtils.dateOnly(DateTime.now());
      SharedPreferences.setMockInitialValues({
        weightHistoryKey: jsonEncode([WeightEntry(day, 83.5).toJson()]),
      });
      final preferences = await SharedPreferences.getInstance();
      final repository = CountingWeightRepository(DiaryRepository(preferences));
      await tester.pumpWidget(
        MaterialApp(home: WeightHistoryPage(repository: repository)),
      );
      await tester.pumpAndSettle();
      final row = find.widgetWithText(ListTile, '83.5 кг');
      await tester.scrollUntilVisible(row, 150);
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '82.75');
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(AlertDialog), findsNothing);
      expect(repository.saves, 1);
      expect((await repository.load()).entries.single.kg, 82.75);
      expect(find.widgetWithText(ListTile, '82.8 кг'), findsOneWidget);
    },
  );
  for (final weight in [false, true]) {
    testWidgets(
      '${weight ? 'weight' : 'saved meals'} read can fail twice then recover without changing saved data',
      (tester) async {
        const item = DiaryItem(
          id: 'kept',
          meal: 'Обед',
          grams: 100,
          time: '12:00',
          food: FoodItem(
            id: 'food',
            name: 'Продукт',
            kcal: 100,
            protein: 10,
            fat: 2,
            carbs: 12,
            fiber: 1,
          ),
        );
        final raw = weight
            ? jsonEncode([WeightEntry(DateTime(2026, 10, 28), 83.5).toJson()])
            : jsonEncode([
                SavedMeal(
                  id: 'saved',
                  name: 'Сохранённый обед',
                  items: [item],
                ).toJson(),
              ]);
        final key = weight ? weightHistoryKey : savedMealsKey;
        SharedPreferences.setMockInitialValues({key: raw});
        final preferences = await SharedPreferences.getInstance();
        var attempts = 0;
        Future<SharedPreferences> load() async {
          if (++attempts <= 2) throw StateError('temporary read failure');
          return preferences;
        }

        final diary = DiaryRepository.withLoader(preferencesLoader: load);
        await tester.pumpWidget(
          MaterialApp(
            home: weight
                ? WeightHistoryPage(repository: WeightRepository(diary))
                : SavedMealsPage(
                    repository: SavedMealsRepository(diary),
                    day: DateTime(2026, 10, 28),
                    initialMeal: 'Обед',
                  ),
          ),
        );
        await tester.pumpAndSettle();
        final retry = weight ? 'Повторить' : 'Повторить загрузку';
        expect(find.text(retry), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(retry));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(retry), findsOneWidget);
        await tester.tap(find.text(retry));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.text(weight ? '83.5 кг' : 'Сохранённый обед'),
          findsWidgets,
        );
        expect(attempts, 3);
        expect(preferences.getString(key), raw);
      },
    );
  }
  testWidgets(
    'weekly read can fail twice then recover without changing diary',
    (tester) async {
      final raw = jsonEncode([
        (const DiaryItem(
          id: 'kept',
          meal: 'Обед',
          grams: 100,
          time: '12:00',
          food: FoodItem(
            id: 'food',
            name: 'Продукт',
            kcal: 100,
            protein: 10,
            fat: 2,
            carbs: 12,
            fiber: 1,
          ),
        )).toJson(),
      ]);
      SharedPreferences.setMockInitialValues({'diary_2026-10-28': raw});
      final preferences = await SharedPreferences.getInstance();
      var attempts = 0;
      Future<SharedPreferences> load() async {
        if (++attempts <= 2) throw StateError('temporary read failure');
        return preferences;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: WeeklySummaryPage(
            end: DateTime(2026, 10, 28),
            preferencesLoader: load,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Не удалось прочитать историю. Ваши записи не изменены.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Повторить'), findsOneWidget);
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('1 из 7 дней'), findsOneWidget);
      expect(attempts, 3);
      expect(preferences.getString('diary_2026-10-28'), raw);
    },
  );
}
