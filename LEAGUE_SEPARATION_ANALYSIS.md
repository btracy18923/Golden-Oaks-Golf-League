# League Separation Analysis

## Executive Summary

This document outlines the analysis and plan for separating Monday and Wednesday leagues into dedicated parent screens with league-specific sub-screens, eliminating shared conditional logic in favor of complete code separation.

## Current Architecture Problems

### Unified Screen Issues
- **Complex Conditional Logic**: `if (currentLeague == League.monday)` scattered throughout code
- **Parameter Threading**: `currentLeague` passed through multiple navigation layers  
- **Development Inefficiency**: Searching through conditional blocks slows editing
- **Context Switching**: Mental overhead of handling both leagues in single files
- **Change Risk**: Modifying one league's behavior risks affecting the other

### Example of Current Complexity
```dart
Widget buildAnteSection() {
  return Container(
    child: Text(
      currentLeague == League.monday ? 'Skats Ante' : 'Player\'s Ante',
      // More conditional logic scattered throughout...
    )
  );
}
```

## Proposed Separation Architecture

### New Design Structure
```
Main Menu Screen
├── Monday League Button → MondayParentScreen
└── Wednesday League Button → WednesdayParentScreen

MondayParentScreen (Green Theme, "Skats" terminology)
├── MondayPlayerSelectionScreen
├── MondayPlayerScoresScreen  
├── MondayEnterScoresScreen
├── MondayPlayerProfileScreen
└── MondayPlayerPayoutScreen

WednesdayParentScreen (Orange Theme, "Scores" terminology)
├── WednesdayPlayerSelectionScreen
├── WednesdayPlayerScoresScreen
├── WednesdayEnterScoresScreen
├── WednesdayPlayerProfileScreen
└── WednesdayPlayerPayoutScreen
```

### Directory Structure
```
lib/screens/
├── main_menu_screen.dart
├── monday/
│   ├── monday_parent_screen.dart
│   ├── monday_player_selection_screen.dart
│   ├── monday_enter_scores_screen.dart
│   ├── monday_player_scores_screen.dart
│   └── monday_player_profile_screen.dart
└── wednesday/
    ├── wednesday_parent_screen.dart
    ├── wednesday_player_selection_screen.dart
    ├── wednesday_enter_scores_screen.dart
    ├── wednesday_player_scores_screen.dart
    └── wednesday_player_profile_screen.dart
```

## Key Benefits of Separation

### Development Efficiency
- **Direct File Targeting**: No searching through conditional blocks
- **Cleaner Code**: No league parameters or conditional logic needed
- **Faster Navigation**: File names immediately indicate scope
- **Isolated Changes**: Zero cross-league risk
- **Single Purpose**: Each file focused on one league only

### Example of Separated Approach
```dart
// monday/monday_player_selection_screen.dart
Widget buildAnteSection() {
  return Container(
    child: Text('Skats Ante'),  // No conditions needed
  );
}

// wednesday/wednesday_player_selection_screen.dart  
Widget buildAnteSection() {
  return Container(
    child: Text('Player\'s Ante'),  // No conditions needed
  );
}
```

### Maintenance Reality
**No "Maintenance Burden" - Issues Are League-Specific:**
- Monday League: "SKAT scoring calculation is wrong" → Fix Monday files only
- Wednesday League: "Closest pin amount not saving" → Fix Wednesday files only
- Feature requests are typically league-specific
- Bug reports come with league context already identified

## Database Strategy for Separation

### Current Structure
- Single SQLite database with `league` field filtering
- Firebase sync with shared collections

### Proposed Structure (Recommended)

#### Firebase Collection Separation
```
Firebase Database:
├── monday-players/{playerId}
├── monday-scores/{scoreId}
├── monday-settings/
├── wednesday-players/{playerId}
├── wednesday-scores/{scoreId}
└── wednesday-settings/
```

#### Local Database Separation
```
Monday Tablet: monday_local.db → syncs with monday-* collections
Wednesday Tablet: wednesday_local.db → syncs with wednesday-* collections
```

#### Database Helper Updates
```dart
class MondayDatabaseHelper {
  static const String DB_NAME = 'monday_league.db';
  
  Future<void> syncToFirebase() async {
    // Upload to monday-players, monday-scores collections only
  }
}

class WednesdayDatabaseHelper {
  static const String DB_NAME = 'wednesday_league.db';
  
  Future<void> syncFromFirebase() async {
    // Download from wednesday-* collections only
  }
}
```

## Future Flutter Web App Integration

### Web App Architecture
```
Web App Structure:
├── lib/
│   ├── monday/
│   │   ├── monday_dashboard.dart
│   │   ├── monday_players.dart
│   │   └── monday_scores.dart
│   ├── wednesday/
│   │   ├── wednesday_dashboard.dart
│   │   ├── wednesday_players.dart
│   │   └── wednesday_scores.dart
│   └── shared/
│       ├── firebase_service.dart
│       └── common_widgets.dart
```

### Web Routing Strategy
- League-specific routes: `/monday/dashboard`, `/wednesday/scores`
- Shared authentication with separate data access
- Option for single deployment with league selection or separate deployments

## Implementation Plan

### Phase 1: Directory Structure
1. Create `lib/screens/monday/` and `lib/screens/wednesday/` directories
2. Create parent screens: `MondayParentScreen` and `WednesdayParentScreen`

### Phase 2: Screen Duplication
1. Copy existing screens to both league directories
2. Remove `currentLeague` parameters and conditional logic
3. Hard-code league-specific logic (colors, labels, database calls)

### Phase 3: Database Separation
1. Backup current data
2. Create league-specific Firebase collections
3. Migrate existing data to new structure
4. Update sync logic for separated collections

### Phase 4: Navigation Updates
1. Update main menu to navigate to parent screens
2. Ensure navigation stays within league context
3. Remove old unified screens

### Phase 5: Testing
1. Test both league paths independently
2. Verify database sync works correctly
3. Ensure no cross-league contamination

## Test Impact

### Current Tests (31 passing, 1 broken)
- Most tests validate core business logic and will remain valuable
- Tests using `League.monday`/`League.wednesday` enums will need updates
- `widget_test.dart` is broken (references wrong package) and should be fixed/removed

### Post-Separation Testing
- Potentially double test scenarios (Monday + Wednesday paths)
- Tests become more focused on single league logic
- Easier to isolate test failures to specific league

## Decision Rationale

### Why Separation Makes Sense
1. **Real-world mapping**: Monday and Wednesday are actually separate organizations
2. **Different business rules**: SKATs vs individual/group scoring, different prize structures
3. **Development efficiency**: Faster editing and cleaner code
4. **Operational reality**: Bug reports and feature requests come with league context
5. **Future flexibility**: Leagues can evolve independently

### Why "Maintenance Burden" Doesn't Apply
- Leagues operate independently in real life
- Issues are inherently league-specific
- Fixes target known league, not both
- Features are typically requested for specific league
- No shared business logic that would require dual maintenance

## Conclusion

League separation aligns the code structure with the real-world operational reality, improves development efficiency, and prepares the codebase for future enhancements including the Flutter web application. The perceived "maintenance burden" of code duplication is outweighed by the benefits of clearer code organization and faster development cycles.

---

*Analysis conducted: November 2024*  
*Status: Planning phase - implementation pending*