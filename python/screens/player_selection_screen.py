"""
Player Selection Screen for Golden Oaks Golf League
==================================================

This module contains the PlayerSelectionScreen class and its supporting UI components
for player selection and score entry functionality.
"""

import os
import sys

# Add parent directory to path for auto-sync imports
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))

# Kivy imports
from kivy.uix.screenmanager import Screen
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.floatlayout import FloatLayout
from kivy.uix.anchorlayout import AnchorLayout
from kivy.uix.gridlayout import GridLayout
from kivy.uix.scrollview import ScrollView
from kivy.uix.label import Label
from kivy.uix.widget import Widget
from kivy.uix.textinput import TextInput
from kivy.graphics import Color, Rectangle, Line, RoundedRectangle
from kivy.uix.behaviors import ButtonBehavior
from kivy.clock import Clock

# Standard library imports
import sqlite3
import random
from datetime import date
from kivy.metrics import dp

# Import unified popup system
try:
    from .popup_utils import QuickPopup
except ImportError:
    from popup_utils import QuickPopup

# Import prize table generation
try:
    from complete_prize_table import generate_complete_prize_table
except ImportError:
    def generate_complete_prize_table():
        # Fallback if module not found
        return {}, {}


class BorderedHeaderLabel(Label):
    """Header label with left and right borders."""
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        with self.canvas.after:
            Color(0, 0, 0, 1)  # Black color for borders
            self.left_border = Line(width=1)
            self.right_border = Line(width=1)
        self.bind(pos=self.update_borders, size=self.update_borders)
    
    def update_borders(self, *args):
        """Update border lines when label moves or resizes."""
        if hasattr(self, 'left_border') and hasattr(self, 'right_border'):
            # Left border
            self.left_border.points = [self.x, self.y, self.x, self.y + self.height]
            # Right border
            self.right_border.points = [self.x + self.width, self.y, self.x + self.width, self.y + self.height]


class NoBorderButton(ButtonBehavior, Label):
    def __init__(self, bg_color=(1, 1, 1, 1), **kwargs):
        super().__init__(**kwargs)
        self.bg_color = bg_color
        with self.canvas.before:
            # Background color with rounded corners (no border)
            Color(*bg_color)
            self.rect = RoundedRectangle(size=self.size, pos=self.pos, radius=[10])
        self.bind(size=self.update_graphics, pos=self.update_graphics)
    
    def update_graphics(self, *args):
        self.rect.size = self.size
        self.rect.pos = self.pos


class GreenTextInput(TextInput):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        # Use built-in background color instead of custom drawing
        self.background_color = (0.7, 1.0, 0.7, 1)  # Light green background
        # Set text properties for visibility
        self.foreground_color = (0, 0, 0, 1)  # Black text
        self.cursor_color = (0, 0, 0, 1)  # Black cursor
        self.selection_color = (0.3, 0.3, 0.3, 0.5)  # Dark gray selection
        # Center align the text horizontally and vertically
        self.halign = 'center'
        # Set font properties for better visibility
        self.font_size = '20sp'
        # Set consistent padding for all text inputs
        self.padding_y = [self.height / 2.0 - (self.line_height / 2.0) * len(self._lines), 0]
        self.bind(size=self.on_size)
    
    def on_size(self, instance, value):
        """Update padding when size changes to keep text centered."""
        self.padding_y = [self.height / 2.0 - (self.line_height / 2.0) * len(self._lines), 0]


class GoldenTextInput(TextInput):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        # Use built-in background color instead of custom drawing
        self.background_color = (1.0, 0.84, 0, 1)  # Gold background
        # Set text properties for visibility
        self.foreground_color = (0, 0, 0, 1)  # Black text
        self.cursor_color = (0, 0, 0, 1)  # Black cursor
        self.selection_color = (0.9, 0.9, 0.9, 0.5)  # Dark gray selection
        # Center align the text horizontally and vertically
        self.halign = 'center'
        # Set font properties for better visibility
        self.font_size = '20sp'
        # Set consistent padding for all text inputs
        self.padding_y = [self.height / 2.0 - (self.line_height / 2.0) * len(self._lines), 0]
        self.bind(size=self.on_size)
    
    def on_size(self, instance, value):
        """Update padding when size changes to keep text centered."""
        self.padding_y = [self.height / 2.0 - (self.line_height / 2.0) * len(self._lines), 0]


