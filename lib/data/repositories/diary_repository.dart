import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/diary_item.dart';
import 'diary_preferences.dart';
import 'preferences_queue.dart';

/// Serializes read/modify/write operations from manual, catalogue and photo entry.
/// Entry IDs make a retried save replace its own record without losing others.
class DiaryRepository {
  DiaryRepository(this.preferences);

  final SharedPreferences preferences;

  Future<List<DiaryItem>> update(
    String key,
    List<DiaryItem> Function(List<DiaryItem>) change,
  ) => PreferencesQueue.run(preferences, () async {
    final current = await DiaryPreferences(
      preferences,
    ).readRecords(key, DiaryItem.fromJson);
    final updated = change(current);
    await PreferencesQueue.checked(
      preferences.setString(
        key,
        jsonEncode(updated.map((entry) => entry.toJson()).toList()),
      ),
    );
    return updated;
  });

  Future<List<DiaryItem>> upsert(String key, DiaryItem entry) =>
      update(key, (current) {
        final index = current.indexWhere((item) => item.id == entry.id);
        if (index < 0) return [...current, entry];
        return [...current]..[index] = entry;
      });
}
