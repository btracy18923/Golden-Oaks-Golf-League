import 'package:flutter/material.dart';
import '../services/device_detection_service.dart';

class ResponsiveWrapper extends StatelessWidget {
  final Widget phone;
  final Widget tablet10;

  const ResponsiveWrapper({
    super.key,
    required this.phone,
    required this.tablet10,
  });

  @override
  Widget build(BuildContext context) {
    // Use unified device detection service for consistent, cached results
    if (DeviceDetectionService.is6Point5Phone(context)) {
      return phone;
    } else {
      return tablet10;
    }
  }
}