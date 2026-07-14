import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/email_config.dart';

/// Sends emails via the Netlify serverless function (which holds the API key securely).
class BackendEmailService {
  static const String _netlifyFunctionUrl =
      'https://goldenoaks.golf/.netlify/functions/send-email';

  Future<bool> _send({
    required List<String> to,
    required String subject,
    required String body,
    String? htmlBody,
    List<String>? bcc,
    List<String>? recipients,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'subject': subject,
        'text': body,
      };
      if (recipients != null && recipients.isNotEmpty) {
        payload['recipients'] = recipients;
      } else {
        payload['to'] = to;
      }
      if (htmlBody != null && htmlBody.isNotEmpty) {
        payload['html'] = htmlBody;
      }
      if (bcc != null && bcc.isNotEmpty) {
        payload['bcc'] = bcc;
      }

      final response = await http.post(
        Uri.parse(_netlifyFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        debugPrint('Email sent successfully to ${to.length} recipients');
        return true;
      } else {
        debugPrint('Email function error ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error sending email: $e');
      return false;
    }
  }

  /// Sends Monday league results to administrators
  Future<bool> sendMondayResultsEmail({
    required String subject,
    required String body,
  }) async {
    final recipients = EmailConfig.adminEmails.toSet().toList();
    debugPrint('Sending Monday results email to ${recipients.length} recipients');
    return _send(to: recipients, subject: subject, body: body);
  }

  /// Sends Wednesday league results to administrators and players
  Future<bool> sendWednesdayResultsEmail({
    required String subject,
    required String body,
    List<String>? playerEmails,
  }) async {
    final recipients = <String>{
      ...EmailConfig.adminEmails,
    };

    if (playerEmails != null) {
      for (final email in playerEmails) {
        if (email.isNotEmpty && email.contains('@')) {
          recipients.add(email);
        } else {
          recipients.add(EmailConfig.fallbackEmail);
        }
      }
    }

    debugPrint('Sending Wednesday results email to ${recipients.length} recipients');
    return _send(to: recipients.toList(), subject: subject, body: body);
  }

  /// Sends a player list email to the ProShop and admins
  Future<bool> sendProShopEmail({
    required String subject,
    required String body,
    String? recipientEmail,
  }) async {
    final recipient = recipientEmail ?? EmailConfig.proShopEmail;
    final recipients = [recipient, ...EmailConfig.adminEmails];
    debugPrint('Sending ProShop email to: $recipients');
    return _send(to: recipients, subject: subject, body: body);
  }

  /// Sends a custom email to specified recipients
  Future<bool> sendCustomEmail({
    required List<String> to,
    required String subject,
    required String body,
    String? htmlBody,
    List<String>? bcc,
  }) async {
    if (to.isEmpty) {
      debugPrint('Error: No recipients specified');
      return false;
    }
    debugPrint('Sending custom email to ${to.length} recipients');
    return _send(to: to, subject: subject, body: body, htmlBody: htmlBody, bcc: bcc);
  }

  /// Sends one individual email per address using Resend's batch API.
  /// Each recipient sees only their own address in the To field.
  /// All emails are submitted in a single API call (no Netlify timeout risk).
  Future<bool> sendBatchEmail({
    required List<String> recipients,
    required String subject,
    required String body,
    String? htmlBody,
  }) async {
    if (recipients.isEmpty) {
      debugPrint('Error: No recipients specified');
      return false;
    }
    debugPrint('Sending batch email to ${recipients.length} recipients');
    return _send(to: [], subject: subject, body: body, htmlBody: htmlBody, recipients: recipients);
  }
}