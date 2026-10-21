import 'dart:async';

import 'package:fitlife/app/state/fitlife_controller.dart';
import 'package:fitlife/app/state/fitlife_state.dart';
import 'package:fitlife/core/models/nutrition_goal_settings.dart';
import 'package:fitlife/main.dart';
import 'package:fitlife/modern_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/controlled_fitlife_repository.dart';

class TrackingController extends FitLifeController {
  TrackingController(ControlledFitLifeRepository repository)
    : super(repository: repository);
  int disposals = 0;
  bool get observed => hasListeners;
  @override
  void dispose() {
    disposals++;
    super.dispose();
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  const changed = NutritionGoalSettings(
    calories: 2400,
    protein: 160,
    fat: 70,
    fiber: 35,
  );

  testWidgets(
    'production and compatibility roots share one localized MaterialApp',
    (tester) async {
      for (final app in [const FitLifeRoot(), const ModernFitLifeApp()]) {
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();
        expect(find.byType(MaterialApp), findsOneWidget);
        expect(
          tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
          const Locale('ru'),
        );
        expect(find.text('FITLIFE'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'borrowed controller is not reinitialized or disposed by its screen',
    (tester) async {
      final repo = ControlledFitLifeRepository();
      final controller = TrackingController(repo);
      addTearDown(controller.dispose);
      await controller.initialize();
      final loads = repo.loads;
      await tester.pumpWidget(
        MaterialApp(home: FitLifeHome(controller: controller)),
      );
      await tester.pumpAndSettle();
      expect(repo.loads, loads);
      expect(controller.observed, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(controller.disposals, 0);
      expect(controller.observed, isFalse);
      await controller.saveGoals(changed);
      expect(controller.state.goals.calories, 2400);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('replacing a borrowed controller detaches the old subscription', (
    tester,
  ) async {
    final first = TrackingController(ControlledFitLifeRepository());
    final secondRepo = ControlledFitLifeRepository();
    secondRepo.onLoad = (day, _) async =>
        FitLifeState(day: day, goals: changed);
    final second = TrackingController(secondRepo);
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await first.initialize();
    await second.initialize();
    await tester.pumpWidget(
      MaterialApp(
        home: FitLifeHome(key: const ValueKey('home'), controller: first),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      MaterialApp(
        home: FitLifeHome(key: const ValueKey('home'), controller: second),
      ),
    );
    await tester.pumpAndSettle();
    expect(first.observed, isFalse);
    expect(first.disposals, 0);
    expect(second.observed, isTrue);
    expect(find.text('2400'), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(second.observed, isFalse);
    expect(second.disposals, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('replacing a pending legacy loader ignores its late completion', (
    tester,
  ) async {
    final pending = Completer<SharedPreferences>();
    await tester.pumpWidget(
      MaterialApp(
        home: FitLifeHome(
          key: const ValueKey('home'),
          preferencesLoader: () => pending.future,
        ),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(
      const MaterialApp(
        home: FitLifeHome(
          key: ValueKey('home'),
          preferencesLoader: SharedPreferences.getInstance,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('FITLIFE'), findsOneWidget);
    pending.complete(await SharedPreferences.getInstance());
    await tester.pump(const Duration(seconds: 16));
    await tester.pumpAndSettle();
    expect(find.text('FITLIFE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'screen lifecycle forwards midnight resumption to the controller',
    (tester) async {
      var clock = DateTime(2026, 10, 21, 23, 59);
      final controller = FitLifeController(
        repository: ControlledFitLifeRepository(),
        clock: () => clock,
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(home: FitLifeHome(controller: controller)),
      );
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      clock = DateTime(2026, 10, 22, 0, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(controller.state.day, DateTime(2026, 10, 22));
      expect(find.text('Сегодня, 22 октября 2026'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
