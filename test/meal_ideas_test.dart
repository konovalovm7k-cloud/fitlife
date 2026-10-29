import 'dart:convert';
import 'dart:io';
import 'package:fitlife/core/nutrition/food_catalog_import.dart';
import 'package:fitlife/core/nutrition/nutrition_database.dart';
import 'package:fitlife/data/repositories/local_fitlife_repository.dart';
import 'package:fitlife/features/meal_ideas/meal_ideas.dart';
import 'package:fitlife/features/meal_ideas/meal_ideas_page.dart';
import 'package:fitlife/features/photo_analysis/photo_diary.dart';
import 'package:fitlife/features/photo_analysis/photo_models.dart';
import 'package:fitlife/features/satiety/satiety_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'diary_flow_test.dart' show launch;
import 'diary_repository_test.dart' show DiaryDisk;
import 'support/source_flow.dart' show reveal;

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final asset = File('assets/data/food_catalog.json').readAsStringSync();
  final records = parseFoodCatalog(asset);
  final day = DateTime(2026, 10, 28);
  const diaryKey = 'diary_2026-10-28';
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    rootBundle.evict('assets/data/food_catalog.json');
    binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (
      message,
    ) async {
      if (utf8.decode(message!.buffer.asUint8List()) !=
          'assets/data/food_catalog.json') {
        return null;
      }
      return ByteData.sublistView(Uint8List.fromList(utf8.encode(asset)));
    });
  });

  test(
    'whole dishes sum source portions; half and double preserve exact mass and nutrients',
    () {
      final expected = [
        (420.0, 225.1),
        (520.0, 388.1),
        (375.0, 301.0),
        (420.0, 360.0),
        (365.0, 305.6),
      ];
      expect(mealIdeas.map((idea) => idea.id), [
        'cottage_vegetables_v1',
        'chicken_rice_v1',
        'lentils_vegetables_v1',
        'rice_beans_broccoli_v1',
        'yogurt_pear_almonds_v1',
      ]);
      for (var i = 0; i < mealIdeas.length; i++) {
        for (final factor in [.5, 1.0, 2.0]) {
          final foods = mealIdeas[i].resolve(records, factor);
          expect(
            foods.fold<double>(0, (sum, f) => sum + f.grams),
            closeTo(expected[i].$1 * factor, 1e-9),
          );
          expect(ideaTotal(foods).kcal, closeTo(expected[i].$2 * factor, 1e-9));
          expect(
            foods.every((f) => f.source!.provenance.kind == 'catalogue'),
            isTrue,
          );
          expect(foods.every((f) => f.source!.fiberKnown), isTrue);
        }
      }
      final total = ideaTotal(mealIdeas.first.resolve(records, 1));
      expect(total.protein, closeTo(19.17, 1e-9));
      expect(total.fat, closeTo(3.8, 1e-9));
      expect(total.carbs, closeTo(30.66, 1e-9));
      expect(total.fiber, closeTo(5.7, 1e-9));
      final riceBeans = ideaTotal(mealIdeas[3].resolve(records, 1));
      expect(riceBeans.protein, closeTo(20.67, 1e-9));
      expect(riceBeans.fat, closeTo(3.3, 1e-9));
      expect(riceBeans.carbs, closeTo(66.12, 1e-9));
      expect(riceBeans.fiber, closeTo(14.61, 1e-9));
      final yogurt = ideaTotal(mealIdeas[4].resolve(records, 1));
      expect(yogurt.protein, closeTo(15.03, 1e-9));
      expect(yogurt.fat, closeTo(13.635, 1e-9));
      expect(yogurt.carbs, closeTo(32.745, 1e-9));
      expect(yogurt.fiber, closeTo(5.925, 1e-9));
    },
  );

  test(
    'missing or ambiguous source and unsupported portion cannot produce an estimate',
    () {
      final idea = mealIdeas.first;
      final id = idea.ingredients.first.recordId;
      final selected = records.singleWhere((r) => r.id == id);
      expect(
        () => idea.resolve(records.where((r) => r.id != id).toList(), 1),
        throwsFormatException,
      );
      expect(
        () => idea.resolve([...records, selected], 1),
        throwsFormatException,
      );
      for (final factor in [0.0, -1.0, 3.0, double.nan, double.infinity]) {
        expect(() => idea.resolve(records, factor), throwsFormatException);
      }
    },
  );

  Widget page(
    Future<void> Function(PhotoMeal) save, {
    Future<List<NutritionFoodRecord>> Function()? loader,
  }) => MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => MealIdeasPage(
                day: day,
                initialMeal: 'Обед',
                onSave: save,
                loadFoods: loader ?? () async => records,
              ),
            ),
          ),
          child: const Text('Open ideas'),
        ),
      ),
    ),
  );

  Future<void> openFirst(WidgetTester tester) async {
    await reveal(
      tester,
      find.byKey(const Key('idea-review-cottage_vegetables_v1')),
    );
    await tester.tap(
      find.byKey(const Key('idea-review-cottage_vegetables_v1')),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'both new half ideas preserve exact sources through whole-draft properties and explicit save/reload',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      var saves = 0;
      final examples = [
        (
          id: 'rice_beans_broccoli_v1',
          kcal: '180',
          grams: [75.0, 60.0, 75.0],
          codes: ['11-869', '13-660', '13-503'],
        ),
        (
          id: 'yogurt_pear_almonds_v1',
          kcal: '153',
          grams: [100.0, 75.0, 7.5],
          codes: ['12-184', '14-321', '14-896'],
        ),
      ];
      for (final example in examples) {
        final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
        await tester.pumpWidget(
          page((meal) async {
            saves++;
            await savePhotoMeal(meal);
          }),
        );
        await tester.tap(find.text('Open ideas'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('½ порции'));
        await tester.pumpAndSettle();
        final open = find.byKey(Key('idea-review-${example.id}'));
        await reveal(tester, open);
        await tester.tap(open);
        await tester.pumpAndSettle();
        expect(find.text('${example.kcal} ккал'), findsOneWidget);
        final properties = find.byKey(const Key('review-meal-properties'));
        await reveal(tester, properties);
        await tester.tap(properties);
        await tester.pumpAndSettle();
        final preview = tester.widget<SatietyPage>(find.byType(SatietyPage));
        expect(preview.day, day);
        expect(preview.portions!.map((p) => p.grams), example.grams);
        expect(
          preview.portions!.map((p) => p.source.provenance.recordId),
          example.codes.map((code) => 'imported_cofid_2021_$code'),
        );
        expect(find.byKey(const Key('observe-hunger')), findsNothing);
        await tester.pageBack();
        await tester.pumpAndSettle();
        await prefs.reload();
        expect({
          for (final key in prefs.getKeys()) key: prefs.get(key),
        }, before);
        await reveal(tester, find.byKey(const Key('photo-save')));
        await tester.tap(find.byKey(const Key('photo-save')));
        await tester.pumpAndSettle();
        expect(find.text('Open ideas'), findsOneWidget);
        final loaded = await LocalFitLifeRepository().loadDay(day, today: day);
        expect(loaded.diary, hasLength(saves * 3));
        final latest = loaded.diary.skip((saves - 1) * 3).toList();
        expect(latest.map((entry) => entry.grams), example.grams);
        expect(
          latest.map((entry) => entry.food.provenance!.recordId),
          example.codes.map((code) => 'imported_cofid_2021_$code'),
        );
        expect(
          latest.every(
            (entry) =>
                entry.food.hasKnownFiber &&
                !entry.food.isChefSuggestion &&
                !entry.food.isPhotoEstimate &&
                !entry.food.isTextEstimate,
          ),
          isTrue,
        );
        expect(prefs.getString('hunger_observations_v1'), isNull);
      }
      expect(saves, 2);
      final loaded = await LocalFitLifeRepository().loadDay(day, today: day);
      expect(loaded.total.calories, closeTo(332.8, 1e-9));
    },
  );

  testWidgets(
    'half example opens explicit review; cancellation writes nothing',
    (tester) async {
      var writes = 0;
      await tester.pumpWidget(
        page((_) async {
          writes++;
        }),
      );
      await tester.tap(find.text('Open ideas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('½ порции'));
      await tester.pumpAndSettle();
      expect(find.text('210 г · 113 ккал'), findsOneWidget);
      await openFirst(tester);
      expect(find.text('113 ккал'), findsOneWidget);
      expect(find.text('СОСТАВ ПРОДУКТОВ'), findsOneWidget);
      expect(writes, 0);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Идеи блюд'), findsOneWidget);
      expect(writes, 0);
    },
  );

  testWidgets(
    'failed batch write retries with same ID, preserving source and portion after reload',
    (tester) async {
      final disk = DiaryDisk();
      SharedPreferencesStorePlatform.instance = disk;
      final ids = <String>[];
      Future<void> save(PhotoMeal meal) async {
        ids.add(meal.id);
        await savePhotoMeal(meal);
      }

      await tester.pumpWidget(page(save));
      await tester.tap(find.text('Open ideas'));
      await tester.pumpAndSettle();
      await openFirst(tester);
      disk.fail = true;
      final button = find.byKey(const Key('photo-save'));
      await reveal(tester, button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.textContaining('Ваши правки остались'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      expect(prefs.getString(diaryKey), isNull);
      // Rebuilding the app/theme must not allocate a new batch ID for retry.
      await tester.pumpWidget(page(save));
      await tester.pumpAndSettle();
      disk.fail = false;
      await reveal(tester, button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('Open ideas'), findsOneWidget);
      expect(ids, hasLength(2));
      expect(ids.toSet(), hasLength(1));
      final saved = await LocalFitLifeRepository().loadDay(day, today: day);
      expect(saved.diary, hasLength(4));
      expect(saved.diary.map((e) => e.id).toSet(), hasLength(4));
      expect(saved.diary.first.grams, 120);
      expect(
        saved.diary.first.food.provenance!.recordId,
        'imported_cofid_2021_12-550',
      );
      expect(saved.diary.every((e) => e.food.hasKnownFiber), isTrue);
      expect(saved.total.calories, closeTo(225.1, 1e-9));
    },
  );

  testWidgets(
    'catalogue read error can retry without unhandled future or diary changes',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        page(
          (_) async {},
          loader: () {
            if (calls++ == 0) throw StateError('disk');
            return Future.value(records);
          },
        ),
      );
      await tester.tap(find.text('Open ideas'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Не удалось открыть справочник'),
        findsOneWidget,
      );
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('idea-review-cottage_vegetables_v1')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      expect(
        (await SharedPreferences.getInstance()).getString(diaryKey),
        isNull,
      );
    },
  );

  testWidgets('missing required source disables only its affected idea', (
    tester,
  ) async {
    await tester.pumpWidget(
      page(
        (_) async {},
        loader: () async =>
            records.where((r) => !r.id.endsWith('12-550')).toList(),
      ),
    );
    await tester.tap(find.text('Open ideas'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('idea-review-cottage_vegetables_v1')),
          )
          .onPressed,
      isNull,
    );
    await reveal(tester, find.byKey(const Key('idea-review-chicken_rice_v1')));
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('idea-review-chicken_rice_v1')),
          )
          .onPressed,
      isNotNull,
    );
    expect(find.text('0 ккал'), findsNothing);
  });

  testWidgets(
    'Today and profile both open actual offline ideas without saving',
    (tester) async {
      await launch(tester);
      final today = find.text('Открыть идеи блюд');
      await reveal(tester, today);
      await tester.tap(today);
      await tester.pumpAndSettle();
      expect(find.text('Простые варианты без запроса AI'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Профиль').last);
      await tester.pumpAndSettle();
      final profile = find.widgetWithText(TextButton, 'Идеи блюд');
      await reveal(tester, profile);
      await tester.tap(profile);
      await tester.pumpAndSettle();
      expect(find.text('Простые варианты без запроса AI'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys().where((k) => k.startsWith('diary_')), isEmpty);
    },
  );
}
