# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter-based golf league management application for Golden Oaks Golf League, designed to handle both Monday and Wednesday league groups through a unified interface. The system supports distributed deployment across Android tablets with cloud synchronization.

## Key Commands

### Running the Application
```bash
flutter run
```

### Building for Android
```bash
flutter build apk
flutter build appbundle
```

### Testing
```bash
flutter test
```

### Code Analysis
```bash
flutter analyze
```

## Architecture Overview

### Deployment Architecture
- **Monday League**: Dedicated Android tablet with local SQLite database
- **Wednesday League**: Dedicated Android tablet with local SQLite database  
- **Cloud Sync**: Both tablets auto-sync with Firebase database
- **Web Interface**: Netlify website connected to Firebase for web access

### Main Application Structure
- **Entry Point**: `lib/main.dart` - Main Flutter application entry point
- **Database**: Local SQLite database containing player data, scores, and league information
- **Screen System**: Modular screen widgets in `lib/screens/` directory handle different UI views

### Core Components

#### 1. Unified League System
- Single database supports both Monday and Wednesday leagues through league field filtering
- League selection in main menu controls all subsequent data operations
- `current_league` state managed through state management solution (Provider/Bloc/Riverpod)
- Local databases sync with Firebase for cross-platform data consistency

#### 2. Screen Architecture
All screens are Flutter widgets managed by Navigator:
- Main Menu Screen - League selection and main navigation
- Player Selection Screen - Player browsing and selection
- Player Profile Screen - Individual player details and statistics
- Player Scores Screen - Score viewing and history
- Enter Scores Screen - Score entry interface
- Player Payout Screen - Prize distribution calculations
- Golf Course Info Screen - Course information management
- Admin Screen - Administrative functions

#### 3. Handicap Calculation System
Implements USGA-compliant handicap calculation with progressive methodology:
- **1-4 scores**: Blending method with progressive blend factors
- **5+ scores**: Full USGA method using lowest differentials
- Detailed algorithm documented in `Handicap_Calculation_Method.txt`

#### 4. Prize Distribution
Dynamic prize calculation system supporting 4-40 players with configurable distribution tables

### Technology Stack
- **Framework**: Flutter (Dart-based UI framework)
- **Database**: SQLite (local) + Firebase (cloud sync)
- **State Management**: Provider/Bloc/Riverpod (to be determined based on implementation)
- **Cloud Services**: Firebase (database sync), Netlify (web hosting)
- **Platform**: Android (primary target), with potential for iOS deployment

### Key Design Patterns
- Widget-based UI with centralized state management
- League filtering at the application level
- Modular screen widgets with consistent interface patterns
- Database operations encapsulated within service classes
- Auto-sync architecture for distributed tablet deployment

### Development Notes
- Application configured for Android deployment
- League state management is central to all data operations
- Custom UI components provide consistent styling
- Native Android APK build process via Flutter's build system
- Firebase integration enables real-time data synchronization between tablets and web interface

## Flutter Build Process

Flutter provides a streamlined build process for Android applications:

### Development Build
```bash
flutter run --debug
```

### Release Build
```bash
flutter build apk --release
flutter build appbundle --release
```

### Key Dependencies
Add these to `pubspec.yaml`:
- `sqflite` - SQLite database support
- `firebase_core` - Firebase initialization
- `cloud_firestore` - Firebase database
- `provider` or `bloc` - State management
- `path` - File path utilities

### Android Configuration
Ensure proper Android configuration in:
- `android/app/build.gradle`
- `android/app/src/main/AndroidManifest.xml`
- Firebase configuration files in `android/app/`

The Flutter framework handles the complexity of Android compilation, eliminating the need for manual Java/Kotlin conversion or complex build tools.

## Responsive Design Guidelines

This application targets multiple Android device sizes:
- **10" tablets**: Primary deployment devices for league management
- **8" tablets**: Secondary deployment option
- **6" phones**: Mobile access for players and officials

### Implementation Approach
**Recommended: Single responsive app**
- Use `MediaQuery.of(context).size` to get screen dimensions
- Implement responsive layouts with `LayoutBuilder` or `ResponsiveBuilder`
- Adjust UI elements based on screen width/height breakpoints

### Prompting for Responsive Changes
When requesting screen optimizations, specify:
- Target screen (e.g., "player selection screen")
- Device sizes (e.g., "for 10", 8", and 6" screens")
- Layout preference (e.g., "use grid layout for tablets and list view for phones")

Example: "Make the player selection screen responsive for 10", 8", and 6" screens - use grid layout for tablets and list view for phones"

### Flutter Responsive Widgets
- `Flexible`, `Expanded` for dynamic sizing
- `Wrap` for flowing layouts
- `OrientationBuilder` for landscape/portrait handling
- `MediaQuery` for screen size detection
- Custom breakpoint logic for device-specific layouts

### Alternative: Device-Specific Versions
If needed, create separate screen variants:
- `player_selection_tablet.dart` for larger screens
- `player_selection_phone.dart` for smaller screens
- Route based on screen size in navigation logic

## Git Workflow Instructions

**IMPORTANT**: Do not automatically commit changes or push changes to GitHub. The user will explicitly tell you when to commit and push. Always wait for user instructions before running git commit or git push commands.