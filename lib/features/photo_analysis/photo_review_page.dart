import 'package:flutter/material.dart';
import '../../app/fitlife_theme.dart';
import '../../core/models/nutrition_profile.dart';
import '../satiety/satiety_estimate.dart';
import '../satiety/satiety_page.dart';
import 'food_source_page.dart';
import 'photo_models.dart';

class PhotoReviewPage extends StatefulWidget {
  const PhotoReviewPage({
    super.key,
    required this.analysis,
    required this.day,
    required this.initialMeal,
    required this.onSave,
  });
  final PhotoAnalysis analysis;
  final DateTime day;
  final String initialMeal;
  final Future<void> Function(PhotoMeal) onSave;
  @override
  State<PhotoReviewPage> createState() => _PhotoReviewPageState();
}

class _PhotoReviewPageState extends State<PhotoReviewPage> {
  late final _items = [...widget.analysis.items];
  late String _meal = widget.initialMeal;
  bool _saving = false;
  String? _error;
  bool get _complete =>
      _items.isNotEmpty && _items.every((f) => f.source != null);

  void _previewProperties() {
    if (_saving || !_complete) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final portions = List<SourcedSatietyPortion>.unmodifiable([
      for (final item in _items) (source: item.source!, grams: item.grams),
    ]);
    final meal = _meal;
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => SatietyPage.planned(
          portions: portions,
          meal: meal,
          day: widget.day,
        ),
      ),
    );
  }

  Future<void> _edit(int? index) async {
    final result = await Navigator.push<SourcedFoodEdit>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            FoodSourcePage(food: index == null ? null : _items[index]),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      if (result.deleted) {
        _items.removeAt(index!);
      } else if (index == null) {
        _items.add(result.food!);
      } else {
        _items[index] = result.food!;
      }
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_saving || !_complete) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(
        PhotoMeal(
          id: widget.analysis.requestId,
          day: widget.day,
          meal: _meal,
          items: List.unmodifiable(_items),
          source: widget.analysis.source,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Не удалось сохранить в дневник. Ваши правки остались на этом экране. Нажмите ещё раз.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double total(double Function(NutritionProfile) get) => _items.fold(
      0.0,
      (sum, f) => sum + (f.portion == null ? 0 : get(f.portion!)),
    );
    final date =
        '${widget.day.day.toString().padLeft(2, '0')}.${widget.day.month.toString().padLeft(2, '0')}.${widget.day.year}';
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: const Text('Проверьте блюдо')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: greenDark,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.analysis.source == MealEstimateSource.chef
                        ? 'ИДЕЯ AI · ИСТОЧНИКИ СОСТАВА'
                        : widget.analysis.source == MealEstimateSource.manual
                        ? 'СОСТАВ ПРОДУКТОВ'
                        : widget.analysis.source == MealEstimateSource.text
                        ? 'ПРОДУКТЫ ИЗ ОПИСАНИЯ'
                        : 'ПРОДУКТЫ НА ФОТО',
                    style: const TextStyle(
                      color: Colors.white70,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _complete
                        ? '${total((p) => p.kcal).round()} ккал'
                        : 'Нужен источник состава',
                    key: const Key('photo-total'),
                    style: const TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (_complete) ...[
                    Text(
                      'Б ${total((p) => p.protein).round()} · Ж ${total((p) => p.fat).round()} · У ${total((p) => p.carbs).round()} г',
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      _items.any((f) => !f.source!.fiberKnown)
                          ? 'Клетчатка: состав неполный'
                          : 'Клетчатка ${total((p) => p.fiber).round()} г',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Запись за $date',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.analysis.source == MealEstimateSource.chef
                  ? 'AI предложил сочетание и массу готовых продуктов. Состав рассчитан по выбранным источникам. Проверьте продукт, состояние и порцию; источники и ингредиенты можно изменить перед записью.'
                  : widget.analysis.source == MealEstimateSource.manual
                  ? 'Проверьте выбранные источники состава и массу порций. Масло, соусы и другие ингредиенты добавьте перед сохранением, если их здесь нет.'
                  : 'AI предлагает только продукт и примерную массу. Выберите источник состава для каждого ингредиента и проверьте порцию. Масло и соусы добавьте отдельно, если они не учтены в блюде.',
            ),
            for (final warning in widget.analysis.warnings)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('• $warning'),
              ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _meal,
              decoration: const InputDecoration(labelText: 'Приём пищи'),
              items: photoMeals
                  .map(
                    (meal) => DropdownMenuItem(value: meal, child: Text(meal)),
                  )
                  .toList(),
              onChanged: _saving ? null : (v) => setState(() => _meal = v!),
            ),
            const SizedBox(height: 16),
            if (_complete) ...[
              Semantics(
                identifier: 'review-meal-properties',
                child: OutlinedButton.icon(
                  key: const Key('review-meal-properties'),
                  onPressed: _saving ? null : _previewProperties,
                  icon: const Icon(Icons.spa_outlined),
                  label: const Text('Свойства порции блюда'),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_items.isEmpty)
              const Text(
                'Продуктов пока нет. Добавьте вручную или вернитесь к фото.',
              ),
            for (var i = 0; i < _items.length; i++)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _items[i].name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '${_items[i].grams} г · ${_items[i].source == null ? 'состав не выбран' : '${_items[i].calories!.round()} ккал'}',
                      ),
                      if (_items[i].source != null) ...[
                        Text(
                          'Источник: ${_items[i].source!.provenance.reference}',
                        ),
                        if (_items[i].source!.provenance.url != null)
                          SelectableText(_items[i].source!.provenance.url!),
                      ] else
                        Text(
                          'Уверенность в названии: ${switch (_items[i].confidence) {
                            'high' => 'высокая',
                            'medium' => 'средняя',
                            _ => 'низкая',
                          }}',
                        ),
                      TextButton.icon(
                        key: Key('food-source-$i'),
                        onPressed: _saving ? null : () => _edit(i),
                        icon: const Icon(Icons.fact_check_outlined),
                        label: Text(
                          _items[i].source == null
                              ? 'Выбрать источник'
                              : 'Изменить источник или порцию',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            OutlinedButton.icon(
              onPressed: _saving || _items.length >= 12
                  ? null
                  : () => _edit(null),
              icon: const Icon(Icons.add),
              label: const Text('Добавить ингредиент'),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            FilledButton.icon(
              key: const Key('photo-save'),
              onPressed: _saving || !_complete ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_saving ? 'Сохраняем…' : 'Подтвердить и сохранить'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
