import 'dart:convert';
import 'package:fitlife/features/satiety/satiety_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'diary_flow_test.dart' show launch, dateKey;
import 'satiety_estimate_test.dart' show satietyItem;
import 'support/source_flow.dart' show reveal;

void main() {
  testWidgets(
    'diary navigation scores sourced meal without changing stored data',
    (tester) async {
      final key = 'diary_${dateKey(DateTime.now())}';
      final diary = jsonEncode([satietyItem().toJson()]);
      SharedPreferences.setMockInitialValues({key: diary});
      await launch(tester, size: const Size(360, 780));
      await tester.tap(find.text('Питание').last);
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('satiety-Обед')));
      await tester.tap(find.byKey(const Key('satiety-Обед')));
      await tester.pumpAndSettle();
      expect(find.text('Умная сытость'), findsOneWidget);
      await reveal(tester, find.text('Нужно жевать'));
      await tester.tap(find.text('Нужно жевать'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('satiety-score')), findsOneWidget);
      expect(find.textContaining('Неизвестно:'), findsNothing);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      expect(prefs.getString(key), diary);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('old unconfirmed composition has no score', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SatietyPage(meal: 'Обед', items: [satietyItem(source: false)]),
      ),
    );
    expect(find.byKey(const Key('satiety-unavailable')), findsOneWidget);
    expect(find.byKey(const Key('satiety-score')), findsNothing);
  });
  testWidgets(
    'large text keeps partial composition readable and does not promise hours',
    (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: SatietyPage(
            meal: 'Обед',
            items: [satietyItem(label: true, fiberKnown: false)],
          ),
        ),
      );
      await reveal(tester, find.byKey(const Key('satiety-score')));
      expect(find.textContaining('Неизвестно:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
