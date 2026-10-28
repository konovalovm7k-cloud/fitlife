import 'support/confirmed_food.dart';
import 'dart:async';
import 'dart:convert';

import 'package:fitlife/app/state/fitlife_controller.dart';
import 'package:fitlife/app/state/fitlife_state.dart';
import 'package:fitlife/core/models/nutrition_goal_settings.dart';
import 'package:fitlife/core/nutrition/nutrition_database.dart';
import 'package:fitlife/data/repositories/settings_repository.dart';
import 'package:fitlife/features/photo_analysis/photo_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'diary_repository_test.dart' show entry;
import 'photo_service_test.dart' show sampleFood;
import 'support/controlled_fitlife_repository.dart';
import 'support/settings_disk.dart';

void main() {
  final today = DateTime(2026, 10, 21);
  final yesterday = DateTime(2026, 10, 20);
  const changed = NutritionGoalSettings(
    calories: 2400,
    protein: 160,
    fat: 70,
    fiber: 35,
  );
  late ControlledFitLifeRepository repo;
  late SettingsDisk disk;
  late DateTime clock;
  late FitLifeController controller;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    disk = SettingsDisk();
    SharedPreferencesStorePlatform.instance = disk;
    repo = ControlledFitLifeRepository();
    clock = today;
    controller = FitLifeController(repository: repo, clock: () => clock);
  });
  tearDown(() => controller.dispose());

  test(
    'a stale read failure after a committed save triggers a fresh read',
    () async {
      await controller.initialize();
      final saveGate = Completer<void>();
      repo.onGoals = (goals) async {
        await saveGate.future;
        await repo.local.saveGoals(goals);
      };
      final save = controller.saveGoals(changed);
      final stale = Completer<FitLifeState>();
      var calls = 0;
      repo.onLoad = (day, now) =>
          calls++ == 0 ? stale.future : repo.local.loadDay(day, today: now);
      final reload = controller.load();
      saveGate.complete();
      await save;
      stale.completeError(StateError('Old read failed'));
      await reload;
      expect(controller.state.status, FitLifeLoadStatus.ready);
      expect(controller.state.goals.toJson(), changed.toJson());
      expect(calls, 2);
    },
  );

  test(
    'state snapshots isolate mutable lists and preserve precise daily totals',
    () async {
      await controller.initialize();
      final before = controller.state;
      await controller.saveEntry(today, entry('rice'));
      final saved = controller.state;
      expect(before.diary, isEmpty);
      expect(saved.total.calories, closeTo(517.72, 1e-9));
      expect(saved.total.fiber, closeTo(3.612, 1e-9));
      expect(saved.caloriesLeft, closeTo(1382.28, 1e-9));
      expect(saved.carbsTarget, 148.75);
      expect(() => saved.diary.clear(), throwsUnsupportedError);
      expect(() => saved.favorites.add('rice'), throwsUnsupportedError);
      expect(() => controller.foods.clear(), throwsUnsupportedError);
      final original = [entry('external')];
      final snapshot = FitLifeState(day: today, diary: original);
      original.clear();
      expect(snapshot.diary.single.id, 'external');
    },
  );

  test('initialization starts exactly one load', () async {
    final pending = Completer<FitLifeState>();
    repo.onLoad = (_, __) => pending.future;
    final first = controller.initialize();
    await controller.initialize();
    expect(repo.loads, 1);
    pending.complete(FitLifeState(day: today));
    await first;
    expect(controller.state.status, FitLifeLoadStatus.ready);
  });

  test(
    'out-of-order loads cannot replace the selected historical day',
    () async {
      final first = Completer<FitLifeState>();
      final second = Completer<FitLifeState>();
      repo.onLoad = (day, _) => day == today ? first.future : second.future;
      final initial = controller.initialize();
      final historical = controller.selectDay(yesterday);
      second.complete(
        FitLifeState(day: yesterday, diary: [entry('history')], water: 0.75),
      );
      await historical;
      first.complete(
        FitLifeState(day: today, diary: [entry('stale')], water: 3),
      );
      await initial;
      expect(controller.state.day, yesterday);
      expect(controller.state.diary.single.id, 'history');
      expect(controller.state.water, 0.75);
    },
  );

  test(
    'stale load errors cannot turn a successfully selected day into a failure',
    () async {
      final pending = Completer<FitLifeState>();
      repo.onLoad = (day, now) =>
          day == today ? pending.future : repo.local.loadDay(day, today: now);
      final initial = controller.initialize();
      await controller.selectDay(yesterday);
      pending.completeError(StateError('Old failure'));
      await initial;
      expect(controller.state.status, FitLifeLoadStatus.ready);
      expect(controller.state.day, yesterday);
    },
  );

  test(
    'a pending water increment stays on its original day after navigation',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('water_2026-10-20', 0.75);
      await controller.initialize();
      final gate = Completer<void>();
      repo.onWater = (day, amount) async {
        await gate.future;
        return repo.local.addWater(day, amount);
      };
      final save = controller.addWater(today);
      await controller.selectDay(yesterday);
      gate.complete();
      await save;
      expect(controller.state.day, yesterday);
      expect(controller.state.water, 0.75);
      await prefs.reload();
      expect(prefs.getDouble('water_2026-10-21'), 0.25);
    },
  );

  test(
    'pending manual entries never appear on the newly selected day',
    () async {
      await controller.initialize();
      final gate = Completer<void>();
      repo.onEntry = (day, item) async {
        await gate.future;
        return repo.local.saveEntry(day, item);
      };
      final save = controller.saveEntry(today, entry('original-date'));
      await controller.selectDay(yesterday);
      gate.complete();
      await save;
      expect(controller.state.diary, isEmpty);
      await controller.selectDay(today);
      expect(controller.state.diary.single.id, 'original-date');
    },
  );

  test(
    'photo completion preserves its original date without replacing the selected diary',
    () async {
      await controller.initialize();
      final gate = Completer<void>();
      repo.onPhoto = (meal) async {
        await gate.future;
        return repo.local.savePhoto(meal);
      };
      final meal = PhotoMeal(
        id: 'a' * 32,
        day: today,
        meal: 'Обед',
        items: [confirmedFood(sampleFood)],
      );
      final save = controller.savePhoto(meal);
      await controller.selectDay(yesterday);
      gate.complete();
      await save;
      expect(controller.state.diary, isEmpty);
      await controller.selectDay(today);
      expect(controller.state.diary.single.food.isPhotoEstimate, isTrue);
    },
  );

  test(
    'a load snapshot requested before a completed save cannot roll back its goals',
    () async {
      await controller.initialize();
      final saveGate = Completer<void>();
      repo.onGoals = (goals) async {
        await saveGate.future;
        await repo.local.saveGoals(goals);
      };
      final save = controller.saveGoals(changed);
      final stale = Completer<FitLifeState>();
      var calls = 0;
      repo.onLoad = (day, now) =>
          calls++ == 0 ? stale.future : repo.local.loadDay(day, today: now);
      final observed = <double>[];
      controller.addListener(
        () => observed.add(controller.state.goals.calories),
      );
      final reload = controller.load();
      saveGate.complete();
      await save;
      stale.complete(FitLifeState(day: today));
      await reload;
      expect(calls, 2);
      expect(controller.state.goals.toJson(), changed.toJson());
      expect(observed.skipWhile((value) => value != 2400), everyElement(2400));
      expect(controller.state.status, FitLifeLoadStatus.ready);
    },
  );

  test(
    'startup timeout blocks mutations and ignores completion after a successful retry',
    () async {
      final timed = FitLifeController(
        repository: repo,
        clock: () => today,
        loadTimeout: const Duration(milliseconds: 10),
      );
      addTearDown(timed.dispose);
      final stalled = Completer<FitLifeState>();
      var calls = 0;
      repo.onLoad = (day, now) =>
          calls++ == 0 ? stalled.future : repo.local.loadDay(day, today: now);
      await timed.initialize();
      expect(timed.state.status, FitLifeLoadStatus.failed);
      await expectLater(
        timed.saveEntry(today, entry('blocked')),
        throwsStateError,
      );
      await timed.load();
      stalled.complete(FitLifeState(day: today, water: 99));
      await Future<void>.delayed(Duration.zero);
      expect(timed.state.status, FitLifeLoadStatus.ready);
      expect(timed.state.water, 0);
      expect(timed.state.diary, isEmpty);
    },
  );

  test(
    'midnight follows today while historical selection remains stable on resume',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('water_2026-10-22', 0.5);
      await controller.initialize();
      clock = DateTime(2026, 10, 22, 0, 1);
      await controller.resume();
      expect(controller.state.day, DateTime(2026, 10, 22));
      expect(controller.state.water, 0.5);
      expect(controller.isToday, isTrue);
      await controller.selectDay(yesterday);
      final loads = repo.loads;
      clock = DateTime(2026, 10, 23);
      await controller.resume();
      expect(controller.state.day, yesterday);
      expect(controller.isToday, isFalse);
      expect(repo.loads, loads);
    },
  );

  test('disposal ignores late startup without sending notifications', () async {
    final disposable = FitLifeController(repository: repo, clock: () => today);
    final pending = Completer<FitLifeState>();
    repo.onLoad = (_, __) => pending.future;
    var notifications = 0;
    disposable.addListener(() => notifications++);
    final load = disposable.initialize();
    disposable.dispose();
    final count = notifications;
    pending.complete(FitLifeState(day: today, water: 5));
    await load;
    expect(notifications, count);
    expect(disposable.state.water, 0);
    await expectLater(disposable.addWater(today), throwsStateError);
  });

  test(
    'an already-started save may persist after disposal without changing the old snapshot',
    () async {
      final disposable = FitLifeController(
        repository: repo,
        clock: () => today,
      );
      await disposable.initialize();
      final before = disposable.state;
      final gate = Completer<void>();
      repo.onGoals = (goals) async {
        await gate.future;
        await repo.local.saveGoals(goals);
      };
      final save = disposable.saveGoals(changed);
      disposable.dispose();
      gate.complete();
      await save;
      expect(identical(disposable.state, before), isTrue);
      final persisted = await repo.local.loadDay(today, today: today);
      expect(persisted.goals.toJson(), changed.toJson());
    },
  );

  test(
    'failed persistence never publishes an optimistic diary or settings snapshot',
    () async {
      await controller.initialize();
      final actions = <String, Future<dynamic> Function()>{
        SettingsRepository.goalsKey: () => controller.saveGoals(changed),
        'favorites': () => controller.setFavorite('rice', true),
        'custom_foods': () => controller.saveFood(entry('food').food),
        'water_2026-10-21': () => controller.addWater(today),
        'weight': () => controller.saveWeight(99.5),
        'diary_2026-10-21': () => controller.saveEntry(today, entry('meal')),
      };
      for (final action in actions.entries) {
        final before = controller.state;
        disk.failedKeys.add(action.key);
        await expectLater(action.value(), throwsStateError);
        expect(identical(controller.state, before), isTrue, reason: action.key);
        disk.failedKeys.clear();
      }
    },
  );

  test(
    'a recent-food failure reports a committed meal and keeps retry idempotent',
    () async {
      await controller.initialize();
      disk.failedKeys.add('recent');
      expect(await controller.addMeal(today, entry('same')), isFalse);
      expect(controller.state.diary.single.id, 'same');
      disk.failedKeys.clear();
      expect(await controller.addMeal(today, entry('same')), isTrue);
      expect(controller.state.diary.length, 1);
      expect(controller.state.recent, ['rice']);
    },
  );

  test(
    'editing and deleting existing entries cannot resurrect an absent entry',
    () async {
      await controller.initialize();
      await controller.saveEntry(today, entry('edit'));
      await controller.editEntry(today, entry('edit', grams: 200.25));
      expect(controller.state.total.calories, closeTo(688.86, 1e-9));
      await controller.editEntry(today, entry('edit'), delete: true);
      expect(controller.state.diary, isEmpty);
      await expectLater(
        controller.editEntry(today, entry('edit')),
        throwsStateError,
      );
    },
  );

  test(
    'catalogue uses the same source profile and stable food ID for distinct portions',
    () async {
      await controller.initialize();
      final record = nutritionDatabase.first;
      for (final grams in [50.0, 100.0]) {
        await controller.addCatalogFood(
          today,
          record,
          grams: grams,
          meal: 'Обед',
          time: '12:00',
        );
      }
      expect(controller.state.customFoods.length, 1);
      expect(controller.state.diary.map((item) => item.id).toSet().length, 2);
      expect(controller.state.total.calories, 1011);
      expect(
        controller.nutritionDay.total.vitamins['B12, кобаламин (мкг)'],
        closeTo(1.095, 1e-9),
      );
      final prefs = await SharedPreferences.getInstance();
      expect((jsonDecode(prefs.getString('custom_foods')!) as List).length, 1);
      expect(controller.newId(prefix: 'custom_'), startsWith('custom_'));
    },
  );
}
