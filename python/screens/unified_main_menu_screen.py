"""
Unified Main Menu Screen for Golden Oaks Golf League
===================================================

This module contains the UnifiedMainMenuScreen class that provides the main navigation
hub for the unified golf league application supporting both Monday and Wednesday groups.
"""

import os
from kivy.uix.screenmanager import Screen
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.floatlayout import FloatLayout
from kivy.uix.label import Label
from kivy.uix.image import Image
from kivy.uix.behaviors import ButtonBehavior
from kivy.graphics import Color, Rectangle, RoundedRectangle, Line
from kivy.metrics import dp
from kivy.app import App


class ColoredButton(ButtonBehavior, Label):
    """A colored button with customizable background color and text color."""
    
    def __init__(self, bg_color=(1, 1, 1, 1), **kwargs):
        super().__init__(**kwargs)
        self._bg_color = bg_color
        self.corner_radius = dp(5)  # Rounded corner radius
        
        # Set up the background
        with self.canvas.before:
            self.bg_color_instruction = Color(*bg_color)
            self.rect = RoundedRectangle(size=self.size, pos=self.pos, radius=[self.corner_radius])
        
        # Set up the border
        with self.canvas.after:
            Color(0, 0, 0, 1)  # Black border
            self.border = Line(rounded_rectangle=(self.x, self.y, self.width, self.height, self.corner_radius), width=2)
        
        # Bind size and position changes
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
        """Update the graphics when size or position changes."""
        self.rect.size = self.size
        self.rect.pos = self.pos
        self.border.rounded_rectangle = (self.x, self.y, self.width, self.height, self.corner_radius)


