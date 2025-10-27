"""
GOLDEN OAKS GOLF LEAGUE - UNIFIED APP
====================================

Unified Android-ready application that handles both Monday and Wednesday golf s
with a single database and league filtering system.

UNIFIED ARCHITECTURE:
- Single app for both Monday and Wednesday leagues
- Uses GoldenOaks.db with league field filtering
- Screen classes organized in separate modules
- League selection controls all data operations
- Ready for Android APK packaging

Requirements:
- Python 3.x
- Kivy framework
- Pillow (PIL) for image handling
"""

import os
import sys
from kivy import platform

# Android-compatible Kivy configuration
if platform == 'android':
    # Android-specific settings
    pass
else:
    # Desktop-specific settings
    os.environ['KIVY_GL_BACKEND'] = 'angle_sdl2'
    os.environ['KIVY_WINDOW'] = 'sdl2'
    from kivy.config import Config
    Config.set('graphics', 'window_state', 'maximized')  # Start maximized
    Config.set('graphics', 'resizable', '1')

# Basic Kivy configuration (works on both desktop and Android)
from kivy.config import Config
Config.set('graphics', 'multisamples', '0')

# Kivy imports
from kivy.app import App
from kivy.uix.screenmanager import ScreenManager

# Import screen classes
from screens.unified_main_menu_screen import UnifiedMainMenuScreen
from screens.player_selection_screen import PlayerSelectionScreen  
from screens.player_profile_screen import PlayerProfileScreen
from screens.player_scores_screen import PlayerScoresScreen
from screens.Enter_Scores_Screen import EnterScoresScreen
from screens.player_payout_screen import PlayerPayoutScreen
from screens.golf_course_info_screen import GolfCourseInfoScreen
from screens.Admin_Screen import AdminScreen


class UnifiedGolfLeagueApp(App):
    """Main application class for unified Monday/Wednesday Golf League."""
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.current_league = None  # Will be set by main menu
        
    def build(self):
        """Build and return the root widget."""
        # Create screen manager
        sm = ScreenManager()
        
        # Add all screens to the screen manager
        sm.add_widget(UnifiedMainMenuScreen(name='unified_main_menu'))
        sm.add_widget(PlayerSelectionScreen(name='player_selection'))
        sm.add_widget(PlayerProfileScreen(name='player_profile'))
        sm.add_widget(PlayerScoresScreen(name='player_scores'))
        sm.add_widget(EnterScoresScreen(name='enter_scores'))
        sm.add_widget(PlayerPayoutScreen(name='player_payout'))
        sm.add_widget(GolfCourseInfoScreen(name='golf_course_info'))
        sm.add_widget(AdminScreen(name='admin'))
        
        # Set initial screen
        sm.current = 'unified_main_menu'
        
        return sm
    
    def set_current_league(self, league):
        """Set the current league (monday or wednesday) for all screens."""
        self.current_league = league
        # Notify all screens of the league change
        if hasattr(self.root, 'screens'):
            for screen in self.root.screens:
                if hasattr(screen, 'set_league'):
                    screen.set_league(league)
    
    def get_current_league(self):
        """Get the currently selected league."""
        return self.current_league
    
    def on_start(self):
        """Called when the app starts."""
        # Set window title (desktop only)
        if platform != 'android':
            from kivy.core.window import Window
            Window.set_title("Golden Oaks Golf League - Unified App")


if __name__ == '__main__':
    # Run the unified application
    UnifiedGolfLeagueApp().run()