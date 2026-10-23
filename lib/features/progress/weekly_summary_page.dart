import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/fitlife_theme.dart';
import 'weekly_summary.dart';

class WeeklySummaryPage extends StatefulWidget {
  const WeeklySummaryPage({
    super.key,
    required this.end,
    this.preferencesLoader,
  });
  final DateTime end;
  final Future<SharedPreferences> Function()? preferencesLoader;
  @override
  State<WeeklySummaryPage> createState() => _WeeklySummaryPageState();
}

class _WeeklySummaryPageState extends State<WeeklySummaryPage> {
  late Future<WeeklySummary> _summary = _load();
  Future<WeeklySummary> _load() => WeeklySummary.load(
    widget.end,
    preferencesLoader: widget.preferencesLoader,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Обзор 7 дней')),
    body: FutureBuilder<WeeklySummary>(
      future: _summary,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Не удалось прочитать историю. Ваши записи не изменены.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => setState(() => _summary = _load()),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final summary = snapshot.data!;
        final average = summary.average((day) => day.calories);
        final maximum = summary.days
            .where((day) => day.hasFood)
            .fold(1.0, (value, day) => math.max(value, day.calories));
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: greenDark,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${summaryDate(summary.days.first.date)} — ${summaryDate(summary.days.last.date)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${summary.logged.length} из 7 дней',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'с записями о еде',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    average == null
                        ? 'Начните с одной записи'
                        : '${average.round()} ккал в среднем',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Только по внесённым продуктам. Пропуски — не нулевой рацион.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ритм недели',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Нажмите на день, чтобы открыть дневник.',
              style: TextStyle(color: muted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final day in summary.days)
                  Expanded(
                    child: Semantics(
                      button: true,
                      label:
                          '${summaryDate(day.date)}: ${day.damaged
                              ? 'неполные данные'
                              : day.hasFood
                              ? '${day.calories.round()} килокалорий'
                              : 'нет записей'}',
                      child: InkWell(
                        onTap: () => Navigator.pop(context, day.date),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 8,
                          ),
                          child: Column(
                            children: [
                              Text(
                                day.damaged
                                    ? '!'
                                    : day.hasFood
                                    ? '${day.calories.round()}'
                                    : '—',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: muted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 110,
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    height: day.hasFood
                                        ? math.max(
                                            6,
                                            day.calories / maximum * 110,
                                          )
                                        : 6,
                                    decoration: BoxDecoration(
                                      color: day.damaged
                                          ? coral
                                          : day.hasFood
                                          ? green
                                          : line,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${day.date.day}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            if (average != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Среднее по дням с записями',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Белки ${summary.average((day) => day.protein)!.round()} г · '
                      'Жиры ${summary.average((day) => day.fat)!.round()} г · '
                      'Углеводы ${summary.average((day) => day.carbs)!.round()} г',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Клетчатка ${summary.average((day) => day.fiber)!.round()} г',
                      style: const TextStyle(color: muted),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            if (summary.days.any((day) => day.damaged))
              const Text(
                'Некоторые дни содержат повреждённые записи. Они не включены в среднее; исходные данные сохранены для восстановления.',
                style: TextStyle(color: muted),
              ),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  await Clipboard.setData(
                    ClipboardData(text: summary.report()),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Отчёт скопирован. Отправляйте его только тем, кому доверяете.',
                        ),
                      ),
                    );
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Не удалось скопировать отчёт. Повторите позже.',
                        ),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.copy_outlined),
              label: const Text('Скопировать отчёт'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Отчёт создаётся на телефоне и не отправляется на сервер. Это записи дневника, не медицинская оценка. Старые дни не сравниваются с текущими целями.',
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ],
        );
      },
    ),
  );
}
