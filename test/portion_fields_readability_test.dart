import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'diary_flow_test.dart' show launch, dateKey;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final scenario in const [
    (Size(320, 700), 1.8),
    (Size(390, 844), 1.0),
    (Size(600, 800), 1.8),
    (Size(600, 800), 1.0),
  ]) {
    testWidgets(
      'selected meal stays readable and saves precise portion at ${scenario.$1}, text ${scenario.$2}',
      (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scenario.$2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await launch(tester, size: scenario.$1);
        await tester.tap(find.text('Добавить еду'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Яйцо'));
        final grams = find.widgetWithText(TextField, 'Граммы');
        await tester.ensureVisible(grams);
        await tester.enterText(grams, '150,5');
        final meal = find.byType(DropdownButtonFormField<String>);
        await tester.ensureVisible(meal);
        await tester.tap(meal);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Перекус').hitTestable().last);
        await tester.pumpAndSettle();
        if (scenario.$1.width == 600 && scenario.$2 == 1.0) {
          tester.view.physicalSize = const Size(320, 700);
          await tester.pumpAndSettle();
        }
        final selected = find.descendant(
          of: meal,
          matching: find.text('Перекус'),
        );
        expect(selected, findsOneWidget);
        final paragraph = tester.renderObject<RenderParagraph>(selected);
        expect(
          paragraph.didExceedMaxLines,
          isFalse,
          reason:
              'The selected meal must be readable without reopening the menu',
        );
        expect(find.text('150,5'), findsOneWidget);
        final add = find.widgetWithText(FilledButton, 'Добавить');
        await tester.ensureVisible(add);
        await tester.tap(add);
        await tester.pumpAndSettle();
        final prefs = await SharedPreferences.getInstance();
        final saved =
            jsonDecode(prefs.getString('diary_${dateKey(DateTime.now())}')!)
                as List;
        expect(saved, hasLength(1));
        expect(saved.single['meal'], 'Перекус');
        expect(saved.single['grams'], 150.5);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
