import 'package:flutter/material.dart';
import '../../app/fitlife_theme.dart';
import '../../app/portion_format.dart';
import '../../core/models/nutrition_profile.dart';
import '../../core/nutrition/food_catalog_import.dart';
import '../../core/nutrition/nutrition_database.dart';
import '../../core/nutrition/nutrition_day.dart';
import '../../core/nutrition/nutrition_engine.dart';
import 'photo_models.dart';
import '../satiety/food_satiety_preview_page.dart';

class SourcedFoodEdit {
  const SourcedFoodEdit(this.food) : deleted = false;
  const SourcedFoodEdit.delete() : food = null, deleted = true;
  final PhotoFood? food;
  final bool deleted;
}

class FoodSourcePage extends StatefulWidget {
  const FoodSourcePage({
    super.key,
    this.food,
    this.startWithLabel = false,
    this.onSave,
    this.allowDelete = true,
    this.caption = 'Распознано',
  });
  final PhotoFood? food;
  final bool startWithLabel;
  final Future<void> Function(PhotoFood)? onSave;
  final bool allowDelete;
  final String caption;
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
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    for (final c in [_grams, _name, _reference, ..._numbers]) {
      c.addListener(_refreshPreview);
    }
    _load();
  }

  void _refreshPreview() {
    if (mounted) setState(() {});
  }

  NutritionSource? get _draftSource {
    if (!_manual) return _selected;
    final numbers = _numbers.map((c) => _number(c.text)).toList();
    if (numbers.take(4).any((value) => value == null) ||
        (_numbers[4].text.trim().isNotEmpty && numbers[4] == null)) {
      return null;
    }
    return NutritionSource(
      name: _name.text.trim(),
      provenance: NutritionProvenance(
        kind: 'label',
        reference: _reference.text.trim(),
      ),
      fiberKnown: _numbers[4].text.trim().isNotEmpty,
      profile: NutritionProfile(
        kcal: numbers[0]!,
        protein: numbers[1]!,
        fat: numbers[2]!,
        carbs: numbers[3]!,
        fiber: numbers[4] ?? 0,
      ),
    );
  }

  Widget _portionPreview() {
    final source = _draftSource;
    final grams = _number(_grams.text);
    NutritionProfile? total;
    if (source != null && grams != null) {
      try {
        total = NutritionEngine.portion(source, grams);
      } on FormatException {
        // Incomplete/invalid drafts have no calculated facts; never show the
        // previous valid portion or substitute zero for missing nutrition.
      }
    }
    return Card(
      key: const Key('source-portion-preview'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: total == null
            ? const Text(
                'Выберите источник и укажите корректную порцию, чтобы увидеть расчёт.',
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Для вашей порции · ${formatFoodGrams(grams!)} г',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(source!.name),
                  Text('Источник: ${source.provenance.reference}'),
                  Text(
                    '${total.kcal.round()} ккал',
                    key: const Key('source-portion-kcal'),
                  ),
                  Text(
                    'Белки ${total.protein.toStringAsFixed(1)} г · '
                    'Жиры ${total.fat.toStringAsFixed(1)} г · Углеводы ${total.carbs.toStringAsFixed(1)} г',
                  ),
                  Text(
                    source.fiberKnown
                        ? 'Клетчатка ${total.fiber.toStringAsFixed(1)} г'
                        : 'Клетчатка не указана в источнике.',
                    key: const Key('source-portion-fiber'),
                  ),
                  const Text(
                    'Расчёт по выбранному источнику. Запись изменится только после подтверждения.',
                  ),
                  TextButton.icon(
                    key: const Key('source-satiety-preview'),
                    onPressed: _saving
                        ? null
                        : () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            Navigator.push<void>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FoodSatietyPreviewPage(
                                  source: source,
                                  grams: grams,
                                ),
                              ),
                            );
                          },
                    icon: const Icon(Icons.spa_outlined),
                    label: const Text('Оценить свойства порции'),
                  ),
                ],
              ),
      ),
    );
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

  Future<void> _confirm() async {
    if (_saving) return;
    final visibleFieldsValid = _form.currentState!.validate();
    // Off-screen fields in a lazy ListView may be unmounted. Validate the full
    // draft, not only the FormFields currently registered with the Form.
    final draftValid =
        _validateNumber(_grams.text, 3000, min: .1) == null &&
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
      final source = _draftSource;
      if (source == null) return;
      final grams = _number(_grams.text)!;
      NutritionEngine.portion(source, grams);
      final food = PhotoFood(
        name: source.name,
        grams: grams,
        confidence: widget.food?.confidence ?? 'low',
        source: source,
      );
      if (widget.onSave != null) {
        setState(() {
          _saving = true;
          _error = null;
        });
        await widget.onSave!(food);
      }
      if (mounted) Navigator.pop(context, SourcedFoodEdit(food));
    } on FormatException {
      if (mounted) {
        setState(
          () => _error =
              'Проверьте значения на 100 г: БЖУ не должны превышать массу продукта.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Не удалось сохранить состав. Проверьте выбранные данные и попробуйте ещё раз.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final matches = NutritionCatalog(records: _records).search(_query.text);
    const labels = [
      'Ккал на 100 г',
      'Белки на 100 г',
      'Жиры на 100 г',
      'Углеводы на 100 г',
      'Клетчатка на 100 г — если указана',
    ];
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: const Text('Продукт и источник')),
        body: AbsorbPointer(
          absorbing: _saving,
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (widget.food != null)
                  Text(
                    '${widget.caption}: ${widget.food!.name}',
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
                    decoration: const InputDecoration(
                      labelText: 'Вес порции, г',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) => _validateNumber(v, 3000, min: .1),
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
                        if (_selected?.provenance.kind == 'label') {
                          _selected = null;
                        }
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
                  Semantics(
                    identifier: 'source-search',
                    child: TextField(
                      controller: _query,
                      decoration: const InputDecoration(
                        labelText: 'Поиск в каталоге',
                        suffixIcon: Icon(Icons.search),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
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
                  if (matches.isEmpty && _query.text.trim().isNotEmpty)
                    TextButton(
                      key: const Key('source-show-all'),
                      onPressed: () => setState(_query.clear),
                      child: const Text('Показать весь каталог'),
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
                        // Keep the selected product and confirmation together;
                        // the query remains editable to choose another source.
                        _query.text = record.name;
                        _error = null;
                      }),
                    ),
                  if (matches.length > 30)
                    const Text(
                      'Показаны первые 30 результатов. Уточните название.',
                    ),
                ],
                const SizedBox(height: 16),
                _portionPreview(),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                FilledButton(
                  key: const Key('source-confirm'),
                  onPressed: _saving || (!_manual && _selected == null)
                      ? null
                      : _confirm,
                  child: Text(
                    _saving ? 'Сохраняем…' : 'Подтвердить источник и порцию',
                  ),
                ),
                if (widget.food != null && widget.allowDelete)
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(context, const SourcedFoodEdit.delete()),
                    child: const Text('Удалить ингредиент'),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