class UnifiedMainMenuScreen(Screen):
    """
    Unified main menu screen for both Monday and Wednesday golf leagues.
    Provides league selection and navigation to all application screens.
    """
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        # Track which group is currently selected
        self.current_league = None
        
        # Store button references for color changes
        self.admin_buttons = []
        self.monday_btn = None
        self.wednesday_btn = None
        
        # Track if admin buttons have been added to layout
        self.buttons_added = False
        
        # Setup UI immediately
        self.add_widget(self.setup_ui())
    
    def setup_ui(self):
        """Set up the main menu user interface."""
        # Main layout with padding
        main_layout = BoxLayout(orientation='vertical', padding=5, spacing=0)
        
        # Set light gray background
        with main_layout.canvas.before:
            Color(0.9, 0.9, 0.9, 1)  # Light gray background
            main_layout.bg_rect = Rectangle(pos=main_layout.pos, size=main_layout.size)
        main_layout.bind(pos=self.update_bg, size=self.update_bg)
        
        """# Title
        title_label = Label(
            text='Golden Oaks Golf League - Select Your Group',
            font_size='24sp',
            bold=True,
            size_hint=(1, 0.15),
            color=(0, 0, 0, 1)
        )
        main_layout.add_widget(title_label)"""
        
        # Content layout (horizontal) - adjusted for footer
        content_layout = BoxLayout(orientation='horizontal', spacing=20, size_hint=(1, 0.70))
        
        # Create frame for left side (30% width)
        left_frame = FloatLayout(size_hint=(0.3, 1))
        
        # Group selection buttons layout - positioned at top
        group_buttons_layout = BoxLayout(
            orientation='horizontal',
            spacing=15,
            size_hint=(1, None),
            height='150dp',
            pos_hint={'top': 0.9, 'x': 0}
        )
        
        # Monday Group button
        self.monday_btn = ColoredButton(
            text="Monday Group",
            size_hint=(1, None),
            height='200dp',
            font_size='25sp',
            bold=True,
            bg_color=(0.7, 1.0, 0.7, 1),  # Light green background
            color=(0, 0, 0, 1),
        )
        self.monday_btn.bind(on_press=lambda x: self.select_monday_league())
        group_buttons_layout.add_widget(self.monday_btn)
        
        # Wednesday Group button
        self.wednesday_btn = ColoredButton(
            text="Wednesday Group",
            size_hint=(1, None),
            height='200dp',
            font_size='25sp',
            bold=True,
            bg_color=(1.0, 0.84, 0, 1),  # Gold background
            color=(0, 0, 0, 1),
        )
        self.wednesday_btn.bind(on_press=lambda x: self.select_wednesday_league())
        group_buttons_layout.add_widget(self.wednesday_btn)
        
        left_frame.add_widget(group_buttons_layout)
        
        # Player Selection button layout - positioned between Wednesday button and bottom
        self.player_selection_layout = BoxLayout(
            orientation='vertical',
            spacing=15,
            size_hint=(None, None),
            width='200dp',
            height='0dp',  # Initially hidden
            pos_hint={'center_x': 0.5, 'y': 0.15}
        )
        
        # Player Selection button
        self.player_selection_btn = ColoredButton(
            text="Select Players for\nToday's Match",
            size_hint=(None, None),
            width='260dp',
            height='200dp',
            font_size='25sp',
            bold=True,
            bg_color=(0.7, 1.0, 0.7, 1),  # Light green
            color=(0, 0, 0, 1),
            halign='center',
            valign='middle'
        )
        self.player_selection_btn.bind(on_press=lambda x: self.open_player_selection())
        
        # Create footer admin buttons - initially not added to layout
        # Add/Edit/Delete Players button
        self.player_profile_btn = ColoredButton(
            text="Add/Edit/Delete Players",
            size_hint=(1, None),
            height='170sp',
            font_size='25sp',
            bold=True,
            bg_color=(0.7, 1.0, 1.0, 1),  # Light cyan
            color=(0, 0, 0, 1)
        )
        self.player_profile_btn.bind(on_press=lambda x: self.open_player_profile())
        
        # Add/Edit/Delete Scores button
        self.player_scores_btn = ColoredButton(
            text="Add/Edit/Delete Scores",
            size_hint=(1, None),
            height='170sp',
            font_size='25sp',
            bold=True,
            bg_color=(0.7, 1.0, 1.0, 1),  # Light cyan
            color=(0, 0, 0, 1)
        )
        self.player_scores_btn.bind(on_press=lambda x: self.open_player_scores())
        
        # Add/Edit/Delete Courses button
        self.golf_course_btn = ColoredButton(
            text="Add/Edit/Delete Courses",
            size_hint=(1, None),
            height='170sp',
            font_size='25sp',
            bold=True,
            bg_color=(0.7, 1.0, 1.0, 1),  # Light cyan
            color=(0, 0, 0, 1)
        )
        self.golf_course_btn.bind(on_press=lambda x: self.open_golf_course_info())
        
        # Game Settings button
        self.game_settings_btn = ColoredButton(
            text="Game Settings",
            size_hint=(1, None),
            height='170sp',
            font_size='25sp',
            bold=True,
            bg_color=(1.0, 0.9, 0.7, 1),  # Light orange
            color=(0, 0, 0, 1)
        )
        self.game_settings_btn.bind(on_press=lambda x: self.open_admin_screen())
        
        # Store admin buttons for color updates
        self.admin_buttons = [
            self.player_selection_btn,
            self.player_profile_btn, 
            self.player_scores_btn,
            self.golf_course_btn,
            self.game_settings_btn
        ]
        
        left_frame.add_widget(self.player_selection_layout)
        content_layout.add_widget(left_frame)
        
        # Right side for image (70% width)
        self.image_widget = self.load_oak_tree_image()
        content_layout.add_widget(self.image_widget)
        
        main_layout.add_widget(content_layout)
        
        # Add spacer between content and footer
        spacer = Label(size_hint=(1, None), height='10dp')
        main_layout.add_widget(spacer)
        
        # Footer with light grey background for admin buttons
        footer_layout = BoxLayout(
            orientation='horizontal',
            size_hint=(1, None),
            height='200dp',
            padding=(20, 15, 20, 15),
            spacing=20
        )
        
        # Set light grey background for footer
        with footer_layout.canvas.before:
            Color(0.8, 0.8, 0.8, 1)  # Light grey background
            footer_layout.bg_rect = Rectangle(pos=footer_layout.pos, size=footer_layout.size)
        footer_layout.bind(pos=self.update_footer_bg, size=self.update_footer_bg)
        
        # Create footer admin buttons layout - initially hidden
        self.footer_admin_layout = BoxLayout(
            orientation='horizontal',
            spacing=20,
            size_hint=(1, None),
            height='0dp'
        )
        
        footer_layout.add_widget(self.footer_admin_layout)
        main_layout.add_widget(footer_layout)
        
        return main_layout
    
    def update_bg(self, instance, value):
        """Update background rectangle when widget moves or resizes."""
        if hasattr(instance, 'bg_rect'):
            instance.bg_rect.pos = instance.pos
            instance.bg_rect.size = instance.size
    
    def update_footer_bg(self, instance, value):
        """Update footer background rectangle when widget moves or resizes."""
        if hasattr(instance, 'bg_rect'):
            instance.bg_rect.pos = instance.pos
            instance.bg_rect.size = instance.size
    
    def load_oak_tree_image(self):
        """Load and display the GoldenOaks.png image."""
        try:
            # Get the path to the image (in root images directory)
            current_dir = os.path.dirname(os.path.abspath(__file__))
            parent_dir = os.path.dirname(current_dir)  # Go up from screens/
            parent_dir = os.path.dirname(parent_dir)  # Go up from python/
            image_path = os.path.join(parent_dir, "images", "GoldenOaks.png")
            
            # Create Kivy Image widget
            image_widget = Image(
                source=image_path,
                size_hint=(.5, 1),
                fit_mode="contain"
            )
            return image_widget
            
        except Exception as e:
            # If image loading fails, show error message
            error_label = Label(
                text=f"Could not load GoldenOaks.png\n{str(e)}",
                font_size='12sp',
                color=(1, 0, 0, 1),
                size_hint=(0.7, 1)
            )
            return error_label
    
    def select_monday_league(self):
        """Select Monday league and show admin buttons."""
        self.current_league = 'monday'
        
        # Set league in the app
        app = App.get_running_app()
        app.set_current_league('monday')
        
        # Hide Wednesday button
        self.wednesday_btn.opacity = 0
        self.wednesday_btn.disabled = True
        
        # Show admin buttons
        self.show_admin_buttons()
        
        # Update button colors for Monday
        self.update_button_colors_for_monday()
    
    def select_wednesday_league(self):
        """Select Wednesday league and show admin buttons."""
        self.current_league = 'wednesday'
        
        # Set league in the app
        app = App.get_running_app()
        app.set_current_league('wednesday')
        
        # Hide Monday button
        self.monday_btn.opacity = 0
        self.monday_btn.disabled = True
        
        # Show admin buttons
        self.show_admin_buttons()
        
        # Update button colors for Wednesday
        self.update_button_colors_for_wednesday()
    
    def show_admin_buttons(self):
        """Show the admin buttons after league selection."""
        # Add buttons to layout if not already added
        if not self.buttons_added:
            self.player_selection_layout.add_widget(self.player_selection_btn)
            self.footer_admin_layout.add_widget(self.player_profile_btn)
            self.footer_admin_layout.add_widget(self.player_scores_btn)
            self.footer_admin_layout.add_widget(self.golf_course_btn)
            self.footer_admin_layout.add_widget(self.game_settings_btn)
            self.buttons_added = True
        
        # Animate the admin buttons into view
        self.player_selection_layout.height = '215dp'  # Height for 1 square button with spacing
        self.footer_admin_layout.height = '70dp'  # Height for footer buttons
    
    def update_button_colors_for_monday(self):
        """Update button colors when Monday league is selected."""
        # Keep existing colors for Monday
        colors = [
            (0.7, 1.0, 0.7, 1),    # Light green for player selection
            (0.7, 1.0, 0.7, 1),    # Light green for player selection
            (0.7, 1.0, 0.7, 1),    # Light green for player selection
            (0.7, 1.0, 0.7, 1),    # Light green for player selection
            (0.7, 1.0, 0.7, 1),    # Light green for player selection
        ]
        for button, color in zip(self.admin_buttons, colors):
            button.bg_color = color
            self.update_button_background(button)
    
    def update_button_colors_for_wednesday(self):
        """Update button colors when Wednesday league is selected."""
        # Use gold-themed colors for Wednesday
        colors = [
            (1.0, 0.84, 0, 1),             # Light gold for player selection
            (1.0, 0.84, 0, 1),             # Light gold for player selection
            (1.0, 0.84, 0, 1),             # Light gold for player selection
            (1.0, 0.84, 0, 1),             # Light gold for player selection
            (1.0, 0.84, 0, 1),             # Light gold for player selection
        ]
        for button, color in zip(self.admin_buttons, colors):
            button.bg_color = color
            self.update_button_background(button)
    
    def update_button_background(self, button):
        """Update a button's background color by redrawing its canvas."""
        button.canvas.before.clear()
        with button.canvas.before:
            Color(*button.bg_color)
            button.rect = RoundedRectangle(size=button.size, pos=button.pos, radius=[button.corner_radius])
    
    def open_player_selection(self):
        """Navigate to the Player Selection screen."""
        if self.current_league:
            player_screen = self.manager.get_screen('player_selection')
            if hasattr(player_screen, 'set_league'):
                player_screen.set_league(self.current_league)
            self.manager.current = 'player_selection'
    
    def open_player_profile(self):
        """Navigate to the Player Profile screen."""
        if self.current_league:
            profile_screen = self.manager.get_screen('player_profile')
            if hasattr(profile_screen, 'set_league'):
                profile_screen.set_league(self.current_league)
            self.manager.current = 'player_profile'
    
    def open_player_scores(self):
        """Navigate to the Player Scores screen."""
        if self.current_league:
            scores_screen = self.manager.get_screen('player_scores')
            if hasattr(scores_screen, 'set_league'):
                scores_screen.set_league(self.current_league)
            self.manager.current = 'player_scores'
    
    def open_golf_course_info(self):
        """Navigate to the Golf Course Info screen."""
        if self.current_league:
            course_screen = self.manager.get_screen('golf_course_info')
            if hasattr(course_screen, 'set_league'):
                course_screen.set_league(self.current_league)
            self.manager.current = 'golf_course_info'
    
    def open_admin_screen(self):
        """Navigate to the Admin screen."""
        if self.current_league:
            admin_screen = self.manager.get_screen('admin')
            if hasattr(admin_screen, 'set_league'):
                admin_screen.set_league(self.current_league)
            self.manager.current = 'admin'
    
    def on_enter(self):
        """Called when this screen is displayed."""
        # If a league was previously selected, restore that state
        if self.current_league:
            # Re-show admin buttons for the selected league
            self.show_admin_buttons()
            
            # Update button colors and visibility based on selected league
            if self.current_league == 'monday':
                self.wednesday_btn.opacity = 0
                self.wednesday_btn.disabled = True
                self.monday_btn.opacity = 1
                self.monday_btn.disabled = False
                self.update_button_colors_for_monday()
            elif self.current_league == 'wednesday':
                self.monday_btn.opacity = 0
                self.monday_btn.disabled = True
                self.wednesday_btn.opacity = 1
                self.wednesday_btn.disabled = False
                self.update_button_colors_for_wednesday()
        else:
            # No league selected - show initial state
            self.player_selection_layout.height = '0dp'  # Hide player selection button
            self.footer_admin_layout.height = '0dp'  # Hide footer admin buttons
            
            # Restore both group buttons visibility
            self.monday_btn.opacity = 1
            self.monday_btn.disabled = False
            self.wednesday_btn.opacity = 1
            self.wednesday_btn.disabled = False
            
            # Remove buttons from layout and reset flag
            if self.buttons_added:
                self.player_selection_layout.clear_widgets()
                self.footer_admin_layout.clear_widgets()
                self.buttons_added = False