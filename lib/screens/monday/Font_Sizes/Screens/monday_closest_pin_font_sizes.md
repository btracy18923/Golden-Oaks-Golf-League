# Font Size Lines - monday_closest_pin_screen.dart

## Player Grid Items
- **154**: `ResponsiveTypography.getBodyText()` - Base fontSize for grid items
- **196**: `deviceType == DeviceType.phone6Point5 ? 14 : fontSize + 3` - Player lastName
- **220**: `deviceType == DeviceType.tablet10Inch ? fontSize + 2 : fontSize - 0` - Closest pin count
- **245**: `deviceType == DeviceType.tablet10Inch ? fontSize + 2 : fontSize` - Player winnings

## Custom Header
- **264**: `ResponsiveTypography.getHeading()` - Base headerFontSize
- **290**: `(headerFontSize - 2) * 0.75 * fontMultiplier` - Players count
- **301**: `(headerFontSize - 4) * 0.75 * fontMultiplier` - Closest Pin Purse label
- **316**: `(headerFontSize - 4) * 0.75 * fontMultiplier` - Closest Pin Purse value
- **334**: `(headerFontSize - 2) * 0.5 * fontMultiplier` - Remaining count
