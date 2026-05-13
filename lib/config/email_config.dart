/// Email configuration for the Golden Oaks Golf League app
class EmailConfig {
  /// Resend API key
  static const String sendGridApiKey = 're_Ha5ovv4P_LDuiouUtRhRof2nfbVaXkh85';

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
}
