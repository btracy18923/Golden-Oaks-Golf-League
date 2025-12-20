# Font Sizes - player_selection_screen.dart

## ResponsiveConfig - Font Size Getters

### headerFontSize (77-86)
- 80: return 14 (phone)
- 82: return 15 (8" tablet)
- 84: return 16 (10" tablet)

### emptyStateFontSize (122-131)
- 125: return 12 (phone)
- 127: return 15 (8" tablet)
- 129: return 18 (10" tablet)

### buttonFontSize (154-163)
- 157: return 14 (phone)
- 159: return 15 (8" tablet)
- 161: return 16 (10" tablet)

### footerButtonFontSize (214-223)
- 217: return isLandscape ? 10 : 12 (phone)
- 219: return 13 (8" tablet)
- 221: return 14 (10" tablet)

### checkboxFontSize (293-302)
- 296: return isLandscape ? 12 : 14 (phone)
- 298: return 16 (8" tablet)
- 300: return 18 (10" tablet)

### playerNameFontSize (315-324)
- 318: return isLandscape ? 10 : 12 (phone)
- 320: return 13 (8" tablet)
- 322: return 14 (10" tablet)

## Usage in UI Components

### Header
- 388: fontSize: config.headerFontSize

### Empty State
- 411: fontSize: config.emptyStateFontSize

### Check All Button
- 451: fontSize: config.buttonFontSize

### Footer Buttons
- 506: fontSize: config.footerButtonFontSize (Return - compact)
- 536: fontSize: 12 (Check All - compact, hardcoded)
- 566: fontSize: 12 (Enter Scores - compact, hardcoded)
- 595: fontSize: config.footerButtonFontSize (Return - standard)
- 619: fontSize: config.footerButtonFontSize (Enter Scores - standard)

### Player Items
- 708: fontSize: config.checkboxFontSize (checkbox X)
- 721: fontSize: config.playerNameFontSize (player name)
