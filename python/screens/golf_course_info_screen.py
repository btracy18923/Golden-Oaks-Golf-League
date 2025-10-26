"""
Golf Course Info Screen for Golden Oaks Golf League
==================================================

This module contains the GolfCourseInfoScreen class for managing golf course information.
Converted from golf_course_info.py to work as a Screen in the main app.
"""

import os
import sqlite3
import re
from kivy.uix.screenmanager import Screen
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.gridlayout import GridLayout
from kivy.uix.label import Label
from kivy.uix.textinput import TextInput
from kivy.uix.popup import Popup
from kivy.uix.scrollview import ScrollView
from kivy.clock import Clock
from kivy.metrics import dp
from kivy.graphics import Color, Rectangle, Line, RoundedRectangle
from kivy.uix.behaviors import ButtonBehavior
from kivy.core.window import Window

# Import unified popup system
try:
    from .popup_utils import QuickPopup, UnifiedPopup
except ImportError:
    from popup_utils import QuickPopup, UnifiedPopup


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


class NavigableTextInput(TextInput):
    """Custom TextInput that handles TAB navigation."""
    
    def __init__(self, navigation_handler=None, **kwargs):
        super().__init__(**kwargs)
        self.navigation_handler = navigation_handler
    
    def keyboard_on_key_down(self, window, keycode, text, modifiers):
        """Override keyboard handling to catch TAB keys."""
        key_code, key_string = keycode
        
        if key_string == 'tab' and self.navigation_handler:
            print(f"TAB intercepted in NavigableTextInput!")
            # Call the navigation handler
            if 'shift' in modifiers:
                self.navigation_handler(self, 'prev')
            else:
                self.navigation_handler(self, 'next')
            return True  # Consume the event
        
        # Let parent handle other keys
        return super().keyboard_on_key_down(window, keycode, text, modifiers)


class ColoredButton(ButtonBehavior, Label):
    def __init__(self, bg_color=(1, 1, 1, 1), **kwargs):
        super().__init__(**kwargs)
        self.bg_color = bg_color
        with self.canvas.before:
            # Background color with rounded corners
            self.color_instruction = Color(*bg_color)
            self.rect = RoundedRectangle(size=self.size, pos=self.pos, radius=[10])
        with self.canvas.after:
            # Black border with rounded corners
            Color(0, 0, 0, 1)  # Black color
            self.border = Line(rounded_rectangle=(self.x, self.y, self.width, self.height, 10), width=2)
        self.bind(size=self.update_graphics, pos=self.update_graphics)
    
    def update_graphics(self, *args):
        self.rect.size = self.size
        self.rect.pos = self.pos
        self.border.rounded_rectangle = (self.x, self.y, self.width, self.height, 10)
    
    def set_bg_color(self, color):
        """Method to change the background color."""
        self.bg_color = color
        if hasattr(self, 'color_instruction'):
            self.color_instruction.rgba = color
    
    def set_button_visible(self, visible):
        """Set the visibility of the button by changing background color."""
        self.canvas.before.clear()
        with self.canvas.before:
            if visible:
                self.color_instruction = Color(*self.bg_color)  # Original button color
            else:
                self.color_instruction = Color(0.9, 0.9, 0.9, 1)  # Match window background - effectively invisible
            self.rect = RoundedRectangle(size=self.size, pos=self.pos, radius=[10])
        with self.canvas.after:
            # Always keep the border visible
            Color(0, 0, 0, 1)  # Black color
            self.border = Line(rounded_rectangle=(self.x, self.y, self.width, self.height, 10), width=2)




