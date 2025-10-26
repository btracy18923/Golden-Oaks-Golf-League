"""
Player Profile Screen for Golden Oaks Golf League
================================================

This module contains the PlayerProfileScreen class for managing player profiles.
"""

import os
import sqlite3
from kivy.uix.screenmanager import Screen
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.gridlayout import GridLayout
from kivy.uix.scrollview import ScrollView
from kivy.uix.label import Label
from kivy.uix.textinput import TextInput
from kivy.uix.behaviors import ButtonBehavior
from kivy.graphics import Color, Rectangle, Line, RoundedRectangle
from kivy.clock import Clock
from kivy.metrics import dp

# Import unified popup system
try:
    from .popup_utils import QuickPopup
except ImportError:
    from popup_utils import QuickPopup


class NavigableTextInput(TextInput):
    """Custom TextInput that handles TAB navigation."""
    
    def __init__(self, navigation_handler=None, **kwargs):
        super().__init__(**kwargs)
        self.navigation_handler = navigation_handler
    
    def keyboard_on_key_down(self, window, keycode, text, modifiers):
        """Override keyboard handling to catch TAB keys."""
        key_code, key_string = keycode
        
        if key_string == 'tab' and self.navigation_handler:
            # Call the navigation handler
            if 'shift' in modifiers:
                self.navigation_handler(self, 'prev')
            else:
                self.navigation_handler(self, 'next')
            return True  # Consume the event
        
        # Let parent handle other keys
        return super().keyboard_on_key_down(window, keycode, text, modifiers)


class ColoredButton(ButtonBehavior, Label):
    """A colored button with customizable background color and text color."""
    
    def __init__(self, bg_color=(1, 1, 1, 1), **kwargs):
        super().__init__(**kwargs)
        self.bg_color = bg_color
        self.corner_radius = dp(5)  # Rounded corner radius
        
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


class BorderedLabel(Label):
    """Label with right border for table columns."""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        with self.canvas.after:
            Color(0, 0, 0, 1)  # Black color for border
            self.border_line = Line(width=1)
        self.bind(size=self.update_border, pos=self.update_border)
    
    def update_border(self, *args):
        """Update the right border line when label moves or resizes."""
        if hasattr(self, 'border_line'):
            # Draw right border line
            self.border_line.points = [self.x + self.width, self.y, self.x + self.width, self.y + self.height]


class BorderedLabelWithBottom(Label):
    """Label with both right and bottom borders for header cells."""
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


