import 'package:flutter/material.dart';
import 'food_source_page.dart';
import 'photo_models.dart';
import 'photo_review_page.dart';
import 'photo_service.dart';

/// Offline source entry uses the same confirmation and persistence as AI review.
/// No connection read, request or quota reservation is made.
Future<bool> openLabelMeal(
  BuildContext context, {
  required DateTime day,
  required String meal,
  required Future<void> Function(PhotoMeal) onSave,
}) async {
  final item = await Navigator.push<SourcedFoodEdit>(
    context,
    MaterialPageRoute(
      builder: (_) => const FoodSourcePage(startWithLabel: true),
    ),
  );
  if (!context.mounted || item?.food == null) return false;
  final analysis = PhotoAnalysis(
    requestId: photoRequestId(),
    items: [item!.food!],
    warnings: const [],
    source: MealEstimateSource.manual,
  );
  return await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PhotoReviewPage(
            analysis: analysis,
            day: day,
            initialMeal: meal,
            onSave: onSave,
          ),
        ),
      ) ??
      false;
}
