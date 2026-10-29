import 'package:flutter/material.dart';
import '../../core/models/diary_item.dart';
import 'satiety_estimate.dart';
import 'satiety_explanation.dart';
import '../../data/repositories/diary_repository.dart';
import 'hunger_observation.dart';
import 'hunger_pages.dart';

class SatietyPage extends StatefulWidget {
  const SatietyPage({
    super.key,
    required this.items,
    required this.meal,
    required this.day,
    this.hungerRepository,
  }) : preview = false;

  /// Evaluate a planned portion without offering observations for uneaten food.
  const SatietyPage.preview({
    super.key,
    required this.items,
    required this.meal,
    required this.day,
  }) : preview = true,
       hungerRepository = null;
  final List<DiaryItem> items;
  final String meal;
  final DateTime day;
  final HungerRepository? hungerRepository;
  final bool preview;
  @override
  State<SatietyPage> createState() => _SatietyPageState();
}

class _SatietyPageState extends State<SatietyPage> {
  late final _observations =
      widget.hungerRepository ?? HungerRepository(DiaryRepository.withLoader());
  FoodStructure? _structure;

  @override
  Widget build(BuildContext context) {
    SatietyEstimate? result;
    try {
      result = SatietyEstimate.calculate(widget.items, structure: _structure);
    } on FormatException {
      // Old AI estimates are readable but are not evidence for a new score.
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preview ? 'Свойства порции блюда' : 'Умная сытость'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(widget.meal, style: Theme.of(context).textTheme.headlineSmall),
          if (widget.preview) ...[
            const SizedBox(height: 12),
            const Text(
              'Предварительная оценка выбранной порции. Дневник и сохранённое '
              'блюдо не меняются. Наблюдения голода доступны после записи еды.',
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Экспериментальная оценка свойств порции. Она не измеряет ваш голод, '
            'не оценивает полезность еды и не предсказывает часы сытости.',
          ),
          const SizedBox(height: 16),
          if (widget.preview)
            ExpansionTile(
              key: const Key('recipe-preview-sources'),
              title: Text('Состав и источники (${widget.items.length})'),
              children: _ingredients,
            )
          else
            ..._ingredients,
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
              children: satietyStructureLabels.entries
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
          if (!widget.preview) ...[
            OutlinedButton.icon(
              key: const Key('observe-hunger'),
              onPressed: () => Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => HungerEntryPage(
                    repository: _observations,
                    items: widget.items,
                    meal: widget.meal,
                    day: widget.day,
                    structure: _structure,
                  ),
                ),
              ),
              icon: const Icon(Icons.edit_note),
              label: const Text('Отметить голод сейчас'),
            ),
            TextButton(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => HungerHistoryPage(repository: _observations),
                ),
              ),
              child: const Text('Мои наблюдения голода'),
            ),
          ],
          const SizedBox(height: 16),
          const SatietyExplanation(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  List<Widget> get _ingredients => [
    for (final item in widget.items)
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          '${item.food.name} · ${item.grams} г\n'
          'Источник: ${item.food.provenance?.reference ?? 'не подтверждён'}',
        ),
      ),
  ];
}
