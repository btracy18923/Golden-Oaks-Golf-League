"""
Simple Main Application for APK Build
=====================================

This is a simplified version of the golf league app that only includes 
the unified main menu screen for initial APK testing with Buildozer.
"""

import os
import sys

# Kivy configuration for Android
os.environ['KIVY_GL_BACKEND'] = 'angle_sdl2'
os.environ['KIVY_WINDOW'] = 'sdl2'

from kivy.config import Config
Config.set('graphics', 'multisamples', '0')
Config.set('kivy', 'window_icon', '')

from kivy.app import App
from kivy.uix.screenmanager import ScreenManager
from kivy.uix.label import Label
from kivy.uix.boxlayout import BoxLayout

class SimpleGolfApp(App):
    """Simplified golf league application for APK build testing."""
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.current_league = None
    
    def build(self):
        """Build the application with only the main menu screen."""
        # Create screen manager
        sm = ScreenManager()
        
        try:
            # Try to import and add the unified main menu screen
            from screens.unified_main_menu_screen import UnifiedMainMenuScreen
            main_menu = UnifiedMainMenuScreen(name='main_menu')
            sm.add_widget(main_menu)
            sm.current = 'main_menu'
        except Exception as e:
            # Fallback: create a simple test screen
            print(f"Failed to load main menu: {e}")
            from kivy.uix.screen import Screen
            test_screen = Screen(name='test')
            layout = BoxLayout(orientation='vertical', padding=50, spacing=20)
            layout.add_widget(Label(text='Golden Oaks Golf League', font_size=24))
            layout.add_widget(Label(text='APK Build Test Successful!', font_size=18))
            layout.add_widget(Label(text=f'Error: {str(e)}', font_size=14))
            test_screen.add_widget(layout)
            sm.add_widget(test_screen)
            sm.current = 'test'
        
        return sm
    
    def set_current_league(self, league):
        """Set the current league (for compatibility with unified_main_menu_screen)."""
        self.current_league = league
        print(f"League set to: {league}")

if __name__ == '__main__':
    SimpleGolfApp().run()