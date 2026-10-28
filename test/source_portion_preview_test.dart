import 'package:fitlife/app/fitlife_theme.dart';
import 'package:fitlife/core/models/nutrition_profile.dart';
import 'package:fitlife/core/nutrition/nutrition_engine.dart';
import 'package:fitlife/features/photo_analysis/food_source_page.dart';
import 'package:fitlife/features/photo_analysis/photo_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/source_flow.dart' show reveal;

const label = NutritionSource(
  name: 'Рис',
  provenance: NutritionProvenance(
    kind: 'label',
    reference: 'Моя этикетка риса',
  ),
  fiberKnown: false,
  profile: NutritionProfile(kcal: 130, protein: 2.7, fat: .3, carbs: 28),
);

void main() {
  late int saves;
  late PhotoFood? saved;
  Future<void> open(
    WidgetTester tester,
    PhotoFood food, {
    bool manual = false,
  }) async {
    saves = 0;
    saved = null;
    await tester.pumpWidget(
      MaterialApp(
        theme: fitLifeTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => FoodSourcePage(
                    food: food,
                    startWithLabel: manual,
                    onSave: (value) async {
                      saves++;
                      saved = value;
                    },
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

  Future<void> top(WidgetTester tester) async {
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(0);
    await tester.pumpAndSettle();
  }

  Future<void> preview(WidgetTester tester, String? kcal) async {
    await top(tester);
    await reveal(tester, find.byKey(const Key('source-portion-preview')));
    final value = find.byKey(const Key('source-portion-kcal'));
    if (kcal == null) {
      expect(value, findsNothing);
    } else {
      expect(tester.widget<Text>(value).data, kcal);
    }
  }

  Future<void> field(WidgetTester tester, Finder finder, String value) async {
    await top(tester);
    await reveal(tester, finder);
    await tester.enterText(finder, value);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'exact label portion updates, invalid mass removes stale facts, only confirmation saves',
    (tester) async {
      await open(
        tester,
        const PhotoFood(
          name: 'Рис',
          grams: 150.5,
          confidence: 'low',
          source: label,
        ),
      );
      await preview(tester, '196 ккал');
      expect(
        tester.widget<Text>(find.byKey(const Key('source-portion-fiber'))).data,
        'Клетчатка не указана в источнике.',
      );
      final grams = find.byKey(const Key('source-grams'));
      for (final invalid in ['0', 'NaN', 'Infinity', '3000.1', '']) {
        await field(tester, grams, invalid);
        await preview(tester, null);
        expect(saves, 0);
      }
      await field(tester, grams, '200,25');
      await preview(tester, '260 ккал');
      expect(saves, 0);
      await reveal(tester, find.byKey(const Key('source-confirm')));
      await tester.tap(find.byKey(const Key('source-confirm')));
      await tester.pumpAndSettle();
      expect(saves, 1);
      expect(saved!.grams, 200.25);
      expect(saved!.calories, closeTo(260.325, .000001));
      expect(saved!.source!.provenance.toJson(), label.provenance.toJson());
      expect(saved!.source!.fiberKnown, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AI numbers cannot become a preview; manual source and all facts are required, unknown fiber stays unknown',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await open(
        tester,
        PhotoFood.fromJson({
          'name': 'Рис',
          'grams': 150.5,
          'confidence': 'high',
          'kcal': 999,
          'protein': 80,
        }),
        manual: true,
      );
      await preview(tester, null);
      final reference = find.widgetWithText(
        TextFormField,
        'Источник: марка и название на упаковке',
      );
      await field(tester, reference, 'Моя этикетка риса');
      for (var i = 0; i < 4; i++) {
        await field(
          tester,
          find.byKey(Key('source-nutrient-$i')),
          ['130', '2.7', '0.3', '28'][i],
        );
      }
      await preview(tester, '196 ккал');
      expect(
        tester.widget<Text>(find.byKey(const Key('source-portion-fiber'))).data,
        contains('не указана'),
      );
      await field(tester, find.byKey(const Key('source-nutrient-1')), '80');
      await field(tester, find.byKey(const Key('source-nutrient-2')), '80');
      await preview(tester, null);
      await field(tester, find.byKey(const Key('source-nutrient-1')), '2.7');
      await field(tester, find.byKey(const Key('source-nutrient-2')), '0.3');
      await field(tester, find.byKey(const Key('source-nutrient-4')), '2');
      await preview(tester, '196 ккал');
      expect(
        tester.widget<Text>(find.byKey(const Key('source-portion-fiber'))).data,
        'Клетчатка 3.0 г',
      );
      await field(tester, reference, '');
      await preview(tester, null);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(saves, 0);
      expect(saved, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'catalogue preview requires explicit selection and scales its attributed facts without saving',
    (tester) async {
      await open(
        tester,
        const PhotoFood(name: 'Яблоко', grams: 150.5, confidence: 'high'),
      );
      await preview(tester, null);
      await top(tester);
      await reveal(tester, find.widgetWithText(ListTile, 'Яблоко'));
      await tester.tap(find.widgetWithText(ListTile, 'Яблоко'));
      await tester.pumpAndSettle();
      await preview(tester, '78 ккал');
      await field(tester, find.byKey(const Key('source-grams')), '100');
      await preview(tester, '52 ккал');
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(saves, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
