import 'package:fitlife/data/repositories/diary_repository.dart';
import 'package:fitlife/features/satiety/hunger_observation.dart';
import 'package:fitlife/features/satiety/hunger_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'parallel_storage_test.dart' show ControlledDisk;
import 'satiety_estimate_test.dart' show satietyItem;
import 'support/source_flow.dart' show reveal;
import 'diary_flow_test.dart' show launch;

void main() {
  late ControlledDisk disk;
  late HungerRepository repo;
  late DateTime now;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    disk = ControlledDisk();
    SharedPreferencesStorePlatform.instance = disk;
    now = DateTime(2026, 10, 27, 15);
    repo = HungerRepository(DiaryRepository.withLoader(), clock: () => now);
  });
  testWidgets(
    'profile keeps observation history accessible with an empty diary',
    (tester) async {
      await launch(tester, size: const Size(360, 780));
      await tester.tap(find.text('Профиль').last);
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Наблюдения голода'));
      await tester.tap(find.text('Наблюдения голода'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Наблюдений пока нет'), findsOneWidget);
      expect(await repo.load(), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'damaged history stays recoverable; confirmed clear handles native failure and retry',
    (tester) async {
      const raw = '[{"damaged":"private"}]';
      await disk.setValue('String', 'flutter.$hungerObservationsKey', raw);
      await tester.pumpWidget(
        MaterialApp(home: HungerHistoryPage(repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Не удалось прочитать'), findsOneWidget);
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Не удалось прочитать'), findsOneWidget);
      disk.failKey = 'flutter.$hungerObservationsKey';
      await tester.tap(find.byTooltip('Удалить все наблюдения'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Удалить'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Не удалось удалить'), findsOneWidget);
      expect((await disk.getAll())['flutter.$hungerObservationsKey'], raw);
      disk.failKey = null;
      await tester.tap(find.byTooltip('Удалить все наблюдения'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Удалить'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Наблюдений пока нет'), findsOneWidget);
      expect(await repo.load(), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  Future<void> entry(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => HungerEntryPage(
                    repository: repo,
                    items: [satietyItem()],
                    meal: 'Обед',
                    day: now,
                    clock: () => now,
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  Future<void> mealTime(WidgetTester tester) async {
    await reveal(tester, find.byKey(const Key('hunger-meal-time')));
    await tester.tap(find.byKey(const Key('hunger-meal-time')));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '13');
    await tester.enterText(fields.at(1), '00');
    final ok = MaterialLocalizations.of(
      tester.element(find.byType(TimePickerDialog)),
    ).okButtonLabel;
    await tester.tap(find.text(ok));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'new observation is voluntary, has no default rating and cancellation writes nothing',
    (tester) async {
      await entry(tester);
      await reveal(tester, find.byKey(const Key('hunger-save')));
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('hunger-save')))
            .onPressed,
        isNull,
      );
      await reveal(tester, find.text('Пропустить'));
      await tester.tap(find.text('Пропустить'));
      await tester.pumpAndSettle();
      expect(await repo.load(), isEmpty);
    },
  );
  testWidgets(
    'failed save retains draft and observation time; retry saves once',
    (tester) async {
      await entry(tester);
      await mealTime(tester);
      await reveal(tester, find.text('Умеренный голод'));
      await tester.tap(find.text('Умеренный голод'));
      await reveal(tester, find.text('Нет'));
      await tester.tap(find.text('Нет'));
      disk.failKey = 'flutter.$hungerObservationsKey';
      await reveal(tester, find.byKey(const Key('hunger-save')));
      await tester.tap(find.byKey(const Key('hunger-save')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Не удалось сохранить'), findsOneWidget);
      expect(await repo.load(), isEmpty);
      now = now.add(const Duration(minutes: 5));
      disk.failKey = null;
      await tester.tap(find.byKey(const Key('hunger-save')));
      await tester.pumpAndSettle();
      final saved = (await repo.load()).single;
      expect(saved.elapsed.inMinutes, 120);
      expect(saved.observedAt.toLocal().hour, 15);
      expect(saved.observedAt.toLocal().minute, 0);
      expect(saved.level, 3);
      expect(saved.foodSince, FoodSinceMeal.no);
      expect(find.text('Open'), findsOneWidget);
    },
  );
  testWidgets(
    'history corrects the same observation and deletes with confirmation',
    (tester) async {
      final value = HungerObservation(
        id: 'a' * 32,
        meal: 'Обед',
        mealAt: now.subtract(const Duration(hours: 2)),
        observedAt: now,
        level: 2,
        foodSince: FoodSinceMeal.unknown,
        items: [satietyItem()],
      );
      await repo.save(value);
      await tester.pumpWidget(
        MaterialApp(home: HungerHistoryPage(repository: repo)),
      );
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Исправить'));
      await tester.tap(find.text('Исправить'));
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Сильный голод'));
      await tester.tap(find.text('Сильный голод'));
      await reveal(tester, find.byKey(const Key('hunger-save')));
      await tester.tap(find.byKey(const Key('hunger-save')));
      await tester.pumpAndSettle();
      expect((await repo.load()).single.level, 4);
      expect((await repo.load()).single.observedAt, value.observedAt.toUtc());
      await reveal(tester, find.text('Удалить запись'));
      await tester.tap(find.text('Удалить запись'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      expect((await repo.load()).length, 1);
      await tester.tap(find.text('Удалить запись'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Удалить'));
      await tester.pumpAndSettle();
      expect(await repo.load(), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
