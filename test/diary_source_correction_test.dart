import 'dart:async';
import 'dart:convert';
import 'package:fitlife/core/models/diary_item.dart';
import 'package:fitlife/features/photo_analysis/food_source_page.dart';
import 'package:fitlife/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'diary_flow_test.dart' show launch, dateKey;
import 'parallel_storage_test.dart' show ControlledDisk;
import 'support/source_flow.dart' show reveal;

void main() {
  late ControlledDisk disk;
  late String key;
  late DiaryItem original;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    disk = ControlledDisk();
    SharedPreferencesStorePlatform.instance = disk;
    key = 'diary_${dateKey(DateTime.now())}';
    original = const DiaryItem(
      id: 'legacy_entry',
      meal: 'Обед',
      time: '12:34',
      grams: 150.5,
      food: FoodItem(
        id: 'legacy_food',
        name: 'Яблоко',
        kcal: 200,
        protein: 0,
        fat: 0,
        carbs: 50,
        fiber: 0,
        isPhotoEstimate: true,
      ),
    );
  });
  Future<void> openSource(WidgetTester tester) async {
    await tester.tap(find.text('Питание').last);
    await tester.pumpAndSettle();
    final button = find.byTooltip('Источник состава: Яблоко');
    await reveal(tester, button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('В дневнике: Яблоко'), findsOneWidget);
    expect(find.text('Удалить ингредиент'), findsNothing);
  }

  Future<void> chooseApple(WidgetTester tester) async {
    await reveal(tester, find.widgetWithText(ListTile, 'Яблоко'));
    await tester.tap(find.widgetWithText(ListTile, 'Яблоко'));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('source-confirm')));
  }

  Future<List<dynamic>> stored() async =>
      jsonDecode((await disk.getAll())['flutter.$key']! as String) as List;

  for (final confirm in [false, true]) {
    testWidgets(
      'Today targets the actual incomplete entry; ${confirm ? 'confirmation updates it in place' : 'cancel writes nothing'}',
      (tester) async {
        original = DiaryItem.fromJson({
          ...original.toJson(),
          'food': {...original.food.toJson(), 'fiberKnown': false},
        });
        const keep = DiaryItem(
          id: 'known_first',
          meal: 'Завтрак',
          time: '09:12',
          grams: 100,
          food: FoodItem(
            id: 'known_food',
            name: 'Не менять',
            kcal: 50,
            protein: 1,
            fat: 0,
            carbs: 10,
            fiber: 0,
          ),
        );
        await disk.setValue(
          'String',
          'flutter.$key',
          jsonEncode([keep.toJson(), original.toJson()]),
        );
        await launch(tester, size: const Size(360, 780));
        final before = {...await disk.getAll()};
        await reveal(tester, find.text('Уточнить запись'));
        await tester.tap(find.text('Уточнить запись'));
        await tester.pumpAndSettle();
        final page = tester.widget<FoodSourcePage>(find.byType(FoodSourcePage));
        expect(page.food!.name, 'Яблоко');
        expect(page.food!.grams, 150.5);
        expect(page.allowDelete, isFalse);
        expect(find.text('В дневнике: Яблоко'), findsOneWidget);
        expect({...await disk.getAll()}, before);
        if (!confirm) {
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
          expect({...await disk.getAll()}, before);
        } else {
          await chooseApple(tester);
          await tester.tap(find.byKey(const Key('source-confirm')));
          await tester.pumpAndSettle();
          expect(find.byType(FoodSourcePage), findsNothing);
          final records = await stored();
          expect(records, hasLength(2));
          expect(records.singleWhere((r) => r['id'] == keep.id), keep.toJson());
          final changed = records.singleWhere((r) => r['id'] == original.id);
          expect(changed['food']['id'], original.food.id);
          expect(
            changed['food']['nutritionSource']['recordId'],
            'healthdiet_15983',
          );
          expect(changed['meal'], original.meal);
          expect(changed['time'], original.time);
          expect(changed['grams'], original.grams);
          final afterOther = {...await disk.getAll()}..remove('flutter.$key');
          expect(afterOther, {...before}..remove('flutter.$key'));
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpWidget(const FitLifeRoot());
          await tester.pumpAndSettle();
          expect(find.text('Уточнить запись'), findsNothing);
          expect(await stored(), records);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'source correction preserves ID/date/time and other meals; failed native write keeps draft',
    (tester) async {
      const keep = DiaryItem(
        id: 'keep',
        meal: 'Завтрак',
        time: '09:12',
        grams: 100,
        food: FoodItem(
          id: 'keep_food',
          name: 'Не менять',
          kcal: 50,
          protein: 1,
          fat: 0,
          carbs: 10,
          fiber: 0,
        ),
      );
      final before = jsonEncode([original.toJson(), keep.toJson()]);
      await disk.setValue('String', 'flutter.$key', before);
      await launch(tester, size: const Size(360, 780));
      await openSource(tester);
      expect((await disk.getAll())['flutter.$key'], before);
      await chooseApple(tester);
      disk.failKey = 'flutter.$key';
      await tester.tap(find.byKey(const Key('source-confirm')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Не удалось сохранить состав'),
        findsOneWidget,
      );
      expect(find.byType(FoodSourcePage), findsOneWidget);
      expect((await disk.getAll())['flutter.$key'], before);
      disk.failKey = null;
      await reveal(tester, find.byKey(const Key('source-confirm')));
      await tester.tap(find.byKey(const Key('source-confirm')));
      await tester.pumpAndSettle();
      final records = await stored();
      expect(records.length, 2);
      final changed = records.singleWhere((r) => r['id'] == original.id);
      expect(changed['meal'], 'Обед');
      expect(changed['time'], '12:34');
      expect(changed['grams'], 150.5);
      expect(changed['food']['kcal'], 52);
      expect(
        changed['food']['nutritionSource']['recordId'],
        'healthdiet_15983',
      );
      expect(changed['food']['id'], 'legacy_food');
      expect(records.singleWhere((r) => r['id'] == 'keep'), keep.toJson());
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(const FitLifeRoot());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Питание').last);
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('satiety-Обед')));
      expect(find.textContaining('150,5 г'), findsOneWidget);
      await tester.tap(find.byKey(const Key('satiety-Обед')));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('satiety-score')));
      expect(find.byKey(const Key('satiety-score')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'sub-gram portion survives source update; pending write blocks duplicate submit and back',
    (tester) async {
      final tiny = {...original.toJson(), 'grams': .5};
      await disk.setValue('String', 'flutter.$key', jsonEncode([tiny]));
      await launch(tester, size: const Size(360, 780));
      await openSource(tester);
      await chooseApple(tester);
      disk.pauseKey = 'flutter.$key';
      disk.pause = Completer<void>();
      await tester.tap(find.byKey(const Key('source-confirm')));
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('source-confirm')))
            .onPressed,
        isNull,
      );
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(FoodSourcePage), findsOneWidget);
      disk.pause!.complete();
      await tester.pumpAndSettle();
      final result = await stored();
      expect(result.length, 1);
      expect(result.single['grams'], .5);
      await reveal(tester, find.textContaining('0,5 г'));
      expect(find.textContaining('0,5 г'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('cancelling source choice leaves legacy entry untouched', (
    tester,
  ) async {
    final before = jsonEncode([original.toJson()]);
    await disk.setValue('String', 'flutter.$key', before);
    await launch(tester, size: const Size(360, 780));
    await openSource(tester);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect((await disk.getAll())['flutter.$key'], before);
    expect(tester.takeException(), isNull);
  });
}
