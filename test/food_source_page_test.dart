import 'package:fitlife/app/fitlife_theme.dart';
import 'package:fitlife/features/photo_analysis/food_source_page.dart';
import 'package:fitlife/features/photo_analysis/photo_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/source_flow.dart';

void main() {
  testWidgets(
    'catalogue requires explicit selection and confirmation, returns source and exact portion',
    (tester) async {
      SourcedFoodEdit? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: fitLifeTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await Navigator.push<SourcedFoodEdit>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FoodSourcePage(
                        food: PhotoFood(
                          name: 'Яблоко',
                          grams: 150.5,
                          confidence: 'high',
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('source-confirm')));
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('source-confirm')))
            .onPressed,
        isNull,
      );
      expect(result, isNull);
      await tester.tap(find.widgetWithText(ListTile, 'Яблоко'));
      await tester.pumpAndSettle();
      expect(result, isNull);
      await reveal(tester, find.byKey(const Key('source-confirm')));
      await tester.tap(find.byKey(const Key('source-confirm')));
      await tester.pumpAndSettle();
      expect(result!.food!.source!.provenance.kind, 'catalogue');
      expect(result!.food!.source!.provenance.recordId, 'healthdiet_15983');
      expect(result!.food!.grams, 150.5);
      expect(result!.food!.calories, closeTo(78.26, .00001));
    },
  );
  testWidgets(
    'label does not prefill AI nutrition and cannot confirm empty or inconsistent values',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: fitLifeTheme(),
          home: FoodSourcePage(
            food: PhotoFood.fromJson({
              'name': 'Рис',
              'grams': 100,
              'confidence': 'high',
              'kcal': 999,
              'protein': 80,
            }),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('С этикетки'));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('source-nutrient-0')));
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('source-nutrient-0')))
            .controller!
            .text,
        isEmpty,
      );
      await reveal(tester, find.byKey(const Key('source-confirm')));
      await tester.tap(find.byKey(const Key('source-confirm')));
      await tester.pumpAndSettle();
      expect(find.byType(FoodSourcePage), findsOneWidget);
      expect(find.textContaining('Введите число'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
