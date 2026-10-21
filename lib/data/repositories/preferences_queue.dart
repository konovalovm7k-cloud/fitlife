import 'package:shared_preferences/shared_preferences.dart';

/// One queue for the cached preferences instance used by all app repositories.
/// This orders operations within the app isolate, not across other processes.
class PreferencesQueue {
  static Future<void>? _pending;

  static Future<T> run<T>(
    SharedPreferences preferences,
    Future<T> Function() operation,
  ) {
    late final Future<void> tail;
    final result = (_pending ?? Future<void>.value()).then((_) async {
      try {
        await preferences.reload();
        return await operation();
      } catch (_) {
        // Native write failures can leave an optimistic value in the cache.
        await preferences.reload();
        rethrow;
      } finally {
        if (identical(_pending, tail)) _pending = null;
      }
    });
    tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    _pending = tail;
    return result;
  }

  static Future<void> checked(Future<bool> write) async {
    if (!await write) throw StateError('Could not save local data');
  }
}
