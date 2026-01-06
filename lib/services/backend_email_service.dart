import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/email_config.dart';

/// Backend email service using Firebase Extension (Trigger Email from Firestore)
///
/// This service sends emails by writing documents to the Firestore 'mail' collection.
/// The Firebase Extension automatically processes these documents and sends emails via SendGrid.
class BackendEmailService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sends Wednesday league results to ProShop, players, and administrators
  ///
  /// Parameters:
  /// - [subject]: Email subject line
  /// - [body]: Email body content (plain text)
  /// - [playerEmails]: List of player email addresses (optional)
  ///
  /// Returns:
  /// - true if email documents were successfully created in Firestore
  /// - false if there was an error
  Future<bool> sendWednesdayResultsEmail({
    required String subject,
    required String body,
    List<String>? playerEmails,
  }) async {
    try {
      // Build recipient list
      Set<String> recipients = {};

      // Add ProShop
      recipients.add(EmailConfig.proShopEmail);

      // Add administrators
      recipients.addAll(EmailConfig.adminEmails);

      // Add players (with fallback to default email if no player email provided)
      if (playerEmails != null && playerEmails.isNotEmpty) {
        for (String email in playerEmails) {
          if (email.isNotEmpty && email.contains('@')) {
            recipients.add(email);
          } else {
            // If player doesn't have valid email, use fallback
            recipients.add(EmailConfig.fallbackEmail);
          }
        }
      }

      // Remove duplicates and create final list
      final recipientList = recipients.toList();

      debugPrint('Sending Wednesday results email to ${recipientList.length} recipients');

      // Create email document in Firestore
      // Firebase Extension will automatically process this and send the email
      await _firestore.collection('mail').add({
        'to': recipientList,
        'from': EmailConfig.senderEmail,
        'message': {
          'subject': subject,
          'text': body,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'wednesday_results',
      });

      debugPrint('Email document created successfully');
      return true;
    } catch (e) {
      debugPrint('Error creating email document: $e');
      return false;
    }
  }

  /// Sends ProShop player list email
  ///
  /// Parameters:
  /// - [subject]: Email subject line
  /// - [body]: Email body content (plain text)
  /// - [recipientEmail]: Optional recipient email (defaults to ProShop email)
  ///
  /// Returns:
  /// - true if email document was successfully created in Firestore
  /// - false if there was an error
  Future<bool> sendProShopEmail({
    required String subject,
    required String body,
    String? recipientEmail,
  }) async {
    try {
      final recipient = recipientEmail ?? EmailConfig.proShopEmail;

      debugPrint('Sending ProShop email to: $recipient');

      // Create email document in Firestore
      await _firestore.collection('mail').add({
        'to': [recipient],
        'from': EmailConfig.senderEmail,
        'message': {
          'subject': subject,
          'text': body,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'proshop_players',
      });

      debugPrint('ProShop email document created successfully');
      return true;
    } catch (e) {
      debugPrint('Error creating ProShop email document: $e');
      return false;
    }
  }

  /// Sends a custom email to specified recipients
  ///
  /// Parameters:
  /// - [to]: List of recipient email addresses
  /// - [subject]: Email subject line
  /// - [body]: Email body content (plain text)
  /// - [htmlBody]: Optional HTML body content
  ///
  /// Returns:
  /// - true if email document was successfully created in Firestore
  /// - false if there was an error
  Future<bool> sendCustomEmail({
    required List<String> to,
    required String subject,
    required String body,
    String? htmlBody,
  }) async {
    try {
      if (to.isEmpty) {
        debugPrint('Error: No recipients specified');
        return false;
      }

      debugPrint('Sending custom email to ${to.length} recipients');

      // Build message
      Map<String, dynamic> message = {
        'subject': subject,
        'text': body,
      };

      // Add HTML body if provided
      if (htmlBody != null && htmlBody.isNotEmpty) {
        message['html'] = htmlBody;
      }

      // Create email document in Firestore
      await _firestore.collection('mail').add({
        'to': to,
        'from': EmailConfig.senderEmail,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'custom',
      });

      debugPrint('Custom email document created successfully');
      return true;
    } catch (e) {
      debugPrint('Error creating custom email document: $e');
      return false;
    }
  }

  /// Checks the delivery status of an email by document ID
  ///
  /// Parameters:
  /// - [documentId]: The Firestore document ID of the email
  ///
  /// Returns:
  /// - Map containing delivery status information, or null if not found
  Future<Map<String, dynamic>?> getEmailDeliveryStatus(String documentId) async {
    try {
      final doc = await _firestore.collection('mail').doc(documentId).get();
      if (!doc.exists) {
        return null;
      }

      final data = doc.data();
      return {
        'delivered': data?['delivery']?['state'] == 'SUCCESS',
        'state': data?['delivery']?['state'],
        'error': data?['delivery']?['error'],
        'info': data?['delivery']?['info'],
      };
    } catch (e) {
      debugPrint('Error checking email delivery status: $e');
      return null;
    }
  }
}
