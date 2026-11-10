import 'package:fitlife/app/state/fitlife_controller.dart';
import 'package:fitlife/data/repositories/local_fitlife_repository.dart';
import 'package:fitlife/modern_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'Today shows steps only after a manual save and removes the record',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final controller = FitLifeController(
        repository: LocalFitLifeRepository(),
        clock: () => DateTime(2026, 11, 9, 12),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(home: FitLifeHome(controller: controller)),
      );
      await tester.pumpAndSettle();
      expect(find.text('7180'), findsNothing);
      await tester.scrollUntilVisible(find.text('Добавить шаги'), 160);
      await tester.tap(find.text('Добавить шаги'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Шаги'),
        '7180',
      );
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      expect(find.text('7180'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('steps_2026-11-09'), 7180);
      await tester.tap(find.text('7180'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Удалить'));
      await tester.pumpAndSettle();
      expect(find.text('7180'), findsNothing);
      expect(find.text('Добавить шаги'), findsOneWidget);
      await prefs.reload();
      expect(prefs.containsKey('steps_2026-11-09'), isFalse);
    },
  );
}
