import 'dart:convert';
import 'package:fitlife/app/fitlife_theme.dart';
import 'package:fitlife/core/models/diary_item.dart';
import 'package:fitlife/features/progress/weekly_summary.dart';
import 'package:fitlife/features/progress/weekly_summary_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const food = FoodItem(
  id: 'test',
  name: 'Продукт',
  kcal: 100,
  protein: 10,
  fat: 2,
  carbs: 12,
  fiber: 1,
);
String entries(double grams) => jsonEncode([
  DiaryItem(
    id: 'stable',
    meal: 'Обед',
    food: food,
    grams: grams,
    time: '12:00',
  ).toJson(),
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'averages exclude missing and damaged days, without replacing saved records',
    () async {
      SharedPreferences.setMockInitialValues({
        'diary_2026-10-20': entries(100),
        'water_2026-10-20': 0.5,
        'diary_2026-10-21': entries(200),
        'diary_2026-10-22': 'damaged',
        'water_2026-10-22': 'bad',
      });
      final summary = await WeeklySummary.load(DateTime(2026, 10, 22));
      expect(summary.days.length, 7);
      expect(summary.days.first.date, DateTime(2026, 10, 16));
      expect(summary.logged.length, 2);
      expect(summary.average((day) => day.calories), 150);
      expect(summary.average((day) => day.protein), 15);
      expect(summary.days.last.damaged, isTrue);
      expect(summary.days.last.water, isNull);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('diary_2026-10-22'), 'damaged');
      expect(preferences.getString('recovery_diary_2026-10-22'), 'damaged');
      expect(summary.report(), contains('Дней с записями о еде: 2 из 7'));
      expect(summary.report(), contains('150 ккал'));
      expect(summary.report(), contains('данные неполные'));
    },
  );
  test(
    'an empty week is not zero-calorie intake; calendar dates cross month boundaries',
    () async {
      SharedPreferences.setMockInitialValues({'water_2026-03-01': 1.0});
      final summary = await WeeklySummary.load(DateTime(2026, 3, 1));
      expect(summary.days.first.date, DateTime(2026, 2, 23));
      expect(summary.average((day) => day.calories), isNull);
      expect(summary.report(), contains('нет записей о еде'));
      expect(summary.report(), contains('вода 1.00 л'));
      expect(summary.report(), isNot(contains('NaN')));
    },
  );
  testWidgets(
    'weekly overview fits a narrow screen with large text and exposes day navigation',
    (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({
        'diary_2026-10-21': entries(200),
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: fitLifeTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: WeeklySummaryPage(end: DateTime(2026, 10, 22)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 из 7 дней'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Скопировать отчёт'), 150);
      await tester.tap(find.text('Скопировать отчёт'));
      await tester.pumpAndSettle();
      expect(copied, contains('Дней с записями о еде: 1 из 7'));
      expect(copied, contains('200 ккал'));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('a week day returns its exact local date to the diary', (
    tester,
  ) async {
    DateTime? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              selected = await Navigator.of(context).push<DateTime>(
                MaterialPageRoute(
                  builder: (_) =>
                      WeeklySummaryPage(end: DateTime(2026, 10, 22)),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('21'));
    await tester.pumpAndSettle();
    expect(selected, DateTime(2026, 10, 21));
  });
}
