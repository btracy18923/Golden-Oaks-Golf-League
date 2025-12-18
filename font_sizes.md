In the monday_results_screen.dart, there are multiple lines controlling font sizes throughout the file. Here are the key ones:

Main content font sizes:
- Line 646: final double fontSize = is6InchPhone ? 12 : 24; (for parent screen data - Players Ante, Closest Pin, Mulligan)
- Line 721: final double fontSize = is6InchPhone ? 12 : 24; (for Total Players and Collect row)
- Line 774: final double fontSize = is6InchPhone ? 12 : 24; (for Golf Course row)
- Line 885: final double fontSize = is6InchPhone ? 14 : 24; (for Skat Value and SKAT Winners)
- Line 985: final double fontSize = is6InchPhone ? 12 : (is8InchTablet ? 11 : 22); (for table cells - main data table)

Header font sizes in Closest Pin Winners table:
- Line 1053: fontSize: is6InchPhone ? 12 : 24 (for "Closest Pin Winners" header)
- Line 1063: fontSize: is6InchPhone ? 12 : 24 (for "Pins Won" header)
- Line 1074: fontSize: is6InchPhone ? 12 : 24 (for "$$$" header)

Closest Pin Winners data rows:
- Line 1093: style: TextStyle(fontSize: is6InchPhone ? 11 : 24) (for winner names)
- Line 1102: style: TextStyle(fontSize: is6InchPhone ? 11 : 24) (for pins count)
- Line 1113: fontSize: is6InchPhone ? 11 : 24 (for winnings amount)

AppBar titles (device-specific layouts):
- Line 311: fontSize: 18 (Phone layout)
- Line 372: fontSize: 20 (8" tablet layout)
- Line 433: fontSize: 24 (10" tablet layout)

Button font sizes:
- Line 302: const double buttonFontSize = 12; (Phone layout)
- Line 363: const double buttonFontSize = 13; (8" tablet layout)
- Line 424: const double buttonFontSize = 24; (10" tablet layout)