class GolfCourseDB:
    def __init__(self, db_name="GoldenOaks.db"):
        # Ensure we're looking in the python directory for the database
        script_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # Go up from screens/ to python/
        self.db_name = os.path.join(script_dir, db_name)
        self.init_database()
    
    def init_database(self):
        """Initialize the database and create golf_courses table if it doesn't exist."""
        conn = sqlite3.connect(self.db_name)
        cursor = conn.cursor()
        
        # Check if golf_courses table exists
        cursor.execute("PRAGMA table_info(golf_courses)")
        columns_info = cursor.fetchall()
        
        if not columns_info:
            cursor.execute("""
                CREATE TABLE golf_courses (
                    id_number TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    address TEXT,
                    city TEXT,
                    state TEXT,
                    zip TEXT,
                    phone TEXT,
                    website TEXT,
                    holes INTEGER,
                    tees TEXT,
                    slope INTEGER,
                    travel_time TEXT
                )
            """)
        
        conn.commit()
        conn.close()
    
    def add_golf_course(self, id_number, name, address, city, state, zip_code, phone, website, holes, tees, slope, travel_time):
        """Add a new golf course to the database."""
        conn = sqlite3.connect(self.db_name)
        cursor = conn.cursor()
        
        try:
            cursor.execute("""
                INSERT INTO golf_courses (id_number, name, address, city, state, zip, phone, website, holes, tees, slope, travel_time)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (id_number, name, address, city, state, zip_code, phone, website, holes, tees, slope, travel_time))
            conn.commit()
            return True
        except sqlite3.IntegrityError:
            return False
        finally:
            conn.close()
    
    def get_all_golf_courses(self):
        """Get all golf courses from the database."""
        conn = sqlite3.connect(self.db_name)
        cursor = conn.cursor()
        
        cursor.execute("SELECT * FROM golf_courses ORDER BY CAST(id_number AS INTEGER)")
        courses = cursor.fetchall()
        conn.close()
        
        return courses
    
    def update_golf_course(self, original_id, new_id, name, address, city, state, zip_code, phone, website, holes, tees, slope, travel_time):
        """Update an existing golf course using original ID# to find the record."""
        conn = sqlite3.connect(self.db_name)
        cursor = conn.cursor()
        
        try:
            cursor.execute("""
                UPDATE golf_courses 
                SET id_number = ?, name = ?, address = ?, city = ?, state = ?, zip = ?, phone = ?, website = ?, holes = ?, tees = ?, slope = ?, travel_time = ?
                WHERE id_number = ?
            """, (new_id, name, address, city, state, zip_code, phone, website, holes, tees, slope, travel_time, original_id))
            conn.commit()
            return True
        except sqlite3.Error:
            return False
        finally:
            conn.close()
    
    def delete_golf_course(self, id_number):
        """Delete a golf course from the database using ID#."""
        conn = sqlite3.connect(self.db_name)
        cursor = conn.cursor()
        
        cursor.execute("DELETE FROM golf_courses WHERE id_number = ?", (id_number,))
        conn.commit()
        success = cursor.rowcount > 0
        conn.close()
        
        return success


class CourseDetailPopup(Popup):
    """Popup window to display course details."""
    
    def __init__(self, course_data, **kwargs):
        super().__init__(**kwargs)
        self.course_data = course_data
        self.title = f"Course Details - {course_data.get('name', 'Unknown')}"
        self.size_hint = (0.6, 0.85)
        
        # Create content layout
        content = BoxLayout(orientation='vertical', spacing=dp(10), padding=dp(15))
        
        # Add light-gold background with rounded corners
        with content.canvas.before:
            Color(1.0, 0.9, 0.5, 1)  # Light-gold background
            content.bg_rect = RoundedRectangle(size=content.size, pos=content.pos, radius=[15])
        content.bind(size=self._update_content_rect, pos=self._update_content_rect)
        
        # Create details grid
        details_grid = GridLayout(cols=2, spacing=dp(10), size_hint_y=None)
        details_grid.bind(minimum_height=details_grid.setter('height'))
        
        # Format phone number
        phone_value = course_data.get('phone', '')
        formatted_phone = self.format_phone_number(phone_value) if phone_value else 'Not provided'
        
        # Course details to display
        details = [
            ('Course ID:', course_data.get('id_number', 'Not provided')),
            ('Course Name:', course_data.get('name', 'Not provided')),
            ('Address:', course_data.get('address', 'Not provided')),
            ('City:', course_data.get('city', 'Not provided')),
            ('State:', course_data.get('state', 'Not provided')),
            ('ZIP Code:', course_data.get('zip', 'Not provided')),
            ('Phone Number:', formatted_phone),
            ('Website:', course_data.get('website', 'Not provided')),
            ('Number of Holes:', str(course_data.get('holes', 'Not provided'))),
            ('Tees:', course_data.get('tees', 'Not provided')),
            ('Slope Rating:', str(course_data.get('slope', 'Not provided'))),
            ('Travel Time:', course_data.get('travel_time', 'Not provided'))
        ]
        
        for label_text, value_text in details:
            # Label
            label = Label(
                text=label_text,
                color=(0, 0, 0, 1),
                font_size='16sp',
                bold=True,
                size_hint_y=None,
                height=dp(30),
                halign='right',
                valign='middle'
            )
            label.bind(size=label.setter('text_size'))
            details_grid.add_widget(label)
            
            # Value
            value = Label(
                text=str(value_text),
                color=(0, 0, 0, 1),
                font_size='16sp',
                size_hint_y=None,
                height=dp(30),
                halign='left',
                valign='middle'
            )
            value.bind(size=value.setter('text_size'))
            details_grid.add_widget(value)
        
        # Scroll view for details
        scroll = ScrollView()
        scroll.add_widget(details_grid)
        content.add_widget(scroll)
        
        # Close button
        close_btn = ColoredButton(
            text="Close",
            bg_color=(0.8, 0.8, 1.0, 1),
            color=(0, 0, 0, 1),
            font_size='16sp',
            size_hint_y=None,
            height=dp(50),
            bold=True
        )
        close_btn.bind(on_press=self.dismiss)
        content.add_widget(close_btn)
        
        self.content = content
    
    def _update_content_rect(self, instance, value):
        """Update background rectangle when content size/position changes."""
        if hasattr(instance, 'bg_rect'):
            instance.bg_rect.size = instance.size
            instance.bg_rect.pos = instance.pos
    
    def format_phone_number(self, phone):
        """Format phone number as xxx-xxx-xxxx."""
        if not phone:
            return ''
        
        # Remove all non-digit characters
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


class SimpleGolfCourseRow(BoxLayout):
    """Simple widget for individual golf course rows."""
    
    def __init__(self, data, callback=None, main_widget=None, **kwargs):
        super().__init__(**kwargs)
        self.orientation = 'horizontal'
        self.size_hint = (1.0, None)  # Use full width
        self.height = '30dp'  # Use string format like Player_Scores
        self.data = data
        self.callback = callback
        self.main_widget = main_widget
        
        # Background (exact copy of ClickableRow)
        with self.canvas.before:
            Color(0.9, 0.9, 0.9, 1)  # Light gray background like Player_Scores
            self.bg_rect = Rectangle(size=self.size, pos=self.pos)
        self.bind(size=self.update_rect, pos=self.update_rect)
        
        # Updated column widths - removed address, city, state, zip, phone, website columns
        # Now showing: ID#, Name, Holes, Tees, Slope, Travel Time, Details Button
        column_widths = [0.10, 0.30, 0.10, 0.15, 0.10, 0.15, 0.10]  # Total = 1.0
        
        data_items = [
            str(data.get('id_number', '')),
            str(data.get('name', '')),
            str(data.get('holes', '')),
            str(data.get('tees', '')),
            str(data.get('slope', '')),
            str(data.get('travel_time', ''))
        ]
        
        # Create labels for the data columns
        for i, item in enumerate(data_items):
            item_label = Label(
                text=str(item),
                color=(0, 0, 0, 1),
                size_hint=(column_widths[i], 1),
                font_size='14sp',  # Exact match
                halign='center',  # Center all columns
                valign='middle',
                bold=True
            )
            item_label.bind(size=item_label.setter('text_size'))
            self.add_widget(item_label)
        
        # Add Details button
        details_btn = ColoredButton(
            text="More Details",
            bg_color=(0.8, 0.8, 1.0, 1),  # Light blue
            color=(0, 0, 0, 1),
            font_size='12sp',
            size_hint=(column_widths[6], 1),
            bold=True
        )
        
        def debug_button_click(instance):
            self.show_details(instance)
        
        details_btn.bind(on_press=debug_button_click)
        self.add_widget(details_btn)
    
    def show_details(self, instance):
        """Show course details in a popup window."""
        popup = CourseDetailPopup(self.data)
        popup.open()
        
    def format_phone_number(self, phone):
        """Format phone number as xxx-xxx-xxxx."""
        if not phone:
            return ''
        
        # Remove all non-digit characters
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
    
    def update_rect(self, *args):
        """Update background rectangle - exact copy from ClickableRow."""
        if hasattr(self, 'bg_rect'):
            self.bg_rect.size = self.size
            self.bg_rect.pos = self.pos
            
    def on_touch_down(self, touch):
        """Handle touch down events for row selection."""
        if self.collide_point(*touch.pos):
            # Check if the touch is on the Details button - if so, handle it directly
            for child in self.children:
                if hasattr(child, 'text') and child.text == "More Details":
                    if child.collide_point(*touch.pos):
                        # Directly call show_details instead of letting row handle it
                        self.show_details(None)
                        return True
            
            # Handle row selection for other areas
            if self.callback:
                self.callback(self.data)
            return True
        return super().on_touch_down(touch)
    
    def set_selected(self, selected):
        """Set selection state."""
        self.canvas.before.clear()
        with self.canvas.before:
            if selected:
                Color(0.7, 1.0, 0.7, 1)  # Light green for selection (like Player_Scores)
            else:
                Color(0.9, 0.9, 0.9, 1)  # Light gray for normal
            self.bg_rect = Rectangle(size=self.size, pos=self.pos)
        self.update_rect()


class GolfCourseInfoScreen(Screen):
    """
    Golf course information management screen.
    Handles adding, editing, and deleting golf course data.
    """
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        # Set light gray background
        with self.canvas.before:
            Color(0.9, 0.9, 0.9, 1)  # Light gray background
            self.bg_rect = Rectangle(pos=self.pos, size=self.size)
        self.bind(pos=self.update_bg, size=self.update_bg)
        
        self.db = GolfCourseDB()
        self.selected_player = None
        
        # Button references
        self.add_button = None
        self.edit_button = None
        self.delete_button = None
        self.clear_btn = None
        
        # Setup UI
        self.add_widget(self.setup_ui())
        
        # Use Clock.schedule_once to ensure UI is fully set up before refreshing
        Clock.schedule_once(lambda dt: self.refresh_course_list(), 0.1)
    
    def set_league(self, league_type):
        """Set the league type - golf courses are shared between leagues."""
    
    def update_bg(self, instance, value):
        """Update background rectangle when widget moves or resizes."""
        if hasattr(self, 'bg_rect'):
            self.bg_rect.pos = self.pos
            self.bg_rect.size = self.size
    
    def update_text_input_border(self, instance, value):
        """Update text input border when input moves or resizes."""
        if hasattr(instance, 'border_line'):
            instance.border_line.rounded_rectangle = (instance.x, instance.y, instance.width, instance.height, 10)
    
    def setup_ui(self):
        """Set up the user interface."""
        main_layout = BoxLayout(orientation='vertical', padding=dp(10), spacing=dp(10))
        
        # Title
        title_label = Label(text="Course Info", font_size='20sp', size_hint_y=None, height=dp(50), color=(0, 0, 0, 1), bold=True)
        main_layout.add_widget(title_label)
        
        # Horizontal layout for form and list
        content_layout = BoxLayout(orientation='horizontal', spacing=dp(10))
        
        # Left side - Form (reduced width to give right frame more space)
        form_layout = BoxLayout(orientation='vertical', size_hint_x=0.22, spacing=dp(5))
        
        # Create a top-aligned container
        top_container = BoxLayout(orientation='vertical', size_hint_y=None, spacing=dp(5))
        top_container.bind(minimum_height=top_container.setter('height'))
        
        # Form fields
        form_grid = GridLayout(cols=2, spacing=dp(5), size_hint_y=None)
        form_grid.bind(minimum_height=form_grid.setter('height'))
        
        # ID Number
        form_grid.add_widget(Label(text="ID#:", size_hint_y=None, height=dp(40), color=(0, 0, 0, 1), bold=True))
        self.id_entry = NavigableTextInput(multiline=False, size_hint_y=None, height=dp(40), 
                                   foreground_color=(0, 0, 0, 1), cursor_color=(0, 0, 0, 1), cursor_width=dp(3),
                                   halign='center', padding=[5, 12], navigation_handler=self.handle_tab_navigation)
        with self.id_entry.canvas.before:
            Color(0, 0, 0, 1)  # Black border
            self.id_entry.border_line = Line(width=2)
        self.id_entry.bind(pos=self.update_text_input_border, size=self.update_text_input_border)
        form_grid.add_widget(self.id_entry)
        
        # Name
        form_grid.add_widget(Label(text="Name:", size_hint_y=None, height=dp(40), color=(0, 0, 0, 1), bold=True))
        self.name_entry = NavigableTextInput(multiline=False, size_hint_y=None, height=dp(40), 
                                   foreground_color=(0, 0, 0, 1), cursor_color=(0, 0, 0, 1), cursor_width=dp(3),
                                   halign='center', padding=[5, 12], navigation_handler=self.handle_tab_navigation)
        with self.name_entry.canvas.before:
            Color(0, 0, 0, 1)  # Black border
            self.name_entry.border_line = Line(width=2)
        self.name_entry.bind(pos=self.update_text_input_border, size=self.update_text_input_border)
        form_grid.add_widget(self.name_entry)
        
        # Address
        form_grid.add_widget(Label(text="Address:", size_hint_y=None, height=dp(40), color=(0, 0, 0, 1), bold=True))
        self.address_entry = NavigableTextInput(multiline=False, size_hint_y=None, height=dp(40), 
                                  foreground_color=(0, 0, 0, 1), cursor_color=(0, 0, 0, 1), cursor_width=dp(3),
                                  halign='center', padding=[5, 12], navigation_handler=self.handle_tab_navigation)
        with self.address_entry.canvas.before:
            Color(0, 0, 0, 1)  # Black border
            self.address_entry.border_line = Line(width=2)
        self.address_entry.bind(pos=self.update_text_input_border, size=self.update_text_input_border)
        form_grid.add_widget(self.address_entry)
        
        # City
        form_grid.add_widget(Label(text="City:", size_hint_y=None, height=dp(40), color=(0, 0, 0, 1), bold=True))
        self.city_entry = NavigableTextInput(multiline=False, size_hint_y=None, height=dp(40), 
                                      foreground_color=(0, 0, 0, 1), cursor_color=(0, 0, 0, 1), cursor_width=dp(3),
                                      halign='center', padding=[5, 12], navigation_handler=self.handle_tab_navigation)
        with self.city_entry.canvas.before:
            Color(0, 0, 0, 1)  # Black border
            self.city_entry.border_line = Line(width=2)
        self.city_entry.bind(pos=self.update_text_input_border, size=self.update_text_input_border)
        form_grid.add_widget(self.city_entry)
        
        # State
        form_grid.add_widget(Label(text="State:", size_hint_y=None, height=dp(40), color=(0, 0, 0, 1), bold=True))
        self.state_entry = NavigableTextInput(multiline=False, size_hint_y=None, height=dp(40), 
                                  foreground_color=(0, 0, 0, 1), cursor_color=(0, 0, 0, 1), cursor_width=dp(3),
                                  halign='center', padding=[5, 12], navigation_handler=self.handle_tab_navigation)
        with self.state_entry.canvas.before:
            Color(0, 0, 0, 1)  # Black border
            self.state_entry.border_line = Line(width=2)
        self.state_entry.bind(pos=self.update_text_input_border, size=self.update_text_input_border)
        form_grid.add_widget(self.state_entry)
        
        # Zip
        form_grid.add_widget(Label(text="Zip:", size_hint_y=None, height=dp(40), color=(0, 0, 0, 1), bold=True))
        self.zip_entry = NavigableTextInput(multiline=False, size_hint_y=None, height=dp(40), 
                                   foreground_color=(0, 0, 0, 1), cursor_color=(0, 0, 0, 1), cursor_width=dp(3),
                                   halign='center', padding=[5, 12], navigation_handler=self.handle_tab_navigation)
        with self.zip_entry.canvas.before:
            Color(0, 0, 0, 1)  # Black border
            self.zip_entry.border_line = Line(width=2)
        self.zip_entry.bind(pos=self.update_text_input_border, size=self.update_text_input_border)
        form_grid.add_widget(self.zip_entry)
        
        # Phone
        form_grid.add_widget(Label(text="Phone #:", size_hint_y=None, height=dp(40), color=(0, 0, 0, 1), bold=True))
        self.phone_entry = NavigableTextInput(multiline=False, size_hint_y=None, height=dp(40), 
                                   foreground_color=(0, 0, 0, 1), cursor_color=(0, 0, 0, 1), cursor_width=dp(3),
                                   halign='center', padding=[5, 12], navigation_handler=self.handle_tab_navigation)
        with self.phone_entry.canvas.before:
            Color(0, 0, 0, 1)  # Black border
            self.phone_entry.border_line = Line(width=2)
        self.phone_entry.bind(pos=self.update_text_input_border, size=self.update_text_input_border)
        form_grid.add_widget(self.phone_entry)
        
        # Website
        form_grid.add_widget(Label(text="Website:", size_hint_y=None, height=dp(40), color=(0, 0, 0, 1), bold=True))
        self.website_entry = NavigableTextInput(multiline=False, size_hint_y=None, height=dp(40), 
                                   foreground_color=(0, 0, 0, 1), cursor_color=(0, 0, 0, 1), cursor_width=dp(3),
                                   halign='center', padding=[5, 12], navigation_handler=self.handle_tab_navigation)
        with self.website_entry.canvas.before:
            Color(0, 0, 0, 1)  # Black border
            self.website_entry.border_line = Line(width=2)
        self.website_entry.bind(pos=self.update_text_input_border, size=self.update_text_input_border)
        form_grid.add_widget(self.website_entry)
        
        # # Holes
        form_grid.add_widget(Label(text="# Holes:", size_hint_y=None, height=dp(40), color=(0, 0, 0, 1), bold=True))
        self.holes_entry = NavigableTextInput(multiline=False, size_hint_y=None, height=dp(40), 
                                   foreground_color=(0, 0, 0, 1), cursor_color=(0, 0, 0, 1), cursor_width=dp(3),
                                   halign='center', padding=[5, 12], navigation_handler=self.handle_tab_navigation)
        with self.holes_entry.canvas.before:
            Color(0, 0, 0, 1)  # Black border
            self.holes_entry.border_line = Line(width=2)
        self.holes_entry.bind(pos=self.update_text_input_border, size=self.update_text_input_border)
        form_grid.add_widget(self.holes_entry)
        
        # Tees
        form_grid.add_widget(Label(text="Tees:", size_hint_y=None, height=dp(40), color=(0, 0, 0, 1), bold=True))
        self.tees_entry = NavigableTextInput(multiline=False, size_hint_y=None, height=dp(40), 
                                   foreground_color=(0, 0, 0, 1), cursor_color=(0, 0, 0, 1), cursor_width=dp(3),
                                   halign='center', padding=[5, 12], navigation_handler=self.handle_tab_navigation)
        with self.tees_entry.canvas.before:
            Color(0, 0, 0, 1)  # Black border
            self.tees_entry.border_line = Line(width=2)
        self.tees_entry.bind(pos=self.update_text_input_border, size=self.update_text_input_border)
        form_grid.add_widget(self.tees_entry)
        
        # Slope
        form_grid.add_widget(Label(text="Slope:", size_hint_y=None, height=dp(40), color=(0, 0, 0, 1), bold=True))
        self.slope_entry = NavigableTextInput(multiline=False, size_hint_y=None, height=dp(40), 
                                   foreground_color=(0, 0, 0, 1), cursor_color=(0, 0, 0, 1), cursor_width=dp(3),
                                   halign='center', padding=[5, 12], navigation_handler=self.handle_tab_navigation)
        with self.slope_entry.canvas.before:
            Color(0, 0, 0, 1)  # Black border
            self.slope_entry.border_line = Line(width=2)
        self.slope_entry.bind(pos=self.update_text_input_border, size=self.update_text_input_border)
        form_grid.add_widget(self.slope_entry)
        
        # Travel Time
        form_grid.add_widget(Label(text="Travel Time:", size_hint_y=None, height=dp(40), color=(0, 0, 0, 1), bold=True))
        self.travel_time_entry = NavigableTextInput(multiline=False, size_hint_y=None, height=dp(40), 
                                   foreground_color=(0, 0, 0, 1), cursor_color=(0, 0, 0, 1), cursor_width=dp(3),
                                   halign='center', padding=[5, 12], navigation_handler=self.handle_tab_navigation)
        with self.travel_time_entry.canvas.before:
            Color(0, 0, 0, 1)  # Black border
            self.travel_time_entry.border_line = Line(width=2)
        self.travel_time_entry.bind(pos=self.update_text_input_border, size=self.update_text_input_border)
        form_grid.add_widget(self.travel_time_entry)
        
        top_container.add_widget(form_grid)
        
        # Bind keyboard events for navigation
        self.id_entry.bind(on_text_validate=self.on_text_validate)
        self.name_entry.bind(on_text_validate=self.on_text_validate)
        self.address_entry.bind(on_text_validate=self.on_text_validate)
        self.city_entry.bind(on_text_validate=self.on_text_validate)
        self.state_entry.bind(on_text_validate=self.on_text_validate)
        self.zip_entry.bind(on_text_validate=self.on_text_validate)
        self.phone_entry.bind(on_text_validate=self.on_text_validate)
        self.website_entry.bind(on_text_validate=self.on_text_validate)
        self.holes_entry.bind(on_text_validate=self.on_text_validate)
        self.tees_entry.bind(on_text_validate=self.on_text_validate)
        self.slope_entry.bind(on_text_validate=self.on_text_validate)
        self.travel_time_entry.bind(on_text_validate=self.on_text_validate)
        
        # Create a list of all input fields in tab order
        self.input_fields = [
            self.id_entry,
            self.name_entry,
            self.address_entry, 
            self.city_entry,
            self.state_entry,
            self.zip_entry,
            self.phone_entry,
            self.website_entry,
            self.holes_entry,
            self.tees_entry,
            self.slope_entry,
            self.travel_time_entry
        ]
        
        # Buttons - matching Player_Scores styling
        button_layout = BoxLayout(orientation='horizontal', size_hint_y=None, height=dp(50), spacing=dp(5))
        
        self.add_button = ColoredButton(
            text="Add Course",
            bg_color=(0.7, 1.0, 0.7, 1),  # Light green (same as Add Score)
            color=(0, 0, 0, 1),
            font_size='16sp',
            bold=True
        )
        self.add_button.bind(on_press=self.add_player)
        button_layout.add_widget(self.add_button)
        
        self.edit_button = ColoredButton(
            text="Edit Course",
            bg_color=(0.8, 0.8, 1.0, 1),  # Light blue (same as Edit Score)
            color=(0, 0, 0, 1),
            font_size='16sp',
            bold=True
        )
        self.edit_button.bind(on_press=self.update_player)
        button_layout.add_widget(self.edit_button)
        
        self.delete_button = ColoredButton(
            text="Delete Course",
            bg_color=(1.0, 0.7, 0.7, 1),  # Light red (same as Delete Score)
            color=(0, 0, 0, 1),
            font_size='16sp',
            bold=True
        )
        self.delete_button.bind(on_press=self.delete_player)
        button_layout.add_widget(self.delete_button)
        
        top_container.add_widget(button_layout)
        
        # Clear Form button (separate row)
        self.clear_btn = ColoredButton(
            text="Clear Form",
            bg_color=(1.0, 0.9, 0.5, 1),  # Light gold (same as Player_Scores)
            color=(0, 0, 0, 1),
            font_size='16sp',
            size_hint_y=None,
            height=dp(50),
            bold=True
        )
        self.clear_btn.bind(on_press=self.clear_form)
        top_container.add_widget(self.clear_btn)
        
        # Return to Main Menu button
        return_btn = ColoredButton(
            text="Return to Main Menu",
            bg_color=(1.0, 0.7, 0.7, 1),  # Light red
            color=(0, 0, 0, 1),
            font_size='16sp',
            size_hint_y=None,
            height=dp(50),
            bold=True
        )
        return_btn.bind(on_press=self.return_to_main_menu)
        top_container.add_widget(return_btn)
        
        # Add the top container to the form layout (this pushes everything to the top)
        form_layout.add_widget(top_container)
        
        # Add a spacer to push everything to the top
        spacer = BoxLayout()  # This will expand to fill remaining space
        form_layout.add_widget(spacer)
        
        content_layout.add_widget(form_layout)
        
        # Right side - Course List (increased width for better column spacing)
        list_layout = BoxLayout(orientation='vertical', size_hint_x=0.78)
        
        # Headers - use full width of right frame
        header_layout = BoxLayout(orientation='horizontal', size_hint=(1.0, None), height=dp(35))
        # Updated column widths to match the simplified layout
        header_column_widths = [0.10, 0.30, 0.10, 0.15, 0.10, 0.15, 0.10]  # Total = 1.0
        headers = ["ID#", "Name", "# Holes", "Tees", "Slope", "Travel Time", "More Details"]
        
        for i, (header, width) in enumerate(zip(headers, header_column_widths)):
            header_layout.add_widget(BorderedHeaderLabel(text=header, bold=True, size_hint_x=width, color=(0, 0, 0, 1), font_size='16sp'))
        list_layout.add_widget(header_layout)
        
        # ScrollView with visible scrollbar (like Player_Scores)
        scroll = ScrollView(
            bar_width=dp(10),           # Make scrollbar wider
            bar_color=[0, 0, 0, 1],     # Black scrollbar
            bar_inactive_color=[0, 0, 0, 0.3],  # Dark gray when inactive
            scroll_type=['bars', 'content'],  # Show both scrollbar and allow content scrolling
            bar_pos_y='right'           # Position scrollbar on right side
        )
        self.player_list_layout = BoxLayout(orientation='vertical', size_hint_y=None, spacing=2)
        self.player_list_layout.bind(minimum_height=self.player_list_layout.setter('height'))
        scroll.add_widget(self.player_list_layout)
        list_layout.add_widget(scroll)
        content_layout.add_widget(list_layout)
        
        main_layout.add_widget(content_layout)
        return main_layout
    
    def handle_tab_navigation(self, field, direction):
        """Handle TAB navigation between fields."""
        
        if field in self.input_fields:
            current_index = self.input_fields.index(field)
            
            if direction == 'next':
                next_index = (current_index + 1) % len(self.input_fields)
            else:  # direction == 'prev'
                next_index = (current_index - 1) % len(self.input_fields)
            
            # Move focus
            field.focus = False
            Clock.schedule_once(lambda dt: setattr(self.input_fields[next_index], 'focus', True), 0.01)
    
    def on_text_validate(self, instance):
        """Handle Return key press - move to next field."""
        if instance in self.input_fields:
            current_index = self.input_fields.index(instance)
            next_index = (current_index + 1) % len(self.input_fields)
            
            # Set focus to next field
            instance.focus = False
            self.input_fields[next_index].focus = True

    def validate_email(self, email):
        """Validate email format."""
        if not email:
            return True  # Email is optional
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        return re.match(pattern, email) is not None
    
    def validate_phone(self, phone):
        """Validate phone number format."""
        if not phone:
            return True  # Phone is optional
        # Remove all non-digit characters
        digits = re.sub(r'\D', '', phone)
        return len(digits) == 10 or len(digits) == 11
    
    
    
    def add_player(self, instance=None):
        """Add a new golf course."""
        
        print("Add course button clicked!")  # Debug
        id_number = self.id_entry.text.strip()
        name = self.name_entry.text.strip()
        address = self.address_entry.text.strip()
        city = self.city_entry.text.strip()
        state = self.state_entry.text.strip()
        zip_code = self.zip_entry.text.strip()
        phone = self.phone_entry.text.strip()
        website = self.website_entry.text.strip()
        holes_str = self.holes_entry.text.strip()
        tees = self.tees_entry.text.strip()
        slope_str = self.slope_entry.text.strip()
        travel_time = self.travel_time_entry.text.strip()
        

        if not id_number or not name:
            QuickPopup.validation_error("ID# and Name are required!")
            return
        
        # Validate ID# is 4 digits
        if not id_number.isdigit() or len(id_number) != 4:
            QuickPopup.validation_error("ID# must be exactly 4 digits!")
            return
        
        # Validate holes if provided
        holes = None
        if holes_str:
            try:
                holes = int(holes_str)
            except ValueError:
                QuickPopup.validation_error("Number of holes must be a whole number!")
                return
        
        # Validate slope if provided
        slope = None
        if slope_str:
            try:
                slope = int(slope_str)
            except ValueError:
                QuickPopup.validation_error("Slope must be a whole number!")
                return
        
        if phone and not self.validate_phone(phone):
            QuickPopup.validation_error("Please enter a valid phone number (10-11 digits)!")
            return
        
        if self.db.add_golf_course(id_number, name, address, city, state, zip_code, phone, website, holes, tees, slope, travel_time):
            self.clear_form()
            self.refresh_course_list()
        else:
            QuickPopup.error("Error", "Course with this ID# already exists!")
    
    def update_player(self, instance=None):
        """Update selected golf course."""
        
        if not self.selected_player:
            QuickPopup.no_selection("course to update")
            return
        
        id_number = self.id_entry.text.strip()
        name = self.name_entry.text.strip()
        address = self.address_entry.text.strip()
        city = self.city_entry.text.strip()
        state = self.state_entry.text.strip()
        zip_code = self.zip_entry.text.strip()
        phone = self.phone_entry.text.strip()
        website = self.website_entry.text.strip()
        holes_str = self.holes_entry.text.strip()
        tees = self.tees_entry.text.strip()
        slope_str = self.slope_entry.text.strip()
        travel_time = self.travel_time_entry.text.strip()
        
        if not id_number or not name:
            QuickPopup.validation_error("ID# and Name are required!")
            return
        
        # Validate ID# is 4 digits
        if not id_number.isdigit() or len(id_number) != 4:
            QuickPopup.validation_error("ID# must be exactly 4 digits!")
            return
        
        # Validate holes if provided
        holes = None
        if holes_str:
            try:
                holes = int(holes_str)
            except ValueError:
                QuickPopup.validation_error("Number of holes must be a whole number!")
                return
        
        # Validate slope if provided
        slope = None
        if slope_str:
            try:
                slope = int(slope_str)
            except ValueError:
                QuickPopup.validation_error("Slope must be a whole number!")
                return
        
        if phone and not self.validate_phone(phone):
            QuickPopup.validation_error("Please enter a valid phone number (10-11 digits)!")
            return
        
        # Use the original ID number from the selected course for the update
        original_id = self.selected_player['id_number']
        

        if self.db.update_golf_course(original_id, id_number, name, address, city, state, zip_code, phone, website, holes, tees, slope, travel_time):
            self.clear_form()
            self.refresh_course_list()
        else:
            QuickPopup.error("Error", "Failed to update course - ID# may already exist!")
    
    def delete_player(self, instance=None):
        """Delete selected golf course."""
        
        if not self.selected_player:
            QuickPopup.no_selection("course to delete")
            return
        
        id_number = self.selected_player['id_number']
        course_name = self.selected_player['name']
        
        def confirm_delete():
            if self.db.delete_golf_course(id_number):
                self.clear_form()
                self.refresh_course_list()
                QuickPopup.success("Success", f"Course '{course_name}' deleted successfully!")
            else:
                QuickPopup.error("Error", "Failed to delete course!")
        
        QuickPopup.confirm_delete(f"course '{course_name}'", on_confirm=confirm_delete)
    
    def clear_form(self, instance=None):
        """Clear all form fields."""
        
        self.id_entry.text = ""
        self.name_entry.text = ""
        self.address_entry.text = ""
        self.city_entry.text = ""
        self.state_entry.text = ""
        self.zip_entry.text = ""
        self.phone_entry.text = ""
        self.website_entry.text = ""
        self.holes_entry.text = ""
        self.tees_entry.text = ""
        self.slope_entry.text = ""
        self.travel_time_entry.text = ""
        self.selected_player = None
        
        # Clear selection highlighting
        for child in self.player_list_layout.children:
            if hasattr(child, 'set_selected'):
                child.set_selected(False)
    
    def refresh_course_list(self):
        """Refresh the player list in the ScrollView."""
        
        # Check if player_list_layout exists
        if not hasattr(self, 'player_list_layout') or self.player_list_layout is None:
            return
            
        # Clear existing widgets
        self.player_list_layout.clear_widgets()
        
        courses = self.db.get_all_golf_courses()
        
        if not courses:
            # Add a message if no courses found
            no_data_label = Label(text="No courses found in database", size_hint_y=None, height=dp(40), bold=True)
            self.player_list_layout.add_widget(no_data_label)
            return
        
        
        for i, course in enumerate(courses):
            course_data = {
                'id_number': course[0] if course[0] else '',
                'name': course[1] if course[1] else '',
                'address': course[2] if course[2] else '', 
                'city': course[3] if course[3] else '',
                'state': course[4] if course[4] else '',
                'zip': course[5] if course[5] else '',
                'phone': course[6] if course[6] else '',
                'website': course[7] if course[7] else '',
                'holes': course[8] if course[8] else '',
                'tees': course[9] if course[9] else '',
                'slope': course[10] if course[10] else '',
                'travel_time': course[11] if course[11] else ''
            }

            row = SimpleGolfCourseRow(course_data, callback=self.on_course_select, main_widget=self)
            self.player_list_layout.add_widget(row)

    
    def on_course_select(self, course_data):
        """Handle course selection from the list."""
        self.selected_player = course_data
        
        # Clear previous selection highlighting
        for child in self.player_list_layout.children:
            if hasattr(child, 'set_selected'):
                child.set_selected(False)
        
        # Find and highlight the selected row
        for child in self.player_list_layout.children:
            if hasattr(child, 'data') and child.data == course_data:
                child.set_selected(True)
                break
        
        # Update form fields
        self.id_entry.text = course_data.get('id_number', '')
        self.name_entry.text = course_data.get('name', '')
        self.address_entry.text = course_data.get('address', '')
        self.city_entry.text = course_data.get('city', '')
        self.state_entry.text = course_data.get('state', '')
        self.zip_entry.text = course_data.get('zip', '')
        self.phone_entry.text = course_data.get('phone', '')
        self.website_entry.text = course_data.get('website', '')
        self.holes_entry.text = str(course_data.get('holes', '')) if course_data.get('holes') else ''
        self.tees_entry.text = course_data.get('tees', '')
        self.slope_entry.text = str(course_data.get('slope', '')) if course_data.get('slope') else ''
        self.travel_time_entry.text = course_data.get('travel_time', '')
    
    
    def return_to_main_menu(self, instance=None):
        """Return to the main menu screen."""
        self.manager.current = 'unified_main_menu'