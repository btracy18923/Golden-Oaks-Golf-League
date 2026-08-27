import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists errors to the device locally so they can be reviewed later from
/// the Admin screen, without needing a tethered `adb logcat` / `flutter logs`
/// session running at the exact moment of failure (not practical for tablets
/// running untethered on the course).
class ErrorLogService {
  static final ErrorLogService _instance = ErrorLogService._internal();
  factory ErrorLogService() => _instance;
  ErrorLogService._internal();

  static const String _key = 'persistent_error_log';
  static const int _maxEntries = 50;

  /// Records an error entry. Never throws — logging must not be able to
  /// break the caller it's reporting on.
  Future<void> logError(String context, Object error) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entries = await getErrors();
      entries.insert(0, {
        'timestamp': DateTime.now().toIso8601String(),
        'context': context,
        'error': error.toString(),
      });
      if (entries.length > _maxEntries) {
        entries.removeRange(_maxEntries, entries.length);
      }
      await prefs.setString(_key, jsonEncode(entries));
    } catch (_) {
      // Swallow - logging failures must never mask or block the real error.
    }
  }

  /// Returns log entries newest-first.
  Future<List<Map<String, dynamic>>> getErrors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearErrors() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}