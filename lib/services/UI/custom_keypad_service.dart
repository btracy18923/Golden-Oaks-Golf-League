import 'package:flutter/material.dart';
import 'enter_scores_UI_service.dart';

/// Callback function type for key presses
typedef KeyPressCallback = void Function(String key);

/// Service for creating a custom numeric keypad overlay
/// Features 0-9 digits, backspace (X), and enter (checkmark) keys
/// Designed to overlay the bottom button bar exactly
class CustomKeypadService {
  
  /// Creates a custom keypad widget that overlays the bottom button bar
  /// [context] - Build context for responsive design
  /// [onKeyPress] - Callback function called when a key is pressed
  /// [isVisible] - Whether the keypad should be visible
  static Widget buildCustomKeypad({
    required BuildContext context,
    required KeyPressCallback onKeyPress,
    required bool isVisible,
  }) {
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    final deviceType = EnterScoresUIService.getDeviceType(context);
    final padding = EnterScoresUIService.getResponsivePadding(deviceType);
    final fontSize = EnterScoresUIService.getResponsiveFontSize(deviceType, isHeader: true);
    
    // Calculate button height to match bottom button bar
    final buttonHeight = _getKeypadButtonHeight(deviceType, padding);
    
    return Container(
      color: Colors.grey[300], // Match bottom button bar color
      padding: EdgeInsets.all(padding.left / 2),
      height: buttonHeight + (padding.left), // Account for padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Digits 0-9
          ...List.generate(10, (index) => 
            _buildKeypadKey(
              context: context,
              text: index.toString(),
              fontSize: fontSize,
              onPressed: () => onKeyPress(index.toString()),
              deviceType: deviceType,
              padding: padding,
            )
          ),
          // Backspace key (X)
          _buildKeypadKey(
            context: context,
            text: 'X',
            fontSize: fontSize,
            onPressed: () => onKeyPress('backspace'),
            deviceType: deviceType,
            padding: padding,
            backgroundColor: Colors.red[200],
          ),
          // Enter key (checkmark)
          _buildKeypadKey(
            context: context,
            icon: Icons.check,
            fontSize: fontSize,
            onPressed: () => onKeyPress('enter'),
            deviceType: deviceType,
            padding: padding,
            backgroundColor: Colors.green[200],
          ),
        ],
      ),
    );
  }
  
  /// Builds an individual keypad key
  static Widget _buildKeypadKey({
    required BuildContext context,
    String? text,
    IconData? icon,
    required double fontSize,
    required VoidCallback onPressed,
    required DeviceType deviceType,
    required EdgeInsets padding,
    Color? backgroundColor,
  }) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: padding.left / 4),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? Colors.blue[100],
            padding: EdgeInsets.symmetric(vertical: padding.top / 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
              side: const BorderSide(color: Colors.black, width: 1),
            ),
          ),
          child: icon != null 
            ? Icon(
                icon,
                size: fontSize * 1.2,
                color: Colors.black,
              )
            : Text(
                text ?? '',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
        ),
      ),
    );
  }
  
  /// Gets the appropriate button height to match the bottom button bar
  static double _getKeypadButtonHeight(DeviceType deviceType, EdgeInsets padding) {
    // Calculate height based on device type and padding to match bottom buttons
    switch (deviceType) {
      case DeviceType.phone6_5:
        return 40.0; // Compact for phone
      case DeviceType.tablet8:
        return 48.0; // Standard for 8" tablet
      case DeviceType.tablet10:
        return 56.0; // Larger for 10" tablet
    }
  }
  
  /// Creates a keypad controller for managing keypad state
  static CustomKeypadController createController() {
    return CustomKeypadController();
  }
}

/// Controller class for managing custom keypad state and input handling
class CustomKeypadController {
  bool _isVisible = false;
  String _currentInput = '';
  
  /// Whether the keypad is currently visible
  bool get isVisible => _isVisible;
  
  /// Current input string
  String get currentInput => _currentInput;
  
  /// Shows the keypad
  void show() {
    _isVisible = true;
  }
  
  /// Hides the keypad
  void hide() {
    _isVisible = false;
  }
  
  /// Toggles keypad visibility
  void toggle() {
    _isVisible = !_isVisible;
  }
  
  /// Clears the current input
  void clear() {
    _currentInput = '';
  }
  
  /// Handles key press events
  /// Returns the updated input value or null for special keys
  String? handleKeyPress(String key) {
    switch (key) {
      case 'backspace':
        if (_currentInput.isNotEmpty) {
          _currentInput = _currentInput.substring(0, _currentInput.length - 1);
        }
        return _currentInput;
      case 'enter':
        // Don't modify input, just signal completion
        return null;
      default:
        // Add digit to input (limit to reasonable length)
        if (_currentInput.length < 3) { // Limit to 3 digits for SKATS
          _currentInput += key;
        }
        return _currentInput;
    }
  }
  
  /// Sets the current input value
  void setInput(String value) {
    _currentInput = value;
  }
}