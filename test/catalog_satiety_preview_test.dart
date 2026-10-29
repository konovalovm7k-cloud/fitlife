import 'dart:convert';
import 'dart:io';
import 'package:fitlife/app/fitlife_theme.dart';
import 'package:fitlife/core/nutrition/nutrition_catalog_page.dart';
import 'package:fitlife/core/nutrition/nutrition_database.dart';
import 'package:fitlife/core/nutrition/nutrition_day.dart';
import 'package:fitlife/features/satiety/food_satiety_preview_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/source_flow.dart' show reveal;

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final catalogue = File('assets/data/food_catalog.json').readAsStringSync();
  late List<({NutritionDayEntry entry, String id})> calls;
  late bool fail;
  setUp(() {
    rootBundle.evict('assets/data/food_catalog.json');
    binding.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (message) async =>
          ByteData.sublistView(Uint8List.fromList(utf8.encode(catalogue))),
    );
    SharedPreferences.setMockInitialValues({'kept': 'original'});
    calls = [];
    fail = false;
  });
  Future<void> top(WidgetTester tester) async {
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(0);
    await tester.pumpAndSettle();
  }

  Future<void> open(
    WidgetTester tester, {
    NutritionDay initial = const NutritionDay(),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: fitLifeTheme(),
        home: NutritionCatalogPage(
          initialDay: initial,
          onAdd: (entry, id) async {
            calls.add((entry: entry, id: id));
            if (fail) throw StateError('disk');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Поиск продуктов'),
      'Яблоко',
    );
    await tester.pumpAndSettle();
    final card = find.ancestor(
      of: find.text('Яблоко'),
      matching: find.byType(Card),
    );
    final add = find.descendant(
      of: card,
      matching: find.text('Добавить в дневник'),
    );
    await reveal(tester, add);
    await tester.tap(add);
    await tester.pumpAndSettle();
  }

  Future<void> preview(WidgetTester tester) async {
    final button = find.byKey(const Key('catalog-satiety-preview'));
    await reveal(tester, button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'catalogue grams and source reach read-only preview; back retains exact draft; cancel never calls save',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await open(tester);
      final grams = find.byType(TextFormField);
      await tester.enterText(grams, '150,5');
      await tester.pumpAndSettle();
      await reveal(tester, find.textContaining('78 ккал').last);
      expect(calls, isEmpty);
      await preview(tester);
      final page = tester.widget<FoodSatietyPreviewPage>(
        find.byType(FoodSatietyPreviewPage),
      );
      expect(page.grams, 150.5);
      expect(page.source.provenance.recordId, 'healthdiet_15983');
      await reveal(tester, find.byKey(const Key('food-satiety-score')));
      expect(calls, isEmpty);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(tester.widget<TextFormField>(grams).controller!.text, '150,5');
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
      expect(
        (await SharedPreferences.getInstance()).getString('kept'),
        'original',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'explicit add after preview retains source and retry identity, without losing the existing day',
    (tester) async {
      final base = NutritionDay(
        entries: [NutritionDayEntry(food: nutritionDatabase.first, grams: 80)],
      );
      await open(tester, initial: base);
      await tester.enterText(find.byType(TextFormField), '150.5');
      await preview(tester);
      await tester.pageBack();
      await tester.pumpAndSettle();
      fail = true;
      await tester.tap(find.text('Добавить').last);
      await tester.pumpAndSettle();
      expect(calls, hasLength(1));
      expect(calls.single.entry.grams, 150.5);
      expect(calls.single.entry.food.id, 'healthdiet_15983');
      expect(calls.single.entry.profile.kcal, closeTo(78.26, .000001));
      await top(tester);
      await reveal(tester, find.text('Повторить сохранение'));
      fail = false;
      await tester.tap(find.text('Повторить сохранение'));
      await tester.pumpAndSettle();
      expect(calls, hasLength(2));
      expect(calls.last.id, calls.first.id);
      expect(calls.last.entry.grams, 150.5);
      await top(tester);
      expect(
        find.text('Ккал ${(base.total.kcal + 78.26).toStringAsFixed(2)}'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'invalid mass cannot preview or add; the existing larger logging limit is unchanged',
    (tester) async {
      await open(tester);
      final grams = find.byType(TextFormField);
      await tester.enterText(grams, '0');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('catalog-satiety-preview')), findsNothing);
      await tester.tap(find.text('Добавить').last);
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.enterText(grams, '4000');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('catalog-satiety-preview')), findsNothing);
      expect(
        find.text('Оценка свойств доступна для порций до 3000 г.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Добавить').last);
      await tester.pumpAndSettle();
      expect(calls, hasLength(1));
      expect(calls.single.entry.grams, 4000);
      expect(tester.takeException(), isNull);
    },
  );
}
