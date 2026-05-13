import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists pending email sends to SharedPreferences so they survive app restarts
/// and can be retried by ConnectivityService when WiFi reconnects.
class PendingEmailService {
  static final PendingEmailService _instance = PendingEmailService._internal();
  factory PendingEmailService() => _instance;
  PendingEmailService._internal();

  static const String _pendingMondayEmailKey = 'pending_monday_results_email';
  static const String _pendingWednesdayEmailKey = 'pending_wednesday_results_email';

  // ── Monday ──────────────────────────────────────────────────────────────────

  Future<void> savePendingMondayEmail({
    required String subject,
    required String body,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _pendingMondayEmailKey,
      jsonEncode({'subject': subject, 'body': body}),
    );
  }

  Future<Map<String, String>?> getPendingMondayEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingMondayEmailKey);
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return {'subject': map['subject'] as String, 'body': map['body'] as String};
  }

  Future<void> clearPendingMondayEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingMondayEmailKey);
  }

  Future<bool> hasPendingMondayEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_pendingMondayEmailKey);
  }

  // ── Wednesday ────────────────────────────────────────────────────────────────

  Future<void> savePendingWednesdayEmail({
    required String subject,
    required String body,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _pendingWednesdayEmailKey,
      jsonEncode({'subject': subject, 'body': body}),
    );
  }

  Future<Map<String, String>?> getPendingWednesdayEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingWednesdayEmailKey);
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return {'subject': map['subject'] as String, 'body': map['body'] as String};
  }

  Future<void> clearPendingWednesdayEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingWednesdayEmailKey);
  }

  Future<bool> hasPendingWednesdayEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_pendingWednesdayEmailKey);
  }
}