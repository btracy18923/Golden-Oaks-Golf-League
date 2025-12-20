import 'package:flutter/material.dart';

/// Device type enumeration matching main_menu_screen logic
enum DeviceType {
  phone6Point5,    // 6.5" phones
  tablet10Inch,    // 10" tablets
}

/// Device size category for more granular control
enum DeviceSize {
  small,    // Phones
  large,    // 10" tablets
}

/// Unified device detection service that uses the EXACT same logic as main_menu_screen
/// and ResponsiveWrapper to ensure consistent device classification across all screens.
///
/// Uses shortest side breakpoints matching the existing implementation:
/// - 6.5" phone: shortestSide < 650dp
/// - 10" tablet: shortestSide >= 650dp
class DeviceDetectionService {
  
  // Static cache to avoid recalculating device type
  static DeviceType? _cachedDeviceType;
  static double? _cachedShortestSide;
  
  /// Initialize device detection cache - call this once in main.dart
  static void initialize(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    _cachedShortestSide = shortestSide;
    _cachedDeviceType = _calculateDeviceType(shortestSide);
    print(_getDebugInfo(context));
  }

  /// Get device type based on screen dimensions - EXACT logic from ResponsiveWrapper
  static DeviceType getDeviceType(BuildContext context) {
    if (_cachedDeviceType != null) {
      return _cachedDeviceType!;
    }
    // Fallback if not initialized
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return _calculateDeviceType(shortestSide);
  }
  
  /// Internal method to calculate device type from shortest side
  static DeviceType _calculateDeviceType(double shortestSide) {
    // Device breakpoints using shortest side (matches main menu screen logic)
    // All devices are in landscape mode
    // 6.5" phone: 412dp height (shortest side in landscape)
    // 10" tablet: Larger height due to lower density on same resolution
    final is6Point5Phone = shortestSide < 650;      // Phone range (includes former 8" tablets)
    final is10Tablet = shortestSide >= 650;         // 10" tablet range

    if (is6Point5Phone) {
      return DeviceType.phone6Point5;
    } else {
      return DeviceType.tablet10Inch;
    }
  }

  /// Get device size category
  static DeviceSize getDeviceSize(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.phone6Point5:
        return DeviceSize.small;
      case DeviceType.tablet10Inch:
        return DeviceSize.large;
    }
  }

  /// Check if device is a 6.5" phone - uses cached value for performance
  static bool is6Point5Phone(BuildContext context) {
    return getDeviceType(context) == DeviceType.phone6Point5;
  }

  /// Check if device is a 10" tablet - uses cached value for performance
  static bool is10Tablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet10Inch;
  }

  /// Check if device is any tablet
  static bool isTablet(BuildContext context) {
    return is10Tablet(context);
  }

  /// Legacy method names for backward compatibility
  static bool isPhone(BuildContext context) => is6Point5Phone(context);
  static bool is10InchTablet(BuildContext context) => is10Tablet(context);

  /// Get screen dimensions info
  static Map<String, dynamic> getScreenInfo(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    final shortestSide = size.shortestSide;
    final longestSide = size.longestSide;
    final deviceType = getDeviceType(context);
    
    return {
      'width': size.width,
      'height': size.height,
      'shortestSide': shortestSide,
      'longestSide': longestSide,
      'orientation': orientation,
      'isLandscape': orientation == Orientation.landscape,
      'isPortrait': orientation == Orientation.portrait,
      'deviceType': deviceType,
      'deviceSize': getDeviceSize(context),
      'deviceName': _getDeviceName(deviceType),
    };
  }

  /// Get human-readable device name
  static String getDeviceName(BuildContext context) {
    return _getDeviceName(getDeviceType(context));
  }

  /// Internal helper to get device name from type
  static String _getDeviceName(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.phone6Point5:
        return '6.5" Phone';
      case DeviceType.tablet10Inch:
        return '10" Tablet';
    }
  }

  /// Get debug info string - matches ResponsiveWrapper format
  static String getDebugInfo(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final size = MediaQuery.of(context).size;

    if (is6Point5Phone(context)) {
      return "DEBUG: Using 6.5\" Phone layout (${shortestSide}dp, ${size.width}x${size.height})";
    } else {
      return "DEBUG: Using 10\" Tablet layout (${shortestSide}dp, ${size.width}x${size.height})";
    }
  }

  /// Print debug info to console - matches ResponsiveWrapper behavior
  static void printDebugInfo(BuildContext context) {
    print(getDebugInfo(context));
  }
  
  /// Internal debug info method
  static String _getDebugInfo(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final size = MediaQuery.of(context).size;

    if (is6Point5Phone(context)) {
      return "DEBUG: Using 6.5\" Phone layout (${shortestSide}dp, ${size.width}x${size.height})";
    } else {
      return "DEBUG: Using 10\" Tablet layout (${shortestSide}dp, ${size.width}x${size.height})";
    }
  }

  /// Breakpoint constants for reference
  static const double phoneMaxWidth = 650.0;

  /// Legacy compatibility methods for existing code

  /// Check if device is large tablet (10") - legacy compatibility
  static bool isLargeTablet(BuildContext context) {
    return is10Tablet(context);
  }

  /// Get responsive font scale based on device type
  static double getFontScale(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.phone6Point5:
        return 0.8;  // Smaller fonts for phones
      case DeviceType.tablet10Inch:
        return 1.2;  // Larger fonts for tablets
    }
  }

  /// Get responsive spacing based on device type
  static double getSpacingScale(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.phone6Point5:
        return 0.75; // Tighter spacing for phones
      case DeviceType.tablet10Inch:
        return 1.5;  // More generous spacing for tablets
    }
  }
}