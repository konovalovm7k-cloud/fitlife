import 'package:flutter/material.dart';

import '../fitlife_theme.dart';
import '../nutrition_goal_format.dart';

class DayNutritionSummary extends StatelessWidget {
  const DayNutritionSummary({
    super.key,
    required this.calories,
    required this.target,
  });

  final double calories;
  final double target;

  @override
  Widget build(BuildContext context) {
    final remaining = (target - calories).clamp(0, target);
    final excess = calories - target;
    final progress = (calories / target).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [greenDark, Color(0xFF32684C)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ЭНЕРГИЯ ДНЯ',
            style: TextStyle(
              color: Color(0xFFD0E4D4),
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 24,
            runSpacing: 20,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Semantics(
                label: 'Осталось ${remaining.round()} килокалорий',
                child: SizedBox.square(
                  dimension: MediaQuery.textScalerOf(
                    context,
                  ).scale(140).clamp(140, 200),
                  child: Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 9,
                        strokeCap: StrokeCap.round,
                        color: const Color(0xFFD6ECA4),
                        backgroundColor: const Color(0xFF4C715C),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FittedBox(
                                child: Text(
                                  '${remaining.round()}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                    letterSpacing: -1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'ккал осталось',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFFD0E4D4),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _number('Съедено', calories.round().toString()),
                    const SizedBox(height: 18),
                    _number('Дневная цель', formatNutritionGoal(target)),
                  ],
                ),
              ),
            ],
          ),
          if (excess > 0) ...[
            const SizedBox(height: 18),
            Text(
              'Выше цели на ${excess.round()} ккал',
              style: const TextStyle(color: Color(0xFFE1EDCF), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _number(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: Color(0xFFD0E4D4), fontSize: 11),
      ),
      const SizedBox(height: 3),
      FittedBox(
        child: Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const Text(
        'ккал',
        style: TextStyle(color: Color(0xFFD0E4D4), fontSize: 10),
      ),
    ],
  );
}

class MacroProgress extends StatelessWidget {
  const MacroProgress({
    super.key,
    required this.title,
    required this.value,
    required this.target,
    required this.color,
    this.partial = false,
  });

  final String title;
  final double value;
  final double target;
  final Color color;
  final bool partial;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: muted, fontSize: 11)),
          const SizedBox(height: 7),
          Text(
            '${partial ? '≥ ' : ''}${value.round()} г',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            'из ${formatNutritionGoal(target)} г',
            style: const TextStyle(color: muted, fontSize: 10),
          ),
          if (partial)
            const Text(
              'Состав неполный',
              style: TextStyle(color: muted, fontSize: 10),
            ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: target <= 0 ? 0 : (value / target).clamp(0.0, 1.0),
            minHeight: 5,
            color: color,
            backgroundColor: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    ),
  );
}
