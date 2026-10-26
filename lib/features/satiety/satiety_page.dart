import 'package:flutter/material.dart';
import '../../core/models/diary_item.dart';
import 'satiety_estimate.dart';

class SatietyPage extends StatefulWidget {
  const SatietyPage({super.key, required this.items, required this.meal});
  final List<DiaryItem> items;
  final String meal;
  @override
  State<SatietyPage> createState() => _SatietyPageState();
}

class _SatietyPageState extends State<SatietyPage> {
  FoodStructure? _structure;
  static const structures = {
    FoodStructure.solid: 'Нужно жевать',
    FoodStructure.soft: 'Мягкая / пюре',
    FoodStructure.liquid: 'Жидкая',
    FoodStructure.mixed: 'Смешанная',
  };

  @override
  Widget build(BuildContext context) {
    SatietyEstimate? result;
    try {
      result = SatietyEstimate.calculate(widget.items, structure: _structure);
    } on FormatException {
      // Old AI estimates are readable but are not evidence for a new score.
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Умная сытость')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(widget.meal, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          const Text(
            'Экспериментальная оценка свойств порции. Она не измеряет ваш голод, '
            'не оценивает полезность еды и не предсказывает часы сытости.',
          ),
          const SizedBox(height: 16),
          ...widget.items.map(
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${i.food.name} · ${i.grams} г\n'
                'Источник: ${i.food.provenance?.reference ?? 'не подтверждён'}',
              ),
            ),
          ),
          if (result == null) ...[
            const SizedBox(height: 16),
            const Text(
              'Пока недостаточно подтверждённых данных. Для расчёта нужен '
              'источник состава каждого ингредиента и ненулевая калорийность. '
              'Оценка доступна для порции до 3000 г. Старые записи сохранены.',
              key: Key('satiety-unavailable'),
            ),
          ] else ...[
            const SizedBox(height: 16),
            const Text('Как выглядит вся порция?'),
            Wrap(
              spacing: 8,
              children: structures.entries
                  .map(
                    (e) => ChoiceChip(
                      label: Text(e.value),
                      selected: _structure == e.key,
                      onSelected: (selected) =>
                          setState(() => _structure = selected ? e.key : null),
                    ),
                  )
                  .toList(),
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
                      result.low == result.high
                          ? '${result.low} из 10'
                          : '${result.low}–${result.high} из 10',
                      key: const Key('satiety-score'),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    if (result.missing.isNotEmpty)
                      Text(
                        'Неизвестно: ${result.missing.join(', ')}. '
                        'Диапазон показывает влияние этих пробелов в формуле, '
                        'а не точность прогноза.',
                      ),
                    const SizedBox(height: 8),
                    const Text(
                      'Личная реакция может отличаться при любой оценке.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Масса ${result.grams.toStringAsFixed(1)} г · '
              '${result.kcal.round()} ккал · белок ${result.protein.toStringAsFixed(1)} г',
            ),
            Text(
              'Клетчатка: ${result.fiber?.toStringAsFixed(1) ?? 'неизвестно'}'
              '${result.fiber == null ? '' : ' г'}',
            ),
            Text(
              'Вода в составе: ${result.water?.toStringAsFixed(1) ?? 'неизвестно'}'
              '${result.water == null ? '' : ' г'}',
            ),
            Text(
              'Энергоёмкость: ${result.energyDensity.toStringAsFixed(2)} ккал/г',
            ),
            const SizedBox(height: 12),
            const Text(
              'Считаем порцию целиком по суммарной массе и составу; '
              'баллы ингредиентов не складываются. Вода из трекера питья '
              'в оценку не входит.',
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Если голодны, можно поесть независимо от оценки. '
            'Баллы не меняют цели, награды или состояние питомца.',
          ),
          const SizedBox(height: 16),
          const ExpansionTile(
            title: Text('Как устроена оценка'),
            children: [
              Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Это локальная формула FitLife v1, а не измеренный '
                  'индекс Холта. Веса факторов и шкала 1–10 пока не проверены '
                  'на пользователях. Учитываем массу, белок, клетчатку, воду '
                  'в еде, энергоёмкость и выбранную структуру. Чем больше '
                  'пробелов в данных, тем шире возможный диапазон.\n\n'
                  'Исследования факторов:\n'
                  'Holt et al., 1995 — pubmed.ncbi.nlm.nih.gov/7498104\n'
                  'Flood-Obbagy & Rolls, 2009 — pubmed.ncbi.nlm.nih.gov/19110020\n'
                  'Rolls et al., 1999 — pubmed.ncbi.nlm.nih.gov/10500012\n\n'
                  'Эти работы не подтверждают нашу формулу и не дают '
                  'универсального времени сытости.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
