import 'package:fitlife/core/models/nutrition_profile.dart';
import 'package:fitlife/core/nutrition/nutrition_engine.dart';
import 'package:fitlife/features/photo_analysis/photo_models.dart';

/// Storage tests start AFTER the user explicitly confirmed label data.
/// Network tests must keep using PhotoFood.fromJson, which cannot confirm it.
PhotoFood confirmedFood(Map<String, dynamic> values) => PhotoFood(
  name: values['name'] as String,
  grams: (values['grams'] as num).toDouble(),
  confidence: values['confidence'] as String,
  source: NutritionSource(
    name: values['name'] as String,
    profile: NutritionProfile.fromJson(values),
    fiberKnown: true,
    provenance: const NutritionProvenance(
      kind: 'label',
      reference: 'Test package label',
    ),
  ),
);