class PlayerProfileScreen(Screen):
    """
    Player profile management screen converted from player_profile.py.
    Handles adding, editing, and deleting players.
    """
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.selected_player = None
        self.selected_league = 'monday'  # Default league
        self.db_name = self.get_database_path()
        
        # Initialize auto-sync
        try:
            from Misc_Old_Files.auto_sync_startup import initialize_auto_sync
            initialize_auto_sync()
        except Exception as e:
            print(f"Warning: Auto-sync not available: {e}")
        
        # Setup UI
        self.add_widget(self.setup_ui())
        
        # Load players after UI is created
        Clock.schedule_once(lambda dt: self.refresh_player_list(), 0.1)
    
    def set_league(self, league_type):
        """Set the league type (monday/wednesday) for this screen."""
        self.selected_league = league_type
        # Refresh player list for the new league
        if hasattr(self, 'refresh_player_list'):
            self.refresh_player_list()
    
    def on_enter(self):
        """Called when the screen is entered - refresh player data."""
        self.refresh_player_list()
    
    def get_database_path(self):
        """Get the path to the GoldenOaks.db database."""
        current_dir = os.path.dirname(os.path.abspath(__file__))
        parent_dir = os.path.dirname(current_dir)  # Go up one level from screens/ directory
        return os.path.join(parent_dir, 'GoldenOaks.db')
    
    def setup_ui(self):
        """Set up the user interface."""
        main_layout = BoxLayout(orientation='vertical', padding=20, spacing=10)
        
        # Set light gray background
        with main_layout.canvas.before:
            Color(0.9, 0.9, 0.9, 1)  # Light gray background
            main_layout.bg_rect = Rectangle(pos=main_layout.pos, size=main_layout.size)
        main_layout.bind(pos=self.update_bg, size=self.update_bg)
        
        # Title
        title_label = Label(
            text="Player Profile",
            font_size='20sp', 
            size_hint_y=None, 
            height='50dp', 
            color=(0, 0, 0, 1), 
            bold=True
        )
        main_layout.add_widget(title_label)
        
        # Horizontal layout for form and list
        content_layout = BoxLayout(orientation='horizontal', spacing=10)
        
        # Left side - Form (30% width)
        form_layout = BoxLayout(orientation='vertical', size_hint_x=0.3, spacing=5)
        
        # Form fields in a grid
        form_grid = GridLayout(cols=2, spacing=5, size_hint_y=None)
        form_grid.bind(minimum_height=form_grid.setter('height'))
        
        # ID Number
        form_grid.add_widget(Label(text="ID#:", size_hint_y=None, height='40dp', color=(0, 0, 0, 1), bold=True))
        self.id_entry = NavigableTextInput(
            multiline=False, 
            size_hint_y=None, 
            height='40dp',
            foreground_color=(0, 0, 0, 1), 
            cursor_color=(0, 0, 0, 1),
            halign='center', 
            padding=[5, 12], 
            navigation_handler=self.handle_tab_navigation
        )
        self.add_text_input_border(self.id_entry)
        form_grid.add_widget(self.id_entry)
        
        # First Name
        form_grid.add_widget(Label(text="First Name:", size_hint_y=None, height='40dp', color=(0, 0, 0, 1), bold=True))
        self.first_entry = NavigableTextInput(
            multiline=False, 
            size_hint_y=None, 
            height='40dp',
            foreground_color=(0, 0, 0, 1), 
            cursor_color=(0, 0, 0, 1),
            halign='center', 
            padding=[5, 12], 
            navigation_handler=self.handle_tab_navigation
        )
        self.add_text_input_border(self.first_entry)
        form_grid.add_widget(self.first_entry)
        
        # Last Name
        form_grid.add_widget(Label(text="Last Name:", size_hint_y=None, height='40dp', color=(0, 0, 0, 1), bold=True))
        self.last_entry = NavigableTextInput(
            multiline=False, 
            size_hint_y=None, 
            height='40dp',
            foreground_color=(0, 0, 0, 1), 
            cursor_color=(0, 0, 0, 1),
            halign='center', 
            padding=[5, 12], 
            navigation_handler=self.handle_tab_navigation
        )
        self.add_text_input_border(self.last_entry)
        form_grid.add_widget(self.last_entry)
        
        # Handicap
        form_grid.add_widget(Label(text="Handicap:", size_hint_y=None, height='40dp', color=(0, 0, 0, 1), bold=True))
        self.handicap_entry = NavigableTextInput(
            multiline=False, 
            size_hint_y=None, 
            height='40dp',
            foreground_color=(0, 0, 0, 1), 
            cursor_color=(0, 0, 0, 1),
            halign='center', 
            padding=[5, 12], 
            navigation_handler=self.handle_tab_navigation
        )
        self.add_text_input_border(self.handicap_entry)
        form_grid.add_widget(self.handicap_entry)
        
        # SKAT Number
        form_grid.add_widget(Label(text="SKAT#:", size_hint_y=None, height='40dp', color=(0, 0, 0, 1), bold=True))
        self.skat_entry = NavigableTextInput(
            multiline=False, 
            size_hint_y=None, 
            height='40dp',
            foreground_color=(0, 0, 0, 1), 
            cursor_color=(0, 0, 0, 1),
            halign='center', 
            padding=[5, 12], 
            navigation_handler=self.handle_tab_navigation
        )
        self.add_text_input_border(self.skat_entry)
        form_grid.add_widget(self.skat_entry)
        
        # Cell Phone
        form_grid.add_widget(Label(text="Cell Phone:", size_hint_y=None, height='40dp', color=(0, 0, 0, 1), bold=True))
        self.cell_entry = NavigableTextInput(
            multiline=False, 
            size_hint_y=None, 
            height='40dp',
            foreground_color=(0, 0, 0, 1), 
            cursor_color=(0, 0, 0, 1),
            halign='center', 
            padding=[5, 12], 
            navigation_handler=self.handle_tab_navigation
        )
        self.add_text_input_border(self.cell_entry)
        form_grid.add_widget(self.cell_entry)
        
        # Email
        form_grid.add_widget(Label(text="Email:", size_hint_y=None, height='40dp', color=(0, 0, 0, 1), bold=True))
        self.email_entry = NavigableTextInput(
            multiline=False, 
            size_hint_y=None, 
            height='40dp',
            foreground_color=(0, 0, 0, 1), 
            cursor_color=(0, 0, 0, 1),
            halign='center', 
            padding=[5, 12], 
            navigation_handler=self.handle_tab_navigation
        )
        self.add_text_input_border(self.email_entry)
        form_grid.add_widget(self.email_entry)
        
        form_layout.add_widget(form_grid)
        
        # Create a list of all input fields in tab order
        self.input_fields = [
            self.id_entry, self.first_entry, self.last_entry, 
            self.handicap_entry, self.skat_entry, self.cell_entry, self.email_entry
        ]
        
        # Buttons
        button_layout = BoxLayout(orientation='horizontal', size_hint_y=None, height='50dp', spacing=5)
        
        self.add_button = ColoredButton(
            text="Add Player",
            bg_color=(0.7, 1.0, 0.7, 1),  # Light green
            color=(0, 0, 0, 1),
            font_size='16sp',
            bold=True
        )
        self.add_button.bind(on_press=self.add_player)
        button_layout.add_widget(self.add_button)
        
        self.edit_button = ColoredButton(
            text="Edit Player",
            bg_color=(0.8, 0.8, 1.0, 1),  # Light blue
            color=(0, 0, 0, 1),
            font_size='16sp',
            bold=True
        )
        self.edit_button.bind(on_press=self.update_player)
        button_layout.add_widget(self.edit_button)
        
        self.delete_button = ColoredButton(
            text="Delete Player",
            bg_color=(1.0, 0.7, 0.7, 1),  # Light red
            color=(0, 0, 0, 1),
            font_size='16sp',
            bold=True
        )
        self.delete_button.bind(on_press=self.delete_player)
        button_layout.add_widget(self.delete_button)
        
        form_layout.add_widget(button_layout)
        
        # Clear Form button
        clear_btn = ColoredButton(
            text="Clear Form",
            bg_color=(1.0, 0.9, 0.5, 1),  # Light gold
            color=(0, 0, 0, 1),
            font_size='16sp',
            size_hint_y=None,
            height='50dp',
            bold=True
        )
        clear_btn.bind(on_press=self.clear_form)
        form_layout.add_widget(clear_btn)
        
        # Return to Main Menu button
        return_btn = ColoredButton(
            text="Return to Main Menu",
            bg_color=(1.0, 0.7, 0.7, 1),  # Light red
            color=(0, 0, 0, 1),
            font_size='16sp',
            size_hint_y=None,
            height='50dp',
            bold=True
        )
        return_btn.bind(on_press=self.return_to_main_menu)
        form_layout.add_widget(return_btn)
        
        content_layout.add_widget(form_layout)
        
        # Right side - Player list (70% width)
        list_layout = BoxLayout(orientation='vertical', size_hint_x=0.7, spacing=5)
        
        # Table header
        header_layout = BoxLayout(orientation='horizontal', size_hint_y=None, height='40dp')
        
        # Header labels with borders
        headers = [
            ("ID#", '60dp'),
            ("First", '120dp'), 
            ("Last", '120dp'),
            ("HC", '60dp'),
            ("SKAT#", '80dp'),
            ("Cell", '120dp'),
            ("Email", '200dp')
        ]
        
        for header_text, width in headers:
            header_label = BorderedLabelWithBottom(
                text=header_text,
                size_hint=(None, 1),
                width=width,
                color=(0, 0, 0, 1),
                bold=True,
                halign='center',
                valign='middle'
            )
            header_label.bind(size=header_label.setter('text_size'))
            header_layout.add_widget(header_label)
        
        list_layout.add_widget(header_layout)
        
        # Scrollable player list
        self.scroll_view = ScrollView(
            do_scroll_x=False, 
            do_scroll_y=True,
            bar_width='20dp',
            bar_color=(0, 0, 0, 1),  # Black scrollbar
            scroll_type=['bars', 'content'],
            bar_inactive_color=(0, 0, 0, 0.8),  # Darker when inactive
            bar_margin=2
        )
        self.player_list_layout = BoxLayout(orientation='vertical', size_hint_y=None, spacing=2)
        self.player_list_layout.bind(minimum_height=self.player_list_layout.setter('height'))
        self.scroll_view.add_widget(self.player_list_layout)
        list_layout.add_widget(self.scroll_view)
        
        content_layout.add_widget(list_layout)
        main_layout.add_widget(content_layout)
        
        return main_layout
    
    # Additional helper methods would continue here...
    # Due to length constraints, this shows the essential structure
    
    def add_text_input_border(self, text_input):
        """Add black border to text input."""
        with text_input.canvas.before:
            Color(0, 0, 0, 1)  # Black border
            text_input.border_line = Line(width=2)
        text_input.bind(pos=self.update_text_input_border, size=self.update_text_input_border)
    
    def update_text_input_border(self, instance, value):
        """Update text input border when input moves or resizes."""
        if hasattr(instance, 'border_line'):
            instance.border_line.rounded_rectangle = (instance.x, instance.y, instance.width, instance.height, 10)
    
    def update_bg(self, instance, value):
        """Update background rectangle when widget moves or resizes."""
        if hasattr(instance, 'bg_rect'):
            instance.bg_rect.pos = instance.pos
            instance.bg_rect.size = instance.size
    
    def handle_tab_navigation(self, current_input, direction):
        """Handle TAB navigation between input fields."""
        try:
            current_index = self.input_fields.index(current_input)
            if direction == 'next':
                next_index = (current_index + 1) % len(self.input_fields)
            else:  # direction == 'prev'
                next_index = (current_index - 1) % len(self.input_fields)
            
            self.input_fields[next_index].focus = True
        except ValueError:
            pass  # Current input not in list
    
    def refresh_player_list(self):
        """Refresh the player list display."""
        # Clear existing player list
        self.player_list_layout.clear_widgets()
        
        try:
            conn = sqlite3.connect(self.db_name)
            cursor = conn.cursor()
            cursor.execute("SELECT id_number, first, last, handicap, skat_number, cell, email FROM players WHERE league = ? ORDER BY last, first", (self.selected_league,))
            players = cursor.fetchall()
            conn.close()
            
            for player in players:
                self.add_player_row(player)
                
        except Exception as e:
            # Create error popup
            content = BoxLayout(orientation='vertical', padding=20)
            with content.canvas.before:
                Color(1.0, 0.9, 0.5, 1)  # Light gold background
                content.bg_rect = Rectangle(pos=content.pos, size=content.size)
            content.bind(pos=lambda instance, value: setattr(content.bg_rect, 'pos', value))
            content.bind(size=lambda instance, value: setattr(content.bg_rect, 'size', value))
            
            label = Label(
                text=f'Error loading players: {str(e)}',
                color=(0, 0, 0, 1),
                bold=True
            )
            content.add_widget(label)
            
            popup = Popup(
                title='Database Error',
                content=content,
                size_hint=(0.6, 0.4)
            )
            popup.open()
            Clock.schedule_once(lambda dt: popup.dismiss(), 3)
    
    def add_player_row(self, player_data):
        """Add a player row to the list."""
        id_num, first, last, handicap, skat_num, cell, email = player_data
        
        row_layout = BoxLayout(orientation='horizontal', size_hint_y=None, height='40dp')
        
        # Make row clickable
        with row_layout.canvas.before:
            Color(0.95, 0.95, 0.95, 1)  # Very light gray background
            row_layout.bg_rect = Rectangle(size=row_layout.size, pos=row_layout.pos)
        row_layout.bind(size=self.update_row_bg, pos=self.update_row_bg)
        
        # Store player data in the row
        row_layout.player_data = {
            'id_number': id_num,
            'first': first or '',
            'last': last or '',
            'handicap': handicap or 0,
            'skat_number': skat_num or '',
            'cell': cell or '',
            'email': email or ''
        }
        
        # Add click handling
        row_layout.bind(on_touch_down=self.on_player_row_click)
        
        # Row data with borders
        row_data = [
            (str(id_num) if id_num else '', '60dp'),
            (first or '', '120dp'),
            (last or '', '120dp'), 
            (str(handicap) if handicap else '', '60dp'),
            (str(skat_num) if skat_num else '', '80dp'),
            (self.format_phone_number(cell) if cell else '', '120dp'),
            (email or '', '200dp')
        ]
        
        for text, width in row_data:
            cell_label = BorderedLabel(
                text=text,
                size_hint=(None, 1),
                width=width,
                color=(0, 0, 0, 1),
                halign='center',
                valign='middle'
            )
            cell_label.bind(size=cell_label.setter('text_size'))
            row_layout.add_widget(cell_label)
        
        self.player_list_layout.add_widget(row_layout)
    
    def update_row_bg(self, instance, value):
        """Update row background rectangle."""
        if hasattr(instance, 'bg_rect'):
            instance.bg_rect.size = instance.size
            instance.bg_rect.pos = instance.pos
    
    def on_player_row_click(self, row_layout, touch):
        """Handle clicking on a player row."""
        if row_layout.collide_point(*touch.pos):
            self.select_player_row(row_layout)
            return True
        return False
    
    def select_player_row(self, row_layout):
        """Select a player row and populate the form."""
        # Clear previous selections
        for child in self.player_list_layout.children:
            if hasattr(child, 'bg_rect'):
                child.canvas.before.clear()
                with child.canvas.before:
                    Color(0.95, 0.95, 0.95, 1)  # Light gray
                    child.bg_rect = Rectangle(size=child.size, pos=child.pos)
        
        # Highlight selected row
        row_layout.canvas.before.clear()
        with row_layout.canvas.before:
            Color(0.7, 1.0, 0.7, 1)  # Light green for selection
            row_layout.bg_rect = Rectangle(size=row_layout.size, pos=row_layout.pos)
        
        # Store selected player
        self.selected_player = row_layout.player_data
        
        # Populate form fields
        self.id_entry.text = str(self.selected_player['id_number'])
        self.first_entry.text = self.selected_player['first']
        self.last_entry.text = self.selected_player['last']
        self.handicap_entry.text = str(self.selected_player['handicap'])
        self.skat_entry.text = str(self.selected_player['skat_number'])
        self.cell_entry.text = self.selected_player['cell']
        self.email_entry.text = self.selected_player['email']
    
    def format_phone_number(self, phone):
        """Format phone number as xxx-xxx-xxxx."""
        if not phone:
            return ''
        
        # Remove all non-digit characters
        import re
        digits = re.sub(r'\D', '', str(phone))
        
        # Format as xxx-xxx-xxxx if we have 10 digits
        if len(digits) == 10:
            return f"{digits[:3]}-{digits[3:6]}-{digits[6:]}"
        elif len(digits) == 11 and digits[0] == '1':
            # Handle 11-digit numbers starting with 1 (US country code)
            return f"{digits[1:4]}-{digits[4:7]}-{digits[7:]}"
        else:
            # Return original if not standard format
            return phone
    
    def add_player(self, instance=None):
        """Add a new player."""
        if not self.validate_form():
            return
        
        player_data = self.get_form_data()
        
        try:
            conn = sqlite3.connect(self.db_name)
            cursor = conn.cursor()
            
            cursor.execute("""
                INSERT INTO players (id_number, first, last, handicap, skat_number, cell, email, league)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                player_data['id_number'],
                player_data['first'],
                player_data['last'],
                player_data['handicap'],
                player_data['skat_number'],
                player_data['cell'],
                player_data['email'],
                self.selected_league
            ))
            
            conn.commit()
            conn.close()
            
            self.clear_form()
            self.refresh_player_list()
            
        except sqlite3.IntegrityError:
            conn.close()
            QuickPopup.validation_error('Player ID already exists!')
            self.clear_form()
        except Exception as e:
            conn.close()
            QuickPopup.database_error(str(e))
            self.clear_form()
    
    def update_player(self, instance=None):
        """Update the selected player."""
        if not self.selected_player:
            QuickPopup.no_selection("player")
            return
        
        if not self.validate_form():
            return
        
        player_data = self.get_form_data()
        original_id = int(self.selected_player['id_number']) if str(self.selected_player['id_number']).strip() else 0
        
        try:
            # Use WAL mode to allow concurrent access and with statement for proper cleanup
            with sqlite3.connect(self.db_name, timeout=30.0) as conn:
                conn.execute("PRAGMA journal_mode=WAL")
                conn.execute("PRAGMA busy_timeout = 30000")  # 30 second timeout
                conn.execute("PRAGMA synchronous = NORMAL")  # Better performance
                cursor = conn.cursor()
                
                # Check if the record exists
                cursor.execute("SELECT * FROM players WHERE id_number=?", (original_id,))
                existing_record = cursor.fetchone()
                
                if not existing_record:
                    return
                
                # Update the player
                cursor.execute("""
                    UPDATE players 
                    SET id_number=?, first=?, last=?, handicap=?, skat_number=?, cell=?, email=?, league=?
                    WHERE id_number=? AND league=?
                """, (
                    player_data['id_number'],
                    player_data['first'],
                    player_data['last'],
                    player_data['handicap'],
                    player_data['skat_number'],
                    player_data['cell'],
                    player_data['email'],
                    self.selected_league,
                    original_id,
                    self.selected_league
                ))
                
                conn.commit()
            
            # Refresh the entire player list to ensure display is updated
            self.refresh_player_list()
            self.clear_form()
            
        except Exception as e:
            QuickPopup.database_error(str(e))
            self.clear_form()
    
    def delete_player(self, instance=None):
        """Delete the selected player."""
        if not self.selected_player:
            QuickPopup.no_selection("player")
            return
        
        # Use unified confirmation dialog with clear form on "No"
        player_name = f"{self.selected_player['first']} {self.selected_player['last']}"
        QuickPopup.confirm(
            'Confirm Delete',
            f'Are you sure you want to delete {player_name}?\n\nThis action cannot be undone.',
            on_yes=self.perform_delete,
            on_no=self.clear_form
        )
    
    def perform_delete(self):
        """Actually delete the player from database."""
        try:
            conn = sqlite3.connect(self.db_name)
            cursor = conn.cursor()
            
            cursor.execute("DELETE FROM players WHERE id_number=? AND league=?", (self.selected_player['id_number'], self.selected_league))
            
            conn.commit()
            conn.close()
            
            self.clear_form()
            self.refresh_player_list()
            
        except Exception as e:
            QuickPopup.database_error(str(e))
            self.clear_form()
    
    def clear_form(self, instance=None):
        """Clear all form fields and reset selection."""
        self.id_entry.text = ""
        self.first_entry.text = ""
        self.last_entry.text = ""
        self.handicap_entry.text = ""
        self.skat_entry.text = ""
        self.cell_entry.text = ""
        self.email_entry.text = ""
        self.selected_player = None
        
        # Clear list selection highlighting
        for child in self.player_list_layout.children:
            if hasattr(child, 'bg_rect'):
                child.canvas.before.clear()
                with child.canvas.before:
                    Color(0.95, 0.95, 0.95, 1)  # Light gray
                    child.bg_rect = Rectangle(size=child.size, pos=child.pos)
    
    def validate_form(self):
        """Validate form data."""
        if not self.id_entry.text.strip():
            QuickPopup.validation_error('ID Number is required!')
            return False
        
        if not self.first_entry.text.strip():
            QuickPopup.validation_error('First Name is required!')
            return False
        
        if not self.last_entry.text.strip():
            QuickPopup.validation_error('Last Name is required!')
            return False
        
        return True
    
    def get_form_data(self):
        """Get data from form fields."""
        return {
            'id_number': int(self.id_entry.text.strip()) if self.id_entry.text.strip() else 0,
            'first': self.first_entry.text.strip(),
            'last': self.last_entry.text.strip(),
            'handicap': float(self.handicap_entry.text.strip()) if self.handicap_entry.text.strip() else 0.0,
            'skat_number': int(self.skat_entry.text.strip()) if self.skat_entry.text.strip() else 0,
            'cell': self.cell_entry.text.strip(),
            'email': self.email_entry.text.strip()
        }
    
    def update_player_row(self, original_id, new_player_data):
        """Update a specific player row without refreshing the entire list."""
        for child in self.player_list_layout.children:
            if hasattr(child, 'player_data') and child.player_data.get('id_number') == original_id:
                # Update the stored player data
                child.player_data = {
                    'id_number': new_player_data['id_number'],
                    'first': new_player_data['first'],
                    'last': new_player_data['last'],
                    'handicap': new_player_data['handicap'],
                    'skat_number': new_player_data['skat_number'],
                    'cell': new_player_data['cell'],
                    'email': new_player_data['email']
                }
                
                # Update the displayed text in each cell
                row_data = [
                    str(new_player_data['id_number']),
                    new_player_data['first'],
                    new_player_data['last'],
                    str(new_player_data['handicap']),
                    str(new_player_data['skat_number']),
                    self.format_phone_number(new_player_data['cell']),
                    new_player_data['email']
                ]
                
                # Update each cell's text (reverse order due to how children are stored)
                for i, cell_widget in enumerate(child.children):
                    if i < len(row_data):
                        cell_widget.text = row_data[len(row_data) - 1 - i]
                
                break
    
    def return_to_main_menu(self, instance=None):
        """Return to main menu."""
        self.manager.current = 'unified_main_menu'