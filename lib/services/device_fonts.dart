/// Device-specific font sizes for known devices
/// No context required, no rebuilds, const-friendly
class DeviceFonts {
  // Device types
  static const String phone6_5 = 'phone6_5';
  static const String tablet8 = 'tablet8';
  static const String tablet10 = 'tablet10';
  
  // Font sizes by device and purpose
  static const Map<String, Map<String, double>> _fontSizes = {
    phone6_5: {
      'appBarTitle': 18.0,
      'heading': 16.0,
      'button': 14.0,
      'label': 12.0,
      'body': 12.0,
      'small': 10.0,
    },
    tablet8: {
      'appBarTitle': 20.0,
      'heading': 20.0,
      'button': 24.0,
      'label': 24.0,
      'body': 20.0,
      'small': 12.0,
    },
    tablet10: {
      'appBarTitle': 24.0,
      'heading': 30.0,
      'button': 30.0,
      'label': 30.0,
      'body': 20.0,
      'small': 14.0,
    },
  };
  
  /// Get device type based on shortest side (matches ResponsiveWrapper logic)
  static String getDeviceType(double shortestSide) {
    if (shortestSide < 450) {
      return phone6_5;
    } else if (shortestSide < 650) {
      return tablet8;
    } else {
      return tablet10;
    }
  }
  
  /// Get font size for device and purpose
  static double getSize(String deviceType, String purpose) {
    return _fontSizes[deviceType]?[purpose] ?? 14.0;
  }
  
  // Convenience methods that can be used with const TextStyle
  static double appBarTitle(String deviceType) => getSize(deviceType, 'appBarTitle');
  static double heading(String deviceType) => getSize(deviceType, 'heading');
  static double button(String deviceType) => getSize(deviceType, 'button');
  static double label(String deviceType) => getSize(deviceType, 'label');
  static double body(String deviceType) => getSize(deviceType, 'body');
  static double small(String deviceType) => getSize(deviceType, 'small');
}

/// Pre-computed TextStyles for each device (const-friendly)
class DeviceTextStyles {
  // Phone 6.5" styles
  static const phone6_5AppBar = TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
  static const phone6_5Heading = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
  static const phone6_5Button = TextStyle(fontSize: 14, fontWeight: FontWeight.bold);
  static const phone6_5Label = TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
  static const phone6_5Body = TextStyle(fontSize: 12, fontWeight: FontWeight.normal);
  static const phone6_5Small = TextStyle(fontSize: 10, fontWeight: FontWeight.normal);
  
  // Tablet 8" styles
  static const tablet8AppBar = TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
  static const tablet8Heading = TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
  static const tablet8Button = TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
  static const tablet8Label = TextStyle(fontSize: 24, fontWeight: FontWeight.w600);
  static const tablet8Body = TextStyle(fontSize: 20, fontWeight: FontWeight.normal);
  static const tablet8Small = TextStyle(fontSize: 12, fontWeight: FontWeight.normal);
  
  // Tablet 10" styles
  static const tablet10AppBar = TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
  static const tablet10Heading = TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  static const tablet10Button = TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  static const tablet10Label = TextStyle(fontSize: 30, fontWeight: FontWeight.w600);
  static const tablet10Body = TextStyle(fontSize: 20, fontWeight: FontWeight.normal);
  static const tablet10Small = TextStyle(fontSize: 14, fontWeight: FontWeight.normal);
}