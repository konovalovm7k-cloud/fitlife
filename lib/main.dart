import 'package:flutter/material.dart';

import 'core/nutrition/nutrition_catalog_page.dart';
import 'modern_app.dart';

void main() => runApp(const FitLifeRoot());

class FitLifeRoot extends StatefulWidget {
  const FitLifeRoot({super.key});

  @override
  State<FitLifeRoot> createState() => _FitLifeRootState();
}

class _FitLifeRootState extends State<FitLifeRoot> {
  bool showNutrition = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const ModernFitLifeApp(),
        Positioned(
          left: 16,
          bottom: 92,
          child: FloatingActionButton.small(
            heroTag: 'nutrition-database',
            tooltip: 'База продуктов',
            onPressed: () => setState(() => showNutrition = true),
            child: const Icon(Icons.science_outlined),
          ),
        ),
        if (showNutrition)
          Positioned.fill(
            child: Material(
              color: const Color(0xFFF6F7F8),
              child: Stack(
                children: [
                  const NutritionCatalogPage(),
                  Positioned(
                    top: 46,
                    right: 12,
                    child: IconButton.filledTonal(
                      tooltip: 'Закрыть',
                      onPressed: () => setState(() => showNutrition = false),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
