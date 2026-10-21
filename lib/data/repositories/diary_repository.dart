import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/diary_item.dart';
import 'diary_preferences.dart';

/// Serializes read/modify/write operations from manual, catalogue and photo entry.
/// Entry IDs make a retried save replace its own record without losing others.
class DiaryRepository {
  DiaryRepository(this.preferences);

  final SharedPreferences preferences;
  static Future<void>? _pending;

  Future<List<DiaryItem>> update(
    String key,
    List<DiaryItem> Function(List<DiaryItem>) change,
  ) {
    late final Future<void> tail;
    final result = (_pending ?? Future<void>.value()).then((_) async {
      try {
        // SharedPreferences updates its cache even when the native write fails.
        await preferences.reload();
        final current = await DiaryPreferences(
          preferences,
        ).readRecords(key, DiaryItem.fromJson);
        final updated = change(current);
        try {
          final saved = await preferences.setString(
            key,
            jsonEncode(updated.map((entry) => entry.toJson()).toList()),
          );
          if (!saved) throw StateError('Could not save diary');
        } catch (_) {
          await preferences.reload();
          rethrow;
        }
        return updated;
      } finally {
        if (identical(_pending, tail)) _pending = null;
      }
    });
    // A failed operation must not poison later attempts in the queue.
    tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    _pending = tail;
    return result;
  }

  Future<List<DiaryItem>> upsert(String key, DiaryItem entry) =>
      update(key, (current) {
        final index = current.indexWhere((item) => item.id == entry.id);
        if (index < 0) return [...current, entry];
        return [...current]..[index] = entry;
      });
}
