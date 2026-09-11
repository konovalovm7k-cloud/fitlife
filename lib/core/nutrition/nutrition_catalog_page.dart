import 'package:flutter/material.dart';

import 'nutrition_database.dart';

class NutritionCatalogPage extends StatelessWidget {
  const NutritionCatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      appBar: AppBar(
        title: const Text('База продуктов'),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: nutritionDatabase.map((item) => _ProductCard(item: item)).toList(),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.item});

  final NutritionFoodRecord item;

  @override
  Widget build(BuildContext context) {
    final p = item.profile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Пищевая ценность на 100 г',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                _row('🔥  Калорийность', '${_fmt(p.kcal)} ккал'),
                _row('🥩  Белки', '${_fmt(p.protein)} г'),
                _row('🟡  Жиры', '${_fmt(p.fat)} г'),
                _row('🌾  Углеводы', '${_fmt(p.carbs)} г'),
                _row('🌿  Пищевые волокна', '${_fmt(p.fiber)} г'),
                _row('💧  Вода', '${_fmt(p.water)} г'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Витамины и минералы', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                _section('Витамины', p.vitamins),
                const SizedBox(height: 16),
                _section('Минералы', p.minerals),
                if (p.omega3 != null || p.omega6 != null || p.cholesterol != null) ...[
                  const SizedBox(height: 16),
                  const Text('Жирные кислоты и стеролы', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  if (p.omega3 != null) _row('Омега-3', '${_fmt(p.omega3!)} г'),
                  if (p.omega6 != null) _row('Омега-6', '${_fmt(p.omega6!)} г'),
                  if (p.cholesterol != null) _row('Холестерин', '${_fmt(p.cholesterol!)} мг'),
                ],
                const SizedBox(height: 16),
                const Text('Аминокислоты', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ...p.aminoAcids.entries.map((e) => _row(e.key, _fmt(e.value))),
                const SizedBox(height: 16),
                const Text('Жирные кислоты', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ...p.fattyAcids.entries.map((e) => _row(e.key, _fmt(e.value))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('Источник: ${item.source}', style: const TextStyle(color: Colors.black54)),
        Text(item.sourceUrl, style: const TextStyle(color: Colors.black54, fontSize: 11)),
      ],
    );
  }

  Widget _section(String title, Map<String, double> values) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        ...values.entries.map((e) => _row(e.key, _fmt(e.value))),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  String _fmt(double value) => value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2);
}
