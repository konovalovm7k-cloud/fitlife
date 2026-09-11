import 'package:flutter/material.dart';

import 'nutrition_database.dart';
import 'nutrition_day.dart';

class NutritionCatalogPage extends StatefulWidget {
  const NutritionCatalogPage({super.key});
  @override State<NutritionCatalogPage> createState() => _NutritionCatalogPageState();
}

class _NutritionCatalogPageState extends State<NutritionCatalogPage> {
  final _search = TextEditingController();
  final _catalog = const NutritionCatalog();
  NutritionDay _day = const NutritionDay();
  @override void dispose() { _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final results = _catalog.search(_search.text);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(title: const Text('База продуктов'), backgroundColor: Colors.white),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 6), child: TextField(
          controller: _search, onChanged: (_) => setState(() {}),
          decoration: InputDecoration(hintText: 'Поиск продуктов', prefixIcon: const Icon(Icons.search),
            suffixIcon: _search.text.isEmpty ? null : IconButton(onPressed: () { _search.clear(); setState(() {}); }, icon: const Icon(Icons.clear)),
            filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
        )),
        _DaySummary(day: _day),
        Expanded(child: ListView.separated(padding: const EdgeInsets.fromLTRB(12, 6, 12, 24), itemCount: results.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (_, i) => _ProductCard(item: results[i], onAdd: _addFood))),
      ]),
    );
  }

  Future<void> _addFood(NutritionFoodRecord food) async {
    final grams = await _askGrams(food.name);
    if (!mounted || grams == null || grams <= 0) return;
    setState(() => _day = _day.add(food, grams));
  }

  Future<double?> _askGrams(String name) async {
    final controller = TextEditingController(text: '100');
    final value = await showDialog<double>(context: context, builder: (context) => AlertDialog(
      title: Text(name), content: TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Граммы')),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')), FilledButton(onPressed: () => Navigator.pop(context, double.tryParse(controller.text.replaceAll(',', '.'))), child: const Text('Добавить'))],
    ));
    controller.dispose();
    return value;
  }
}

class _DaySummary extends StatelessWidget {
  const _DaySummary({required this.day});
  final NutritionDay day;
  @override Widget build(BuildContext context) {
    final p = day.total;
    return Card(margin: const EdgeInsets.fromLTRB(12, 4, 12, 6), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Сегодня', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 8),
      Wrap(spacing: 14, runSpacing: 5, children: [_metric('Ккал', p.kcal), _metric('Б', p.protein), _metric('Ж', p.fat), _metric('У', p.carbs), _metric('Клетчатка', p.fiber)]),
    ])));
  }
  Widget _metric(String label, double value) => Text('$label ${_fmt(value)}', style: const TextStyle(fontWeight: FontWeight.w700));
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.item, required this.onAdd});
  final NutritionFoodRecord item;
  final ValueChanged<NutritionFoodRecord> onAdd;

  @override Widget build(BuildContext context) {
    final p = item.profile;
    return Card(margin: EdgeInsets.zero, child: Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(item.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 10),
      const Text('Пищевая ценность на 100 г', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 8),
      _nutrient('🔥 Калорийность', p.kcal, 'ккал', 1684),
      _nutrient('🥩 Белки', p.protein, 'г', 76),
      _nutrient('🟡 Жиры', p.fat, 'г', 56),
      _nutrient('🌾 Углеводы', p.carbs, 'г', 219),
      _nutrient('🌿 Пищевые волокна', p.fiber, 'г', 20),
      _nutrient('💧 Вода', p.water, 'г', 2273),
      const SizedBox(height: 12),
      const Text('Витамины и минералы', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 6),
      _twoColumns(p.vitamins, p.minerals),
      if (p.aminoAcids.isNotEmpty) ...[const SizedBox(height: 10), const Text('Аминокислоты', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), _mapGrid(p.aminoAcids)],
      if (p.fattyAcids.isNotEmpty || p.omega3 != null || p.omega6 != null || p.cholesterol != null) ...[
        const SizedBox(height: 10), const Text('Жирные кислоты и стеролы', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        if (p.omega3 != null) _row('Омега-3', '${_fmt(p.omega3!)} г'), if (p.omega6 != null) _row('Омега-6', '${_fmt(p.omega6!)} г'), if (p.cholesterol != null) _row('Холестерин', '${_fmt(p.cholesterol!)} мг'),
        if (p.fattyAcids.isNotEmpty) _mapGrid(p.fattyAcids),
      ],
      const SizedBox(height: 12),
      const Text('Рейтинг', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      const SizedBox(height: 3),
      Text('Полнота состава: ${_completeness(p)}%', style: const TextStyle(color: Colors.black54)),
      const SizedBox(height: 8),
      FilledButton.icon(onPressed: () => onAdd(item), icon: const Icon(Icons.add), label: const Text('Добавить в дневник')),
      const SizedBox(height: 6), Text('Источник: ${item.source}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
    ])));
  }

  Widget _nutrient(String label, double value, String unit, double norm) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Column(children: [
    Row(children: [Expanded(child: Text(label)), Text('${_fmt(value)} $unit', style: const TextStyle(fontWeight: FontWeight.w700)), Text('  ${_pct(value, norm)}%', style: const TextStyle(color: Colors.black54, fontSize: 12))]),
    const SizedBox(height: 3), LinearProgressIndicator(value: (value / norm).clamp(0, 1), minHeight: 5),
  ]));

  Widget _twoColumns(Map<String, double> vitamins, Map<String, double> minerals) {
    final left = vitamins.entries.toList(), right = minerals.entries.toList(), rows = left.length > right.length ? left.length : right.length;
    return Column(children: List.generate(rows, (i) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: i < left.length ? _compact(left[i]) : const SizedBox()), const SizedBox(width: 12), Expanded(child: i < right.length ? _compact(right[i]) : const SizedBox())])));
  }

  Widget _compact(MapEntry<String, double> e) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(e.key, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)), Row(children: [Expanded(child: LinearProgressIndicator(value: _microProgress(e.key, e.value), minHeight: 4)), const SizedBox(width: 6), Text(_fmt(e.value), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))]),
  ]));

  Widget _mapGrid(Map<String, double> map) => Column(children: map.entries.map(_compact).toList());
  Widget _row(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [Expanded(child: Text(label)), Text(value, style: const TextStyle(fontWeight: FontWeight.w700))]));

  double _microProgress(String key, double value) {
    final k = key.toLowerCase();
    double norm = k.contains('мкг') ? 100 : 1;
    if (k.contains('калий')) norm = 3500; else if (k.contains('кальций')) norm = 1000; else if (k.contains('магний')) norm = 400; else if (k.contains('натрий')) norm = 2300; else if (k.contains('фосфор')) norm = 800; else if (k.contains('железо')) norm = 10; else if (k.contains('цинк')) norm = 12; else if (k.contains('витамин c')) norm = 90;
    return (value / norm).clamp(0, 1);
  }
}

int _pct(double value, double norm) => ((value / norm) * 100).round();
int _completeness(NutritionProfile p) => (((p.vitamins.length / 12) * .5 + (p.minerals.length / 15) * .5) * 100).round().clamp(0, 100);
String _fmt(double value) => value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2);
