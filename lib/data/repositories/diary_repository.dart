import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/diary_item.dart';
import 'diary_preferences.dart';
import 'preferences_queue.dart';
import '../../core/models/diary_date.dart';

String diaryDateKey(DateTime date) => DiaryDate.key(date);

/// Serializes read/modify/write operations from manual, catalogue and photo entry.
/// Entry IDs make a retried save replace its own record without losing others.
String newDiaryEntryId() {
  final random = Random.secure();
  return List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

class DiaryRepository {
  DiaryRepository(SharedPreferences preferences)
    : _load = (() async => preferences);
  DiaryRepository.withLoader({
    Future<SharedPreferences> Function()? preferencesLoader,
  }) : _load = preferencesLoader ?? SharedPreferences.getInstance;
  final Future<SharedPreferences> Function() _load;

  Future<T> run<T>(Future<T> Function(DiaryPreferences) operation) async {
    final preferences = await _load();
    return PreferencesQueue.run(
      preferences,
      () => operation(DiaryPreferences(preferences)),
    );
  }

  Future<List<DiaryItem>> update(
    String key,
    List<DiaryItem> Function(List<DiaryItem>) change,
  ) => run((store) async {
    final preferences = store.preferences;
    final current = await store.readRecords(key, DiaryItem.fromJson);
    final updated = change(current);
    for (final entry in updated) {
      DiaryItem.fromJson(entry.toJson());
    }
    await PreferencesQueue.checked(
      preferences.setString(
        key,
        jsonEncode(updated.map((entry) => entry.toJson()).toList()),
      ),
    );
    return List.unmodifiable(updated);
  });

  Future<List<DiaryItem>> updateDay(
    DateTime day,
    List<DiaryItem> Function(List<DiaryItem>) change,
  ) => update('diary_${DiaryDate.key(day)}', change);

  Future<List<DiaryItem>> upsert(String key, DiaryItem entry) =>
      update(key, (current) {
        final index = current.indexWhere((item) => item.id == entry.id);
        if (index < 0) return [...current, entry];
        return [...current]..[index] = entry;
      });

  Future<List<DiaryItem>> upsertDay(DateTime day, DiaryItem entry) =>
      upsert('diary_${DiaryDate.key(day)}', entry);
}
