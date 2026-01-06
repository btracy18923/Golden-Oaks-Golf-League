/// Email configuration for the Golden Oaks Golf League app
class EmailConfig {
  /// ProShop email address
  static const String proShopEmail = 'btracy18923@gmail.com';

  /// Administrator email addresses
  static const List<String> adminEmails = [
    'btracy18923@gmail.com', // TODO: Replace with actual admin email
    'btracy18923@gmail.com', // TODO: Replace with actual admin email
    'btracy18923@gmail.com', // TODO: Replace with actual admin email
  ];

  /// Default fallback email (used when player has no email)
  static const String fallbackEmail = 'btracy18923@gmail.com';

  /// Sender email (must match SendGrid verified sender)
  static const String senderEmail = 'noreply@sandboxb6fd959adeab4f16a46fed32bd290dc6.mailgun.org';

  /// Sender name
  static const String senderName = 'Golden Oaks Golf League';
}
