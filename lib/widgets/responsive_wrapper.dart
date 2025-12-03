import 'package:flutter/material.dart';

class ResponsiveWrapper extends StatelessWidget {
  final Widget phone;
  final Widget tablet8;
  final Widget tablet10;

  const ResponsiveWrapper({
    super.key,
    required this.phone,
    required this.tablet8,
    required this.tablet10,
  });

  @override
  Widget build(BuildContext context) {
    // Use exact device detection logic from main_menu_screen.dart
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    
    // Device breakpoints using shortest side (matches main menu screen logic)
    // All devices are in landscape mode
    // 6.5" phone: 412dp height (shortest side in landscape)
    // 8" tablet: ~533dp height (800×1280px with higher density)  
    // 10" tablet: Larger height due to lower density on same resolution
    final is6Point5Phone = shortestSide < 450;      // Phone range
    final is8Tablet = shortestSide >= 450 && shortestSide < 650;  // 8" tablet range (expanded)
    final is10Tablet = shortestSide >= 650;         // 10" tablet range
    
    if (is6Point5Phone) {
      print("DEBUG: Using 6.5\" Phone layout (${shortestSide}dp)");
      return phone;
    } else if (is8Tablet) {
      print("DEBUG: Using 8\" Tablet layout (${shortestSide}dp)");
      return tablet8;
    } else {
      print("DEBUG: Using 10\" Tablet layout (${shortestSide}dp)");
      return tablet10;
    }
  }
}