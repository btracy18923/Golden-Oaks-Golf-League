"""
Payout Screen for Golden Oaks Golf League
=========================================

This module contains the PayoutScreen class that handles the scores tab functionality
moved from PlayerSelectionScreen. Handles score entry, calculations, and payout management.
"""

import os
import sqlite3
import json
from datetime import date, datetime
from kivy.uix.screenmanager import Screen
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.scrollview import ScrollView
from kivy.uix.label import Label
from kivy.uix.textinput import TextInput
from kivy.uix.popup import Popup
from kivy.uix.widget import Widget
from kivy.uix.floatlayout import FloatLayout
from kivy.uix.anchorlayout import AnchorLayout
from kivy.graphics import Color, Rectangle, Line, RoundedRectangle
from kivy.uix.behaviors import ButtonBehavior
from kivy.clock import Clock
from kivy.metrics import dp

# Import unified popup system
try:
    from .popup_utils import QuickPopup, UnifiedPopup
except ImportError:
    from popup_utils import QuickPopup, UnifiedPopup


class ColoredButton(ButtonBehavior, Label):
    """Custom button with colored background."""
    def __init__(self, bg_color=(0.9, 0.9, 0.9, 1), **kwargs):
        super().__init__(**kwargs)
        self._bg_color = bg_color
        self.corner_radius = dp(10)
        with self.canvas.before:
            self.bg_color_instruction = Color(*bg_color)
            self.rect = RoundedRectangle(size=self.size, pos=self.pos, radius=[self.corner_radius])
        with self.canvas.after:
            Color(0, 0, 0, 1)
            self.border = Line(rounded_rectangle=(self.x, self.y, self.width, self.height, self.corner_radius), width=2)
        self.bind(size=self.update_graphics, pos=self.update_graphics)
        
        # Override disabled_color to prevent Kivy from dimming text
        self.disabled_color = self.color
    
    @property
    def bg_color(self):
        return self._bg_color
    
    @bg_color.setter
    def bg_color(self, value):
        self._bg_color = value
        if hasattr(self, 'bg_color_instruction'):
            self.bg_color_instruction.rgba = value
    
    def on_disabled(self, instance, value):
        """Override disabled behavior to maintain our custom colors."""
        # Don't call super() to avoid Kivy's default disabled styling
        pass
    
    def update_graphics(self, *args):
        self.rect.size = self.size
        self.rect.pos = self.pos
        self.border.rounded_rectangle = (self.x, self.y, self.width, self.height, self.corner_radius)


class BorderedHeaderLabel(Label):
    """Label with border for table headers."""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        with self.canvas.after:
            Color(0, 0, 0, 1)  # Black color for borders
            self.right_border_line = Line(width=1)
            self.bottom_border_line = Line(width=1)
        self.bind(size=self.update_borders, pos=self.update_borders)
    
    def update_borders(self, *args):
        """Update both right and bottom border lines when label moves or resizes."""
        if hasattr(self, 'right_border_line') and hasattr(self, 'bottom_border_line'):
            # Draw right border line
            self.right_border_line.points = [self.x + self.width, self.y, self.x + self.width, self.y + self.height]
            # Draw bottom border line
            self.bottom_border_line.points = [self.x, self.y, self.x + self.width, self.y]


