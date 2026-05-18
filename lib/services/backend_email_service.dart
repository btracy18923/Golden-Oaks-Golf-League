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
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'to': to,
        'subject': subject,
        'text': body,
      };
      if (htmlBody != null && htmlBody.isNotEmpty) {
        payload['html'] = htmlBody;
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

  /// Sends Wednesday league results to ProShop, administrators, and players
  Future<bool> sendWednesdayResultsEmail({
    required String subject,
    required String body,
    List<String>? playerEmails,
  }) async {
    final recipients = <String>{
      EmailConfig.proShopEmail,
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
  }) async {
    if (to.isEmpty) {
      debugPrint('Error: No recipients specified');
      return false;
    }
    debugPrint('Sending custom email to ${to.length} recipients');
    return _send(to: to, subject: subject, body: body, htmlBody: htmlBody);
  }
}