import 'dart:convert';
import 'package:fitlife/app/fitlife_theme.dart';
import 'package:fitlife/data/repositories/diary_repository.dart';
import 'package:fitlife/features/saved_meals/saved_meals.dart';
import 'package:fitlife/features/saved_meals/saved_meals_page.dart';
import 'package:fitlife/features/saved_meals/saved_meal_editor.dart';
import 'package:fitlife/features/progress/weight_history.dart';
import 'package:fitlife/features/progress/weight_history_page.dart';
import 'package:fitlife/modern_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'parallel_storage_test.dart' show ControlledDisk, entry;

void main() {
  late ControlledDisk disk;
  final day = DateTime(2026, 10, 23);
  SavedMeal recipe() =>
      SavedMeal(id: 'test', name: 'Мой завтрак', items: [entry('one')]);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    disk = ControlledDisk();
    SharedPreferencesStorePlatform.instance = disk;
  });
  Future<void> reveal(WidgetTester tester, String label) async {
    await tester.scrollUntilVisible(
      find.text(label),
      150,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> launch(
    WidgetTester tester,
    Widget child, {
    bool iphone = false,
  }) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: fitLifeTheme().copyWith(
          platform: iphone ? TargetPlatform.iOS : TargetPlatform.android,
        ),
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: child,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('saved meal editor retains composition on failure and retries', (
    tester,
  ) async {
    disk.failKey = 'flutter.$savedMealsKey';
    await launch(
      tester,
      SavedMealEditor(
        initial: recipe(),
        repository: SavedMealsRepository(DiaryRepository.withLoader()),
      ),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Название блюда'),
      'Завтрак дома',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Порций во всём составе'),
      '2',
    );
    await reveal(tester, 'Сохранить в мои блюда');
    await tester.tap(find.text('Сохранить в мои блюда'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Состав остался здесь'), findsOneWidget);
    expect(find.text('Завтрак дома'), findsOneWidget);
    disk.failKey = null;
    await reveal(tester, 'Сохранить в мои блюда');
    await tester.tap(find.text('Сохранить в мои блюда'));
    await tester.pumpAndSettle();
    final saved = (await SavedMealsRepository(
      DiaryRepository.withLoader(),
    ).load()).meals.single;
    expect(saved.name, 'Завтрак дома');
    expect(saved.servings, 2);
  });
  testWidgets('iPhone portion flow keeps failed input and retries one batch', (
    tester,
  ) async {
    final repository = SavedMealsRepository(DiaryRepository.withLoader());
    await repository.save(recipe());
    await launch(
      tester,
      SavedMealsPage(repository: repository, day: day, initialMeal: 'Обед'),
      iphone: true,
    );
    await tester.tap(find.text('Выбрать порцию'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Количество порций'),
      '0,5',
    );
    disk.failKey = 'flutter.diary_2026-10-23';
    await reveal(tester, 'Добавить блюдо в дневник');
    await tester.tap(find.text('Добавить блюдо в дневник'));
    await tester.pumpAndSettle();
    expect(find.textContaining('дубля не будет'), findsOneWidget);
    disk.failKey = null;
    await reveal(tester, 'Добавить блюдо в дневник');
    await tester.tap(find.text('Добавить блюдо в дневник'));
    await tester.pumpAndSettle();
    final saved =
        jsonDecode((await disk.getAll())['flutter.diary_2026-10-23']! as String)
            as List;
    expect(saved.single['grams'], 50);
    expect(saved.single['meal'], 'Обед');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'weight history has honest empty and single-point states on iPhone',
    (tester) async {
      final repository = WeightRepository(DiaryRepository.withLoader());
      await launch(
        tester,
        WeightHistoryPage(repository: repository),
        iphone: true,
      );
      expect(find.text('Пока нет данных'), findsOneWidget);
      expect(find.text('104.2 кг'), findsNothing);
      await repository.save(
        WeightEntry(DateUtils.dateOnly(DateTime.now()), 80),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await launch(
        tester,
        WeightHistoryPage(repository: repository),
        iphone: true,
      );
      expect(find.text('Для динамики нужны два измерения'), findsOneWidget);
      expect(find.text('80.0 кг'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('iPhone compact editor with keyboard remains scrollable', (
    tester,
  ) async {
    await launch(
      tester,
      SavedMealEditor(
        initial: recipe(),
        repository: SavedMealsRepository(DiaryRepository.withLoader()),
      ),
      iphone: true,
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetViewInsets);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Порций во всём составе'),
      '1,5',
    );
    await tester.pumpAndSettle();
    await reveal(tester, 'Сохранить в мои блюда');
    expect(find.text('Сохранить в мои блюда').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('home meal bookmark creates template without modifying diary', (
    tester,
  ) async {
    final key = 'diary_${diaryDateKey(DateTime.now())}';
    await disk.setValue(
      'String',
      'flutter.$key',
      jsonEncode([entry('source').toJson()]),
    );
    await launch(tester, const FitLifeHome());
    await tester.tap(find.text('Питание').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byTooltip('Сохранить блюдо'), 200);
    await tester.ensureVisible(find.byTooltip('Сохранить блюдо'));
    await tester.tap(find.byTooltip('Сохранить блюдо'));
    await tester.pumpAndSettle();
    await reveal(tester, 'Сохранить в мои блюда');
    await tester.tap(find.text('Сохранить в мои блюда'));
    await tester.pumpAndSettle();
    expect(
      (await SavedMealsRepository(
        DiaryRepository.withLoader(),
      ).load()).meals.single.items.single.grams,
      100,
    );
    expect(
      jsonDecode((await disk.getAll())['flutter.$key']! as String),
      hasLength(1),
    );
  });
}
