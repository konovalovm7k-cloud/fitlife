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
      if (raw is String && !preferences.containsKey('recovery_$key')) {
        await preferences.setString('recovery_$key', raw);
      }
    }
    return records;
  }

  double number(String key, double fallback, {bool allowZero = false}) {
    final value = preferences.get(key);
    if (value is! num || !value.isFinite) return fallback;
    if (allowZero ? value < 0 : value <= 0) return fallback;
    return value.toDouble();
  }
}
