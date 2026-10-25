import 'dart:convert';
import '../../data/repositories/diary_preferences.dart';
import '../../data/repositories/diary_repository.dart';

const weightHistoryKey = 'weight_history_v1';

class WeightEntry {
  const WeightEntry(this.day, this.kg);
  final DateTime day;
  final double kg;
  Map<String, dynamic> toJson() => {'date': diaryDateKey(day), 'kg': kg};
  factory WeightEntry.fromJson(Map<String, dynamic> json) {
    final text = json['date'] as String;
    final date = DateTime.parse(text);
    final kg = (json['kg'] as num).toDouble();
    if (diaryDateKey(date) != text ||
        date.year < 2020 ||
        !kg.isFinite ||
        kg < 30 ||
        kg > 300) {
      throw const FormatException('Invalid weight record');
    }
    return WeightEntry(date, kg);
  }
}

class WeightHistory {
  WeightHistory(this.entries, {this.legacyWeight, this.recovered = false});
  final List<WeightEntry> entries;
  final double? legacyWeight;
  final bool recovered;
  double? get latest => entries.isEmpty ? legacyWeight : entries.last.kg;

  static Future<WeightHistory> read(DiaryPreferences store) async {
    final hadHistory = store.preferences.containsKey(weightHistoryKey);
    final records = await store.readRecords(
      weightHistoryKey,
      WeightEntry.fromJson,
    );
    final unique = <String, WeightEntry>{
      for (final item in records) diaryDateKey(item.day): item,
    };
    final sorted = unique.values.toList()
      ..sort((a, b) => a.day.compareTo(b.day));
    final old = store.preferences.get('weight');
    final legacy =
        !hadHistory && old is num && old.isFinite && old >= 30 && old <= 300
        ? old.toDouble()
        : null;
    return WeightHistory(
      List.unmodifiable(sorted),
      legacyWeight: legacy,
      recovered: store.recoveredData,
    );
  }
}

class WeightRepository {
  WeightRepository(this.diary);
  final DiaryRepository diary;
  Future<WeightHistory> load() => diary.run(WeightHistory.read);
  Future<WeightHistory> save(WeightEntry entry) => diary.run((store) async {
    WeightEntry.fromJson(entry.toJson());
    final today = DateTime.now();
    if (entry.day.isAfter(DateTime(today.year, today.month, today.day))) {
      throw const FormatException('Future measurement');
    }
    final current = await WeightHistory.read(store);
    final updated = [
      ...current.entries.where(
        (e) => diaryDateKey(e.day) != diaryDateKey(entry.day),
      ),
      entry,
    ]..sort((a, b) => a.day.compareTo(b.day));
    await store.writeString(
      weightHistoryKey,
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
    return WeightHistory(
      List.unmodifiable(updated),
      recovered: current.recovered,
    );
  });
  Future<WeightHistory> delete(DateTime date) => diary.run((store) async {
    final current = await WeightHistory.read(store);
    final updated = current.entries
        .where((e) => diaryDateKey(e.day) != diaryDateKey(date))
        .toList();
    await store.writeString(
      weightHistoryKey,
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
    return WeightHistory(
      List.unmodifiable(updated),
      recovered: current.recovered,
    );
  });
}
