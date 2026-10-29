import 'package:fitlife/app/fitlife_theme.dart';
import 'package:fitlife/core/models/diary_item.dart';
import 'package:fitlife/core/models/nutrition_profile.dart';
import 'package:fitlife/core/nutrition/nutrition_engine.dart';
import 'package:fitlife/features/photo_analysis/food_source_page.dart';
import 'package:fitlife/features/photo_analysis/photo_models.dart';
import 'package:fitlife/features/satiety/food_satiety_preview_page.dart';
import 'package:fitlife/features/satiety/satiety_estimate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/source_flow.dart' show reveal;

const source = NutritionSource(
  name: 'Мой рис',
  provenance: NutritionProvenance(
    kind: 'label',
    reference: 'Моя этикетка риса',
  ),
  fiberKnown: false,
  profile: NutritionProfile(kcal: 130, protein: 2.7, fat: .3, carbs: 28),
);

void main() {
  test(
    'sourced preview and saved diary use identical portion properties and formula version',
    () {
      for (final grams in [1.0, 150.5, 3000.0]) {
        for (final structure in <FoodStructure?>[
          null,
          ...FoodStructure.values,
        ]) {
          final preview = SatietyEstimate.fromPortions([
            (source: source, grams: grams),
          ], structure: structure);
          final diary = SatietyEstimate.calculate([
            DiaryItem(
              id: 'existing',
              meal: 'Обед',
              time: '12:34',
              grams: grams,
              food: FoodItem(
                id: 'label',
                name: source.name,
                kcal: 130,
                protein: 2.7,
                fat: .3,
                carbs: 28,
                fiber: 0,
                hasKnownFiber: false,
                provenance: source.provenance,
                nutrition: source.profile,
              ),
            ),
          ], structure: structure);
          expect(
            [
              preview.low,
              preview.high,
              preview.grams,
              preview.kcal,
              preview.protein,
              preview.missing,
            ],
            [
              diary.low,
              diary.high,
              diary.grams,
              diary.kcal,
              diary.protein,
              diary.missing,
            ],
          );
          expect(preview.kcal, closeTo(1.3 * grams, .000001));
          expect(preview.fiber, isNull);
          expect(preview.water, isNull);
          expect(SatietyEstimate.formulaVersion, 1);
        }
      }
    },
  );

  test(
    'direct sourced portions reject invalid facts and scope without inventing a score',
    () {
      const water = NutritionSource(
        name: 'Вода',
        provenance: NutritionProvenance(kind: 'label', reference: 'Этикетка'),
        fiberKnown: true,
        profile: NutritionProfile(
          kcal: 0,
          protein: 0,
          fat: 0,
          carbs: 0,
          water: 100,
        ),
      );
      const invalid = NutritionSource(
        name: 'AI',
        provenance: NutritionProvenance(kind: 'ai', reference: 'generated'),
        fiberKnown: true,
        profile: NutritionProfile(kcal: 100, protein: 1, fat: 1, carbs: 1),
      );
      for (final portions in <List<SourcedSatietyPortion>>[
        [],
        [(source: source, grams: 0)],
        [(source: source, grams: double.nan)],
        [(source: source, grams: 2000), (source: source, grams: 2000)],
        [(source: water, grams: 200)],
        [(source: invalid, grams: 200)],
      ]) {
        expect(
          () => SatietyEstimate.fromPortions(portions),
          throwsFormatException,
        );
      }
    },
  );

  testWidgets(
    'source draft opens read-only score, structure changes locally, back retains draft and all preferences',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'diary_kept': 'unchanged',
        'hunger_observations_v1': '[]',
      });
      final prefs = await SharedPreferences.getInstance();
      final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
      var saves = 0;
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        MaterialApp(
          theme: fitLifeTheme().copyWith(platform: TargetPlatform.android),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FoodSourcePage(
                      food: const PhotoFood(
                        name: 'Мой рис',
                        grams: 150.5,
                        confidence: 'low',
                        source: source,
                      ),
                      onSave: (_) async {
                        saves++;
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
      final focusedNutrient = find.byKey(const Key('source-nutrient-3'));
      await reveal(tester, focusedNutrient);
      await tester.showKeyboard(focusedNutrient);
      final sourceFocus = FocusManager.instance.primaryFocus!;
      expect(sourceFocus.hasFocus, isTrue);
      await reveal(tester, find.byKey(const Key('source-satiety-preview')));
      expect(sourceFocus.hasFocus, isTrue);
      await tester.tap(find.byKey(const Key('source-satiety-preview')));
      await tester.pumpAndSettle();
      expect(find.byType(FoodSatietyPreviewPage), findsOneWidget);
      await reveal(tester, find.widgetWithText(ChoiceChip, 'Нужно жевать'));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Нужно жевать'));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('food-satiety-score')));
      final expected = SatietyEstimate.fromPortions([
        (source: source, grams: 150.5),
      ], structure: FoodStructure.solid);
      expect(
        tester.widget<Text>(find.byKey(const Key('food-satiety-score'))).data,
        expected.low == expected.high
            ? '${expected.low} из 10'
            : '${expected.low}–${expected.high} из 10',
      );
      expect(find.byKey(const Key('observe-hunger')), findsNothing);
      expect(find.text('Мои наблюдения голода'), findsNothing);
      expect(saves, 0);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(sourceFocus.hasFocus, isFalse);
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      final grams = find.byKey(const Key('source-grams'));
      expect(tester.widget<TextFormField>(grams).controller!.text, '150.5');
      await tester.enterText(grams, '0');
      await reveal(tester, find.byKey(const Key('source-portion-preview')));
      expect(find.byKey(const Key('source-satiety-preview')), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(saves, 0);
      expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, before);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('zero-energy portion displays no score or structure reward', (
    tester,
  ) async {
    const water = NutritionSource(
      name: 'Вода',
      provenance: NutritionProvenance(kind: 'label', reference: 'Этикетка'),
      fiberKnown: true,
      profile: NutritionProfile(
        kcal: 0,
        protein: 0,
        fat: 0,
        carbs: 0,
        water: 100,
      ),
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: FoodSatietyPreviewPage(source: water, grams: 200),
      ),
    );
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('food-satiety-unavailable')));
    expect(find.byKey(const Key('food-satiety-score')), findsNothing);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
