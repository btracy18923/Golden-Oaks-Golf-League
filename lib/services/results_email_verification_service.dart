import 'package:flutter/foundation.dart';
import '../models/league.dart';
import 'backend_email_service.dart';
import 'error_log_service.dart';
import 'firebase_upload_service.dart';
import 'pending_email_service.dart';
import 'upload_queue_service.dart';

/// Coordinates sending the weekly results email so it only goes out once a
/// real Firestore read-back has confirmed the player profile upload (SK# /
/// HC) actually landed — instead of trusting the upload call's return
/// value, which reports "success" both when the write truly succeeded and
/// when it was merely queued for later (offline), and can't detect a
/// connectivity blip that silently drops the write while "online".
///
/// If verification can't even be attempted (no real connectivity), the
/// email is held and retried later via ConnectivityService's reconnect
/// handler — the same mechanism already used for offline email queuing.
class ResultsEmailVerificationService {
  static final ResultsEmailVerificationService _instance = ResultsEmailVerificationService._internal();
  factory ResultsEmailVerificationService() => _instance;
  ResultsEmailVerificationService._internal();

  final FirebaseUploadService _uploadService = FirebaseUploadService();
  final PendingEmailService _pendingEmailService = PendingEmailService();
  final BackendEmailService _emailService = BackendEmailService();
  final UploadQueueService _uploadQueueService = UploadQueueService();

  /// Attempts to verify the profile upload and send the results email now.
  /// [verifyManifest] is a list of {'name': lastName, 'expected': value}
  /// describing what should now be in Firebase for each player who played.
  Future<void> verifyAndSendOrQueue({
    required League league,
    required String subject,
    required String body,
    required List<Map<String, dynamic>> verifyManifest,
  }) async {
    final leagueName = league == League.monday ? 'Monday' : 'Wednesday';

    // If the profile upload that would make Firebase correct is still
    // sitting in the offline queue (e.g. flaky course connectivity let this
    // verify call itself go through moments before the queued upload had a
    // chance to retry), don't bother comparing against Firebase yet — we
    // already know it's stale. Hold the email so it gets a real comparison
    // once the queue actually clears via ConnectivityService's reconnect
    // handler, instead of sending a "MISMATCH" report that's already
    // obsolete by the time it's read.
    final uploadStillQueued = await _uploadQueueService.hasPendingUploadFor(league, UploadType.players);
    if (uploadStillQueued) {
      debugPrint('$leagueName results email deferred — profile upload still queued, not yet landed in Firebase');
      await _savePending(league, subject, body, verifyManifest);
      return;
    }

    try {
      final result = await _uploadService.verifyPlayerProfileSync(league, verifyManifest);
      final fullBody = body + _buildVerifyFooter(result);

      final success = await _sendEmail(league, subject, fullBody);

      if (success) {
        await _clearPending(league);
      } else {
        // Verify succeeded but the email backend itself failed — queue the
        // already-finalized body (empty manifest) so retry just resends it
        // without re-running the Firestore check.
        await _savePending(league, subject, fullBody, const []);
      }

      if (result['ok'] != true) {
        await ErrorLogService().logError(
          '$leagueName Results Email Verify',
          'Mismatch after upload: ${(result['mismatches'] as List).join('; ')}',
        );
      }
    } catch (e) {
      // Couldn't even complete the verify — most likely no real internet
      // despite the device showing as connected to WiFi. Hold the email
      // entirely rather than send it without having confirmed anything.
      await ErrorLogService().logError('$leagueName Results Email Verify', e);
      await _savePending(league, subject, body, verifyManifest);
    }
  }

  /// Retries a queued email. Called by ConnectivityService when WiFi
  /// reconnects, after any queued Firebase uploads have already been
  /// retried, so the verify below has a real chance of finding the upload
  /// landed this time.
  Future<void> retryPending(League league) async {
    final pending = league == League.monday
        ? await _pendingEmailService.getPendingMondayEmail()
        : await _pendingEmailService.getPendingWednesdayEmail();
    if (pending == null) return;

    final subject = pending['subject'] as String;
    final body = pending['body'] as String;
    final manifest = pending['verify'] as List<Map<String, dynamic>>;

    if (manifest.isEmpty) {
      // Already verified before being queued (only the email send itself
      // failed last time) — just resend as-is, no need to re-verify.
      final success = await _sendEmail(league, subject, body);
      if (success) await _clearPending(league);
      return;
    }

    await verifyAndSendOrQueue(league: league, subject: subject, body: body, verifyManifest: manifest);
  }

  Future<bool> _sendEmail(League league, String subject, String body) {
    return league == League.monday
        ? _emailService.sendMondayResultsEmail(subject: subject, body: body)
        : _emailService.sendWednesdayResultsEmail(subject: subject, body: body);
  }

  Future<void> _savePending(
    League league,
    String subject,
    String body,
    List<Map<String, dynamic>> manifest,
  ) {
    return league == League.monday
        ? _pendingEmailService.savePendingMondayEmail(subject: subject, body: body, verifyManifest: manifest)
        : _pendingEmailService.savePendingWednesdayEmail(subject: subject, body: body, verifyManifest: manifest);
  }

  Future<void> _clearPending(League league) {
    return league == League.monday
        ? _pendingEmailService.clearPendingMondayEmail()
        : _pendingEmailService.clearPendingWednesdayEmail();
  }

  String _buildVerifyFooter(Map<String, dynamic> result) {
    final buffer = StringBuffer();
    buffer.writeln();
    buffer.writeln('-' * 40);
    if (result['ok'] == true) {
      buffer.writeln('Firebase Verify: OK - all player profile updates confirmed in Firebase.');
    } else {
      buffer.writeln('Firebase Verify: MISMATCH - the following did not match Firebase and may need manual correction:');
      for (final m in (result['mismatches'] as List)) {
        buffer.writeln('  - $m');
      }
    }
    return buffer.toString();
  }
}