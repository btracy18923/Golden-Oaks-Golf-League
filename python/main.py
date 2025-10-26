"""
Ultra-Simple Main Application for APK Build
==========================================

Minimal Kivy app to test APK build process.
"""

from kivy.app import App
from kivy.uix.label import Label
from kivy.uix.boxlayout import BoxLayout

class SimpleGolfApp(App):
    """Ultra-simple golf league app for APK build testing."""
    
    def build(self):
        """Build a simple test application."""
        layout = BoxLayout(orientation='vertical', padding=50, spacing=20)
        layout.add_widget(Label(text='Golden Oaks Golf League', font_size='30sp'))
        layout.add_widget(Label(text='Android APK Build Successful!', font_size='20sp'))
        layout.add_widget(Label(text='This confirms the build process works.', font_size='16sp'))
        return layout

if __name__ == '__main__':
    SimpleGolfApp().run()