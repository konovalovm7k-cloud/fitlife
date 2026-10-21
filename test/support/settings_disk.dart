import 'dart:async';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class SettingsDisk extends InMemorySharedPreferencesStore {
  SettingsDisk() : super.empty();
  final failedKeys = <String>{};
  final writes = <String>[];
  String? throwKey;
  String? blockedKey;
  Completer<void>? gate;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    final name = key.replaceFirst('flutter.', '');
    writes.add(name);
    if (name == blockedKey) await gate!.future;
    if (name == throwKey) throw StateError('Simulated disk failure');
    if (failedKeys.contains(name)) return false;
    return super.setValue(valueType, key, value);
  }
}
