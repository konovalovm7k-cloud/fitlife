import 'package:flutter/material.dart';
import '../../app/portion_format.dart';
import '../../core/nutrition/nutrition_engine.dart';
import 'satiety_estimate.dart';
import 'satiety_explanation.dart';

/// Local, read-only properties of a sourced portion, including unsaved drafts.
/// It deliberately has no diary/hunger repository or write callback.
class FoodSatietyPreviewPage extends StatefulWidget {
  const FoodSatietyPreviewPage({
    super.key,
    required this.source,
    required this.grams,
  });
  final NutritionSource source;
  final double grams;

  @override
  State<FoodSatietyPreviewPage> createState() => _FoodSatietyPreviewPageState();
}

class _FoodSatietyPreviewPageState extends State<FoodSatietyPreviewPage> {
  FoodStructure? _structure;

  @override
  Widget build(BuildContext context) {
    SatietyEstimate? estimate;
    try {
      estimate = SatietyEstimate.fromPortions([
        (source: widget.source, grams: widget.grams),
      ], structure: _structure);
    } on FormatException {
      // Nutrition facts can be valid while the heuristic is outside its scope,
      // e.g. zero-energy water. Do not invent a fallback score.
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Свойства порции')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.source.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text('${formatFoodGrams(widget.grams)} г'),
          Text('Источник: ${widget.source.provenance.reference}'),
          const SizedBox(height: 16),
          const Text(
            'Предварительная оценка выбранной порции. Открытие этого экрана не меняет дневник.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Экспериментальная оценка свойств порции. Она не измеряет ваш голод, '
            'не оценивает полезность еды и не предсказывает часы сытости.',
          ),
          const SizedBox(height: 16),
          if (estimate == null)
            const Text(
              'Для этой порции оценка недоступна. Нужны подтверждённый источник, '
              'ненулевая калорийность и порция до 3000 г.',
              key: Key('food-satiety-unavailable'),
            )
          else ...[
            const Text('Как выглядит эта порция?'),
            Wrap(
              spacing: 8,
              children: [
                for (final entry in satietyStructureLabels.entries)
                  ChoiceChip(
                    label: Text(entry.value),
                    selected: _structure == entry.key,
                    onSelected: (selected) => setState(
                      () => _structure = selected ? entry.key : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ориентир свойств порции'),
                    Text(
                      estimate.low == estimate.high
                          ? '${estimate.low} из 10'
                          : '${estimate.low}–${estimate.high} из 10',
                      key: const Key('food-satiety-score'),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    if (estimate.missing.isNotEmpty)
                      Text(
                        'Неизвестно: ${estimate.missing.join(', ')}. Диапазон показывает влияние '
                        'этих пробелов в формуле, а не точность прогноза.',
                      ),
                    const Text(
                      'Личная реакция может отличаться при любой оценке.',
                    ),
                  ],
                ),
              ),
            ),
            Text(
              '${estimate.kcal.round()} ккал · белок ${estimate.protein.toStringAsFixed(1)} г',
            ),
            Text(
              'Клетчатка: ${estimate.fiber?.toStringAsFixed(1) ?? 'неизвестно'}'
              '${estimate.fiber == null ? '' : ' г'}',
            ),
            Text(
              'Вода в составе: ${estimate.water?.toStringAsFixed(1) ?? 'неизвестно'}'
              '${estimate.water == null ? '' : ' г'}',
            ),
            Text(
              'Энергоёмкость: ${estimate.energyDensity.toStringAsFixed(2)} ккал/г',
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'В составе блюда оценка изменится: считаем всю порцию целиком, '
            'баллы продуктов не складываются.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Если голодны, можно поесть независимо от оценки. '
            'Баллы не меняют цели, награды или состояние питомца.',
          ),
          const SatietyExplanation(),
        ],
      ),
    );
  }
}
