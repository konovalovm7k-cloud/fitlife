import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Reads existing diary keys without letting one damaged record block startup.
class DiaryPreferences {
  DiaryPreferences(this.preferences);

  final SharedPreferences preferences;
  bool recoveredData = false;

  Future<List<T>> readRecords<T>(
    String key,
    T Function(Map<String, dynamic>) decode,
  ) async {
    final raw = preferences.get(key);
    if (raw == null) return [];
    final records = <T>[];
    var damaged = false;
    try {
      final value = jsonDecode(raw as String);
      if (value is! List) throw const FormatException('Expected a record list');
      for (final item in value) {
        try {
          records.add(decode(Map<String, dynamic>.from(item as Map)));
        } catch (_) {
          damaged = true;
        }
      }
    } catch (_) {
      damaged = true;
    }
    if (damaged) {
      recoveredData = true;
      // Retain the original data before a later save replaces the damaged list.
      await _preserve(key, raw);
    }
    return records;
  }

  double number(String key, double fallback, {bool allowZero = false}) {
    final value = preferences.get(key);
    if (value is! num || !value.isFinite) return fallback;
    if (allowZero ? value < 0 : value <= 0) return fallback;
    return value.toDouble();
  }

  Future<List<String>> readStringList(String key) async {
    final value = preferences.get(key);
    if (value == null) return [];
    if (value is List && value.every((item) => item is String)) {
      return value.cast<String>().toList();
    }
    recoveredData = true;
    await _preserve(key, value);
    return value is List ? value.whereType<String>().toList() : [];
  }

  Future<void> _preserve(String key, Object raw) async {
    Object? recoverable(Object? value) {
      if (value is num && !value.isFinite) {
        return {'invalidNumber': value.toString()};
      }
      if (value is List) return value.map(recoverable).toList();
      if (value is Map) {
        return value.map(
          (key, item) => MapEntry(key.toString(), recoverable(item)),
        );
      }
      return value;
    }

    final encoded = raw is String ? raw : jsonEncode(recoverable(raw));
    final base = 'recovery_$key';
    var backup = base;
    var index = 1;
    while (preferences.containsKey(backup)) {
      if (preferences.get(backup) == encoded) return;
      backup = '${base}_${index++}';
    }
    try {
      final saved = await preferences.setString(backup, encoded);
      if (!saved) throw StateError('Could not preserve damaged $key');
    } catch (_) {
      // Drop the optimistic cache entry so retry actually writes the backup.
      await preferences.reload();
      rethrow;
    }
  }

  Future<void> preserveValue(String key, Object raw) async {
    recoveredData = true;
    await _preserve(key, raw);
  }
}
