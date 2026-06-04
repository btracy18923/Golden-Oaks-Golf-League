import 'package:shared_preferences/shared_preferences.dart';

/// Email configuration for the Golden Oaks Golf League app
class EmailConfig {
  /// Resend API key
  static const String sendGridApiKey = '';

  /// ProShop email address
  static const String proShopEmail = 'pro.shop@thehideout.us';
  //// "grohol@aol.com" - also change phone # '9083775851' in line 1453 in wednesday_enter_scores_screen

  /// Administrator email addresses
  static const List<String> adminEmails = [
    'btracy18923@gmail.com',
    'grohol@aol.com',
    'ajfederico5@yahoo.com',
  ];

  /// Default fallback email (used when player has no email)
  static const String fallbackEmail = 'btracy18923@gmail.com';

  /// Sender email (custom domain)
  static const String senderEmail = 'noreply@goldenoaks.golf';

  /// Sender name
  static const String senderName = 'Golden Oaks Golf League';

  /// When true, ALL emails are sent only to [fallbackEmail] for testing.
  /// Toggle from the Wednesday Admin screen. Set to false before going live.
  static bool testEmailMode = false;

  static Future<void> loadTestEmailModeState() async {
    final prefs = await SharedPreferences.getInstance();
    testEmailMode = prefs.getBool('test_email_mode') ?? false;
  }

  static Future<void> saveTestEmailModeState(bool value) async {
    testEmailMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('test_email_mode', value);
  }
}