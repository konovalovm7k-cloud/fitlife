import 'dart:convert';

import 'package:fitlife/app/state/fitlife_controller.dart';
import 'package:fitlife/core/models/diary_item.dart';
import 'package:fitlife/data/repositories/local_fitlife_repository.dart';
import 'package:fitlife/features/progress/weekly_summary.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    '4.5 legacy data, AI flags and fractional goals survive migration twice',
    () async {
      final day = DateTime(2026, 10, 25);
      Map<String, dynamic> record(
        String id, {
        bool photo = false,
        bool text = false,
      }) => {
        'id': id,
        'meal': 'Обед',
        'grams': 150.5,
        'time': '12:00',
        'food': {
          'id': id,
          'name': id,
          'kcal': 100,
          'protein': 10,
          'fat': 2,
          'carbs': 9,
          'fiber': 3,
          if (photo) 'photoEstimate': true,
          if (text) 'textEstimate': true,
        },
      };
      final original = jsonEncode([
        record('manual'),
        record('photo', photo: true),
        record('text', text: true),
      ]);
      SharedPreferences.setMockInitialValues({
        'diary_2026-10-25': original,
        'goal_calories': 2400.5,
        'goal_protein': 160.25,
        'goal_fat': 70.5,
        'goal_fiber': 35.25,
        'water': 0.75,
        'weight': 82.4,
        'favorites': ['manual'],
        'recent': ['text'],
      });
      for (var pass = 0; pass < 2; pass++) {
        final controller = FitLifeController(
          repository: LocalFitLifeRepository(),
          clock: () => day,
        );
        await controller.initialize();
        final state = controller.state;
        expect(state.diary.length, 3);
        expect(state.diary.where((e) => e.food.isPhotoEstimate).length, 1);
        expect(state.diary.where((e) => e.food.isTextEstimate).length, 1);
        expect(state.goals.carbs, 281.25);
        expect(state.water, 0.75);
        expect(state.weight, 82.4);
        expect(state.favorites, ['manual']);
        expect(state.recent, ['text']);
        final summary = await WeeklySummary.load(day);
        expect(summary.days.last.calories, state.total.calories);
        expect(summary.days.last.entries.map((e) => e.id), [
          'manual',
          'photo',
          'text',
        ]);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('diary_2026-10-25'), original);
        expect(prefs.getDouble('goal_calories'), 2400.5);
        controller.dispose();
      }
    },
  );

  test(
    'catalog retry after commit keeps the operation ID across controller reload',
    () async {
      SharedPreferences.setMockInitialValues({});
      final day = DateTime(2026, 10, 25);
      final controller = FitLifeController(
        repository: LocalFitLifeRepository(),
        clock: () => day,
      );
      await controller.initialize();
      const food = FoodItem(
        id: 'f',
        name: 'Продукт',
        kcal: 100,
        protein: 10,
        fat: 2,
        carbs: 9,
        fiber: 3,
      );
      const entry = DiaryItem(
        id: 'catalog_stable',
        meal: 'Обед',
        food: food,
        grams: 123.5,
        time: '12:00',
      );
      await controller.saveEntry(day, entry);
      await controller.load();
      await controller.saveEntry(day, entry);
      expect(controller.state.diary.single.id, entry.id);
      expect(controller.state.diary.single.grams, 123.5);
      controller.dispose();
    },
  );
}
