# Font Size Lines - monday_enter_scores_screen.dart

## No Direct Font Size Controls

This screen delegates all UI rendering to service classes:
- `EnterScoresUIService.buildPurseHeader()`
- `EnterScoresUIService.buildGroupsGrid()`
- `ButtonBarUIService.buildButtonBar()`
- `ButtonBarUIService.buildActionButton()`
- `CustomKeypadService.buildCustomKeypad()`

All font sizes are controlled within these service classes, not in the screen file itself.

**Font size locations:**
- Purse header fonts → `enter_scores_UI_service.dart`
- Groups grid fonts → `enter_scores_UI_service.dart`
- Button fonts → `button_bar_UI_service.dart`
- Keypad fonts → `custom_keypad_service.dart`
