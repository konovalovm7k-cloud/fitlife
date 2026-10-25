import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/diary_item.dart';
import '../../data/repositories/diary_preferences.dart';
import '../../data/repositories/preferences_queue.dart';

String summaryDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';

class SummaryDay {
  const SummaryDay({
    required this.date,
    required this.entries,
    this.water,
    this.damaged = false,
  });
  final DateTime date;
  final List<DiaryItem> entries;
  final double? water;
  final bool damaged;
  bool get hasFood => entries.isNotEmpty && !damaged;
  double get calories => entries.fold(0, (sum, entry) => sum + entry.kcal);
  double get protein => entries.fold(0, (sum, entry) => sum + entry.protein);
  double get fat => entries.fold(0, (sum, entry) => sum + entry.fat);
  double get carbs => entries.fold(0, (sum, entry) => sum + entry.carbs);
  double get fiber => entries.fold(0, (sum, entry) => sum + entry.fiber);
  bool get hasFiberGaps => entries.any((e) => !e.food.hasKnownFiber);
}

class WeeklySummary {
  const WeeklySummary(this.days);
  final List<SummaryDay> days;
  bool get hasFiberGaps => days.any((day) => day.hasFiberGaps);
  List<SummaryDay> get logged => days.where((day) => day.hasFood).toList();
  double? average(double Function(SummaryDay) value) {
    final values = logged;
    return values.isEmpty
        ? null
        : values.fold(0.0, (sum, day) => sum + value(day)) / values.length;
  }

  static Future<WeeklySummary> load(
    DateTime end, {
    Future<SharedPreferences> Function()? preferencesLoader,
  }) => (() async {
    final preferences =
        await (preferencesLoader ?? SharedPreferences.getInstance)();
    return PreferencesQueue.run(preferences, () async {
      final result = <SummaryDay>[];
      for (var offset = 6; offset >= 0; offset--) {
        // Calendar arithmetic preserves local dates across daylight-saving changes.
        final date = DateTime(end.year, end.month, end.day - offset);
        final key =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final store = DiaryPreferences(preferences);
        final entries = await store.readRecords(
          'diary_$key',
          DiaryItem.fromJson,
        );
        final water = preferences.get('water_$key');
        result.add(
          SummaryDay(
            date: date,
            entries: List.unmodifiable(entries),
            damaged: store.recoveredData,
            water: water is num && water.isFinite && water >= 0
                ? water.toDouble()
                : null,
          ),
        );
      }
      return WeeklySummary(List.unmodifiable(result));
    });
  })().timeout(const Duration(seconds: 15));

  String report() {
    final text = StringBuffer(
      'FitLife: ${summaryDate(days.first.date)}–${summaryDate(days.last.date)}.${days.last.date.year}\n',
    );
    text.writeln('Дней с записями о еде: ${logged.length} из ${days.length}.');
    if (hasFiberGaps) {
      text.writeln(
        'Клетчатка: сумма неполная, не во всех продуктах есть данные.',
      );
    }
    final kcal = average((day) => day.calories);
    if (kcal != null) {
      text.writeln(
        'Среднее по внесённым продуктам: ${kcal.round()} ккал; '
        'Б ${average((day) => day.protein)!.round()}, Ж ${average((day) => day.fat)!.round()}, '
        'У ${average((day) => day.carbs)!.round()}, клетчатка ${average((day) => day.fiber)!.round()} г.',
      );
    }
    for (final day in days) {
      final food = day.damaged
          ? 'данные неполные'
          : day.hasFood
          ? '${day.calories.round()} ккал'
          : 'нет записей о еде';
      text.writeln(
        '${summaryDate(day.date)}: $food${day.water == null ? '' : '; вода ${day.water!.toStringAsFixed(2)} л'}.',
      );
    }
    text.writeln(
      'Это внесённые записи, не оценка полного рациона. AI-оценки приблизительные. '
      'Дни без записей и повреждённые дни не включены в среднее.',
    );
    return text.toString();
  }
}
