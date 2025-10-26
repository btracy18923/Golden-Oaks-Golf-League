"""
Player Payout Screen for Golden Oaks Golf League
===============================================

This module contains the PlayerPayoutScreen class that handles payout calculations
and winner determination based on net scores from the Enter_Scores_Screen.
"""

import os
import sqlite3
from datetime import date
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
        self.bg_color = bg_color
        self.corner_radius = dp(10)
        with self.canvas.before:
            Color(*bg_color)
            self.rect = RoundedRectangle(size=self.size, pos=self.pos, radius=[self.corner_radius])
        with self.canvas.after:
            Color(0, 0, 0, 1)
            self.border = Line(rounded_rectangle=(self.x, self.y, self.width, self.height, self.corner_radius), width=2)
        self.bind(size=self.update_graphics, pos=self.update_graphics)
    
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
        self.background_color = (1.0, 0.84, 0, 1)  # Light gold background
        self.foreground_color = (0, 0, 0, 1)  # Black text
        self.cursor_color = (0, 0, 0, 1)  # Black cursor
        self.selection_color = (0.8, 0.7, 0.3, 0.5)  # Selection highlight
        self.halign = 'center'  # Center align text horizontally
        self.font_size = '19sp'  # Consistent font size
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
        self.background_color = (0.7, 1.0, 0.7, 1)  # Light green background
        self.foreground_color = (0, 0, 0, 1)  # Black text
        self.cursor_color = (0, 0, 0, 1)  # Black cursor
        self.selection_color = (0.5, 0.8, 0.5, 0.5)  # Selection highlight
        self.halign = 'center'  # Center align text horizontally
        self.font_size = '19sp'  # Consistent font size
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


