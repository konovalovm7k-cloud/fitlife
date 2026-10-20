import 'dart:async';

import 'package:fitlife/modern_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget app(Future<SharedPreferences> Function() load) =>
    MaterialApp(home: FitLifeHome(preferencesLoader: load));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('startup error replaces the spinner and retry restores data', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'goal_calories': 2200.0});
    var attempts = 0;
    await tester.pumpWidget(
      app(() {
        if (attempts++ == 0) return Future.error(StateError('Native storage'));
        return SharedPreferences.getInstance();
      }),
    );
    await tester.pumpAndSettle();
    expect(find.text('Не удалось открыть дневник'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Добавить еду'), findsNothing);

    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(find.text('FITLIFE'), findsOneWidget);
    expect(find.text('2200'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stalled startup times out and cannot later replace retry data', (
    tester,
  ) async {
    final stalled = Completer<SharedPreferences>();
    var attempts = 0;
    await tester.pumpWidget(
      app(
        () =>
            attempts++ == 0 ? stalled.future : SharedPreferences.getInstance(),
      ),
    );
    await tester.pump(const Duration(seconds: 16));
    await tester.pumpAndSettle();
    expect(find.text('Не удалось открыть дневник'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(find.text('FITLIFE'), findsOneWidget);
    stalled.complete(await SharedPreferences.getInstance());
    await tester.pumpAndSettle();
    expect(find.text('FITLIFE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unmount during startup does not update disposed state', (
    tester,
  ) async {
    final pending = Completer<SharedPreferences>();
    await tester.pumpWidget(app(() => pending.future));
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(await SharedPreferences.getInstance());
    await tester.pump(const Duration(seconds: 16));
    expect(tester.takeException(), isNull);
  });

  testWidgets('damaged favorites do not block startup or erase their source', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'favorites': 'old-invalid-value',
      'recent': ['egg'],
    });
    await tester.pumpWidget(app(SharedPreferences.getInstance));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(find.text('FITLIFE'), findsOneWidget);
    expect(prefs.get('favorites'), 'old-invalid-value');
    expect(prefs.getString('recovery_favorites'), isNotNull);
    expect(prefs.getStringList('recent'), ['egg']);
    expect(tester.takeException(), isNull);
  });
}
