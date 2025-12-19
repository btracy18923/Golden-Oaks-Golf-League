import 'package:flutter/material.dart';
import '../device_detection_service.dart';
import '../responsive_typography.dart';

/// Standardized button bar UI service for consistent button bars across all screens
/// Provides uniform container height, button height, padding, and styling
class ButtonBarUIService {

  /// Standard button bar configuration
  static const double _phoneContainerHeight = 55.0;
  static const double _tabletContainerHeight = 70.0;
  static const EdgeInsets _phoneContainerPadding = EdgeInsets.symmetric(horizontal: 2, vertical: 5);
  static const EdgeInsets _tabletContainerPadding = EdgeInsets.symmetric(horizontal: 5, vertical: 5);
  static const EdgeInsets _phoneButtonPadding = EdgeInsets.symmetric(horizontal: 3);
  static const EdgeInsets _tabletButtonPadding = EdgeInsets.symmetric(horizontal: 10);
  static const EdgeInsets _phoneButtonInternalPadding = EdgeInsets.symmetric(vertical: 4, horizontal: 4);
  static const EdgeInsets _tabletButtonInternalPadding = EdgeInsets.symmetric(vertical: 8, horizontal: 4);
  static const double _phoneButtonRadius = 6.0;
  static const double _tabletButtonRadius = 10.0;

  /// Gets the standard container height based on device type
  static double getContainerHeight(BuildContext context) {
    final isPhone = DeviceDetectionService.isPhone(context);
    return isPhone ? _phoneContainerHeight : _tabletContainerHeight;
  }

  /// Gets the standard container padding based on device type
  static EdgeInsets getContainerPadding(BuildContext context) {
    final isPhone = DeviceDetectionService.isPhone(context);
    return isPhone ? _phoneContainerPadding : _tabletContainerPadding;
  }

  /// Gets the standard button outer padding (between buttons) based on device type
  static EdgeInsets getButtonPadding(BuildContext context) {
    final isPhone = DeviceDetectionService.isPhone(context);
    return isPhone ? _phoneButtonPadding : _tabletButtonPadding;
  }

  /// Gets the standard button internal padding based on device type
  static EdgeInsets getButtonInternalPadding(BuildContext context) {
    final isPhone = DeviceDetectionService.isPhone(context);
    return isPhone ? _phoneButtonInternalPadding : _tabletButtonInternalPadding;
  }

  /// Gets the standard button border radius based on device type
  static double getButtonRadius(BuildContext context) {
    final isPhone = DeviceDetectionService.isPhone(context);
    return isPhone ? _phoneButtonRadius : _tabletButtonRadius;
  }

  /// Builds a standardized button bar container with consistent styling
  ///
  /// [backgroundColor] - Background color of the button bar container
  /// [children] - List of button widgets to display in the bar
  /// [mainAxisAlignment] - How to align buttons horizontally (default: spaceEvenly)
  /// [useMinHeight] - If true, uses minHeight constraint instead of fixed height (default: false)
  static Widget buildButtonBar(
    BuildContext context, {
    required Color backgroundColor,
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.spaceEvenly,
    bool useMinHeight = false,
  }) {
    final containerHeight = getContainerHeight(context);
    final containerPadding = getContainerPadding(context);

    return Container(
      constraints: useMinHeight
        ? BoxConstraints(minHeight: containerHeight)
        : null,
      height: useMinHeight ? null : containerHeight,
      color: backgroundColor,
      padding: containerPadding,
      child: Row(
        mainAxisAlignment: mainAxisAlignment,
        children: children,
      ),
    );
  }

  /// Builds a standardized action button with consistent styling
  ///
  /// [text] - Button text
  /// [color] - Button background color
  /// [onPressed] - Callback when button is pressed (null disables the button)
  /// [maxLines] - Maximum lines for button text (default: 1)
  static Widget buildActionButton(
    BuildContext context, {
    required String text,
    required Color color,
    required VoidCallback? onPressed,
    int maxLines = 1,
  }) {
    final buttonPadding = getButtonPadding(context);
    final buttonInternalPadding = getButtonInternalPadding(context);
    final buttonRadius = getButtonRadius(context);
    final buttonFontSize = ResponsiveTypography.getButton(context);

    return Expanded(
      child: Padding(
        padding: buttonPadding,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: onPressed != null ? Colors.black : Colors.grey[600],
            padding: buttonInternalPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonRadius),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return FittedBox(
                fit: BoxFit.scaleDown,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth,
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: buttonFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: maxLines,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Builds a spacer widget to maintain button positioning in button bars
  /// Use this when you want to show fewer buttons but maintain their positions
  static Widget buildSpacer() {
    return Expanded(child: SizedBox());
  }
}
