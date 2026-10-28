import 'package:fitlife/main.dart';
import 'package:fitlife/data/repositories/diary_repository.dart';
import 'package:fitlife/features/photo_analysis/photo_service.dart';
import 'package:fitlife/features/progress/weight_history.dart';
import 'package:fitlife/features/saved_meals/saved_meals.dart';
import 'package:fitlife/modern_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// CI runs this only on a fresh simulator. Uses native preferences and Keychain.
/// No provider request or real invitation is involved.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'iPhone launch, local diary, meals, weights and Keychain persist',
    (tester) async {
      await tester.pumpWidget(const FitLifeRoot());
      await tester.pumpAndSettle();
      expect(find.text('FITLIFE'), findsOneWidget);
      final diary = DiaryRepository.withLoader();
      final day = DateTime(2026, 10, 20);
      final meals = SavedMealsRepository(diary);
      final recipe = SavedMeal(
        id: 'ios-smoke',
        name: 'Тестовый завтрак',
        items: [
          DiaryItem(
            id: 'ingredient',
            meal: 'Завтрак',
            food: builtInFoods.first,
            grams: 100,
            time: '08:00',
          ),
        ],
      );
      await meals.save(recipe);
      await meals.add(
        recipe: recipe,
        day: day,
        meal: 'Завтрак',
        portions: 1.5,
        operationId: 'ios-smoke',
        time: '08:00',
      );
      expect(
        (await SavedMealsRepository(
          DiaryRepository.withLoader(),
        ).load()).meals.any((e) => e.id == recipe.id),
        isTrue,
      );
      final weights = WeightRepository(diary);
      await weights.save(WeightEntry(day, 75.5));
      expect(
        (await WeightRepository(
          DiaryRepository.withLoader(),
        ).load()).entries.any((e) => e.kg == 75.5),
        isTrue,
      );
      const connection = PhotoConnectionStore();
      await connection.write(
        PhotoConnection('https://fitlife-ci.example.com', 'c' * 43),
      );
      expect(
        (await const PhotoConnectionStore().read())?.address,
        'https://fitlife-ci.example.com',
      );
      await connection.clear();
      expect(await connection.read(), isNull);
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      expect(prefs.getString('diary_2026-10-20'), contains('150.0'));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(const FitLifeRoot());
      await tester.pumpAndSettle();
      for (final label in ['Питание', 'Прогресс', 'Профиль', 'Сегодня']) {
        await tester.tap(find.text(label).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );
}
