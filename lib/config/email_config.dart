/// Email configuration for the Golden Oaks Golf League app
class EmailConfig {
  /// ProShop email address
  static const String proShopEmail = 'PROSHOP@HIDEOUTGOLFCLUB.COM';
  //// "grohol@aol.com" - also change phone # '9083775851' in line 1453 in wednesday_enter_scores_screen

  /// Administrator email addresses
  static const List<String> adminEmails = [
    'btracy18923@gmail.com', // TODO: Replace with actual admin email
    'grohol@aol.com', // TODO: Replace with actual admin email
    'ajfederico5@yahoo.com', // TODO: Replace with actual admin email
  ];

  /// Default fallback email (used when player has no email)
  static const String fallbackEmail = 'btracy18923@gmail.com';

  /// Sender email (custom domain)
  static const String senderEmail = 'noreply@goldenoaks.golf';

  /// Sender name
  static const String senderName = 'Golden Oaks Golf League';
}
