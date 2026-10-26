import 'package:flutter/material.dart';
import '../../app/fitlife_theme.dart';
import '../../core/models/nutrition_profile.dart';
import '../../core/nutrition/food_catalog_import.dart';
import '../../core/nutrition/nutrition_database.dart';
import '../../core/nutrition/nutrition_engine.dart';
import 'photo_models.dart';

class SourcedFoodEdit {
  const SourcedFoodEdit(this.food) : deleted = false;
  const SourcedFoodEdit.delete() : food = null, deleted = true;
  final PhotoFood? food;
  final bool deleted;
}

class FoodSourcePage extends StatefulWidget {
  const FoodSourcePage({super.key, this.food, this.startWithLabel = false});
  final PhotoFood? food;
  final bool startWithLabel;
  @override
  State<FoodSourcePage> createState() => _FoodSourcePageState();
}

class _FoodSourcePageState extends State<FoodSourcePage> {
  final _form = GlobalKey<FormState>();
  late final _grams = TextEditingController(
    text: '${widget.food?.grams ?? 100}',
  );
  late final _query = TextEditingController(text: widget.food?.name ?? '');
  late final _name = TextEditingController(
    text: widget.food?.source?.name ?? widget.food?.name ?? '',
  );
  late final _reference = TextEditingController(
    text: widget.food?.source?.provenance.kind == 'label'
        ? widget.food!.source!.provenance.reference
        : '',
  );
  late final _numbers = List.generate(5, (i) {
    final source = widget.food?.source;
    if (source?.provenance.kind != 'label') return TextEditingController();
    final p = source!.profile;
    final values = [p.kcal, p.protein, p.fat, p.carbs, p.fiber];
    return TextEditingController(
      text: i == 4 && !source.fiberKnown ? '' : '${values[i]}',
    );
  });
  late NutritionSource? _selected = widget.food?.source;
  late bool _manual =
      widget.startWithLabel || _selected?.provenance.kind == 'label';
  List<NutritionFoodRecord> _records = nutritionDatabase;
  String? _notice;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final additional = await loadAdditionalFoods();
      if (mounted) {
        setState(() => _records = [...nutritionDatabase, ...additional]);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _notice =
              'Дополнительный каталог недоступен. Можно выбрать встроенный продукт или ввести этикетку.',
        );
      }
    }
  }

  @override
  void dispose() {
    for (final c in [_grams, _query, _name, _reference, ..._numbers]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _number(String? value) =>
      double.tryParse((value ?? '').trim().replaceAll(',', '.'));
  String? _validateNumber(
    String? value,
    double max, {
    bool optional = false,
    double min = 0,
  }) {
    if (optional && (value ?? '').trim().isEmpty) return null;
    final n = _number(value);
    return n == null || !n.isFinite || n < min || n > max
        ? 'Введите число от $min до $max'
        : null;
  }

  void _confirm() {
    final visibleFieldsValid = _form.currentState!.validate();
    // Off-screen fields in a lazy ListView may be unmounted. Validate the full
    // draft, not only the FormFields currently registered with the Form.
    final draftValid =
        _validateNumber(_grams.text, 3000, min: 1) == null &&
        (!_manual ||
            (_name.text.trim().isNotEmpty &&
                _name.text.trim().length <= 80 &&
                _reference.text.trim().isNotEmpty &&
                _reference.text.trim().length <= 240 &&
                List.generate(
                  5,
                  (i) => _validateNumber(
                    _numbers[i].text,
                    i == 0 ? 1000 : 100,
                    optional: i == 4,
                  ),
                ).every((error) => error == null)));
    if (!visibleFieldsValid || !draftValid) {
      setState(
        () => _error =
            'Заполните название, источник, массу и КБЖУ на 100 г. Клетчатку можно оставить пустой.',
      );
      return;
    }
    try {
      final source = _manual
          ? NutritionSource(
              name: _name.text.trim(),
              provenance: NutritionProvenance(
                kind: 'label',
                reference: _reference.text.trim(),
              ),
              fiberKnown: _numbers[4].text.trim().isNotEmpty,
              profile: NutritionProfile(
                kcal: _number(_numbers[0].text)!,
                protein: _number(_numbers[1].text)!,
                fat: _number(_numbers[2].text)!,
                carbs: _number(_numbers[3].text)!,
                fiber: _number(_numbers[4].text) ?? 0,
              ),
            )
          : _selected;
      if (source == null) return;
      final grams = _number(_grams.text)!;
      NutritionEngine.portion(source, grams);
      Navigator.pop(
        context,
        SourcedFoodEdit(
          PhotoFood(
            name: source.name,
            grams: grams,
            confidence: widget.food?.confidence ?? 'low',
            source: source,
          ),
        ),
      );
    } on FormatException {
      setState(
        () => _error =
            'Проверьте значения на 100 г: БЖУ не должны превышать массу продукта.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.text.toLowerCase().trim();
    final matches = _records
        .where((r) => r.name.toLowerCase().contains(query))
        .toList();
    const labels = [
      'Ккал на 100 г',
      'Белки на 100 г',
      'Жиры на 100 г',
      'Углеводы на 100 г',
      'Клетчатка на 100 г — если указана',
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Продукт и источник')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (widget.food != null)
              Text(
                'Распознано: ${widget.food!.name}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            const SizedBox(height: 10),
            const Text(
              'Проверьте вид продукта и способ приготовления. Похожее название не гарантирует одинаковый состав.',
            ),
            const SizedBox(height: 16),
            Semantics(
              identifier: 'source-grams',
              child: TextFormField(
                controller: _grams,
                key: const Key('source-grams'),
                decoration: const InputDecoration(labelText: 'Вес порции, г'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) => _validateNumber(v, 3000, min: 1),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Из каталога'),
                  selected: !_manual,
                  onSelected: (_) => setState(() {
                    _manual = false;
                    if (_selected?.provenance.kind == 'label') _selected = null;
                  }),
                ),
                ChoiceChip(
                  label: const Text('С этикетки'),
                  selected: _manual,
                  onSelected: (_) => setState(() => _manual = true),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_manual) ...[
              const Text(
                'Перенесите состав на 100 г с упаковки. Поля не заполняются ответом AI. Если клетчатка не указана, оставьте её пустой.',
              ),
              const SizedBox(height: 12),
              Semantics(
                identifier: 'source-name',
                child: TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Название продукта',
                  ),
                  maxLength: 80,
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Укажите продукт' : null,
                ),
              ),
              Semantics(
                identifier: 'source-reference',
                child: TextFormField(
                  controller: _reference,
                  decoration: const InputDecoration(
                    labelText: 'Источник: марка и название на упаковке',
                  ),
                  maxLength: 240,
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? 'Укажите, с какой этикетки взят состав'
                      : null,
                ),
              ),
              for (var i = 0; i < labels.length; i++)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Semantics(
                    identifier: 'source-nutrient-$i',
                    child: TextFormField(
                      key: Key('source-nutrient-$i'),
                      controller: _numbers[i],
                      decoration: InputDecoration(labelText: labels[i]),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) => _validateNumber(
                        v,
                        i == 0 ? 1000 : 100,
                        optional: i == 4,
                      ),
                    ),
                  ),
                ),
            ] else ...[
              if (_notice != null) Text(_notice!),
              TextField(
                controller: _query,
                decoration: const InputDecoration(
                  labelText: 'Поиск в каталоге',
                  suffixIcon: Icon(Icons.search),
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (_selected != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Выбрано: ${_selected!.name}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text('${_selected!.profile.kcal} ккал на 100 г'),
                        Text(_selected!.provenance.reference),
                        SelectableText(_selected!.provenance.url ?? ''),
                        if (!_selected!.fiberKnown)
                          const Text('Клетчатка не указана в источнике.'),
                      ],
                    ),
                  ),
                ),
              if (matches.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Совпадений нет. Измените запрос или введите состав с этикетки.',
                  ),
                ),
              for (final record in matches.take(30))
                ListTile(
                  title: Text(record.name),
                  subtitle: Text(
                    '${record.source}\n${record.profile.kcal} ккал на 100 г',
                  ),
                  trailing: _selected?.provenance.recordId == record.id
                      ? const Icon(Icons.check_circle, color: green)
                      : const Icon(Icons.chevron_right),
                  onTap: () => setState(() {
                    _selected = NutritionSource.catalogue(record);
                    _error = null;
                  }),
                ),
              if (matches.length > 30)
                const Text(
                  'Показаны первые 30 результатов. Уточните название.',
                ),
            ],
            const SizedBox(height: 16),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            FilledButton(
              key: const Key('source-confirm'),
              onPressed: !_manual && _selected == null ? null : _confirm,
              child: const Text('Подтвердить источник и порцию'),
            ),
            if (widget.food != null)
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, const SourcedFoodEdit.delete()),
                child: const Text('Удалить ингредиент'),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
