# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Python-based golf league management application for Golden Oaks Golf League, designed to handle both Monday and Wednesday league groups through a unified interface. The system supports distributed deployment across Android tablets with cloud synchronization.

## Key Commands

### Running the Application
```bash
cd python
python main_unified_golf_app.py
```

### Testing Individual Components
```bash
# Generate handicap scores for testing
python handicap_score_generator.py

# Generate prize distribution tables
python complete_prize_table.py

# Test distribution functions
python "Distribution Function.py"
```

## Architecture Overview

### Deployment Architecture
- **Monday League**: Dedicated Android tablet with local SQLite database
- **Wednesday League**: Dedicated Android tablet with local SQLite database  
- **Cloud Sync**: Both tablets auto-sync with Firebase database
- **Web Interface**: Netlify website connected to Firebase for web access

### Main Application Structure
- **Entry Point**: `python/main_unified_golf_app.py` - Main Kivy application class that manages screen navigation
- **Database**: `python/GoldenOaks.db` - SQLite database containing player data, scores, and league information
- **Screen System**: Modular screen classes in `python/screens/` directory handle different UI views

### Core Components

#### 1. Unified League System
- Single database supports both Monday and Wednesday leagues through league field filtering
- League selection in main menu controls all subsequent data operations
- `current_league` state propagated to all screens via `set_league()` method
- Local databases sync with Firebase for cross-platform data consistency

#### 2. Screen Architecture
All screens inherit from Kivy's Screen class and are managed by ScreenManager:
- `unified_main_menu_screen.py` - League selection and main navigation
- `player_selection_screen.py` - Player browsing and selection
- `player_profile_screen.py` - Individual player details and statistics
- `player_scores_screen.py` - Score viewing and history
- `Enter_Scores_Screen.py` - Score entry interface
- `player_payout_screen.py` - Prize distribution calculations
- `golf_course_info_screen.py` - Course information management
- `Admin_Screen.py` - Administrative functions

#### 3. Handicap Calculation System
Implements USGA-compliant handicap calculation with progressive methodology:
- **1-4 scores**: Blending method with progressive blend factors
- **5+ scores**: Full USGA method using lowest differentials
- Detailed algorithm documented in `Handicap_Calculation_Method.txt`

#### 4. Prize Distribution
Dynamic prize calculation system supporting 4-40 players with configurable distribution tables

### Technology Stack
- **Framework**: Kivy (Python GUI framework)
- **Database**: SQLite3 (local) + Firebase (cloud sync)
- **Graphics Backend**: OpenGL (configured for angle_sdl2)
- **Image Handling**: Pillow (PIL)
- **Cloud Services**: Firebase (database sync), Netlify (web hosting)

### Key Design Patterns
- Screen-based navigation with centralized state management
- League filtering at the application level
- Modular screen classes with consistent interface patterns
- Database operations encapsulated within screen classes
- Auto-sync architecture for distributed tablet deployment

### Development Notes
- Application configured to start maximized with OpenGL rendering
- League state management is central to all data operations
- Custom UI components (ColoredButton) provide consistent styling
- Ready for Android APK packaging via Kivy's buildozer
- Firebase integration enables real-time data synchronization between tablets and web interface


## APK Build Process - Recommended Approach

After many failed attempts at creating an android apk with the kivy/python code we used to develop the Golden Oaks Golf League I have decided to ONLY use Buildozer.  Do NOT change code to JAVA.  Do NOT use Chaquopy.  Do NOT use Android Studio.  I want to only used the Kivy/Python code with no changes.  To start using Buildozer I think that using only one python screen instead of the whole project simplifies the work.  The screen I want to use is the unified_main_menu.py screen.  If we can get this to work then we can add the other screens one at a time.

So concentrate on Buildozer to compile the Kivy/Python code to create an Android apk.

