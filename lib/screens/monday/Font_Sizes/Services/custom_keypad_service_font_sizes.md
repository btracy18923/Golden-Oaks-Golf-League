# Font Sizes - custom_keypad_service.dart

## Keypad (buildCustomKeypad)
- 27: fontSize = EnterScoresUIService.getResponsiveFontSize(deviceType, isHeader: true)
- 44: fontSize: fontSize * 2 (digit keys 0-9)
- 54: fontSize: fontSize * 2 (backspace key)
- 64: fontSize: fontSize * 2 (enter key)

## Keypad Key (_buildKeypadKey)
- 102: size: fontSize * 1.2 (icon)
- 108: fontSize: fontSize (text)