"""class GreyTextInput(TextInput):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        # Use built-in background color instead of custom drawing
        self.background_color = (0.9, 0.9, 0.9, 1)  # Light grey background
        # Set text properties for visibility
        self.foreground_color = (0, 0, 0, 1)  # Black text
        self.cursor_color = (0, 0, 0, 1)  # Black cursor
        self.selection_color = (0.3, 0.3, 0.3, 0.5)  # Dark gray selection
        # Center align the text horizontally and vertically
        self.halign = 'center'
        # Set font properties for better visibility
        self.font_size = '20sp'
        # Set consistent padding for all text inputs
        self.padding_y = [self.height / 2.0 - (self.line_height / 2.0) * len(self._lines), 0]
        self.bind(size=self.on_size)
        # Make it disabled by default
        self.disabled = True
    
    def on_size(self, instance, value):
        #Update padding when size changes to keep text centered.
        self.padding_y = [self.height / 2.0 - (self.line_height / 2.0) * len(self._lines), 0]"""


class ColoredButton(ButtonBehavior, Label):
    """A colored button with customizable background color and text color."""
    
    def __init__(self, bg_color=(1, 1, 1, 1), **kwargs):
        super().__init__(**kwargs)
        self.bg_color = bg_color
        self.corner_radius = dp(10)  # Rounded corner radius
        
        # Set up the background
        with self.canvas.before:
            Color(*bg_color)
            self.rect = RoundedRectangle(size=self.size, pos=self.pos, radius=[self.corner_radius])
        
        # Set up the border
        with self.canvas.after:
            Color(0, 0, 0, 1)  # Black border
            self.border = Line(rounded_rectangle=(self.x, self.y, self.width, self.height, self.corner_radius), width=2)
        
        # Bind size and position changes
        self.bind(size=self.update_graphics, pos=self.update_graphics)
    
    def update_graphics(self, *args):
        """Update the graphics when size or position changes."""
        self.rect.size = self.size
        self.rect.pos = self.pos
        self.border.rounded_rectangle = (self.x, self.y, self.width, self.height, self.corner_radius)


# Note: The complete PlayerSelectionScreen class is very large (1400+ lines)
# This is just a placeholder. The actual implementation would continue here...

