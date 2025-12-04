import 'package:flutter/material.dart';
import 'device_detection_service.dart';

/// Device information that gets calculated once and shared app-wide
class DeviceInfo {
  final DeviceType deviceType;
  final bool isPhone;
  final bool is8Tablet;
  final bool is10Tablet;
  final bool isTablet;
  final double shortestSide;
  final Size screenSize;
  final String deviceName;

  const DeviceInfo({
    required this.deviceType,
    required this.isPhone,
    required this.is8Tablet,
    required this.is10Tablet,
    required this.isTablet,
    required this.shortestSide,
    required this.screenSize,
    required this.deviceName,
  });

  /// Create DeviceInfo from BuildContext - called once in main.dart
  factory DeviceInfo.fromContext(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortestSide = size.shortestSide;
    final deviceType = DeviceDetectionService.getDeviceType(context);
    
    return DeviceInfo(
      deviceType: deviceType,
      isPhone: DeviceDetectionService.is6Point5Phone(context),
      is8Tablet: DeviceDetectionService.is8Tablet(context),
      is10Tablet: DeviceDetectionService.is10Tablet(context),
      isTablet: DeviceDetectionService.isTablet(context),
      shortestSide: shortestSide,
      screenSize: size,
      deviceName: DeviceDetectionService.getDeviceName(context),
    );
  }

  /// Get debug info string
  String get debugInfo {
    return "DEBUG: Using $deviceName layout (${shortestSide}dp, ${screenSize.width}x${screenSize.height})";
  }

  @override
  String toString() => debugInfo;
}

/// InheritedWidget to provide DeviceInfo throughout the app
class DeviceInfoProvider extends InheritedWidget {
  final DeviceInfo deviceInfo;

  const DeviceInfoProvider({
    super.key,
    required this.deviceInfo,
    required super.child,
  });

  /// Get DeviceInfo from anywhere in the widget tree
  static DeviceInfo of(BuildContext context) {
    final DeviceInfoProvider? result = context.dependOnInheritedWidgetOfExactType<DeviceInfoProvider>();
    assert(result != null, 'No DeviceInfoProvider found in context');
    return result!.deviceInfo;
  }

  /// Check if DeviceInfo is available in context
  static DeviceInfo? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DeviceInfoProvider>()?.deviceInfo;
  }

  @override
  bool updateShouldNotify(DeviceInfoProvider oldWidget) {
    return deviceInfo != oldWidget.deviceInfo;
  }
}

/// Convenient static access methods using DeviceInfoProvider
class DeviceFlags {
  /// Check if current device is a 6.5" phone
  static bool isPhone(BuildContext context) {
    return DeviceInfoProvider.of(context).isPhone;
  }

  /// Check if current device is an 8" tablet
  static bool is8Tablet(BuildContext context) {
    return DeviceInfoProvider.of(context).is8Tablet;
  }

  /// Check if current device is a 10" tablet
  static bool is10Tablet(BuildContext context) {
    return DeviceInfoProvider.of(context).is10Tablet;
  }

  /// Check if current device is any tablet
  static bool isTablet(BuildContext context) {
    return DeviceInfoProvider.of(context).isTablet;
  }

  /// Get device type
  static DeviceType getDeviceType(BuildContext context) {
    return DeviceInfoProvider.of(context).deviceType;
  }

  /// Get device name
  static String getDeviceName(BuildContext context) {
    return DeviceInfoProvider.of(context).deviceName;
  }

  /// Get screen size
  static Size getScreenSize(BuildContext context) {
    return DeviceInfoProvider.of(context).screenSize;
  }

  /// Get debug info
  static String getDebugInfo(BuildContext context) {
    return DeviceInfoProvider.of(context).debugInfo;
  }

  /// Print debug info to console
  static void printDebugInfo(BuildContext context) {
    print(getDebugInfo(context));
  }
}