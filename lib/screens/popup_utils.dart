import 'package:flutter/material.dart';

/// Unified popup utilities for consistent messaging across all screens
class PopupUtils {
  // Color schemes for different popup types
  static const Map<String, Color> colors = {
    'info': Color(0xFFCCE5FF),      // Light blue
    'success': Color(0xFFCCFFCC),   // Light green
    'warning': Color(0xFFFFE680),   // Light gold/yellow
    'error': Color(0xFFFFCCCC),     // Light red
    'confirm': Color(0xFFE5E5E5),   // Light gray
  };

  /// Show an information dialog
  static Future<void> showInfo(BuildContext context, String title, String message) {
    return _showDialog(context, title, message, 'info');
  }

  /// Show a success dialog
  static Future<void> showSuccess(BuildContext context, String title, String message) {
    // Unfocus any active text fields before showing dialog
    FocusScope.of(context).unfocus();
    return _showDialog(context, title, message, 'success');
  }

  /// Show a warning dialog
  static Future<void> showWarning(BuildContext context, String title, String message) {
    return _showDialog(context, title, message, 'warning');
  }

  /// Show an error dialog
  static Future<void> showError(BuildContext context, String title, String message) {
    return _showDialog(context, title, message, 'error');
  }

  /// Show a confirmation dialog with Yes/No buttons
  static Future<bool?> showConfirm(
    BuildContext context, 
    String title, 
    String message,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colors['confirm'],
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFFCCCC), // Light red
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('No', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFCCFFCC), // Light green
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('Yes', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  /// Internal method to create and show dialog
  static Future<void> _showDialog(
    BuildContext context,
    String title,
    String message,
    String type,
  ) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colors[type] ?? colors['info'],
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Ensure keyboard stays hidden after dialog closes
                FocusScope.of(context).unfocus();
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFE5E5E5), // Light gray
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}

/// Quick popup class for one-liner messages (similar to the Python QuickPopup)
class QuickPopup {
  /// Show a quick info message
  static void info(BuildContext context, String message) {
    PopupUtils.showInfo(context, 'Information', message);
  }

  /// Show a quick success message
  static void success(BuildContext context, String message) {
    PopupUtils.showSuccess(context, 'Success', message);
  }

  /// Show a quick warning message
  static void warning(BuildContext context, String message) {
    PopupUtils.showWarning(context, 'Warning', message);
  }

  /// Show a quick error message
  static void error(BuildContext context, String message) {
    PopupUtils.showError(context, 'Error', message);
  }

  /// Show a quick confirmation dialog
  static Future<bool?> confirm(BuildContext context, String message) {
    return PopupUtils.showConfirm(context, 'Confirm', message);
  }
}