import 'dart:async';
import 'dart:convert';
import 'package:fitlife/core/models/diary_item.dart';
import 'package:fitlife/features/saved_meals/saved_meal_editor.dart';
import 'package:fitlife/features/saved_meals/saved_meals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'diary_flow_test.dart' show launch, dateKey;
import 'parallel_storage_test.dart' show ControlledDisk;
import 'support/source_flow.dart' show reveal;

const ingredient = DiaryItem(
  id: 'original-entry',
  meal: 'Обед',
  time: '12:34',
  grams: 100,
  food: FoodItem(
    id: 'egg',
    name: 'Яйцо',
    kcal: 157,
    protein: 12,
    fat: 10,
    carbs: 1,
    fiber: 0,
  ),
);

void main() {
  late ControlledDisk disk;
  late String diaryKey;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    disk = ControlledDisk();
    SharedPreferencesStorePlatform.instance = disk;
    diaryKey = 'flutter.diary_${dateKey(DateTime.now())}';
    await disk.setValue('String', diaryKey, jsonEncode([ingredient.toJson()]));
  });

  Future<void> openDraft(WidgetTester tester) async {
    final save = find.byTooltip('Сохранить блюдо');
    await reveal(tester, save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.byType(SavedMealEditor), findsOneWidget);
  }

  testWidgets(
    'template ID survives route rebuild; a separate draft gets its own ID',
    (tester) async {
      await launch(tester, size: const Size(360, 780));
      await tester.tap(find.text('Питание').last);
      await tester.pumpAndSettle();
      final before = {...await disk.getAll()};
      await openDraft(tester);
      final draft = find.byType(SavedMealEditor);
      final originalId = tester.widget<SavedMealEditor>(draft).initial.id;
      final name = find.widgetWithText(TextFormField, 'Название блюда');
      await tester.enterText(name, 'Мой обед');
      ModalRoute.of(tester.element(draft))!.changedExternalState();
      await tester.pumpAndSettle();
      expect(tester.widget<SavedMealEditor>(draft).initial.id, originalId);
      expect(tester.widget<TextFormField>(name).controller!.text, 'Мой обед');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await openDraft(tester);
      expect(
        tester.widget<SavedMealEditor>(draft).initial.id,
        isNot(originalId),
      );
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect({...await disk.getAll()}, before);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'timed-out native write and rebuilt-route retry store one template',
    (tester) async {
      final kept = SavedMeal(
        id: 'kept-template',
        name: 'Не менять',
        items: [ingredient],
      );
      await disk.setValue(
        'String',
        'flutter.$savedMealsKey',
        jsonEncode([kept.toJson()]),
      );
      await launch(tester, size: const Size(360, 780));
      await tester.tap(find.text('Питание').last);
      await tester.pumpAndSettle();
      final before = {...await disk.getAll()};
      await openDraft(tester);
      final draft = find.byType(SavedMealEditor);
      final draftId = tester.widget<SavedMealEditor>(draft).initial.id;
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Название блюда'),
        'Мой обед',
      );
      final save = find.text('Сохранить в мои блюда');
      await reveal(tester, save);
      disk.pauseKey = 'flutter.$savedMealsKey';
      disk.pause = Completer<void>();
      addTearDown(() {
        if (!disk.pause!.isCompleted) disk.pause!.complete();
      });
      disk.writes.clear();
      await tester.tap(save);
      await tester.pump();
      expect(disk.pauseKey, isNull);
      await tester.pump(const Duration(seconds: 16));
      expect(
        find.textContaining('Не удалось сохранить. Состав остался здесь'),
        findsOneWidget,
      );
      ModalRoute.of(tester.element(draft))!.changedExternalState();
      await tester.pumpAndSettle();
      await reveal(tester, save);
      await tester.tap(save);
      await tester.pump();
      disk.pause!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(SavedMealEditor), findsNothing);
      final values = {...await disk.getAll()};
      final stored =
          jsonDecode(values['flutter.$savedMealsKey']! as String) as List;
      expect(stored, hasLength(2));
      expect(
        stored.singleWhere((entry) => entry['id'] == kept.id),
        kept.toJson(),
      );
      final saved = stored.singleWhere((entry) => entry['name'] == 'Мой обед');
      expect(saved['id'], draftId);
      expect(saved['items'], [ingredient.toJson()]);
      expect(
        disk.writes.where((key) => key == 'flutter.$savedMealsKey'),
        hasLength(2),
      );
      values.remove('flutter.$savedMealsKey');
      expect(values, {...before}..remove('flutter.$savedMealsKey'));
      expect(tester.takeException(), isNull);
    },
  );
}
