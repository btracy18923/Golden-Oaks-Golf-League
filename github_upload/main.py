"""
Simple Main Application for APK Build
=====================================

This is a simplified version of the golf league app that only includes 
the unified main menu screen for initial APK testing with Buildozer.
"""

import os
from kivy.app import App
from kivy.uix.screenmanager import ScreenManager
from kivy.config import Config

# Configure Kivy for Android
Config.set('graphics', 'width', '1200')
Config.set('graphics', 'height', '800')

class SimpleGolfApp(App):
    """Simplified golf league application for APK build testing."""
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.current_league = None
    
    def build(self):
        """Build the application with only the main menu screen."""
        # Create screen manager
        sm = ScreenManager()
        
        # Import and add the unified main menu screen
        from screens.unified_main_menu_screen import UnifiedMainMenuScreen
        main_menu = UnifiedMainMenuScreen(name='main_menu')
        sm.add_widget(main_menu)
        
        # Set the main menu as the current screen
        sm.current = 'main_menu'
        
        return sm
    
    def set_current_league(self, league):
        """Set the current league (for compatibility with unified_main_menu_screen)."""
        self.current_league = league
        print(f"League set to: {league}")

if __name__ == '__main__':
    SimpleGolfApp().run()