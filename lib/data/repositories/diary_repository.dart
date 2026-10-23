import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/diary_item.dart';
import 'diary_preferences.dart';

String diaryDateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String newDiaryEntryId() {
  final random = Random.secure();
  return List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

/// All active-app writes share one queue, including separate AI/client instances.
/// This coordinates this isolate, not independent processes or devices.
class DiaryRepository {
  DiaryRepository({Future<SharedPreferences> Function()? preferencesLoader})
    : _load = preferencesLoader ?? SharedPreferences.getInstance;
  final Future<SharedPreferences> Function() _load;
  static Future<void>? _tail;

  Future<T> run<T>(Future<T> Function(DiaryPreferences) action) {
    Future<T> execute() async {
      final preferences = await _load();
      await preferences.reload();
      try {
        return await action(DiaryPreferences(preferences));
      } catch (_) {
        // SharedPreferences updates its cache even when the native write fails.
        try {
          await preferences.reload();
        } catch (_) {
          /* Preserve original error. */
        }
        rethrow;
      }
    }

    final previous = _tail;
    final result = previous == null
        ? execute()
        : previous.then((_) => execute());
    late final Future<void> tail;
    void release() {
      if (identical(_tail, tail)) _tail = null;
    }

    tail = result.then<void>(
      (_) => release(),
      onError: (Object _, StackTrace __) => release(),
    );
    _tail = tail;
    return result;
  }

  Future<List<DiaryItem>> updateDay(
    DateTime day,
    List<DiaryItem> Function(List<DiaryItem>) update,
  ) => run((store) async {
    final key = 'diary_${diaryDateKey(day)}';
    final current = await store.readRecords(key, DiaryItem.fromJson);
    final updated = update(current);
    // Validate before replacing a persisted day, including caller-built records.
    for (final item in updated) {
      DiaryItem.fromJson(item.toJson());
    }
    await store.writeString(
      key,
      jsonEncode(updated.map((item) => item.toJson()).toList()),
    );
    return List.unmodifiable(updated);
  });

  Future<List<DiaryItem>> upsert(DateTime day, DiaryItem entry) => updateDay(
    day,
    (current) => [...current.where((item) => item.id != entry.id), entry],
  );
}