class PlayerPayoutScreen(Screen):
    """
    Player Payout screen for calculating winners and distributing purse
    based on net scores from Enter_Scores_Screen.
    """
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.selected_league = 'monday'  # Default league
        self.db_name = self.get_database_path()
        self.player_scores = []  # Will hold player data with scores
        self.total_purse = 0.0
        self.individual_percent = 40
        self.group_percent = 60
        self.individual_purse = 0.0
        self.group_purse = 0.0
        self.winners_calculated = False
        
        # Variables for 9 groups display (copied from Enter Scores Screen)
        self.selected_players = []
        self.groups = []
        self.selected_for_swap = []
        self.player_name_buttons = {}
        self.score_entries = {}
        self.score_entry_order = []
        self.grid_rows = []
        
        # Setup UI
        self.add_widget(self.setup_ui())
    
    def set_league(self, league_type):
        """Set the league type (monday/wednesday) for this screen."""
        self.selected_league = league_type
        self.group_type = league_type  # Keep group_type in sync
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
    
    def get_database_path(self):
        """Get the path to the GoldenOaks.db database."""
        script_dir = os.path.dirname(os.path.abspath(__file__))
        parent_dir = os.path.dirname(script_dir)
        return os.path.join(parent_dir, "GoldenOaks.db")
    
    def setup_ui(self):
        """Setup the main UI for the payout screen."""
        main_layout = BoxLayout(orientation='vertical', padding=0, spacing=0)
        
        # Title with light grey background
        title_label = Label(
            text="PLAYER PAYOUT SCREEN",
            font_size='20sp',
            bold=True,
            size_hint=(1, 0.05),
            color=(0, 0, 0, 1)
        )
        # Add light grey background to title
        with title_label.canvas.before:
            Color(0.9, 0.9, 0.9, 1)  # Light grey background
            title_label.bg_rect = Rectangle(size=title_label.size, pos=title_label.pos)
        title_label.bind(size=lambda instance, value: setattr(instance.bg_rect, 'size', value),
                        pos=lambda instance, value: setattr(instance.bg_rect, 'pos', value))
        main_layout.add_widget(title_label)
        
        # Main content area
        content_area = self.setup_payout_content()
        main_layout.add_widget(content_area)
        
        # Footer with buttons
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
            size_hint=(None, None),
            height='100sp',
            width='1090dp'  # 3 buttons at 350dp each + 40dp spacing
        )
        
        # Return to Main Menu button
        menu_btn = ColoredButton(
            text="Return to Main Menu",
            size_hint=(None, 1),
            width='350dp',
            font_size='25sp',
            bold=True,
            bg_color=(0.7, 1.0, 1.0, 1),  # Light-cyan
            color=(0, 0, 0, 1)
        )
        menu_btn.bind(on_press=lambda x: self.return_to_main_menu())
        button_container.add_widget(menu_btn)
        
        # Return to Enter Scores button - color will be updated when league is set
        self.return_btn = ColoredButton(
            text="Return to Enter Scores",
            size_hint=(None, 1),
            width='350dp',
            font_size='25sp',
            bold=True,
            bg_color=(1.0, 0.84, 0, 1),  # Default to Wednesday color
            color=(0, 0, 0, 1)
        )
        self.return_btn.bind(on_press=lambda x: self.return_to_enter_scores())
        button_container.add_widget(self.return_btn)
        
        # Process Individuals button
        self.process_btn = ColoredButton(
            text="Process Individuals",
            size_hint=(None, 1),
            width='350dp',
            font_size='25sp',
            bold=True,
            bg_color=(0.9, 0.9, 0.9, 1),  # Light grey
            color=(0, 0, 0, 1)
        )
        self.process_btn.bind(on_press=lambda x: self.process_individuals())
        button_container.add_widget(self.process_btn)
        
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
        """Setup the main payout content (exact duplicate of Enter Scores Screen layout)."""
        tab_layout = BoxLayout(orientation='vertical', padding=10, spacing=10)
        
        # Determine background color based on group type (defaults to Wednesday if not set)
        if hasattr(self, 'group_type') and self.group_type == 'monday':
            label_bg_color = (0.7, 1.0, 0.7, 1)  # Light green for Monday
        else:
            label_bg_color = (1.0, 0.84, 0, 1)  # Light gold for Wednesday
        
        # Add white background
        with tab_layout.canvas.before:
            Color(1, 1, 1, 1)  # White background
            self.payout_rect = Rectangle(size=tab_layout.size, pos=tab_layout.pos)
        tab_layout.bind(size=self.update_payout_rect, pos=self.update_payout_rect)
        
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
    
    def update_payout_rect(self, instance, value):
        """Update the payout screen background rectangle."""
        self.payout_rect.size = instance.size
        self.payout_rect.pos = instance.pos
    
    
    def set_player_scores_and_groups(self, player_scores, groups, total_purse, league_type='monday'):
        """Set player scores data and groups structure from Enter_Scores_Screen."""
        self.player_scores = player_scores
        self.groups = groups  # Use the exact groups structure from Enter Scores Screen
        self.total_purse = total_purse
        self.selected_league = league_type
        self.group_type = league_type  # Keep group_type in sync
        self.winners_calculated = False
        
        # Clear existing layout and populate score table
        for section_layout in self.section_layouts:
            section_layout.clear_widgets()
        self.score_entries = {}
        self.score_entry_order = []
        self.player_name_buttons = {}
        
        # Populate the score table with groups data
        self.populate_score_table()
    
    def set_player_scores(self, player_scores, total_purse, league_type='monday'):
        """Set player scores data from Enter_Scores_Screen (legacy method)."""
        self.player_scores = player_scores
        self.total_purse = total_purse
        self.selected_league = league_type
        self.group_type = league_type  # Keep group_type in sync
        self.winners_calculated = False
        
        # Convert player_scores to groups format for display
        self.convert_player_scores_to_groups(player_scores)
        
        # Clear existing layout and populate score table
        for section_layout in self.section_layouts:
            section_layout.clear_widgets()
        self.score_entries = {}
        self.score_entry_order = []
        self.player_name_buttons = {}
        
        # Populate the score table with groups data
        self.populate_score_table()
    
    def convert_player_scores_to_groups(self, player_scores):
        """Convert player_scores list to groups format for display."""
        # Reset groups
        self.groups = []
        
        # Group players by their group_num if available, otherwise distribute evenly
        group_dict = {}
        
        for player in player_scores:
            # Use group_num if available, otherwise assign to group 1
            group_num = player.get('group_num', 1)
            if group_num not in group_dict:
                group_dict[group_num] = []
            group_dict[group_num].append(player)
        
        # Convert group_dict to groups list (ensure we have at least empty groups up to 9)
        for group_num in range(1, 10):  # Groups 1-9
            if group_num in group_dict:
                self.groups.append(group_dict[group_num])
            else:
                self.groups.append([])  # Empty group
    
    def populate_score_table(self):
        """Populate the score table with selected players distributed across 3 sections (exact duplicate from Enter Scores Screen)."""
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
            
            group_header = Label(
                text=f'------------------Group {group_num}------------------',
                font_size='20sp',
                bold=True,
                size_hint=(None, 1),
                width='400dp',  # Same width as Name column
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
                    width='140dp',
                    color=(0, 0, 0, 1),
                    halign='center',
                    valign='middle',
                    font_size='15sp',
                    bold=True
                )
                name_header.bind(size=name_header.setter('text_size'))
                header_layout.add_widget(name_header)
                
                
                # Net header - only show for Wednesday league
                if self.group_type == 'wednesday':
                    net_header = Label(
                        text='Net',
                        size_hint=(None, 1),
                        width='60dp',
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
                        width='60dp',
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
                        width='80dp',
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
                    # Last name - make it clickable for swapping
                    name_button = NoBorderButton(
                        text=player['last'],
                        size_hint=(None, 1),
                        width='140dp',
                        font_size='20sp',
                        bg_color=(1, 1, 1, 1),  # White background
                        color=(0, 0, 0, 1)
                    )
                    name_button.player_data = player
                    name_button.group_index = group_num - 1
                    
                    # Store reference to name button
                    self.player_name_buttons[player['last']] = name_button
                    row_layout.add_widget(name_button)
                else:
                    # Empty placeholder for name
                    name_placeholder = NoBorderButton(
                        text='',
                        size_hint=(None, 1),
                        width='140dp',
                        color=(0, 0, 0, 1),
                        bg_color=(1, 1, 1, 1)  # White background
                    )
                    # Set up empty slot data
                    name_placeholder.player_data = None
                    name_placeholder.group_index = group_num - 1
                    name_placeholder.row_index = row_index
                    
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
                
                
                # Net score label (only show for Wednesday league) - static display from Enter Scores Screen
                if self.group_type == 'wednesday':
                    if player:  # Check if player is not None
                        # Display net score as static value (already calculated in Enter Scores Screen)
                        net_score_value = player.get('net_score')
                        net_score_text = str(net_score_value) if net_score_value is not None else ''
                    else:
                        # Empty slot
                        net_score_text = ''
                        
                    net_label = Label(
                        text=net_score_text,
                        size_hint=(None, 1),
                        width='60dp',
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
                        width='60dp',
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
                        width='80dp',
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
                if self.group_type == 'monday':
                    if player:
                        # SKAT Number
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
                        
                        # SKATS score display (read-only label)
                        skats_score_text = str(player.get('skats_score', '')) if player.get('skats_score') is not None else ''
                        skats_label = Label(
                            text=skats_score_text,
                            size_hint=(None, 1),
                            width='80dp',
                            color=(0, 0, 0, 1),
                            halign='center',
                            valign='middle',
                            font_size='20sp'
                        )
                        skats_label.bind(size=skats_label.setter('text_size'))
                        
                        # Add border for SKATS label
                        with skats_label.canvas.after:
                            Color(0, 0, 0, 1)  # Black border
                            skats_label.border_line = Line(rectangle=(0, 0, 0, 0), width=1)
                        skats_label.bind(pos=lambda instance, value: setattr(instance.border_line, 'rectangle', 
                                       (instance.x, instance.y, instance.width, instance.height)),
                                      size=lambda instance, value: setattr(instance.border_line, 'rectangle', 
                                       (instance.x, instance.y, instance.width, instance.height)))
                        
                        row_layout.add_widget(skats_label)
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
                
                section_widgets[section_index].append(row_layout)
        
        # Add all widgets to their respective sections in correct order (Group 1 at top)
        for section_index, widgets in enumerate(section_widgets):
            for widget in widgets:
                self.section_layouts[section_index].add_widget(widget)
    
    def process_individuals(self):
        """Calculate winners and distribute individual purse."""
        
        if not self.player_scores:
            QuickPopup.warning("Process Error", "No player scores available to process!")
            return
        
        # Calculate total purse if not set: (# of players × ante × individual %)
        if self.total_purse == 0.0:
            # Get ante amount based on league type
            ante_amount = 6.00 if self.selected_league == 'wednesday' else 12.00
            individual_percentage = 0.40  # 40% as per Admin Screen default
            
            # Count valid players (those with scores)
            num_players = len([p for p in self.player_scores if p.get('gross_score') is not None])
            
            # Calculate: (# players × ante × individual %)
            calculated_total_purse = num_players * ante_amount
            self.individual_purse = calculated_total_purse * individual_percentage
        else:
            # Use provided total purse (40% for individual)
            self.individual_purse = self.total_purse * 0.40
        
        # Calculate net scores if they're missing
        for p in self.player_scores:
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
        for p in self.player_scores:
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
        self.calculate_winnings(sorted_players)
        
        # Make sure groups structure is updated with the new data
        self.sync_player_data_to_groups()
        
        # Clear existing layout completely and rebuild
        for section_layout in self.section_layouts:
            section_layout.clear_widgets()
        self.score_entries = {}
        self.score_entry_order = []
        self.player_name_buttons = {}
        
        # Rebuild the display to show updated IND values
        self.populate_score_table()
        
        self.winners_calculated = True
        QuickPopup.success("Success", f"Individual payouts calculated! {len(sorted_players)} players processed.")
    
    def calculate_winnings(self, sorted_players):
        """Calculate winnings distribution based on individual purse with proper tie handling."""
        total_players = len(sorted_players)
        
        # Reset all winnings
        for player in self.player_scores:
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
    
    def sync_player_data_to_groups(self):
        """Ensure groups structure has the updated player data."""
        # Create a lookup dictionary for updated player data
        player_lookup = {player['last']: player for player in self.player_scores}
        
        # Update each group with the latest player data
        for group_idx, group in enumerate(self.groups):
            for i, player in enumerate(group):
                if player and player['last'] in player_lookup:
                    # Update the group's player data with the latest from player_scores
                    updated_player = player_lookup[player['last']]
                    group[i] = updated_player
    
    def return_to_enter_scores(self):
        """Return to the Enter Scores screen."""
        self.manager.current = 'enter_scores'
    
    def return_to_main_menu(self):
        """Return to the main menu screen."""
        self.manager.current = 'unified_main_menu'