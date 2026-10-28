import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/fitlife_theme.dart';
import '../../app/widgets/value_editor.dart';
import 'weight_history.dart';

String weightDate(DateTime day) =>
    '${day.day}.${day.month.toString().padLeft(2, '0')}.${day.year}';

class WeightHistoryPage extends StatefulWidget {
  const WeightHistoryPage({super.key, required this.repository});
  final WeightRepository repository;
  @override
  State<WeightHistoryPage> createState() => _WeightHistoryPageState();
}

class _WeightHistoryPageState extends State<WeightHistoryPage> {
  late Future<WeightHistory> _data = _load();
  int _period = 30;
  Future<WeightHistory> _load() {
    final future = Future<WeightHistory>.sync(
      widget.repository.load,
    ).timeout(const Duration(seconds: 15));
    future.ignore();
    return future;
  }

  void _retry() {
    setState(() {
      _data = _load();
    });
  }

  Future<void> _edit(WeightHistory history, {WeightEntry? entry}) async {
    final now = DateUtils.dateOnly(DateTime.now());
    final date =
        entry?.day ??
        await showDatePicker(
          context: context,
          initialDate: now,
          firstDate: DateTime(2020),
          lastDate: now,
          helpText: 'Дата измерения',
        );
    if (!mounted || date == null) return;
    final sameDay = history.entries.where(
      (e) => DateUtils.isSameDay(e.day, date),
    );
    final existing = sameDay.firstOrNull;
    await showDialog<ValueEditResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ValueEditorDialog(
        title: 'Вес · ${weightDate(date)}',
        allowDelete: existing != null,
        fields: [
          NumberFieldSpec(
            'Вес, кг',
            existing?.kg ?? history.latest ?? 70,
            min: 30,
            max: 300,
          ),
        ],
        onSave: (result) async {
          final updated = result.deleted
              ? await widget.repository.delete(date)
              : await widget.repository.save(
                  WeightEntry(date, result.values.single),
                );
          if (mounted) {
            setState(() {
              _data = Future.value(updated);
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('История веса')),
    body: FutureBuilder<WeightHistory>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Не удалось прочитать измерения.'),
                TextButton(onPressed: _retry, child: const Text('Повторить')),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final history = snapshot.data!;
        final now = DateTime.now();
        final since = DateTime(now.year, now.month, now.day - _period + 1);
        final visible = history.entries
            .where((e) => _period == 0 || !e.day.isBefore(since))
            .toList();
        final change = visible.length >= 2
            ? visible.last.kg - visible.first.kg
            : null;
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
                  const Text(
                    'Последнее измерение',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    history.latest == null
                        ? 'Пока нет данных'
                        : '${history.latest!.toStringAsFixed(1)} кг',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    history.entries.isNotEmpty
                        ? weightDate(history.entries.last.day)
                        : history.legacyWeight != null
                        ? 'Ранее сохранённый вес · дата неизвестна'
                        : 'Добавьте первое измерение',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => _edit(history),
              icon: const Icon(Icons.add),
              label: const Text('Записать вес'),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              children: [
                for (final option in {
                  30: '30 дней',
                  90: '90 дней',
                  0: 'Всё время',
                }.entries)
                  ChoiceChip(
                    label: Text(option.value),
                    selected: _period == option.key,
                    onSelected: (_) => setState(() => _period = option.key),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              change == null
                  ? 'Для динамики нужны два измерения'
                  : '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)} кг за период',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Точки — ваши измерения. Линия связывает записи; значения между ними не измерены.',
              style: TextStyle(color: muted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            if (visible.isNotEmpty) ...[
              Semantics(
                label:
                    'График веса. ${visible.map((e) => '${weightDate(e.day)}: ${e.kg.toStringAsFixed(1)} кг').join('; ')}',
                child: SizedBox(
                  height: 180,
                  child: CustomPaint(painter: _WeightChart(visible)),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(weightDate(visible.first.day)),
                  Text(weightDate(visible.last.day)),
                ],
              ),
            ] else
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'В этом периоде измерений нет.',
                  textAlign: TextAlign.center,
                ),
              ),
            if (history.recovered)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Часть данных повреждена. Исходная запись сохранена для восстановления.',
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              'Измерения',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            for (final entry in visible.reversed)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${entry.kg.toStringAsFixed(1)} кг'),
                subtitle: Text(weightDate(entry.day)),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => _edit(history, entry: entry),
              ),
          ],
        );
      },
    ),
  );
}

class _WeightChart extends CustomPainter {
  _WeightChart(this.entries);
  final List<WeightEntry> entries;
  @override
  void paint(Canvas canvas, Size size) {
    final minKg = entries.map((e) => e.kg).reduce(math.min) - 0.5;
    final maxKg = entries.map((e) => e.kg).reduce(math.max) + 0.5;
    double stamp(DateTime date) => DateTime.utc(
      date.year,
      date.month,
      date.day,
    ).millisecondsSinceEpoch.toDouble();
    final first = stamp(entries.first.day);
    final span = math.max(1.0, stamp(entries.last.day) - first);
    final width = math.max(0.0, size.width - 54);
    final height = size.height - 24;
    final path = Path();
    final points = <Offset>[];
    final guide = Paint()
      ..color = line
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = 12 + height * i / 2;
      canvas.drawLine(Offset(42, y), Offset(size.width - 12, y), guide);
      final text = TextPainter(
        text: TextSpan(
          text: (maxKg - (maxKg - minKg) * i / 2).toStringAsFixed(1),
          style: const TextStyle(
            color: muted,
            fontSize: 10,
            fontFamily: 'Manrope',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, Offset(0, y - 6));
    }
    for (var i = 0; i < entries.length; i++) {
      final p = Offset(
        42 +
            (entries.length == 1
                ? width / 2
                : width * (stamp(entries[i].day) - first) / span),
        12 + height * (maxKg - entries[i].kg) / (maxKg - minKg),
      );
      points.add(p);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = green
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
    for (final point in points) {
      canvas.drawCircle(point, 4, Paint()..color = greenDark);
    }
  }

  @override
  bool shouldRepaint(covariant _WeightChart oldDelegate) =>
      oldDelegate.entries != entries;
}
