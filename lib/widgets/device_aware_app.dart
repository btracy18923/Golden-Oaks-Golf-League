import 'package:flutter/material.dart';
import '../services/device_info_provider.dart';
import '../screens/main_menu_screen.dart';

/// Wrapper widget that determines device type once and provides it app-wide
class DeviceAwareApp extends StatelessWidget {
  const DeviceAwareApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get device info once when the app builds
    final deviceInfo = DeviceInfo.fromContext(context);
    
    // Print debug info to console
    print(deviceInfo.debugInfo);
    
    return DeviceInfoProvider(
      deviceInfo: deviceInfo,
      child: const UnifiedMainMenuScreen(),
    );
  }
}