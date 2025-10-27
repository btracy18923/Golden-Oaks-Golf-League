"""
Simplified Main Application for APK Build
=========================================

Main entry point using only the unified main menu screen for APK testing.
Following CLAUDE.md guidance to start with single screen.
"""

from kivy.app import App
from kivy.uix.screenmanager import ScreenManager
from screens.unified_main_menu_screen import UnifiedMainMenuScreen

class GoldenOaksGolfApp(App):
    """Simplified golf league app using only the main menu screen."""
    
    def build(self):
        """Build the app with just the main menu screen."""
        print("DEBUG: Building GoldenOaksGolfApp with UnifiedMainMenuScreen")
        # Create screen manager
        sm = ScreenManager()
        
        # Add the unified main menu screen
        main_menu = UnifiedMainMenuScreen(name='main_menu')
        print(f"DEBUG: Created UnifiedMainMenuScreen: {main_menu}")
        sm.add_widget(main_menu)
        
        return sm

if __name__ == '__main__':
    GoldenOaksGolfApp().run()