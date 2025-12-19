import 'package:flutter/material.dart';

/// Responsive typography system that provides device-specific font sizes
/// based on screen dimensions using the same breakpoints as ResponsiveWrapper
class ResponsiveTypography {
  
  /// Get device type based on shortest side (matches ResponsiveWrapper logic)
  static String _getDeviceType(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    
    if (shortestSide < 450) {
      return 'phone';       // 6.5" phone
    } else if (shortestSide < 650) {
      return 'tablet8';     // 8" tablet  
    } else {
      return 'tablet10';    // 10" tablet
    }
  }

  /// Main body text size (for general content)
  static double getBodyText(BuildContext context) {
    switch (_getDeviceType(context)) {
      case 'phone':
        return 12;  //Choose Course
      case 'tablet8':
        return 18;
      case 'tablet10':
        return 20;
      default:
        return 22;
    }
  }

  /// Label text size (for field labels like "Players Ante")
  static double getLabel(BuildContext context) {
    switch (_getDeviceType(context)) {
      case 'phone':
        return 14;
      case 'tablet8':
        return 24;
      case 'tablet10':
        return 30;
      default:
        return 21;
    }
  }

  /// Heading text size (for screen titles, section headers)
  static double getHeading(BuildContext context) {
    switch (_getDeviceType(context)) {
      case 'phone':
        return 14;
      case 'tablet8':
        return 20;
      case 'tablet10':
        return 30;
      default:
        return 22;
    }
  }

  /// Large display text size (for amounts, scores, important values)
  static double getDisplay(BuildContext context) {
    switch (_getDeviceType(context)) {
      case 'phone':
        return 14;
      case 'tablet8':
        return 24;
      case 'tablet10':
        return 30;
      default:
        return 24;
    }
  }

  /// Small text size (for table data, hints, helper text, secondary info)
  static double getSmall(BuildContext context) {
    switch (_getDeviceType(context)) {
      case 'phone':
        return 14;  //Select Course
      case 'tablet8':
        return 22;
      case 'tablet10':
        return 26;
      default:
        return 20;
    }
  }

  /// Button text size (for button labels)
  static double getButton(BuildContext context) {
    switch (_getDeviceType(context)) {
      case 'phone':
        return 14;  //Buttons
      case 'tablet10':
        return 30;
      default:
        return 18;
    }
  }

  /// Table header text size (for column headers in data tables)
  static double getTableHeader(BuildContext context) {
    switch (_getDeviceType(context)) {
      case 'phone':
        return 14;
      case 'tablet8':
        return 16;
      case 'tablet10':
        return 22;
      default:
        return 9;
    }
  }

  /// AppBar title text size
  static double getAppBarTitle(BuildContext context) {
    switch (_getDeviceType(context)) {
      case 'phone':
        return 18;
      case 'tablet8':
        return 24;
      case 'tablet10':
        return 28;
      default:
        return 24;
    }
  }

  /// Helper method to get TextStyle with responsive font size
  static TextStyle getTextStyle(BuildContext context, {
    required double Function(BuildContext) fontSize,
    FontWeight? fontWeight,
    Color? color,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontSize: fontSize(context),
      fontWeight: fontWeight,
      color: color,
      decoration: decoration,
    );
  }

  /// Convenience methods for common text styles
  static TextStyle bodyTextStyle(BuildContext context, {FontWeight? fontWeight, Color? color}) {
    return getTextStyle(context, fontSize: getBodyText, fontWeight: fontWeight, color: color);
  }

  static TextStyle labelStyle(BuildContext context, {FontWeight? fontWeight, Color? color}) {
    return getTextStyle(context, fontSize: getLabel, fontWeight: fontWeight, color: color);
  }

  static TextStyle headingStyle(BuildContext context, {FontWeight? fontWeight, Color? color}) {
    return getTextStyle(context, fontSize: getHeading, fontWeight: fontWeight, color: color);
  }

  static TextStyle displayStyle(BuildContext context, {FontWeight? fontWeight, Color? color}) {
    return getTextStyle(context, fontSize: getDisplay, fontWeight: fontWeight, color: color);
  }

  static TextStyle smallStyle(BuildContext context, {FontWeight? fontWeight, Color? color}) {
    return getTextStyle(context, fontSize: getSmall, fontWeight: fontWeight, color: color);
  }

  static TextStyle buttonStyle(BuildContext context, {FontWeight? fontWeight, Color? color}) {
    return getTextStyle(context, fontSize: getButton, fontWeight: fontWeight, color: color);
  }

  static TextStyle tableHeaderStyle(BuildContext context, {FontWeight? fontWeight, Color? color}) {
    return getTextStyle(context, fontSize: getTableHeader, fontWeight: fontWeight, color: color);
  }

  static TextStyle appBarTitleStyle(BuildContext context, {FontWeight? fontWeight, Color? color}) {
    return getTextStyle(context, fontSize: getAppBarTitle, fontWeight: fontWeight, color: color);
  }
}