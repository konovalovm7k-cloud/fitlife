import 'package:flutter/material.dart';

import 'core/nutrition/nutrition_catalog_page.dart';
import 'modern_app.dart';

const _green = Color(0xFF3D9B70);
const _bg = Color(0xFFF6F8F6);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FitLifeRoot());
}

class FitLifeRoot extends StatefulWidget {
  const FitLifeRoot({super.key});

  @override
  State<FitLifeRoot> createState() => _FitLifeRootState();
}

class _FitLifeRootState extends State<FitLifeRoot> {
  bool showNutrition = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FitLife',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _bg,
        colorScheme: ColorScheme.fromSeed(seedColor: _green),
      ),
      home: Stack(
        children: [
          const FitLifeHome(),
          if (!showNutrition)
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
                color: _bg,
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
      ),
    );
  }
}
