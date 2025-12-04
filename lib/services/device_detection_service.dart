import 'package:flutter/material.dart';

/// Device type enumeration matching main_menu_screen logic
enum DeviceType {
  phone6Point5,    // 6.5" phones
  tablet8Inch,     // 8" tablets  
  tablet10Inch,    // 10" tablets
}

/// Device size category for more granular control
enum DeviceSize {
  small,    // Phones
  medium,   // 8" tablets
  large,    // 10" tablets
}

/// Unified device detection service that uses the EXACT same logic as main_menu_screen
/// and ResponsiveWrapper to ensure consistent device classification across all screens.
/// 
/// Uses shortest side breakpoints matching the existing implementation:
/// - 6.5" phone: shortestSide < 450dp  
/// - 8" tablet: 450dp <= shortestSide < 650dp
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
    // 8" tablet: ~533dp height (800×1280px with higher density)  
    // 10" tablet: Larger height due to lower density on same resolution
    final is6Point5Phone = shortestSide < 450;      // Phone range
    final is8Tablet = shortestSide >= 450 && shortestSide < 650;  // 8" tablet range (expanded)
    final is10Tablet = shortestSide >= 650;         // 10" tablet range
    
    if (is6Point5Phone) {
      return DeviceType.phone6Point5;
    } else if (is8Tablet) {
      return DeviceType.tablet8Inch;
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
      case DeviceType.tablet8Inch:
        return DeviceSize.medium;
      case DeviceType.tablet10Inch:
        return DeviceSize.large;
    }
  }

  /// Check if device is a 6.5" phone - uses cached value for performance
  static bool is6Point5Phone(BuildContext context) {
    return getDeviceType(context) == DeviceType.phone6Point5;
  }

  /// Check if device is an 8" tablet - uses cached value for performance
  static bool is8Tablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet8Inch;
  }

  /// Check if device is a 10" tablet - uses cached value for performance
  static bool is10Tablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet10Inch;
  }

  /// Check if device is any tablet (8" or 10")
  static bool isTablet(BuildContext context) {
    return is8Tablet(context) || is10Tablet(context);
  }

  /// Legacy method names for backward compatibility
  static bool isPhone(BuildContext context) => is6Point5Phone(context);
  static bool is8InchTablet(BuildContext context) => is8Tablet(context);
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
      case DeviceType.tablet8Inch:
        return '8" Tablet';
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
    } else if (is8Tablet(context)) {
      return "DEBUG: Using 8\" Tablet layout (${shortestSide}dp, ${size.width}x${size.height})";
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
    } else if (is8Tablet(context)) {
      return "DEBUG: Using 8\" Tablet layout (${shortestSide}dp, ${size.width}x${size.height})";
    } else {
      return "DEBUG: Using 10\" Tablet layout (${shortestSide}dp, ${size.width}x${size.height})";
    }
  }

  /// Breakpoint constants for reference
  static const double phoneMaxWidth = 450.0;
  static const double tablet8InchMaxWidth = 650.0;
  
  /// Legacy compatibility methods for existing code
  
  /// Check if device is medium tablet (8") - legacy compatibility
  static bool isMediumTablet(BuildContext context) {
    return is8Tablet(context);
  }

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
      case DeviceType.tablet8Inch:
        return 1.0;  // Base font size
      case DeviceType.tablet10Inch:
        return 1.2;  // Larger fonts for bigger tablets
    }
  }

  /// Get responsive spacing based on device type
  static double getSpacingScale(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.phone6Point5:
        return 0.75; // Tighter spacing for phones
      case DeviceType.tablet8Inch:
        return 1.0;  // Base spacing
      case DeviceType.tablet10Inch:
        return 1.5;  // More generous spacing for larger screens
    }
  }
}