class PlayerSelectionScreen(Screen):
    """
    Player selection screen converted from player_selection.py.
    Handles player selection for Monday and Wednesday groups.
    """
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.selected_league = 'monday'  # Default league
        self.player_vars = {}  # Store player checkbox data
        self.db_name = self.get_database_path()
        
        # Setup UI
        self.add_widget(self.setup_ui())
        
        # Load players after UI is created
        Clock.schedule_once(lambda dt: self.load_players(), 0.1)
    
    def set_league(self, league_type):
        """Set the league type (monday/wednesday) for this screen."""
        self.selected_league = league_type
        # Reload players for the new league
        self.load_players()
    
    def set_group(self, group_type):
        """Set the group type (monday/wednesday) for this screen."""
        print(f"PlayerSelectionScreen: set_group called with {group_type}")
        self.selected_league = group_type
    
    def get_database_path(self):
        """Get the path to the GoldenOaks.db database."""
        current_dir = os.path.dirname(os.path.abspath(__file__))
        parent_dir = os.path.dirname(current_dir)  # Go up one level from screens/ directory
        return os.path.join(parent_dir, 'GoldenOaks.db')
    
    def update_ui_for_league(self):
        """Update UI elements based on the selected league."""
        # Update title if it exists
        if hasattr(self, 'title_label'):
            title_text = "Select Players for Monday's Match" if self.selected_league == 'monday' else "Select Players for Wednesday's Match"
            self.title_label.text = title_text
        
        # Update Enter Player's Scores button color based on league
        if hasattr(self, 'show_btn'):
            show_btn_color = (0.7, 1.0, 0.7, 1) if self.selected_league == 'monday' else (1.0, 0.84, 0, 1)
            self.show_btn.bg_color = show_btn_color
            self.update_button_background(self.show_btn)
        
        # Update Check All button color based on league
        if hasattr(self, 'check_all_btn'):
            check_all_btn_color = (0.7, 1.0, 0.7, 1) if self.selected_league == 'monday' else (1.0, 0.84, 0, 1)
            self.check_all_btn.bg_color = check_all_btn_color
            self.update_button_background(self.check_all_btn)
    
    def on_enter(self):
        """Called when this screen is displayed."""
        # Update UI based on selected league
        self.update_ui_for_league()
    
    def return_to_main_menu(self, instance=None):
        """Return to the main menu screen."""
        self.clear_form()
        self.manager.current = 'unified_main_menu'
    
    def clear_form(self):
        """Clear all player selections."""
        if hasattr(self, 'player_vars'):
            for last_name, player_data in self.player_vars.items():
                checkbox = player_data['checkbox']
                checkbox.is_selected = False
                checkbox.text = ''  # Empty for unchecked
                checkbox.bg_color = (0.9, 0.9, 0.9, 1)  # Light gray
                
                # Force redraw of the checkbox
                checkbox.canvas.before.clear()
                with checkbox.canvas.before:
                    Color(*checkbox.bg_color)
                    checkbox.rect = RoundedRectangle(size=checkbox.size, pos=checkbox.pos, radius=[10])
                with checkbox.canvas.after:
                    Color(0, 0, 0, 1)  # Black border
                    checkbox.border = Line(rounded_rectangle=(checkbox.x, checkbox.y, checkbox.width, checkbox.height, 10), width=2)
    
    def update_button_background(self, button):
        """Update a button's background color by redrawing its canvas."""
        button.canvas.before.clear()
        with button.canvas.before:
            Color(*button.bg_color)
            button.rect = RoundedRectangle(size=button.size, pos=button.pos, radius=[10])
    
    def update_main_bg(self, instance, value):
        """Update main background rectangle when widget moves or resizes."""
        if hasattr(instance, 'bg_rect'):
            instance.bg_rect.pos = instance.pos
            instance.bg_rect.size = instance.size

    def setup_ui(self):
        main_layout = BoxLayout(orientation='vertical', padding=0, spacing=0)
        
        # Set light gray background for main layout
        with main_layout.canvas.before:
            Color(0.9, 0.9, 0.9, 1)  # Light gray background
            main_layout.bg_rect = Rectangle(pos=main_layout.pos, size=main_layout.size)
        main_layout.bind(pos=self.update_main_bg, size=self.update_main_bg)
        
        # Title - set based on selected league
        title_text = "Select Players for Monday's Match" if self.selected_league == 'monday' else "Select Players for Wednesday's Match"
        self.title_label = Label(
            text=title_text,
            font_size='20sp',
            bold=True,
            size_hint=(1, 0.05),
            color=(0, 0, 0, 1)
        )
        main_layout.add_widget(self.title_label)
        
        # Player selection content area - give it most of the screen space
        self.selection_content = self.setup_selection_tab()
        self.selection_content.size_hint_y = 0.85  # Take 85% of remaining space
        main_layout.add_widget(self.selection_content)
        
        # Check All button area - just above footer
        button_area = BoxLayout(
            orientation='horizontal',
            size_hint=(1, None),
            height='40dp',
            padding=(10, 5, 10, 5)
        )
        
        # Add white background to button area to match content
        with button_area.canvas.before:
            Color(1, 1, 1, 1)  # White background
            button_area.bg_rect = Rectangle(pos=button_area.pos, size=button_area.size)
        button_area.bind(pos=lambda instance, value: setattr(instance.bg_rect, 'pos', value),
                        size=lambda instance, value: setattr(instance.bg_rect, 'size', value))
        
        # Center the Check All button using AnchorLayout
        center_anchor = AnchorLayout(
            anchor_x='center',
            anchor_y='center'
        )
        
        # Check All button - color based on selected league
        check_all_btn_color = (0.7, 1.0, 0.7, 1) if self.selected_league == 'monday' else (1.0, 0.84, 0, 1)
        self.check_all_btn = ColoredButton(
            text="Check All",
            size_hint=(None, 1),
            width='80dp',
            font_size='12sp',
            bold=True,
            bg_color=check_all_btn_color,
            color=(0, 0, 0, 1)
        )
        self.check_all_btn.bind(on_press=lambda x: self.check_all_players())
        center_anchor.add_widget(self.check_all_btn)
        button_area.add_widget(center_anchor)
        
        main_layout.add_widget(button_area)
        
        # Footer with same structure as unified main menu
        footer_layout = BoxLayout(
            orientation='horizontal',
            size_hint=(1, None),
            height='200dp',
            padding=(20, 15, 20, 15),
            spacing=20
        )
        
        # Set light grey background for footer to match main menu
        with footer_layout.canvas.before:
            Color(0.9, 0.9, 0.9, 1)  # Light grey background
            footer_layout.bg_rect = Rectangle(pos=footer_layout.pos, size=footer_layout.size)
        footer_layout.bind(pos=self.update_footer_bg, size=self.update_footer_bg)
        
        # Center the button container
        center_layout = AnchorLayout(
            anchor_x='center',
            anchor_y='center',
            size_hint=(1, None),
            height='170sp'
        )
        
        button_container = BoxLayout(
            orientation='horizontal',
            spacing=20,
            size_hint=(None, None),
            height='170sp',
            width='620dp'  # 300dp + 300dp + 20dp spacing (removed test button)
        )
        
        # Return to Main Menu button
        return_btn = ColoredButton(
            text="Return to Main Menu",
            size_hint=(1, None),
            height='170sp',
            width='500dp',
            font_size='25sp',
            bold=True,
            bg_color=(0.7, 1.0, 1.0, 1),  # Light cyan
            color=(0, 0, 0, 1)
        )
        return_btn.bind(on_press=lambda x: self.return_to_main_menu())
        button_container.add_widget(return_btn)
        
        # Enter Player's Scores button - color based on selected league
        show_btn_color = (0.7, 1.0, 0.7, 1) if self.selected_league == 'monday' else (1.0, 0.84, 0, 1)
        self.show_btn = ColoredButton(
            text="Enter Player's Scores",
            size_hint=(1, None),
            height='170sp',
            width='500dp',
            font_size='25sp',
            bold=True,
            bg_color=show_btn_color,
            color=(0, 0, 0, 1),
            halign='center',
            valign='middle'
        )
        self.show_btn.bind(on_press=lambda x: self.show_selected_players())
        button_container.add_widget(self.show_btn)
        
        center_layout.add_widget(button_container)
        footer_layout.add_widget(center_layout)
        main_layout.add_widget(footer_layout)
        
        return main_layout

    def update_footer_bg(self, instance, value):
        """Update footer background rectangle when widget moves or resizes."""
        if hasattr(instance, 'bg_rect'):
            instance.bg_rect.pos = instance.pos
            instance.bg_rect.size = instance.size

    def setup_selection_tab(self):
        # Use FloatLayout to allow absolute positioning of the check-all button
        main_tab_layout = FloatLayout()
        
        # Add white background to selection tab
        with main_tab_layout.canvas.before:
            Color(1, 1, 1, 1)  # White background
            self.selection_rect = Rectangle(size=main_tab_layout.size, pos=main_tab_layout.pos)
        main_tab_layout.bind(size=self.update_selection_rect, pos=self.update_selection_rect)
        
        # Create the grid layout directly in the main layout, centered
        self.scrollable_layout = GridLayout(
            cols=4, 
            spacing=10, 
            size_hint=(0.95, None),  # Take 95% width, height based on content
            pos_hint={'center_x': 0.5, 'center_y': 0.5}
        )
        self.scrollable_layout.bind(minimum_height=self.scrollable_layout.setter('height'))
        
        # Add grid directly to main layout, centered
        main_tab_layout.add_widget(self.scrollable_layout)
        
        return main_tab_layout

    def update_selection_rect(self, instance, value):
        """Update the selection tab background rectangle."""
        self.selection_rect.size = instance.size
        self.selection_rect.pos = instance.pos


    def load_players(self):
        try:
            # Clear existing players if scrollable layout exists
            if hasattr(self, 'scrollable_layout'):
                self.scrollable_layout.clear_widgets()
                self.player_vars.clear()
            
            conn = sqlite3.connect(self.db_name)
            cursor = conn.cursor()

            # Filter players by the selected league
            cursor.execute("SELECT last, first, handicap, skat_number FROM players WHERE league = ? ORDER BY last", (self.selected_league,))
            players = cursor.fetchall()

            # Create list to store all player layouts
            player_layouts = []
            
            for player in players:
                last, first, handicap, skat_number = player
                full_name = f"{first} {last}"
                
                # Create player entry layout
                player_layout = BoxLayout(
                    orientation='horizontal',
                    size_hint_y=None,
                    height='40dp',
                    spacing=10
                )
                
                # Create checkbox container with center anchor for vertical centering
                checkbox_container = AnchorLayout(
                    anchor_x='left',
                    anchor_y='center',
                    size_hint=(None, 1),
                    width='30dp'
                )
                
                # Create checkbox button (toggle style) using simple approach
                checkbox = ColoredButton(
                    text='',
                    size_hint=(None, None),
                    size=('30dp', '30dp'),
                    font_size='20sp',
                    bg_color=(0.9, 0.9, 0.9, 1),  # Light gray background
                    color=(0, 0, 0, 1)
                )
                checkbox.is_selected = False
                checkbox.bind(on_press=lambda btn: self.toggle_checkbox(btn))
                
                # Store player data
                self.player_vars[last] = {
                    'checkbox': checkbox,
                    'first': first,
                    'handicap': handicap if handicap else 0,
                    'skat_number': skat_number if skat_number else ''
                }
                
                # Player name label
                name_label = Label(
                    text=full_name,
                    size_hint=(None, 1),
                    width='150dp',
                    color=(0, 0, 0, 1),
                    halign='left',
                    valign='middle',
                    font_size='20sp'
                )
                name_label.bind(size=name_label.setter('text_size'))
                
                checkbox_container.add_widget(checkbox)
                player_layout.add_widget(checkbox_container)
                player_layout.add_widget(name_label)
                
                player_layouts.append(player_layout)

            # Add players to grid in proper 3-column vertical order
            cols = 4
            total_players = len(player_layouts)
            
            if total_players > 0:
                # Calculate proper column distribution: 25 players = 9, 8, 8 per column
                players_per_col = total_players // cols  # 8
                extra_players = total_players % cols     # 1 
                
                # Determine column sizes (first columns get extra players)
                col_sizes = []
                for col in range(cols):
                    if col < extra_players:
                        col_sizes.append(players_per_col + 1)  # Column 1: 9 players
                    else:
                        col_sizes.append(players_per_col)      # Columns 2,3: 8 players each
                
                # Fill grid column by column with proper distribution
                max_rows = max(col_sizes) if col_sizes else 0
                for row in range(max_rows):
                    for col in range(cols):
                        if row < col_sizes[col]:  # Only if this column has a player at this row
                            # Calculate player index for this column and row
                            col_start = sum(col_sizes[:col])  # Starting index for this column
                            player_index = col_start + row
                            if player_index < total_players:
                                self.scrollable_layout.add_widget(player_layouts[player_index])

            conn.close()

        except Exception as e:
            QuickPopup.database_error(str(e))

    def toggle_checkbox(self, checkbox_btn):
        """Toggle the checkbox button state."""
        checkbox_btn.is_selected = not checkbox_btn.is_selected
        if checkbox_btn.is_selected:
            checkbox_btn.text = 'X'  # Just X for checked
            # Set color based on selected group
            if self.selected_league == 'monday':
                checkbox_btn.bg_color = (0.7, 1.0, 0.7, 1)  # Light green
            else:  # Wednesday
                checkbox_btn.bg_color = (1.0, 0.84, 0, 1)  # Light gold
        else:
            checkbox_btn.text = ''  # Empty for unchecked
            checkbox_btn.bg_color = (0.9, 0.9, 0.9, 1)  # Light gray
        
        # Force redraw of the checkbox
        checkbox_btn.canvas.before.clear()
        with checkbox_btn.canvas.before:
            Color(*checkbox_btn.bg_color)
            checkbox_btn.rect = RoundedRectangle(size=checkbox_btn.size, pos=checkbox_btn.pos, radius=[10])
        with checkbox_btn.canvas.after:
            Color(0, 0, 0, 1)  # Black border
            checkbox_btn.border = Line(rounded_rectangle=(checkbox_btn.x, checkbox_btn.y, checkbox_btn.width, checkbox_btn.height, 10), width=2)

    def show_selected_players(self):
        """Process selected players and switch to scores tab."""
        self.selected_players = []

        for last_name, player_data in self.player_vars.items():
            if player_data['checkbox'].is_selected:
                self.selected_players.append({
                    'last': last_name,
                    'first': player_data['first'],
                    'handicap': player_data['handicap'],
                    'skat_number': player_data['skat_number']
                })

        if not self.selected_players:
            QuickPopup.warning('No Players Selected', 'Please select at least one player.')
            return

        # Navigate to Payout Screen with selected players
        self.navigate_to_payout()
    
    def navigate_to_payout(self):
        """Navigate to the PayoutScreen with selected players data."""
        # Create groups of 4 players (similar to main_android_app.py logic)
        randomized_players = self.selected_players.copy()
        random.shuffle(randomized_players)
        
        # Create groups of 4 and sort each group by handicap (lowest first)
        groups = []
        for i in range(0, len(randomized_players), 4):
            group = randomized_players[i:i+4]
            # Sort each group by handicap (lowest handicap first)
            group.sort(key=lambda player: player['handicap'] if player['handicap'] else 999)
            groups.append(group)
        
        # Get the enter scores screen and pass data including group type
        enter_scores_screen = self.manager.get_screen('enter_scores')
        enter_scores_screen.set_players(self.selected_players, groups, self.selected_league)
        self.manager.current = 'enter_scores'
    
    def check_all_players(self):
        """Check all player checkboxes for testing purposes."""
        if hasattr(self, 'player_vars'):
            # Determine checkbox color based on selected league
            checkbox_color = (0.7, 1.0, 0.7, 1) if self.selected_league == 'monday' else (1.0, 0.84, 0, 1)
            
            for last_name, player_data in self.player_vars.items():
                checkbox = player_data['checkbox']
                checkbox.is_selected = True
                checkbox.text = 'X'  # X for selected (consistent with toggle method)
                checkbox.bg_color = checkbox_color
                
                # Force redraw of the checkbox
                checkbox.canvas.before.clear()
                with checkbox.canvas.before:
                    Color(*checkbox.bg_color)
                    checkbox.rect = RoundedRectangle(size=checkbox.size, pos=checkbox.pos, radius=[10])
                with checkbox.canvas.after:
                    Color(0, 0, 0, 1)  # Black border
                    checkbox.border = Line(rounded_rectangle=(checkbox.x, checkbox.y, checkbox.width, checkbox.height, 10), width=2)
