import 'package:flutter/material.dart';
import '../../app/nutrition_goal_format.dart';
import '../../app/portion_format.dart';
import '../../core/nutrition/food_catalog_import.dart';
import '../../core/nutrition/nutrition_database.dart';
import '../photo_analysis/photo_models.dart';
import '../photo_analysis/photo_review_page.dart';
import '../photo_analysis/photo_service.dart';
import 'meal_ideas.dart';

class MealIdeasPage extends StatefulWidget {
  const MealIdeasPage({
    super.key,
    required this.day,
    required this.initialMeal,
    required this.onSave,
    this.loadFoods = loadAdditionalFoods,
  });
  final DateTime day;
  final String initialMeal;
  final Future<void> Function(PhotoMeal) onSave;
  final Future<List<NutritionFoodRecord>> Function() loadFoods;
  @override
  State<MealIdeasPage> createState() => _MealIdeasPageState();
}

class _MealIdeasPageState extends State<MealIdeasPage> {
  late Future<List<NutritionFoodRecord>> _data = _load();
  double _factor = 1;
  bool _reviewing = false;
  Future<List<NutritionFoodRecord>> _load() {
    final future = Future<List<NutritionFoodRecord>>.sync(
      widget.loadFoods,
    ).timeout(const Duration(seconds: 10));
    future.ignore();
    return future;
  }

  void _retry() {
    setState(() {
      _data = _load();
    });
  }

  Future<void> _review(List<PhotoFood> foods) async {
    if (_reviewing) return;
    setState(() => _reviewing = true);
    try {
      // Allocate once per opened draft, outside a route builder that can run
      // again after theme/metrics changes while a failed write is retried.
      final analysis = PhotoAnalysis(
        requestId: photoRequestId(),
        items: foods,
        warnings: const [],
        source: MealEstimateSource.manual,
      );
      final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PhotoReviewPage(
            analysis: analysis,
            day: widget.day,
            initialMeal: widget.initialMeal,
            onSave: widget.onSave,
          ),
        ),
      );
      if (mounted && saved == true) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _reviewing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Идеи блюд')),
    body: FutureBuilder<List<NutritionFoodRecord>>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Не удалось открыть справочник. Дневник доступен; попробуйте загрузить идеи ещё раз.',
                  ),
                  TextButton(onPressed: _retry, child: const Text('Повторить')),
                ],
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Простые варианты без запроса AI',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Порция здесь — пример, а не личная норма. Взвешивайте съедобную часть в указанном состоянии. Перед записью можно изменить ингредиенты, источники и массу.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final factor in [.5, 1.0, 2.0])
                  ChoiceChip(
                    label: Text(switch (factor) {
                      .5 => '½ порции',
                      1.0 => '1 порция',
                      _ => '2 порции',
                    }),
                    selected: _factor == factor,
                    onSelected: (_) => setState(() => _factor = factor),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            for (final idea in mealIdeas) _card(idea, snapshot.data!),
          ],
        );
      },
    ),
  );

  Widget _card(MealIdea idea, List<NutritionFoodRecord> records) {
    List<PhotoFood>? foods;
    try {
      foods = idea.resolve(records, _factor);
    } on FormatException {
      foods = null;
    }
    final ready = foods;
    final total = ready == null ? null : ideaTotal(ready);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              idea.title,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(idea.instructions),
            const SizedBox(height: 8),
            Text(idea.allergenNote),
            if (ready == null) ...[
              const SizedBox(height: 8),
              const Text(
                'Для этой идеи не хватает проверенного источника. Состав не рассчитан.',
              ),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                '${formatFoodGrams(ready.fold<double>(0, (sum, f) => sum + f.grams))} г · ${total!.kcal.round()} ккал',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                'Б ${formatNutritionGoal(total.protein)} г · Ж ${formatNutritionGoal(total.fat)} г · У ${formatNutritionGoal(total.carbs)} г',
              ),
              Text(
                ready.every((f) => f.source!.fiberKnown)
                    ? 'Клетчатка ${formatNutritionGoal(total.fiber)} г'
                    : 'Клетчатка: состав неполный',
              ),
              for (final food in ready)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${food.name} — ${formatFoodGrams(food.grams)} г',
                  ),
                ),
              const SizedBox(height: 8),
              const Text(
                'Источник: CoFID 2021. Сверьте со своим продуктом при проверке. Масло и соусы добавьте отдельно, если используете.',
              ),
            ],
            const SizedBox(height: 12),
            Semantics(
              identifier: 'idea-review-${idea.id}',
              child: FilledButton.icon(
                key: Key('idea-review-${idea.id}'),
                onPressed: ready == null || _reviewing
                    ? null
                    : () => _review(ready),
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Проверить и добавить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
