import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Single source of truth for FitLife local persistence.
/// UI code should not need to know SharedPreferences keys or JSON details.
class FitLifeStorage {
  const FitLifeStorage();

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<String?> readString(String key) async => (await _prefs).getString(key);

  Future<bool?> readBool(String key) async => (await _prefs).getBool(key);

  Future<double?> readDouble(String key) async => (await _prefs).getDouble(key);

  Future<int?> readInt(String key) async => (await _prefs).getInt(key);

  Future<void> writeBool(String key, bool value) async =>
      (await _prefs).setBool(key, value);

  Future<void> writeDouble(String key, double value) async =>
      (await _prefs).setDouble(key, value);

  Future<void> writeInt(String key, int value) async =>
      (await _prefs).setInt(key, value);

  Future<void> writeString(String key, String value) async =>
      (await _prefs).setString(key, value);

  Future<List<Map<String, dynamic>>> readList(String key) async {
    final raw = await readString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> writeList(String key, List<Map<String, dynamic>> value) =>
      writeString(key, jsonEncode(value));
}
