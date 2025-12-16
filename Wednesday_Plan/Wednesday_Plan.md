# Wednesday League Modernization Plan

## Objective
Modernize the Wednesday League screens to match Monday League's architecture, incorporating:
- DeviceDetectionService for consistent device classification
- ResponsiveTypography for adaptive font sizing
- UI Services for extracted, reusable UI components
- Landscape orientation locking (matching Monday pattern)
- Editable settings fields (Ante, Closest Pin, Mulligans) like Monday

## User Preferences (Confirmed)
- **Parent Screen**: Make fields editable like Monday (with keypad)
- **Orientation**: Lock to landscape mode (match Monday)
- **Enter Scores Refactor**: Full refactor to match Monday patterns

## Current State Analysis

### Monday League (Complete)
- **9 screens** with consistent architecture
- Uses `DeviceDetectionService` for device detection
- Uses `ResponsiveTypography` for adaptive fonts
- UI extracted into services (`lib/services/UI/`)
- Landscape-locked orientation
- Editable settings (ante, closest pin, mulligans)
- Green color scheme

### Wednesday League (Needs Modernization)
- **9 screens** with older patterns
- Minimal `DeviceDetectionService` usage
- Hardcoded font sizes
- UI logic embedded in screens
- No orientation locking
- Static settings display (not editable)
- Orange color scheme
- More complex business logic (group processing, 40%/60% split)

## Modernization Phases

### Phase 1: Core Infrastructure Updates
Update foundational Wednesday screens to use existing shared services.

**Files to modify:**

#### 1. `lib/screens/wednesday/wednesday_parent_screen.dart`
**Major refactor to match Monday's pattern:**
- Import `DeviceDetectionService` and `ResponsiveTypography`
- Add landscape orientation locking via `SystemChrome.setPreferredOrientations`
- Use `ParentScreenUI` service widget (adapt for Wednesday orange color scheme)
- Add editable fields for:
  - Players Ante (with keypad editing)
  - Closest Pin amount (with keypad editing)
  - Mulligans amount (with keypad editing)
- Add golf course dropdown (Wednesday uses fixed course)
- Wire up database persistence for settings
- Add `CustomKeypadService` integration for amount editing

#### 2. `lib/screens/wednesday/wednesday_player_selection_screen.dart`
- Import `DeviceDetectionService` and `ResponsiveTypography`
- Add landscape orientation locking
- Replace hardcoded fonts with `ResponsiveTypography` calls
- Use `PlayerSelectionUIService` patterns where applicable
- Maintain Wednesday's random shuffle behavior for group assignment

### Phase 2: Screen-by-Screen Updates

**3. `lib/screens/wednesday/wednesday_player_profile_screen.dart`**
   - Import responsive services
   - Use `PlayerProfileService` for form rendering
   - Apply responsive typography

**4. `lib/screens/wednesday/wednesday_player_scores_screen.dart`**
   - Import responsive services
   - Use `PlayerScoresService` patterns
   - Apply responsive typography

#### 5. `lib/screens/wednesday/wednesday_enter_scores_screen.dart` (largest file - 150KB)
**Full refactor to match Monday patterns:**
- Import `DeviceDetectionService` and `ResponsiveTypography`
- Add landscape orientation locking
- Refactor to use `EnterScoresUIService` patterns for:
  - Purse header display
  - Group grid layout (Wednesday uses different group structure)
  - Bottom action buttons
- Create new `lib/services/UI/wednesday_enter_scores_UI_service.dart` for:
  - Wednesday-specific group processing UI
  - Individual vs Group payout display (40%/60% split)
  - Wildcard mode UI components
- Apply `ResponsiveTypography` throughout
- Use `CustomKeypadService` for score entry
- Preserve Wednesday business logic:
  - Auto-grouping algorithm
  - Individual handicap winners
  - Group winners calculation
  - 40%/60% payout split logic

**6. `lib/screens/wednesday/wednesday_golf_course_info_screen.dart`**
   - Import responsive services
   - Apply responsive typography

### Phase 3: Admin and Specialized Screens

**7. `lib/screens/wednesday/wednesday_admin_screen.dart`**
   - Import responsive services
   - Match Monday admin screen patterns

**8. `lib/screens/wednesday/wednesday_auto_process_groups_screen.dart`**
   - Import responsive services
   - Apply responsive typography

