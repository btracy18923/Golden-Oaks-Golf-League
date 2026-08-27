import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists pending email sends to SharedPreferences so they survive app restarts
/// and can be retried by ConnectivityService when connectivity is restored.
///
/// Alongside subject/body, a "verify manifest" can be stored — a list of
/// {name, expected} pairs describing what a Firebase read-back check should
/// confirm before the email actually goes out (see
/// ResultsEmailVerificationService). An empty manifest means the body was
/// already fully finalized (verify already ran) and just needs resending.
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
    List<Map<String, dynamic>> verifyManifest = const [],
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _pendingMondayEmailKey,
      jsonEncode({'subject': subject, 'body': body, 'verify': verifyManifest}),
    );
  }

  Future<Map<String, dynamic>?> getPendingMondayEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingMondayEmailKey);
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return {
      'subject': map['subject'] as String,
      'body': map['body'] as String,
      'verify': List<Map<String, dynamic>>.from(
        (map['verify'] as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)),
      ),
    };
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
    List<Map<String, dynamic>> verifyManifest = const [],
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _pendingWednesdayEmailKey,
      jsonEncode({'subject': subject, 'body': body, 'verify': verifyManifest}),
    );
  }

  Future<Map<String, dynamic>?> getPendingWednesdayEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingWednesdayEmailKey);
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return {
      'subject': map['subject'] as String,
      'body': map['body'] as String,
      'verify': List<Map<String, dynamic>>.from(
        (map['verify'] as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)),
      ),
    };
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
