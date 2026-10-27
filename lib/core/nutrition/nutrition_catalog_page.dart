import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/widgets/value_editor.dart';
import 'dart:math';
import '../models/nutrition_profile.dart';
import 'nutrition_database.dart';
import 'nutrition_day.dart';
import 'nutrition_targets.dart';
import 'food_catalog_import.dart';

class NutritionCatalogPage extends StatefulWidget {
  const NutritionCatalogPage({
    super.key,
    this.initialDay = const NutritionDay(),
    this.onAdd,
    this.dayLabel = 'Сегодня',
  });
  final NutritionDay initialDay;
  final Future<void> Function(NutritionDayEntry, String id)? onAdd;
  final String dayLabel;
  @override
  State<NutritionCatalogPage> createState() => _NutritionCatalogPageState();
}

class _NutritionCatalogPageState extends State<NutritionCatalogPage> {
  final _search = TextEditingController();
  var _catalog = const NutritionCatalog();
  bool _catalogError = false;

  @override
  void initState() {
    super.initState();
    _loadAdditional();
  }

  Future<void> _loadAdditional() async {
    try {
      final extra = await loadAdditionalFoods().timeout(
        const Duration(seconds: 10),
      );
      if (mounted) {
        setState(
          () => _catalog = NutritionCatalog(
            records: [...nutritionDatabase, ...extra],
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _catalogError = true);
    }
  }

  late NutritionDay _day = widget.initialDay;
  NutritionDayEntry? _pending;
  String? _pendingId;
  bool _saving = false;
  String? _saveError;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _catalog.search(_search.text);
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7F8),
        appBar: AppBar(
          title: const Text('База продуктов'),
          backgroundColor: Colors.white,
        ),
        body: CustomScrollView(
          slivers: [
            if (_catalogError)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Дополнительная база недоступна. Основные продукты и дневник работают.',
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Поиск продуктов',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _search.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.clear),
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  widget.dayLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _DaySummary(day: _day)),
            SliverToBoxAdapter(child: _DayMicronutrientAnalysis(day: _day)),
            if (_saveError != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        _saveError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      FilledButton(
                        onPressed: _saving ? null : _savePending,
                        child: Text(
                          _saving ? 'Сохраняем...' : 'Повторить сохранение',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (results.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Продукты не найдены. Попробуй другое название.'),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
              sliver: SliverList.builder(
                itemCount: results.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ProductCard(
                    item: results[i],
                    onAdd: _saving || _pending != null ? null : _addFood,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addFood(NutritionFoodRecord food) async {
    if (_saving || _pending != null) return;
    final grams = await _askGrams(food.name);
    if (!mounted || grams == null || !grams.isFinite || grams <= 0) return;
    setState(() {
      _pending = NutritionDayEntry(food: food, grams: grams);
      _pendingId =
          'catalog_${List.generate(16, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
    });
    await _savePending();
  }

  Future<void> _savePending() async {
    final entry = _pending;
    if (_saving || entry == null) return;
    setState(() => _saving = true);
    try {
      await widget.onAdd
          ?.call(entry, _pendingId!)
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      setState(() {
        _day = _day.add(entry.food, entry.grams);
        _pending = null;
        _pendingId = null;
        _saveError = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${entry.food.name}: добавлено ${entry.grams} г'),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _saveError =
              'Не удалось завершить сохранение. Повторите попытку: выбранная порция сохранена на этом экране.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<double?> _askGrams(String name) async {
    final value = await showDialog<ValueEditResult>(
      context: context,
      builder: (context) => ValueEditorDialog(
        title: name,
        saveLabel: 'Добавить',
        fields: const [NumberFieldSpec('Граммы', 100, min: 0.1)],
      ),
    );
    return value?.values.first;
  }
}

class _DaySummary extends StatelessWidget {
  const _DaySummary({required this.day});
  final NutritionDay day;

  @override
  Widget build(BuildContext context) {
    final p = day.total;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Итого за день',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 14,
              runSpacing: 5,
              children: [
                _metric('Ккал', p.kcal),
                _metric('Б', p.protein),
                _metric('Ж', p.fat),
                _metric('У', p.carbs),
                _metric(
                  day.entries.any((e) => !e.food.hasKnownFiber)
                      ? 'Клетчатка ≥'
                      : 'Клетчатка',
                  p.fiber,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, double value) => Text(
    '$label ${_fmt(value)}',
    style: const TextStyle(fontWeight: FontWeight.w700),
  );
}

class _DayMicronutrientAnalysis extends StatelessWidget {
  const _DayMicronutrientAnalysis({required this.day});
  final NutritionDay day;

  @override
  Widget build(BuildContext context) {
    final p = day.total;
    if (p.vitamins.isEmpty && p.minerals.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: ExpansionTile(
        title: const Text(
          'Витамины и минералы',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        children: [
          Padding(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Анализ дня',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Витамины и минералы',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                _analysisGrid(p.vitamins, p.minerals),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _analysisGrid(
    Map<String, double> vitamins,
    Map<String, double> minerals,
  ) {
    final left = vitamins.entries.toList();
    final right = minerals.entries.toList();
    final rows = left.length > right.length ? left.length : right.length;
    return Column(
      children: List.generate(
        rows,
        (i) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: i < left.length
                  ? _analysisRow(left[i], true)
                  : const SizedBox(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: i < right.length
                  ? _analysisRow(right[i], false)
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _analysisRow(MapEntry<String, double> entry, bool vitamin) {
    final target = vitamin
        ? NutritionTargets.forVitamin(entry.key)
        : NutritionTargets.forMineral(entry.key);
    final ratio = target == null || target <= 0 ? null : entry.value / target;
    final percent = ratio == null ? null : (ratio * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.key,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: ratio?.clamp(0.0, 1.0).toDouble() ?? 0,
                  minHeight: 5,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${_fmt(entry.value)}${percent == null ? '' : '  $percent%'}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.item, required this.onAdd});
  final NutritionFoodRecord item;
  final ValueChanged<NutritionFoodRecord>? onAdd;

  @override
  Widget build(BuildContext context) {
    final p = item.profile;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              item.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              '${_fmt(p.kcal)} ккал · Б ${_fmt(p.protein)} · Ж ${_fmt(p.fat)} · У ${_fmt(p.carbs)} на 100 г',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onAdd == null ? null : () => onAdd!(item),
              icon: const Icon(Icons.add),
              label: const Text('Добавить в дневник'),
            ),
            if (item.macrosOnly)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  item.hasKnownFiber
                      ? 'Клетчатка: ${_fmt(p.fiber)} г на 100 г. Витамины и минералы в этой подборке не представлены.'
                      : 'Клетчатка: нет данных. Витамины и минералы в этой подборке не представлены.',
                ),
              ),
            if (!item.macrosOnly)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text(
                  'Полный состав',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                children: [
                  const Text(
                    'Пищевая ценность на 100 г',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  _nutrient('🔥 Калорийность', p.kcal, 'ккал', 1684),
                  _nutrient('🥩 Белки', p.protein, 'г', 76),
                  _nutrient('🟡 Жиры', p.fat, 'г', 56),
                  _nutrient('🌾 Углеводы', p.carbs, 'г', 219),
                  _nutrient('🌿 Пищевые волокна', p.fiber, 'г', 20),
                  _nutrient('💧 Вода', p.water, 'г', 2273),
                  const SizedBox(height: 12),
                  const Text(
                    'Витамины и минералы',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  _twoColumns(p.vitamins, p.minerals),
                  if (p.aminoAcids.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Аминокислоты',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    _mapGrid(p.aminoAcids),
                  ],
                  if (p.fattyAcids.isNotEmpty ||
                      p.omega3 != null ||
                      p.omega6 != null ||
                      p.cholesterol != null) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Жирные кислоты и стеролы',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (p.omega3 != null)
                      _row('Омега-3', '${_fmt(p.omega3!)} г'),
                    if (p.omega6 != null)
                      _row('Омега-6', '${_fmt(p.omega6!)} г'),
                    if (p.cholesterol != null)
                      _row('Холестерин', '${_fmt(p.cholesterol!)} мг'),
                    if (p.fattyAcids.isNotEmpty) _mapGrid(p.fattyAcids),
                  ],
                  const SizedBox(height: 12),
                  const Text(
                    'Рейтинг',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'Полнота состава: ${_completeness(p)}%',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            const SizedBox(height: 6),
            Text(
              'Источник: ${item.source}',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: item.sourceUrl));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ссылка на источник скопирована'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.link),
              label: const Text('Скопировать ссылку на источник'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nutrient(String label, double value, String unit, double norm) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text(label)),
                Text(
                  '${_fmt(value)} $unit',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '  ${_pct(value, norm)}%',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 3),
            LinearProgressIndicator(
              value: (value / norm).clamp(0.0, 1.0).toDouble(),
              minHeight: 5,
            ),
          ],
        ),
      );

  Widget _twoColumns(
    Map<String, double> vitamins,
    Map<String, double> minerals,
  ) {
    final left = vitamins.entries.toList();
    final right = minerals.entries.toList();
    final rows = left.length > right.length ? left.length : right.length;
    return Column(
      children: List.generate(
        rows,
        (i) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: i < left.length
                  ? _compact(left[i], true)
                  : const SizedBox(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: i < right.length
                  ? _compact(right[i], false)
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compact(MapEntry<String, double> e, bool vitamin) {
    final target = vitamin
        ? NutritionTargets.forVitamin(e.key)
        : NutritionTargets.forMineral(e.key);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            e.key,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: target == null
                      ? 0
                      : (e.value / target).clamp(0.0, 1.0).toDouble(),
                  minHeight: 4,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _fmt(e.value),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mapGrid(Map<String, double> map) =>
      Column(children: map.entries.map((e) => _compact(e, false)).toList());
  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

int _pct(double value, double norm) => (value / norm * 100).round();
int _completeness(NutritionProfile p) =>
    (((p.vitamins.length / 12) * .5 + (p.minerals.length / 15) * .5) * 100)
        .round()
        .clamp(0, 100)
        .toInt();
String _fmt(double value) =>
    value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2);