class GoldenTextInput(TextInput):
    """Custom TextInput with golden styling and rounded corners."""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        # Use Kivy's built-in styling for maximum compatibility
        self.background_color = (1.0, 0.84, 0, 1)  # Light gold background
        self.foreground_color = (0, 0, 0, 1)  # Black text
        self.cursor_color = (0, 0, 0, 1)  # Black cursor
        self.selection_color = (0.8, 0.7, 0.3, 0.5)  # Selection highlight
        self.halign = 'center'  # Center align text horizontally
        self.font_size = '20sp'  # Consistent font size
        # Use simple padding for better compatibility
        self.padding = [10, (40 - 16) // 2, 10, (40 - 16) // 2]  # [x, top, x, bottom] - center for 40dp height
        
        # Add rounded border using canvas
        with self.canvas.after:
            Color(0, 0, 0, 1)  # Black border
            self.border_line = Line(rounded_rectangle=(self.x, self.y, self.width, self.height, 8), width=2)
        
        # Bind to update the border when size/position changes
        self.bind(size=self._update_border, pos=self._update_border)
    
    def _update_border(self, *args):
        """Update the border when size or position changes."""
        if hasattr(self, 'border_line'):
            self.border_line.rounded_rectangle = (self.x, self.y, self.width, self.height, 8)


class GreenTextInput(TextInput):
    """Custom TextInput with green styling and rounded corners for Monday groups."""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        # Use Kivy's built-in styling for maximum compatibility
        self.background_color = (0.7, 1.0, 0.7, 1)  # Light green background
        self.foreground_color = (0, 0, 0, 1)  # Black text
        self.cursor_color = (0, 0, 0, 1)  # Black cursor
        self.selection_color = (0.5, 0.8, 0.5, 0.5)  # Selection highlight
        self.halign = 'center'  # Center align text horizontally
        self.font_size = '20sp'  # Consistent font size
        # Use simple padding for better compatibility
        self.padding = [10, (40 - 16) // 2, 10, (40 - 16) // 2]  # [x, top, x, bottom] - center for 40dp height
        
        # Add rounded border using canvas
        with self.canvas.after:
            Color(0, 0, 0, 1)  # Black border
            self.border_line = Line(rounded_rectangle=(self.x, self.y, self.width, self.height, 8), width=2)
        
        # Bind to update the border when size/position changes
        self.bind(size=self._update_border, pos=self._update_border)
    
    def _update_border(self, *args):
        """Update the border when size or position changes."""
        if hasattr(self, 'border_line'):
            self.border_line.rounded_rectangle = (self.x, self.y, self.width, self.height, 8)


"""class GreyTextInput(TextInput):
    #Custom TextInput with grey styling and rounded corners (disabled appearance).
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        # Use Kivy's built-in styling for maximum compatibility
        self.background_color = (0.9, 0.9, 0.9, 1)  # Light grey background
        self.foreground_color = (0.5, 0.5, 0.5, 1)  # Dark grey text
        self.cursor_color = (0.5, 0.5, 0.5, 1)  # Dark grey cursor
        self.selection_color = (0.6, 0.6, 0.6, 0.5)  # Selection highlight
        self.halign = 'center'  # Center align text horizontally
        self.font_size = '20sp'  # Consistent font size
        self.padding = [10, (40 - 16) // 2, 10, (40 - 16) // 2]  # [x, top, x, bottom] - center for 40dp height
        self.disabled = True
        
        # Add rounded border using canvas
        with self.canvas.after:
            Color(0, 0, 0, 1)  # Black border
            self.border_line = Line(rounded_rectangle=(self.x, self.y, self.width, self.height, 8), width=2)
        
        # Bind to update the border when size/position changes
        self.bind(size=self._update_border, pos=self._update_border)
    
    def _update_border(self, *args):
        #Update the border when size or position changes.
        if hasattr(self, 'border_line'):
            self.border_line.rounded_rectangle = (self.x, self.y, self.width, self.height, 8)"""


class ColoredLabel(Label):
    """Label with colored background."""
    def __init__(self, bg_color=(1, 1, 1, 1), **kwargs):
        super().__init__(**kwargs)
        self.bg_color = bg_color
        with self.canvas.before:
            Color(*bg_color)
            self.bg_rect = Rectangle(size=self.size, pos=self.pos)
        # Add black border
        with self.canvas.after:
            Color(0, 0, 0, 1)  # Black border
            self.border_line = Line(rectangle=(self.x, self.y, self.width, self.height), width=1)
        self.bind(size=self.update_graphics, pos=self.update_graphics)
    
    def update_graphics(self, *args):
        self.bg_rect.size = self.size
        self.bg_rect.pos = self.pos
        self.border_line.rectangle = (self.x, self.y, self.width, self.height)


class NoBorderButton(ButtonBehavior, Label):
    """Button with no visible border, used for player names."""
    def __init__(self, bg_color=(1, 1, 1, 1), **kwargs):
        super().__init__(**kwargs)
        self._bg_color = bg_color
        with self.canvas.before:
            self.color_instruction = Color(*bg_color)
            self.rect = Rectangle(size=self.size, pos=self.pos)
        self.bind(size=self.update_graphics, pos=self.update_graphics)
    
    @property
    def bg_color(self):
        return self._bg_color
    
    @bg_color.setter
    def bg_color(self, value):
        self._bg_color = value
        if hasattr(self, 'color_instruction'):
            self.color_instruction.rgba = value
    
    def update_graphics(self, *args):
        self.rect.size = self.size
        self.rect.pos = self.pos


class EnterScoresScreen(Screen):
    """
    Enter Scores screen for managing player score entry.
    This was previously the scores tab in PlayerSelectionScreen.
    """
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.selected_league = 'monday'  # Default league
        self.db_name = self.get_database_path()
        self.selected_players = []
        self.groups = []
        self.selected_for_swap = []
        self.player_name_buttons = {}
        self.score_entries = {}
        self.score_entry_order = []
        self.grid_rows = []
        
        # Individual processing variables
        self.total_purse = 0.0
        self.individual_percent = 40
        self.group_percent = 60
        self.individual_purse = 0.0
        self.group_purse = 0.0
        self.winners_calculated = False
        
        # Setup UI
        self.add_widget(self.setup_ui())
    
    def set_league(self, league_type):
        """Set the league type (monday/wednesday) for this screen."""
        self.selected_league = league_type
        self.group_type = league_type  # Keep group_type in sync
        
        # Update title information if we have labels
        if hasattr(self, 'ante_label'):
            self.update_title_information()
        
        self.update_button_colors()
    
    def update_button_colors(self):
        """Update button colors based on selected league."""
        if hasattr(self, 'return_btn'):
            if self.selected_league == 'monday':
                new_color = (0.7, 1.0, 0.7, 1)  # Light green for Monday
            else:
                new_color = (1.0, 0.84, 0, 1)  # Light gold for Wednesday
            
            # Update the button's background color
            self.return_btn.bg_color = new_color
            # Update the canvas color
            with self.return_btn.canvas.before:
                Color(*new_color)
                self.return_btn.rect.size = self.return_btn.size
                self.return_btn.rect.pos = self.return_btn.pos
    
    def set_players(self, selected_players, groups, league_type):
        """Set the players, groups, and league type for this screen."""
        self.selected_players = selected_players
        self.groups = groups
        self.selected_league = league_type
    
    def get_database_path(self):
        """Get the path to the GoldenOaks.db database."""
        script_dir = os.path.dirname(os.path.abspath(__file__))
        parent_dir = os.path.dirname(script_dir)
        return os.path.join(parent_dir, "GoldenOaks.db")
    
    def setup_ui(self):
        """Setup the main UI for the payout screen."""
        main_layout = BoxLayout(orientation='vertical', padding=0, spacing=0)
        
        # Title with comprehensive game information in left-aligned layout
        title_container = BoxLayout(
            orientation='horizontal',
            size_hint=(1, 0.05),
            padding=(10, 5, 10, 5),
            spacing=10
        )
        
        # Add light grey background to title container
        with title_container.canvas.before:
            Color(0.9, 0.9, 0.9, 1)  # Light grey background
            title_container.bg_rect = Rectangle(size=title_container.size, pos=title_container.pos)
        title_container.bind(size=lambda instance, value: setattr(instance.bg_rect, 'size', value),
                           pos=lambda instance, value: setattr(instance.bg_rect, 'pos', value))
        
        # Left-aligned Enter Scores Screen title
        title_label = Label(
            text="Enter Scores Screen",
            font_size='20sp',
            bold=True,
            size_hint=(None, 1),
            width='200dp',
            color=(0, 0, 0, 1),
            halign='left',
            valign='middle'
        )
        title_label.bind(size=title_label.setter('text_size'))
        title_container.add_widget(title_label)
        
        # Center wrapper to center the game info container accounting for title width
        center_wrapper = BoxLayout(
            orientation='horizontal',
            size_hint=(1, 1)
        )
        
        # Left spacer - needs to account for the 200dp title width to center properly
        # For true centering: left_spacer = (total_width - game_info_width) / 2 - title_width
        # We'll use a ratio: left spacer gets less space, right spacer gets more
        left_spacer = Widget(size_hint=(0.3, 1))  # Smaller left spacer
        center_wrapper.add_widget(left_spacer)
        
        # Game info container with fixed width
        game_info_container = BoxLayout(
            orientation='horizontal',
            size_hint=(None, 1),
            width='650dp',  # Fixed width to contain all game info
            spacing=10
        )
        
        # Player Ante information
        self.ante_label = Label(
            text="Player Ante = $6.00",
            font_size='16sp',
            bold=True,
            size_hint=(None, 1),
            width='140dp',
            color=(0, 0, 0, 1),
            halign='center',
            valign='middle'
        )
        self.ante_label.bind(size=self.ante_label.setter('text_size'))
        game_info_container.add_widget(self.ante_label)
        
        # Number of players
        self.num_players_label = Label(
            text="# Players = 0",
            font_size='16sp',
            bold=True,
            size_hint=(None, 1),
            width='120dp',
            color=(0, 0, 0, 1),
            halign='center',
            valign='middle'
        )
        self.num_players_label.bind(size=self.num_players_label.setter('text_size'))
        game_info_container.add_widget(self.num_players_label)
        
        # Individual percentage
        self.individual_percent_label = Label(
            text="Individual % = 40%",
            font_size='16sp',
            bold=True,
            size_hint=(None, 1),
            width='150dp',
            color=(0, 0, 0, 1),
            halign='center',
            valign='middle'
        )
        self.individual_percent_label.bind(size=self.individual_percent_label.setter('text_size'))
        game_info_container.add_widget(self.individual_percent_label)
        
        # Total Player's Purse
        self.players_purse_label = Label(
            text="Total Player's Purse = $0.00",
            font_size='16sp',
            bold=True,
            size_hint=(None, 1),
            width='230dp',  # Fixed width instead of expanding
            color=(0, 0, 0, 1),
            halign='center',
            valign='middle'
        )
        self.players_purse_label.bind(size=self.players_purse_label.setter('text_size'))
        game_info_container.add_widget(self.players_purse_label)
        
        center_wrapper.add_widget(game_info_container)
        
        # Right spacer - larger to compensate for title on left
        right_spacer = Widget(size_hint=(0.7, 1))  # Larger right spacer
        center_wrapper.add_widget(right_spacer)
        
        title_container.add_widget(center_wrapper)
        
        main_layout.add_widget(title_container)
        
        # Main content area
        content_area = self.setup_payout_content()
        main_layout.add_widget(content_area)
        
        # Footer with same structure as player selection screen
        footer_layout = BoxLayout(
            orientation='horizontal',
            size_hint=(1, None),
            height='130dp',
            padding=(30, 15, 30, 15),
            spacing=20
        )
        
        # Set light grey background for footer
        with footer_layout.canvas.before:
            Color(0.9, 0.9, 0.9, 1)  # Light grey background
            footer_layout.bg_rect = Rectangle(pos=footer_layout.pos, size=footer_layout.size)
        footer_layout.bind(pos=self.update_footer_bg, size=self.update_footer_bg)
        
        # Center the button container
        center_layout = AnchorLayout(
            anchor_x='center',
            anchor_y='center',
            size_hint=(1, None),
            height='100sp'
        )
        
        button_container = BoxLayout(
            orientation='horizontal',
            spacing=20,
            size_hint=(1, None),  # Use full width, responsive
            height='100sp'
        )
        
        # Return to Main Menu button
        menu_btn = ColoredButton(
            text="Return to Main Menu",
            size_hint=(0.2, 1),  # 20% of width
            font_size='25sp',
            bold=True,
            bg_color=(0.7, 1.0, 1.0, 1),  # Light-cyan
            color=(0, 0, 0, 1)
        )
        menu_btn.bind(on_press=lambda x: self.return_to_main_menu())
        button_container.add_widget(menu_btn)
        
        # Return to Player Selection button - color will be updated when league is set
        self.return_btn = ColoredButton(
            text="Return to Player Selection",
            size_hint=(0.2, 1),  # 20% of width
            font_size='25sp',
            bold=True,
            bg_color=(1.0, 0.84, 0, 1),  # Default to Wednesday color
            color=(0, 0, 0, 1)
        )
        self.return_btn.bind(on_press=lambda x: self.return_to_player_selection())
        button_container.add_widget(self.return_btn)
        
        # Process Individuals button
        self.payouts_btn = ColoredButton(
            text="Process Individuals",
            size_hint=(0.2, 1),  # 20% of width
            font_size='25sp',
            bold=True,
            bg_color=(0.9, 0.9, 0.9, 1),  # Light grey
            color=(0, 0, 0, 1)
        )
        self.payouts_btn.bind(on_press=lambda x: self.process_individuals())
        button_container.add_widget(self.payouts_btn)
        
        # Process Groups button
        self.process_groups_btn = ColoredButton(
            text="Process Groups",
            size_hint=(0.2, 1),  # 20% of width
            font_size='25sp',
            bold=True,
            bg_color=(0.9, 0.9, 0.9, 1),  # Light grey
            color=(0, 0, 0, 1)
        )
        self.process_groups_btn.bind(on_press=lambda x: self.navigate_to_player_payout())
        button_container.add_widget(self.process_groups_btn)
        
        # SWAP button - moved from left panel, now shows prompts
        self.swap_btn = ColoredButton(
            text="Click Two Player Names\nto SWAP",
            size_hint=(0.2, 1),  # 20% of width
            font_size='20sp',
            bold=True,
            bg_color=(0.8, 0.8, 0.8, 1),  # Medium grey
            color=(0, 0, 0, 1),
            halign='center',
            valign='middle'
        )
        self.swap_btn.bind(on_press=self.perform_swap)
        self.swap_btn.disabled = True
        button_container.add_widget(self.swap_btn)
        
        center_layout.add_widget(button_container)
        footer_layout.add_widget(center_layout)
        main_layout.add_widget(footer_layout)
        
        return main_layout

    def update_footer_bg(self, instance, value):
        """Update footer background rectangle when widget moves or resizes."""
        if hasattr(instance, 'bg_rect'):
            instance.bg_rect.pos = instance.pos
            instance.bg_rect.size = instance.size
    
    def setup_payout_content(self):
        """Setup the main payout content (moved from setup_scores_tab)."""
        tab_layout = BoxLayout(orientation='vertical', padding=10, spacing=10)
        
        # Determine background color based on group type (defaults to Wednesday if not set)
        if hasattr(self, 'group_type') and self.group_type == 'monday':
            label_bg_color = (0.7, 1.0, 0.7, 1)  # Light green for Monday
        else:
            label_bg_color = (1.0, 0.84, 0, 1)  # Light gold for Wednesday
        
        # Add white background
        with tab_layout.canvas.before:
            Color(1, 1, 1, 1)  # White background
            self.scores_rect = Rectangle(size=tab_layout.size, pos=tab_layout.pos)
        tab_layout.bind(size=self.update_scores_rect, pos=self.update_scores_rect)
        
        # Main container - now just the score table (full width)
        main_container = BoxLayout(orientation='vertical')
        
        # Three-section horizontal layout for groups (max 9 groups: 3 per section)
        sections_container = BoxLayout(orientation='horizontal', spacing=10, padding=[5, 0, 5, 0])
        
        # Create 3 sections, each will hold up to 3 groups
        self.section_layouts = []
        for section_num in range(3):
            # Wrapper to anchor content to top
            section_wrapper = AnchorLayout(anchor_x='center', anchor_y='top')
            
            # Container for groups in this section
            section_groups_layout = BoxLayout(orientation='vertical', spacing=3, size_hint_y=None)
            section_groups_layout.bind(minimum_height=section_groups_layout.setter('height'))
            
            section_wrapper.add_widget(section_groups_layout)
            self.section_layouts.append(section_groups_layout)
            sections_container.add_widget(section_wrapper)
        
        main_container.add_widget(sections_container)
        tab_layout.add_widget(main_container)
        
        return tab_layout
    
    def update_scores_rect(self, instance, value):
        """Update the scores tab background rectangle."""
        self.scores_rect.size = instance.size
        self.scores_rect.pos = instance.pos
    
    
    def set_players(self, selected_players, groups, group_type='monday'):
        """Set the selected players and groups for this payout screen."""
        self.selected_players = selected_players
        self.groups = groups
        self.group_type = group_type
        
        # Update player data with current skat_number from database
        self.update_player_skat_numbers()
        
        # Clear existing score entries and populate with new players
        for section_layout in self.section_layouts:
            section_layout.clear_widgets()
        self.score_entries = {}
        self.score_entry_order = []  # Will store score inputs in order for navigation
        self.grid_rows = []
        self.selected_for_swap = []
        self.player_name_buttons = {}
        
        # Update title information with current data
        self.update_title_information()
        
        # Populate the score table with selected players
        self.populate_score_table()
    
    def update_title_information(self):
        """Update the title bar with current game information."""
        # Get ante amount based on league type (default values)
        ante_amount = 12.00 if self.selected_league == 'monday' else 6.00
        
        # Try to get ante from Admin Screen if available
        try:
            if hasattr(self.manager, 'get_screen'):
                admin_screen = self.manager.get_screen('admin')
                if hasattr(admin_screen, 'ante_input') and admin_screen.ante_input.text:
                    ante_text = admin_screen.ante_input.text.replace('$', '')
                    ante_amount = float(ante_text) if ante_text else ante_amount
        except:
            pass  # Use default values if admin screen not available
        
        # Count total number of players
        num_players = 0
        for group in self.groups:
            num_players += len([player for player in group if player is not None])
        
        # Calculate total purse
        total_purse = num_players * ante_amount
        
        # Get individual percentage (default 40%)
        individual_percent = 40
        try:
            if hasattr(self.manager, 'get_screen'):
                admin_screen = self.manager.get_screen('admin')
                if hasattr(admin_screen, 'prefill_input') and admin_screen.prefill_input.text:
                    individual_percent = int(admin_screen.prefill_input.text) if admin_screen.prefill_input.text else 40
        except:
            pass  # Use default if admin screen not available
        
        # Calculate total player's purse (individual percentage of total purse)
        players_purse = total_purse * (individual_percent / 100)
        
        # Update all title labels (excluding Total Purse)
        self.ante_label.text = f"Player Ante = ${ante_amount:.2f}"
        self.num_players_label.text = f"# Players = {num_players}"
        self.individual_percent_label.text = f"Individual % = {individual_percent}%"
        self.players_purse_label.text = f"Total Player's Purse = ${players_purse:.2f}"
    
    def update_player_skat_numbers(self):
        """Update player data with current skat_number from database."""
        try:
            conn = sqlite3.connect(self.db_name)
            cursor = conn.cursor()
            
            # Update skat_number for each player in groups
            for group in self.groups:
                for player in group:
                    cursor.execute(
                        "SELECT skat_number FROM players WHERE first = ? AND last = ? AND league = ?",
                        (player['first'], player['last'], self.selected_league)
                    )
                    result = cursor.fetchone()
                    if result:
                        player['skat_number'] = result[0] if result[0] else ''
            
            conn.close()
            
        except Exception as e:
            # Continue with existing skat_number data if database query fails
            pass
    
    def populate_score_table(self):
        """Populate the score table with selected players distributed across 3 sections."""
        # Collect widgets for each section to add in correct order
        section_widgets = [[] for _ in range(3)]
        
        # Always show 9 groups (3 sections × 3 groups each)
        for group_num in range(1, 10):  # Groups 1-9
            # Determine which section this group belongs to (0, 1, or 2)
            section_index = (group_num - 1) // 3
            
            # Get the group data if it exists, otherwise use empty group
            if group_num <= len(self.groups):
                group = self.groups[group_num - 1]
            else:
                group = []  # Empty group
            
            # Group header with border for Group 1 to visualize layout
            group_header_container = BoxLayout(
                orientation='horizontal',
                size_hint_y=None,
                height='30dp'
            )
            
            # Add left padding to shift header right
            #group_header_container.add_widget(Widget(size_hint=(None, 1), width='5dp'))
            
            group_header = Label(
                text=f'------------------Group {group_num}------------------',
                font_size='20sp',
                bold=True,
                size_hint=(None, 1),
                width='400dp',  # 140dp Same width as Name column
                color=(0, 0, 0, 1),
                halign='center',
                valign='middle'
            )
            group_header.bind(size=group_header.setter('text_size'))
            group_header_container.add_widget(group_header)
            
            # Add right spacer to fill remaining space
            group_header_container.add_widget(Widget())
            
            
            section_widgets[section_index].append(group_header_container)
            
            # Add column headers for Group 1, 4, and 7 (start of each section)
            if group_num in [1, 4, 7]:
                header_layout = BoxLayout(
                    orientation='horizontal',
                    size_hint_y=None,
                    height='25dp',
                    spacing=15
                )
                
                # Name header
                name_header = Label(
                    text='Name',
                    size_hint=(None, 1),
                    width='120dp',
                    color=(0, 0, 0, 1),
                    halign='center',
                    valign='middle',
                    font_size='15sp',
                    bold=True
                )
                name_header.bind(size=name_header.setter('text_size'))
                header_layout.add_widget(name_header)
                
                # HC header - only show for Wednesday league
                if self.group_type == 'wednesday':
                    hc_header = Label(
                        text='HC',
                        size_hint=(None, 1),
                        width='60dp',
                        color=(0, 0, 0, 1),
                        halign='center',
                        valign='middle',
                        font_size='15sp',
                        bold=True
                    )
                    hc_header.bind(size=hc_header.setter('text_size'))
                    header_layout.add_widget(hc_header)
                
                # Gross header
                gross_header = Label(
                    text='Gross',
                    size_hint=(None, 1),
                    width='70dp',
                    color=(0, 0, 0, 1),
                    halign='center',
                    valign='middle',
                    font_size='15sp',
                    bold=True
                )
                gross_header.bind(size=gross_header.setter('text_size'))
                header_layout.add_widget(gross_header)
                
                # Net header - only show for Wednesday league
                if self.group_type == 'wednesday':
                    net_header = Label(
                        text='Net',
                        size_hint=(None, 1),
                        width='50dp',
                        color=(0, 0, 0, 1),
                        halign='center',
                        valign='middle',
                        font_size='15sp',
                        bold=True
                    )
                    net_header.bind(size=net_header.setter('text_size'))
                    header_layout.add_widget(net_header)
                    
                    # Place header - only show for Wednesday league
                    place_header = Label(
                        text='Place',
                        size_hint=(None, 1),
                        width='50dp',
                        color=(0, 0, 0, 1),
                        halign='center',
                        valign='middle',
                        font_size='15sp',
                        bold=True
                    )
                    place_header.bind(size=place_header.setter('text_size'))
                    header_layout.add_widget(place_header)
                    
                    # IND-Win header - only show for Wednesday league
                    ind_header = Label(
                        text='Ind-Win',
                        size_hint=(None, 1),
                        width='70dp',
                        color=(0, 0, 0, 1),
                        halign='center',
                        valign='middle',
                        font_size='15sp',
                        bold=True
                    )
                    ind_header.bind(size=ind_header.setter('text_size'))
                    header_layout.add_widget(ind_header)
                
                # Add SKAT headers for Monday groups
                if self.group_type == 'monday':
                    skat_header = Label(
                        text='SKAT#',
                        size_hint=(None, 1),
                        width='60dp',
                        color=(0, 0, 0, 1),
                        halign='center',
                        valign='middle',
                        font_size='15sp',
                        bold=True
                    )
                    skat_header.bind(size=skat_header.setter('text_size'))
                    header_layout.add_widget(skat_header)
                    
                    skats_header = Label(
                        text='SKATS',
                        size_hint=(None, 1),
                        width='80dp',
                        color=(0, 0, 0, 1),
                        halign='center',
                        valign='middle',
                        font_size='15sp',
                        bold=True
                    )
                    skats_header.bind(size=skats_header.setter('text_size'))
                    header_layout.add_widget(skats_header)
                
                section_widgets[section_index].append(header_layout)

            # Always create 4 rows per group (filled with players or empty placeholders)
            for row_index in range(4):
                # Create player score row
                row_layout = BoxLayout(
                    orientation='horizontal',
                    size_hint_y=None,
                    height='40dp',
                    spacing=15
                )
                
                # Check if there's a player for this row
                player = group[row_index] if row_index < len(group) else None
                
                if player:
                    # Last name - make it clickable for swapping (updated width for 3-section layout)
                    name_button = NoBorderButton(
                        text=player['last'],
                        size_hint=(None, 1),
                        width='120dp',
                        font_size='20sp',
                        bg_color=(1, 1, 1, 1),  # White background
                        color=(0, 0, 0, 1)
                    )
                    name_button.player_data = player
                    name_button.group_index = group_num - 1
                    name_button.bind(on_press=self.on_player_name_click)
                    
                    # Store reference to name button
                    self.player_name_buttons[player['last']] = name_button
                    row_layout.add_widget(name_button)
                else:
                    # Empty placeholder for name - make it clickable for swapping
                    name_placeholder = NoBorderButton(
                        text='',
                        size_hint=(None, 1),
                        width='120dp',
                        color=(0, 0, 0, 1),
                        bg_color=(1, 1, 1, 1)  # White background
                    )
                    # Set up empty slot data for swapping
                    name_placeholder.player_data = None
                    name_placeholder.group_index = group_num - 1
                    name_placeholder.row_index = row_index
                    name_placeholder.bind(on_press=self.on_empty_slot_click)
                    
                    # Add border for empty placeholder
                    with name_placeholder.canvas.after:
                        Color(0, 0, 0, 1)  # Black border
                        name_placeholder.border_line = Line(rectangle=(0, 0, 0, 0), width=1)
                    name_placeholder.bind(pos=lambda instance, value: setattr(instance.border_line, 'rectangle', 
                                       (instance.x, instance.y, instance.width, instance.height)),
                                      size=lambda instance, value: setattr(instance.border_line, 'rectangle', 
                                       (instance.x, instance.y, instance.width, instance.height)))
                    
                    # Store reference to empty slot button using unique key
                    empty_slot_key = f"empty_{group_num}_{row_index}"
                    self.player_name_buttons[empty_slot_key] = name_placeholder
                    row_layout.add_widget(name_placeholder)
                
                if player:
                    # Handicap (only show for Wednesday league)
                    if self.group_type == 'wednesday':
                        hc_label = Label(
                            text=str(player['handicap']),
                            size_hint=(None, 1),
                            width='60dp',
                            color=(0, 0, 0, 1),
                            halign='center',
                            valign='middle',
                            font_size='20sp'
                        )
                        hc_label.bind(size=hc_label.setter('text_size'))
                        
                        # Add border for HC label
                        with hc_label.canvas.after:
                            Color(0, 0, 0, 1)  # Black border
                            hc_label.border_line = Line(rectangle=(0, 0, 0, 0), width=1)
                        hc_label.bind(pos=lambda instance, value: setattr(instance.border_line, 'rectangle', 
                                       (instance.x, instance.y, instance.width, instance.height)),
                                      size=lambda instance, value: setattr(instance.border_line, 'rectangle', 
                                       (instance.x, instance.y, instance.width, instance.height)))
                        
                        row_layout.add_widget(hc_label)
                    
                    # Score entry - color based on group type (updated width for 3-section layout)
                    # Check if player has existing gross score data to display
                    gross_text = ''
                    if player and player.get('gross_score') is not None:
                        gross_text = str(player['gross_score'])
                    
                    if self.group_type == 'wednesday':
                        score_input = GoldenTextInput(
                            text=gross_text,
                            multiline=False,
                            size_hint=(None, 1),
                            width='70dp',
                            input_filter='int',
                            font_size='20sp'
                        )
                    else:  # Monday
                        score_input = GreenTextInput(
                            text=gross_text,
                            multiline=False,
                            size_hint=(None, 1),
                            width='70dp',
                            input_filter='int',
                            font_size='20sp'
                        )
                    score_input.bind(text=lambda instance, value, last=player['last']: self.handle_gross_score_input(instance, last, value))
                    row_layout.add_widget(score_input)
                    
                    # Add to score entry order for navigation (Gross field first)
                    self.score_entry_order.append(score_input)
                else:
                    # Empty placeholders for columns when no player
                    # Handicap placeholder (only show for Wednesday league)
                    if self.group_type == 'wednesday':
                        hc_placeholder = Label(
                            text='',
                            size_hint=(None, 1),
                            width='60dp',
                            color=(0, 0, 0, 1)
                        )
                        # Add border for HC placeholder
                        with hc_placeholder.canvas.after:
                            Color(0, 0, 0, 1)  # Black border
                            hc_placeholder.border_line = Line(rectangle=(0, 0, 0, 0), width=1)
                        hc_placeholder.bind(pos=lambda instance, value: setattr(instance.border_line, 'rectangle', 
                                           (instance.x, instance.y, instance.width, instance.height)),
                                          size=lambda instance, value: setattr(instance.border_line, 'rectangle', 
                                           (instance.x, instance.y, instance.width, instance.height)))
                        row_layout.add_widget(hc_placeholder)
                    
                    # Score placeholder
                    score_placeholder = Label(
                        text='',
                        size_hint=(None, 1),
                        width='70dp',
                        color=(0, 0, 0, 1)
                    )
                    # Add border for score placeholder
                    with score_placeholder.canvas.after:
                        Color(0, 0, 0, 1)  # Black border
                        score_placeholder.border_line = Line(rectangle=(0, 0, 0, 0), width=1)
                    score_placeholder.bind(pos=lambda instance, value: setattr(instance.border_line, 'rectangle', 
                                           (instance.x, instance.y, instance.width, instance.height)),
                                          size=lambda instance, value: setattr(instance.border_line, 'rectangle', 
                                           (instance.x, instance.y, instance.width, instance.height)))
                    row_layout.add_widget(score_placeholder)
                
                # Net score label (only show for Wednesday league)
                net_label = None
                if self.group_type == 'wednesday':
                    # Check if player has existing net score data to display
                    net_text = ''
                    if player and player.get('net_score') is not None:
                        net_text = str(int(player['net_score']))
                    
                    net_label = Label(
                        text=net_text,
                        size_hint=(None, 1),
                        width='50dp',
                        color=(0, 0, 0, 1),
                        halign='center',
                        valign='middle',
                        font_size='20sp'
                    )
                    net_label.bind(size=net_label.setter('text_size'))
                    
                    # Add border for Net label
                    with net_label.canvas.after:
                        Color(0, 0, 0, 1)  # Black border
                        net_label.border_line = Line(rectangle=(0, 0, 0, 0), width=1)
                    net_label.bind(pos=lambda instance, value: setattr(instance.border_line, 'rectangle', 
                                   (instance.x, instance.y, instance.width, instance.height)),
                                  size=lambda instance, value: setattr(instance.border_line, 'rectangle', 
                                   (instance.x, instance.y, instance.width, instance.height)))
                    
                    row_layout.add_widget(net_label)
                    
                    # Place field (only show for Wednesday league) - display place ranking
                    if player:  # Check if player is not None
                        # Only show place ranking if player has winnings > 0
                        winnings = player.get('winnings', 0.0)
                        if winnings > 0:
                            place_text = player.get('place', '')
                        else:
                            place_text = ''
                    else:
                        # Empty slot
                        place_text = ''
                        
                    place_label = Label(
                        text=place_text,
                        size_hint=(None, 1),
                        width='50dp',
                        color=(0, 0, 0, 1),
                        halign='center',
                        valign='middle',
                        font_size='20sp'
                    )
                    place_label.bind(size=place_label.setter('text_size'))
                    
                    # Add border for Place label
                    with place_label.canvas.after:
                        Color(0, 0, 0, 1)  # Black border
                        place_label.border_line = Line(rectangle=(0, 0, 0, 0), width=1)
                    place_label.bind(pos=lambda instance, value: setattr(instance.border_line, 'rectangle', 
                                   (instance.x, instance.y, instance.width, instance.height)),
                                  size=lambda instance, value: setattr(instance.border_line, 'rectangle', 
                                   (instance.x, instance.y, instance.width, instance.height)))
                    
                    row_layout.add_widget(place_label)
                    
                    # IND field (only show for Wednesday league) - display individual winnings
                    if player:  # Check if player is not None
                        # Only show winnings if player has winnings > 0
                        ind_value = player.get('winnings', 0.0)
                        if ind_value > 0:
                            ind_text = f"${ind_value:.2f}"
                        else:
                            ind_text = ''
                    else:
                        # Empty slot
                        ind_text = ''
                        
                    ind_label = Label(
                        text=ind_text,
                        size_hint=(None, 1),
                        width='70dp',
                        color=(0, 0, 0, 1),
                        halign='center',
                        valign='middle',
                        font_size='20sp'
                    )
                    ind_label.bind(size=ind_label.setter('text_size'))
                    
                    # Add border for IND label
                    with ind_label.canvas.after:
                        Color(0, 0, 0, 1)  # Black border
                        ind_label.border_line = Line(rectangle=(0, 0, 0, 0), width=1)
                    ind_label.bind(pos=lambda instance, value: setattr(instance.border_line, 'rectangle', 
                                   (instance.x, instance.y, instance.width, instance.height)),
                                  size=lambda instance, value: setattr(instance.border_line, 'rectangle', 
                                   (instance.x, instance.y, instance.width, instance.height)))
                    
                    row_layout.add_widget(ind_label)
                
                # Add SKAT columns only for Monday groups
                skats_input = None
                if self.group_type == 'monday':
                    if player:
                        # SKAT Number (updated width for 3-section layout)
                        skat_label = Label(
                            text=str(player['skat_number']) if player['skat_number'] else '',
                            size_hint=(None, 1),
                            width='60dp',
                            color=(0, 0, 0, 1),
                            halign='center',
                            valign='middle',
                            font_size='20sp'
                        )
                        skat_label.bind(size=skat_label.setter('text_size'))
                        row_layout.add_widget(skat_label)
                        
                        # SKATS entry - green input for Monday (updated width for 3-section layout)
                        # Check if player has existing skats score data to display
                        skats_text = ''
                        if player and player.get('skats_score') is not None:
                            skats_text = str(player['skats_score'])
                        
                        skats_input = GreenTextInput(
                            text=skats_text,
                            multiline=False,
                            size_hint=(None, 1),
                            width='80dp',
                            input_filter='int',
                            font_size='20sp'
                        )
                        # Add SKATS input to navigation order for Monday groups only
                        skats_input.bind(text=lambda instance, value: self.handle_skats_input(instance, value))
                        self.score_entry_order.append(skats_input)
                        row_layout.add_widget(skats_input)
                    else:
                        # SKAT Number placeholder
                        skat_placeholder = Label(
                            text='',
                            size_hint=(None, 1),
                            width='60dp',
                            color=(0, 0, 0, 1)
                        )
                        # Add border for SKAT placeholder
                        with skat_placeholder.canvas.after:
                            Color(0, 0, 0, 1)  # Black border
                            skat_placeholder.border_line = Line(rectangle=(0, 0, 0, 0), width=1)
                        skat_placeholder.bind(pos=lambda instance, value: setattr(instance.border_line, 'rectangle', 
                                               (instance.x, instance.y, instance.width, instance.height)),
                                              size=lambda instance, value: setattr(instance.border_line, 'rectangle', 
                                               (instance.x, instance.y, instance.width, instance.height)))
                        row_layout.add_widget(skat_placeholder)
                        
                        # SKATS placeholder
                        skats_placeholder = Label(
                            text='',
                            size_hint=(None, 1),
                            width='80dp',
                            color=(0, 0, 0, 1)
                        )
                        # Add border for SKATS placeholder
                        with skats_placeholder.canvas.after:
                            Color(0, 0, 0, 1)  # Black border
                            skats_placeholder.border_line = Line(rectangle=(0, 0, 0, 0), width=1)
                        skats_placeholder.bind(pos=lambda instance, value: setattr(instance.border_line, 'rectangle', 
                                               (instance.x, instance.y, instance.width, instance.height)),
                                              size=lambda instance, value: setattr(instance.border_line, 'rectangle', 
                                               (instance.x, instance.y, instance.width, instance.height)))
                        row_layout.add_widget(skats_placeholder)
                
                # Store references for score calculations (only for actual players)
                if player:
                    self.score_entries[player['last']] = {
                        'score_input': score_input,
                        'net_label': net_label,
                        'skats_input': skats_input,
                        'player_data': player,
                        'group_num': group_num
                    }
                
                section_widgets[section_index].append(row_layout)
        
        # Add all widgets to their respective sections in correct order (Group 1 at top)
        for section_index, widgets in enumerate(section_widgets):
            for widget in widgets:
                self.section_layouts[section_index].add_widget(widget)
    
    def handle_gross_score_input(self, instance, last_name, value):
        """Handle gross score input, calculate net score, and auto-focus next field."""
        if value and value.isdigit():
            # Only calculate handicap and net score for 2-digit entries
            if len(value) == 2:
                gross_score = int(value)
                
                # Only calculate and display net score for Wednesday league
                if self.group_type == 'wednesday':
                    player_data = self.score_entries[last_name]['player_data']
                    handicap = player_data['handicap'] if player_data['handicap'] else 0
                    net_score = gross_score - handicap
                    # Display net score as number only for Wednesday groups
                    if self.score_entries[last_name]['net_label']:
                        self.score_entries[last_name]['net_label'].text = str(net_score)
                
                # Auto-focus to next input after calculation
                if self.group_type == 'monday':
                    # For Monday: Gross -> SKATS -> Next Gross
                    self.move_focus_to_next_input(instance)
                else:
                    # For Wednesday: Gross -> Next Gross (skip SKATS)
                    self.move_focus_to_next_gross_input(instance)
            else:
                # Clear net score for single digit entries (Wednesday only)
                if self.group_type == 'wednesday' and self.score_entries[last_name]['net_label']:
                    self.score_entries[last_name]['net_label'].text = ''
        else:
            # Clear net score when input is empty (Wednesday only)
            if self.group_type == 'wednesday' and self.score_entries[last_name]['net_label']:
                self.score_entries[last_name]['net_label'].text = ''
    
    def handle_skats_input(self, instance, value):
        """Handle SKATS input and auto-focus to next gross score field."""
        if value and value.isdigit() and len(value) == 2:
            # Move to next gross score input after 2-digit SKATS entry
            self.move_focus_to_next_gross_input(instance)
    
    def move_focus_to_next_input(self, current_input):
        """Move focus to the next input in the entry order (used for Monday: Gross->SKATS->Gross)."""
        try:
            current_index = self.score_entry_order.index(current_input)
            # Move to next input if available
            if current_index + 1 < len(self.score_entry_order):
                next_input = self.score_entry_order[current_index + 1]
                # Use Clock.schedule_once to ensure the focus change happens after current event
                Clock.schedule_once(lambda dt: setattr(next_input, 'focus', True), 0.1)
        except (ValueError, IndexError):
            # Current input not found in order or no next input available
            pass
    
    def move_focus_to_next_gross_input(self, current_input):
        """Move focus to the next Gross score input, skipping SKATS (used for Wednesday and SKATS->Gross)."""
        try:
            current_index = self.score_entry_order.index(current_input)
            # Find the next Gross input (they're at even indices: 0, 2, 4, etc.)
            next_gross_index = None
            
            if self.group_type == 'monday':
                # For Monday: order is [Gross0, SKATS0, Gross1, SKATS1, ...]
                # If current is SKATS (odd index), next Gross is at index + 1
                # If current is Gross (even index), next Gross is at index + 2
                if current_index % 2 == 0:  # Current is Gross
                    next_gross_index = current_index + 2
                else:  # Current is SKATS
                    next_gross_index = current_index + 1
            else:
                # For Wednesday: order is [Gross0, Gross1, Gross2, ...] (no SKATS)
                next_gross_index = current_index + 1
            
            # Move to next gross input if available
            if next_gross_index < len(self.score_entry_order):
                next_input = self.score_entry_order[next_gross_index]
                Clock.schedule_once(lambda dt: setattr(next_input, 'focus', True), 0.1)
        except (ValueError, IndexError):
            # Current input not found in order or no next input available
            pass
    
    def return_to_player_selection(self):
        """Return to the player selection screen."""
        self.manager.current = 'player_selection'
    
    def return_to_main_menu(self):
        """Return to the main menu screen."""
        self.manager.current = 'unified_main_menu'
    
    def navigate_to_player_payout(self):
        """Navigate to the Player Payout screen for group processing."""
        # Collect player scores data
        player_scores = self.collect_player_scores()
        
        if not player_scores:
            from .popup_utils import QuickPopup
            QuickPopup("No player scores to process! Please enter scores first.")
            return
        
        # Update groups with the latest score data
        updated_groups = self.update_groups_with_scores()
        
        # Set default total purse to 0 (will be calculated in payout screen)
        total_purse = 0.0
        
        # Get the payout screen and set the data
        payout_screen = self.manager.get_screen('player_payout')
        payout_screen.set_league(self.selected_league)
        # Pass both player_scores and the updated groups structure
        payout_screen.set_player_scores_and_groups(player_scores, updated_groups, total_purse, self.selected_league)
        
        # Navigate to payout screen
        self.manager.current = 'player_payout'
    
    def navigate_to_payouts(self):
        """Navigate to the Player Payout screen with current scores data."""
        # Collect player scores data
        player_scores = self.collect_player_scores()
        
        if not player_scores:
            from .popup_utils import QuickPopup
            QuickPopup("No player scores to process! Please enter scores first.")
            return
        
        # Update groups with the latest score data
        updated_groups = self.update_groups_with_scores()
        
        # Set default total purse to 0 (will be calculated in payout screen)
        total_purse = 0.0
        
        # Get the payout screen and set the data
        payout_screen = self.manager.get_screen('player_payout')
        payout_screen.set_league(self.selected_league)
        # Pass both player_scores and the updated groups structure
        payout_screen.set_player_scores_and_groups(player_scores, updated_groups, total_purse, self.selected_league)
        
        # Navigate to payout screen
        self.manager.current = 'player_payout'
    
    def process_individuals(self):
        """Calculate winners and distribute individual purse."""
        # Collect current player scores from UI
        player_scores = self.collect_player_scores()
        
        if not player_scores:
            QuickPopup.warning("Process Error", "No player scores available to process!")
            return
        
        # Calculate total purse if not set: (# of players × ante × individual %)
        if self.total_purse == 0.0:
            # Get ante amount based on league type
            ante_amount = 6.00 if self.selected_league == 'wednesday' else 12.00
            individual_percentage = 0.40  # 40% as per Admin Screen default
            
            # Count valid players (those with scores)
            num_players = len([p for p in player_scores if p.get('gross_score') is not None])
            
            # Calculate: (# players × ante × individual %)
            calculated_total_purse = num_players * ante_amount
            self.individual_purse = calculated_total_purse * individual_percentage
        else:
            # Use provided total purse (40% for individual)
            self.individual_purse = self.total_purse * 0.40
        
        # Calculate net scores if they're missing
        for p in player_scores:
            gross = p.get('gross_score')
            handicap = p.get('handicap')
            if gross is not None and handicap is not None and p.get('net_score') is None:
                try:
                    net_score = float(gross) - float(handicap)
                    p['net_score'] = net_score
                except (ValueError, TypeError):
                    continue
        
        # Filter players with valid net scores
        valid_players = []
        for p in player_scores:
            net_score = p.get('net_score')
            if net_score is not None:
                try:
                    # Convert to float to handle decimals and negative numbers
                    float(net_score)
                    valid_players.append(p)
                except (ValueError, TypeError):
                    continue
        
        if not valid_players:
            QuickPopup.warning("Process Error", "No valid net scores found to process!")
            return
        
        # Sort players by net score (lowest score wins)
        sorted_players = sorted(valid_players, key=lambda x: float(x['net_score']))
        
        # Calculate winnings distribution
        self.calculate_winnings(sorted_players, player_scores)
        
        # Make sure groups structure is updated with the new data
        self.sync_player_data_to_groups(player_scores)
        
        # Clear existing layout completely and rebuild
        for section_layout in self.section_layouts:
            section_layout.clear_widgets()
        self.score_entries = {}
        self.score_entry_order = []
        self.player_name_buttons = {}
        
        # Update title information after processing
        self.update_title_information()
        
        # Rebuild the display to show updated IND values
        self.populate_score_table()
        
        # Save processed winnings data to file for later transfer to Player's Score Screen
        self.save_processed_winnings_data(player_scores)
        
        self.winners_calculated = True
        QuickPopup.success("Success", f"Individual payouts calculated! {len(sorted_players)} players processed.")

    def save_processed_winnings_data(self, player_scores):
        """Save processed winnings data to a JSON file for later transfer to Player's Score Screen."""
        try:
            # Create simplified data structure with only essential information
            winnings_data = {
                'timestamp': datetime.now().isoformat(),
                'league': self.selected_league,
                'players': []
            }
            
            # Extract only Player Name, Gross Score, and Individual Winnings
            for player in player_scores:
                # Only save players who have gross score data
                if player.get('gross_score') is not None:
                    player_data = {
                        'player_name': f"{player.get('first', '')} {player.get('last', '')}".strip(),
                        'gross_score': player.get('gross_score'),
                        'ind_winnings': player.get('winnings', 0.0)
                    }
                    
                    winnings_data['players'].append(player_data)
            
            # Create processed_winnings directory if it doesn't exist
            script_dir = os.path.dirname(os.path.abspath(__file__))
            parent_dir = os.path.dirname(script_dir)
            winnings_dir = os.path.join(parent_dir, "processed_winnings")
            if not os.path.exists(winnings_dir):
                os.makedirs(winnings_dir)
            
            # Generate filename with timestamp and league
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            filename = f"winnings_{self.selected_league}_{timestamp}.json"
            file_path = os.path.join(winnings_dir, filename)
            
            # Save to JSON file
            with open(file_path, 'w') as f:
                json.dump(winnings_data, f, indent=2)
            
            # Also save a "latest" file for easy access
            latest_file_path = os.path.join(winnings_dir, f"latest_{self.selected_league}_winnings.json")
            with open(latest_file_path, 'w') as f:
                json.dump(winnings_data, f, indent=2)
            
        except Exception as e:
            QuickPopup.warning("Save Warning", f"Could not save winnings data: {str(e)}")

    @staticmethod
    def load_latest_winnings_data(league_type):
        """
        Load the latest processed winnings data for a specific league.
        
        Usage from Player's Score Screen:
        from screens.Enter_Scores_Screen import EnterScoresScreen
        winnings_data = EnterScoresScreen.load_latest_winnings_data('monday')
        if winnings_data:
            for player in winnings_data['players']:
                # Access player data: player['player_name'], player['gross_score'], player['ind_winnings']
                pass
        """
        try:
            # Get the file path
            script_dir = os.path.dirname(os.path.abspath(__file__))
            parent_dir = os.path.dirname(script_dir)
            winnings_dir = os.path.join(parent_dir, "processed_winnings")
            latest_file_path = os.path.join(winnings_dir, f"latest_{league_type}_winnings.json")
            
            if not os.path.exists(latest_file_path):
                return None
            
            # Load the data
            with open(latest_file_path, 'r') as f:
                winnings_data = json.load(f)
            
            return winnings_data
            
        except Exception as e:
            return None

    @staticmethod
    def get_available_winnings_files():
        """Get a list of all available processed winnings files."""
        try:
            script_dir = os.path.dirname(os.path.abspath(__file__))
            parent_dir = os.path.dirname(script_dir)
            winnings_dir = os.path.join(parent_dir, "processed_winnings")
            
            if not os.path.exists(winnings_dir):
                return []
            
            # Get all JSON files in the directory
            files = []
            for filename in os.listdir(winnings_dir):
                if filename.endswith('.json') and filename.startswith('winnings_'):
                    file_path = os.path.join(winnings_dir, filename)
                    # Extract metadata from filename
                    parts = filename.replace('.json', '').split('_')
                    if len(parts) >= 3:
                        league = parts[1]
                        timestamp = '_'.join(parts[2:])
                        files.append({
                            'filename': filename,
                            'path': file_path,
                            'league': league,
                            'timestamp': timestamp
                        })
            
            # Sort by timestamp (newest first)
            files.sort(key=lambda x: x['timestamp'], reverse=True)
            return files
            
        except Exception as e:
            return []

    def collect_player_scores(self):
        """Collect all player score data for the payout screen."""
        player_scores = []
        
        for last_name, score_data in self.score_entries.items():
            player_data = score_data['player_data'].copy()
            
            # Get gross score
            gross_score_text = score_data['score_input'].text
            if gross_score_text and gross_score_text.isdigit():
                player_data['gross_score'] = int(gross_score_text)
                
                # Get net score
                net_score_text = score_data['net_label'].text
                if net_score_text and net_score_text.isdigit():
                    player_data['net_score'] = int(net_score_text)
                else:
                    player_data['net_score'] = None
            else:
                player_data['gross_score'] = None
                player_data['net_score'] = None
            
            # Get skats score if available (Monday groups only)
            if 'skats_input' in score_data and score_data['skats_input'] is not None:
                skats_text = score_data['skats_input'].text
                if skats_text and skats_text.isdigit():
                    player_data['skats_score'] = int(skats_text)
                else:
                    player_data['skats_score'] = None
            else:
                player_data['skats_score'] = None
            
            # Initialize payout data
            player_data['place'] = ''
            player_data['winnings'] = 0.0
            
            player_scores.append(player_data)
        
        return player_scores
    
    def update_groups_with_scores(self):
        """Update the groups structure with current score data from the UI."""
        updated_groups = []
        
        # Create a deep copy of groups and update with current scores
        for group in self.groups:
            updated_group = []
            for player in group:
                # Create a copy of the player data
                updated_player = player.copy()
                
                # Get the current scores from the UI if this player has score entries
                if player['last'] in self.score_entries:
                    score_data = self.score_entries[player['last']]
                    
                    # Update gross score
                    gross_score_text = score_data['score_input'].text
                    if gross_score_text and gross_score_text.isdigit():
                        updated_player['gross_score'] = int(gross_score_text)
                    else:
                        updated_player['gross_score'] = None
                    
                    # Update net score (Wednesday only) - handle independently from gross score
                    if self.group_type == 'wednesday' and score_data['net_label']:
                        net_score_text = score_data['net_label'].text
                        if net_score_text:
                            try:
                                # Handle both integer and float values
                                net_score_value = float(net_score_text)
                                updated_player['net_score'] = int(net_score_value)  # Convert to int for display
                            except ValueError:
                                updated_player['net_score'] = None
                        else:
                            updated_player['net_score'] = None
                    elif self.group_type != 'wednesday':
                        # For Monday league, ensure net_score is not set
                        updated_player['net_score'] = None
                    
                    # Update skats score (Monday only)
                    if self.group_type == 'monday' and 'skats_input' in score_data and score_data['skats_input'] is not None:
                        skats_text = score_data['skats_input'].text
                        if skats_text and skats_text.isdigit():
                            updated_player['skats_score'] = int(skats_text)
                        else:
                            updated_player['skats_score'] = None
                
                updated_group.append(updated_player)
            updated_groups.append(updated_group)
        
        return updated_groups
    
    def calculate_winnings(self, sorted_players, all_player_scores):
        """Calculate winnings distribution based on individual purse with proper tie handling."""
        total_players = len(sorted_players)
        
        # Reset all winnings
        for player in all_player_scores:
            player['winnings'] = 0.0
            player['place'] = ''
        
        if total_players == 0:
            return
        
        # Define prize percentages for top 3 places
        prize_percentages = [0.50, 0.30, 0.20]  # 1st: 50%, 2nd: 30%, 3rd: 20%
        
        # Group players by their net scores to handle ties
        score_groups = []
        current_group = [sorted_players[0]]
        current_score = float(sorted_players[0]['net_score'])
        
        for i in range(1, len(sorted_players)):
            player_score = float(sorted_players[i]['net_score'])
            if player_score == current_score:
                # Same score - add to current group
                current_group.append(sorted_players[i])
            else:
                # Different score - start new group
                score_groups.append(current_group)
                current_group = [sorted_players[i]]
                current_score = player_score
        
        # Add the last group
        score_groups.append(current_group)
        
        # Distribute prizes accounting for ties
        current_position = 0
        
        for group in score_groups:
            group_size = len(group)
            
            # Calculate which prize positions this group covers
            positions_covered = list(range(current_position, current_position + group_size))
            
            # Sum up the prize money for all positions this group covers
            total_prize_for_group = 0.0
            place_names = []
            
            for pos in positions_covered:
                if pos < len(prize_percentages):
                    total_prize_for_group += self.individual_purse * prize_percentages[pos]
                    place_names.append(f"{pos + 1}")
            
            # If there are ties, show tied places (e.g., "T1st" for tied first)
            if group_size > 1 and place_names:
                if len(place_names) == 1:
                    place_text = f"T{place_names[0]}{'st' if place_names[0]=='1' else 'nd' if place_names[0]=='2' else 'rd' if place_names[0]=='3' else 'th'}"
                else:
                    first_pos = place_names[0]
                    last_pos = place_names[-1]
                    place_text = f"T{first_pos}-{last_pos}"
            elif place_names:
                pos_num = place_names[0]
                place_text = f"{pos_num}{'st' if pos_num=='1' else 'nd' if pos_num=='2' else 'rd' if pos_num=='3' else 'th'}"
            else:
                place_text = f"{current_position + 1}th"
            
            # Split the prize money evenly among tied players
            prize_per_player = total_prize_for_group / group_size if group_size > 0 else 0.0
            
            # Assign winnings and place to each player in the group
            for player in group:
                player['winnings'] = prize_per_player
                player['place'] = place_text
            
            current_position += group_size
            
            # Stop processing if we've covered the top 3 prize positions
            if current_position >= len(prize_percentages):
                break
        
        # Assign places to remaining players (no winnings)
        remaining_position = current_position
        for group in score_groups[len([g for g in score_groups if any(p.get('winnings', 0) > 0 for p in g)]):]:
            for player in group:
                if player.get('winnings', 0) == 0:
                    player['place'] = f"{remaining_position + 1}th"
            remaining_position += len(group)
    
    def sync_player_data_to_groups(self, player_scores):
        """Ensure groups structure has the updated player data."""
        # Create a lookup dictionary for updated player data
        player_lookup = {player['last']: player for player in player_scores}
        
        # Update each group with the latest player data
        for group_idx, group in enumerate(self.groups):
            for i, player in enumerate(group):
                if player and player['last'] in player_lookup:
                    # Update the group's player data with the latest from player_scores
                    updated_player = player_lookup[player['last']]
                    group[i] = updated_player
    
    def on_player_name_click(self, button):
        """Handle player name button click for swap selection."""
        player_last = button.text
        
        if player_last in self.selected_for_swap:
            # Player already selected, deselect them
            self.selected_for_swap.remove(player_last)
            button.bg_color = (1, 1, 1, 1)  # White background
        else:
            # Select player for swap
            if len(self.selected_for_swap) < 2:
                self.selected_for_swap.append(player_last)
                button.bg_color = (1, 1, 0, 1)  # Yellow background for selection
            else:
                # Already have 2 players selected, clear selection and start over
                self.clear_swap_selection()
                self.selected_for_swap.append(player_last)
                button.bg_color = (1, 1, 0, 1)  # Yellow background for selection
        
        self.update_swap_ui()
    
    def on_empty_slot_click(self, button):
        """Handle empty slot button click for swap selection."""
        empty_slot_key = f"empty_{button.group_index + 1}_{button.row_index}"
        
        if empty_slot_key in self.selected_for_swap:
            # Empty slot already selected, deselect it
            self.selected_for_swap.remove(empty_slot_key)
            button.bg_color = (1, 1, 1, 1)  # White background
        else:
            # Select empty slot for swap
            if len(self.selected_for_swap) < 2:
                self.selected_for_swap.append(empty_slot_key)
                button.bg_color = (1, 1, 0, 1)  # Yellow background for selection
            else:
                # Already have 2 items selected, clear selection and start over
                self.clear_swap_selection()
                self.selected_for_swap.append(empty_slot_key)
                button.bg_color = (1, 1, 0, 1)  # Yellow background for selection
        
        self.update_swap_ui()
    
    def clear_swap_selection(self):
        """Clear all swap selections and reset button colors."""
        for selected_item in self.selected_for_swap:
            if selected_item in self.player_name_buttons:
                self.player_name_buttons[selected_item].bg_color = (1, 1, 1, 1)  # White
        self.selected_for_swap.clear()
    
    def update_swap_ui(self):
        """Update the swap UI based on current selection."""
        def get_display_name(selected_item):
            """Get display name for selected item (player name or empty slot)."""
            if selected_item.startswith('empty_'):
                # Parse empty slot key: "empty_group_row"
                parts = selected_item.split('_')
                group_num = parts[1]
                row_num = parts[2]
                return f"Empty G{group_num}R{int(row_num)+1}"
            else:
                return selected_item
        
        if len(self.selected_for_swap) == 0:
            self.swap_btn.text = 'Click Two Items\nto SWAP'
            self.swap_btn.disabled = True
            self.swap_btn.bg_color = (.8, .8, .8, 1)  # Disabled grey
            self.swap_btn.color = (0.3, 0.3, 0.3, 1)  # Dark grey text
        elif len(self.selected_for_swap) == 1:
            display_name = get_display_name(self.selected_for_swap[0])
            self.swap_btn.text = f'Selected: {display_name}\nClick another item'
            self.swap_btn.disabled = True
            self.swap_btn.bg_color = (0.8, 0.8, 0.8, 1)  # Disabled grey
            self.swap_btn.color = (0.3, 0.3, 0.3, 1)  # Dark grey text
        elif len(self.selected_for_swap) == 2:
            display_name1 = get_display_name(self.selected_for_swap[0])
            display_name2 = get_display_name(self.selected_for_swap[1])
            self.swap_btn.text = f'SWAP:\n{display_name1} <-> {display_name2}'
            self.swap_btn.disabled = False
            # Use league-appropriate color for enabled button
            if self.selected_league == 'monday':
                self.swap_btn.bg_color = (0.7, 1.0, 0.7, 1)  # Light green
            else:
                self.swap_btn.bg_color = (1.0, 0.84, 0, 1)  # Light gold
            self.swap_btn.color = (0, 0, 0, 1)  # Black text
    
    def perform_swap(self, button):
        """Perform the swap between selected items (players and/or empty slots)."""
        if len(self.selected_for_swap) != 2:
            QuickPopup.warning("Invalid Selection", "Please select exactly 2 items to swap.")
            return
        
        item1 = self.selected_for_swap[0]
        item2 = self.selected_for_swap[1]
        
        # Parse the selected items to determine if they're players or empty slots
        def parse_item(item):
            """Parse item to get group, position, and player data if applicable."""
            if item.startswith('empty_'):
                # Parse empty slot: "empty_group_row"
                parts = item.split('_')
                group_idx = int(parts[1]) - 1  # Convert to 0-based index
                row_pos = int(parts[2])
                return group_idx, row_pos, None  # No player data
            else:
                # Find player in groups
                for group_idx, group in enumerate(self.groups):
                    for pos, player in enumerate(group):
                        if player['last'] == item:
                            return group_idx, pos, player
                return None, None, None  # Not found
        
        # Parse both items
        group1_idx, pos1, player1_data = parse_item(item1)
        group2_idx, pos2, player2_data = parse_item(item2)
        
        if group1_idx is None or group2_idx is None:
            QuickPopup.error("Swap Error", "Could not locate selected items.")
            return
        
        # Ensure we have enough space in the groups data structure
        while len(self.groups) <= max(group1_idx, group2_idx):
            self.groups.append([])
        
        # Extend groups to have at least 4 positions each
        while len(self.groups[group1_idx]) <= pos1:
            self.groups[group1_idx].append(None)
        while len(self.groups[group2_idx]) <= pos2:
            self.groups[group2_idx].append(None)
        
        # Handle different swap scenarios
        if player1_data and player2_data:
            # Player to Player swap
            self.groups[group1_idx][pos1] = player2_data
            self.groups[group2_idx][pos2] = player1_data
        elif player1_data and not player2_data:
            # Player to Empty slot
            self.groups[group2_idx][pos2] = player1_data
            # Remove player from original position
            if pos1 < len(self.groups[group1_idx]):
                self.groups[group1_idx].pop(pos1)
        elif not player1_data and player2_data:
            # Empty slot to Player
            self.groups[group1_idx][pos1] = player2_data
            # Remove player from original position
            if pos2 < len(self.groups[group2_idx]):
                self.groups[group2_idx].pop(pos2)
        else:
            # Both empty slots - no action needed
            QuickPopup.warning("Invalid Swap", "Cannot swap two empty slots.")
            return
        
        # Clean up empty groups at the end
        while self.groups and not self.groups[-1]:
            self.groups.pop()
        
        # Clear the current table and repopulate with swapped data
        self.clear_swap_selection()
        for section_layout in self.section_layouts:
            section_layout.clear_widgets()
        self.score_entries = {}
        self.score_entry_order = []
        self.player_name_buttons = {}
        
        # Update title information after swap
        self.update_title_information()
        
        # Repopulate the table with the new group arrangement
        self.populate_score_table()
        
        # Update the UI
        self.update_swap_ui()