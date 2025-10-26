"""
Kivy Launcher Version - Golden Oaks Golf League
==============================================

This is a Kivy Launcher compatible version of the golf league app
that only includes the unified main menu screen for testing.
"""

import os
from kivy.app import App
from kivy.uix.screenmanager import ScreenManager
from kivy.uix.screenmanager import Screen
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.floatlayout import FloatLayout
from kivy.uix.label import Label
from kivy.uix.image import Image
from kivy.uix.behaviors import ButtonBehavior
from kivy.graphics import Color, Rectangle, RoundedRectangle, Line
from kivy.metrics import dp


class ColoredButton(ButtonBehavior, Label):
    """A colored button with customizable background color and text color."""
    
    def __init__(self, bg_color=(1, 1, 1, 1), **kwargs):
        super().__init__(**kwargs)
        self._bg_color = bg_color
        self.corner_radius = dp(5)
        
        with self.canvas.before:
            self.bg_color_instruction = Color(*bg_color)
            self.rect = RoundedRectangle(size=self.size, pos=self.pos, radius=[self.corner_radius])
        
        with self.canvas.after:
            Color(0, 0, 0, 1)
            self.border = Line(rounded_rectangle=(self.x, self.y, self.width, self.height, self.corner_radius), width=2)
        
        self.bind(size=self.update_graphics, pos=self.update_graphics)
    
    @property
    def bg_color(self):
        return self._bg_color
    
    @bg_color.setter
    def bg_color(self, value):
        self._bg_color = value
        if hasattr(self, 'bg_color_instruction'):
            self.bg_color_instruction.rgba = value
    
    def update_graphics(self, *args):
        self.rect.size = self.size
        self.rect.pos = self.pos
        self.border.rounded_rectangle = (self.x, self.y, self.width, self.height, self.corner_radius)


class MainMenuScreen(Screen):
    """Simplified main menu screen for Kivy Launcher testing."""
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.current_league = None
        self.monday_btn = None
        self.wednesday_btn = None
        self.add_widget(self.setup_ui())
    
    def setup_ui(self):
        main_layout = BoxLayout(orientation='vertical', padding=20, spacing=10)
        
        with main_layout.canvas.before:
            Color(0.9, 0.9, 0.9, 1)
            main_layout.bg_rect = Rectangle(pos=main_layout.pos, size=main_layout.size)
        main_layout.bind(pos=self.update_bg, size=self.update_bg)
        
        # Title
        title_label = Label(
            text='Golden Oaks Golf League\nKivy Launcher Test',
            font_size='28sp',
            bold=True,
            size_hint=(1, 0.3),
            color=(0, 0, 0, 1),
            halign='center'
        )
        main_layout.add_widget(title_label)
        
        # Buttons layout
        buttons_layout = BoxLayout(orientation='vertical', spacing=20, size_hint=(1, 0.7))
        
        # Monday Group button
        self.monday_btn = ColoredButton(
            text="Monday Group",
            size_hint=(1, 0.3),
            font_size='24sp',
            bold=True,
            bg_color=(0.7, 1.0, 0.7, 1),
            color=(0, 0, 0, 1),
        )
        self.monday_btn.bind(on_press=lambda x: self.select_league('Monday'))
        buttons_layout.add_widget(self.monday_btn)
        
        # Wednesday Group button
        self.wednesday_btn = ColoredButton(
            text="Wednesday Group",
            size_hint=(1, 0.3),
            font_size='24sp',
            bold=True,
            bg_color=(1.0, 0.84, 0, 1),
            color=(0, 0, 0, 1),
        )
        self.wednesday_btn.bind(on_press=lambda x: self.select_league('Wednesday'))
        buttons_layout.add_widget(self.wednesday_btn)
        
        # Status label
        self.status_label = Label(
            text='Select your golf league above',
            font_size='18sp',
            size_hint=(1, 0.4),
            color=(0, 0, 0, 1),
            halign='center'
        )
        buttons_layout.add_widget(self.status_label)
        
        main_layout.add_widget(buttons_layout)
        return main_layout
    
    def update_bg(self, instance, value):
        if hasattr(instance, 'bg_rect'):
            instance.bg_rect.pos = instance.pos
            instance.bg_rect.size = instance.size
    
    def select_league(self, league):
        self.current_league = league
        self.status_label.text = f'{league} League Selected!\n\nKivy Launcher Test Successful!\n\nThis proves your app structure works\nand is ready for APK building.'
        self.status_label.color = (0, 0.5, 0, 1)  # Green text


class GoldenOaksGolfApp(App):
    """Main application class for Kivy Launcher."""
    
    def build(self):
        sm = ScreenManager()
        main_menu = MainMenuScreen(name='main')
        sm.add_widget(main_menu)
        sm.current = 'main'
        return sm


if __name__ == '__main__':
    GoldenOaksGolfApp().run()