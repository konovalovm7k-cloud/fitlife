import 'dart:convert';
import 'dart:io';
import 'package:fitlife/app/state/fitlife_controller.dart';
import 'package:fitlife/core/nutrition/food_catalog_import.dart';
import 'package:fitlife/core/nutrition/nutrition_catalog_page.dart';
import 'package:fitlife/core/nutrition/nutrition_day.dart';
import 'package:fitlife/core/nutrition/nutrition_engine.dart';
import 'package:fitlife/data/repositories/local_fitlife_repository.dart';
import 'package:fitlife/features/photo_analysis/food_source_page.dart';
import 'package:fitlife/features/photo_analysis/photo_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/source_flow.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final text = File('assets/data/food_catalog.json').readAsStringSync();
  final records = parseFoodCatalog(text);
  setUp(() {
    rootBundle.evict('assets/data/food_catalog.json');
    binding.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (message) async =>
          ByteData.sublistView(Uint8List.fromList(utf8.encode(text))),
    );
  });
  final rice = records.singleWhere((r) => r.id.endsWith('11-858'));
  final yogurt = records.singleWhere((r) => r.id.endsWith('12-379'));
  testWidgets('source search finds reordered words without auto selecting', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FoodSourcePage(
          food: PhotoFood(name: 'рис вареный', grams: 150.5, confidence: 'low'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, rice.name), findsOneWidget);
    expect(find.byType(ListTile), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('source-confirm')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.widgetWithText(ListTile, rice.name));
    await tester.pumpAndSettle();
    expect(find.text('Выбрано: ${rice.name}'), findsOneWidget);
    await reveal(tester, find.byKey(const Key('source-confirm')));
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('source-confirm')))
          .onPressed,
      isNotNull,
    );
  });
  testWidgets(
    'no-match escape opens full catalogue without selecting or saving',
    (tester) async {
      var saves = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: FoodSourcePage(
            food: const PhotoFood(
              name: 'Несуществующее блюдо',
              grams: 150.5,
              confidence: 'low',
            ),
            onSave: (_) async {
              saves++;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsNothing);
      final all = find.byKey(const Key('source-show-all'));
      await tester.ensureVisible(all);
      await tester.tap(all);
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsWidgets);
      expect(
        tester
            .widget<TextField>(
              find.widgetWithText(TextField, 'Поиск в каталоге'),
            )
            .controller!
            .text,
        isEmpty,
      );
      await reveal(tester, find.byKey(const Key('source-confirm')));
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('source-confirm')))
            .onPressed,
        isNull,
      );
      expect(saves, 0);
    },
  );
  testWidgets(
    'selected catalogue product narrows the list and query stays editable',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: FoodSourcePage()));
      await tester.pumpAndSettle();
      final query = find.widgetWithText(TextField, 'Поиск в каталоге');
      await tester.enterText(query, 'CoFID');
      await tester.pumpAndSettle();
      final apple = records.first;
      final row = find.widgetWithText(ListTile, apple.name);
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(query).controller!.text, apple.name);
      await reveal(tester, row);
      expect(find.byType(ListTile), findsOneWidget);
      await reveal(tester, find.byKey(const Key('source-confirm')));
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('source-confirm')))
            .onPressed,
        isNotNull,
      );
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      await tester.ensureVisible(query);
      await tester.enterText(query, 'Банан');
      await tester.pumpAndSettle();
      final banana = find.widgetWithText(ListTile, 'Банан, мякоть (CoFID)');
      await tester.ensureVisible(banana);
      await tester.tap(banana);
      await tester.pumpAndSettle();
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(query).controller!.text,
        'Банан, мякоть (CoFID)',
      );
      await reveal(tester, banana);
      expect(find.byType(ListTile), findsOneWidget);
    },
  );
  test('curated identities, source values and unknown fibre are explicit', () {
    expect(records, hasLength(20));
    expect(records.map((r) => r.id).toSet(), hasLength(20));
    expect(records.every((r) => r.macrosOnly), isTrue);
    expect(records.where((r) => r.hasKnownFiber), hasLength(19));
    expect(yogurt.hasKnownFiber, isFalse); // CoFID AOAC fibre = N.
    expect(rice.profile.kcal, 117);
    expect(rice.profile.water, 69.5);
    expect(rice.profile.fiber, .6);
    final source = NutritionSource.catalogue(rice);
    final portion = NutritionEngine.portion(source, 150.5);
    expect(portion.kcal, closeTo(176.085, 1e-9));
    expect(portion.fiber, closeTo(.903, 1e-9));
    expect(source.provenance.reference, contains('11-858'));
    expect(source.fiberKnown, isTrue);
    expect(NutritionSource.catalogue(yogurt).fiberKnown, isFalse);
  });
  test('invalid optional nutrients reject import instead of becoming zero', () {
    for (final key in ['fiber', 'water']) {
      for (final value in [-1, 101, 'Tr', null]) {
        final data = jsonDecode(text) as Map<String, dynamic>;
        data['foods'][0][key] = value;
        expect(() => parseFoodCatalog(jsonEncode(data)), throwsFormatException);
      }
    }
  });
  test('known fibre and exact source survive real repository reload', () async {
    SharedPreferences.setMockInitialValues({});
    final day = DateTime(2026, 10, 27);
    final controller = FitLifeController(
      repository: LocalFitLifeRepository(),
      clock: () => day,
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.addCatalogFood(
      day,
      rice,
      grams: 150.5,
      meal: 'Обед',
      time: '12:00',
    );
    await controller.addCatalogFood(
      day,
      yogurt,
      grams: 100,
      meal: 'Перекус',
      time: '16:00',
    );
    final reloaded = FitLifeController(
      repository: LocalFitLifeRepository(),
      clock: () => day,
    );
    addTearDown(reloaded.dispose);
    await reloaded.initialize();
    final saved = reloaded.state.diary;
    expect(saved.map((e) => e.food.hasKnownFiber), [true, false]);
    expect(saved.first.grams, 150.5);
    expect(saved.first.food.provenance!.recordId, rice.id);
    expect(saved.first.food.profile.water, 69.5);
    expect(reloaded.nutritionDay.entries.first.food.hasKnownFiber, isTrue);
    expect(reloaded.nutritionDay.entries.first.food.macrosOnly, isTrue);
    expect(reloaded.state.total.fiber, closeTo(.903, 1e-9));
  });
  testWidgets(
    'catalogue distinguishes known fibre from missing micronutrients',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: NutritionCatalogPage()));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'Рис басмати белый, варёный',
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -250));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Клетчатка: 0.60 г на 100 г.'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Витамины и минералы в этой подборке не представлены.',
        ),
        findsOneWidget,
      );
    },
  );
  testWidgets('mixed diary fibre total is a lower bound, not measured zero', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NutritionCatalogPage(
          initialDay: NutritionDay(
            entries: [NutritionDayEntry(food: yogurt, grams: 100)],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Клетчатка ≥ 0'), findsOneWidget);
  });
}