**9. `lib/screens/wednesday/wednesday_player_payout_screen.dart`**
   - Import responsive services
   - Apply responsive typography
   - (Note: Monday doesn't have equivalent - unique to Wednesday)

### Phase 4: Wednesday-Specific UI Service (Optional)
If needed, create Wednesday-specific UI services for unique functionality:
- `lib/services/UI/wednesday_enter_scores_UI_service.dart` - Group processing UI
- `lib/services/UI/wednesday_payout_UI_service.dart` - Payout display

## Implementation Details

### Common Pattern for Each Screen

```dart
// Imports to add
import '../../services/device_detection_service.dart';
import '../../services/responsive_typography.dart';

// In initState or build, add orientation lock
void _setOrientation() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    DeviceDetectionService.printDebugInfo(context);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  });
}

// Replace hardcoded font sizes like:
// TextStyle(fontSize: 14)
// With:
// TextStyle(fontSize: ResponsiveTypography.getBodyText(context))
// Or use convenience methods:
// ResponsiveTypography.bodyTextStyle(context)
```

### Color Scheme Preservation
Wednesday screens should maintain their orange color scheme:
- Primary: `Colors.orange[700]` (AppBar)
- Accent: `Colors.orange[300]` / `Color.fromRGBO(255, 214, 0, 1)` (gold)
- Background: `Colors.orange[100]`, `Colors.orange[200]`

### Device Breakpoints (Already Defined)
- **6.5" Phone**: shortestSide < 450dp
- **8" Tablet**: 450 <= shortestSide < 650dp
- **10" Tablet**: shortestSide >= 650dp

## Priority Order

1. **wednesday_parent_screen.dart** - Foundation screen
2. **wednesday_player_selection_screen.dart** - Entry point for game flow
3. **wednesday_enter_scores_screen.dart** - Core functionality (most complex)
4. **wednesday_player_profile_screen.dart** - Player management
5. **wednesday_player_scores_screen.dart** - Score viewing
6. **wednesday_player_payout_screen.dart** - Wednesday-unique feature
7. **wednesday_golf_course_info_screen.dart** - Reference screen
8. **wednesday_admin_screen.dart** - Admin functions
9. **wednesday_auto_process_groups_screen.dart** - Automation

## Testing Approach
After each screen update:
- User performs hot restart in Flutter IDE
- Test on all three device sizes (6.5" phone, 8" tablet, 10" tablet)
- Verify orange color scheme is preserved
- Verify responsive typography scales correctly
- Verify landscape orientation locking works

## Files Modified Summary

| File | Complexity | Key Changes |
|------|------------|-------------|
| `wednesday_parent_screen.dart` | **High** | Full rewrite with ParentScreenUI, editable settings, keypad |
| `wednesday_player_selection_screen.dart` | Medium | Add services, responsive fonts, orientation lock |
| `wednesday_enter_scores_screen.dart` | **High** | Full refactor to match Monday patterns |
| `wednesday_player_profile_screen.dart` | Low | Add services, responsive fonts |
| `wednesday_player_scores_screen.dart` | Medium | Add services, responsive fonts |
| `wednesday_player_payout_screen.dart` | Medium | Add services, responsive fonts |
| `wednesday_golf_course_info_screen.dart` | Low | Add services, responsive fonts |
| `wednesday_admin_screen.dart` | Low | Add services, responsive fonts |
| `wednesday_auto_process_groups_screen.dart` | Medium | Add services, responsive fonts |

## New Files to Create

| File | Purpose |
|------|---------|
| `lib/services/UI/wednesday_enter_scores_UI_service.dart` | Wednesday-specific enter scores UI components |

## Implementation Order (Recommended)

1. **wednesday_parent_screen.dart** - Foundation with editable settings
2. **wednesday_player_selection_screen.dart** - Game flow entry
3. **wednesday_enter_scores_screen.dart** + new UI service - Core gameplay
4. **wednesday_player_profile_screen.dart** - Player management
5. **wednesday_player_scores_screen.dart** - Score viewing
6. **wednesday_player_payout_screen.dart** - Wednesday-unique payout
7. **wednesday_golf_course_info_screen.dart** - Static info
8. **wednesday_admin_screen.dart** - Admin functions
9. **wednesday_auto_process_groups_screen.dart** - Automation

## Key Preserved Wednesday Functionality
- Orange color scheme (`Colors.orange[700]`, `Colors.orange[300]`)
- Random player shuffle for group assignment
- Auto-grouping algorithm (4 players per group)
- Individual vs Group payout split (40%/60%)
- Individual handicap winner calculation
- Group winner calculation
- Wildcard mode for incomplete groups
- Firebase collections: `W_player_scores`, `W_player_profile`

## Estimated Scope
- **9 Wednesday screens** to update
- **1 new UI service** to create
- Reuse existing Monday UI services where applicable
- Preserve all Wednesday-specific business logic
- Full landscape orientation locking
