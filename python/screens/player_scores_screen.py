"""
Player Scores Screen for Golden Oaks Golf League
===============================================

This module contains the PlayerScoresScreen class converted from main_android_app.py.
Handles adding, editing, and deleting scores and handicap calculations.
"""

import os
import sqlite3
from datetime import datetime
from kivy.uix.screenmanager import Screen
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.scrollview import ScrollView
from kivy.uix.label import Label
from kivy.uix.textinput import TextInput
from kivy.uix.widget import Widget
from kivy.uix.spinner import Spinner
from kivy.graphics import Color, Rectangle, Line, RoundedRectangle
from kivy.uix.behaviors import ButtonBehavior
from kivy.clock import Clock
from kivy.metrics import dp

# Import unified popup system
try:
    from .popup_utils import QuickPopup, UnifiedPopup
except ImportError:
    from popup_utils import QuickPopup, UnifiedPopup


class SquareButton(ButtonBehavior, Label):
    def __init__(self, bg_color=(1, 1, 1, 1), **kwargs):
        super().__init__(**kwargs)
        self.bg_color = bg_color
        self.corner_radius = dp(10)  # Rounded corner radius
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



class PlayerScoresDB:
    def __init__(self, db_name="GoldenOaks.db"):
        script_dir = os.path.dirname(os.path.abspath(__file__))
        parent_dir = os.path.dirname(script_dir)  # Go up one level from screens/ directory
        self.db_name = os.path.join(parent_dir, db_name)
        self.selected_league = 'monday'  # Default league
        self.init_database()

    def init_database(self):
        conn = sqlite3.connect(self.db_name)
        cursor = conn.cursor()

        cursor.execute("""
            CREATE TABLE IF NOT EXISTS player_scores (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                last TEXT NOT NULL,
                date TEXT NOT NULL,
                score INTEGER NOT NULL,
                handicap REAL DEFAULT 0,
                FOREIGN KEY (last) REFERENCES players (last)
            )
        """)
        
        # Add columns if they don't exist
        try:
            cursor.execute('ALTER TABLE player_scores ADD COLUMN handicap REAL DEFAULT 0')
        except:
            pass
        
        try:
            cursor.execute('ALTER TABLE player_scores ADD COLUMN individual_place INTEGER')
        except:
            pass
        
        try:
            cursor.execute('ALTER TABLE player_scores ADD COLUMN individual_winnings REAL')
        except:
            pass
        
        try:
            cursor.execute('ALTER TABLE player_scores ADD COLUMN group_winnings REAL DEFAULT 0')
        except:
            pass
        
        try:
            cursor.execute('ALTER TABLE player_scores ADD COLUMN skat_number INTEGER')
        except:
            pass
        
        try:
            cursor.execute('ALTER TABLE player_scores ADD COLUMN golf_course TEXT')
        except:
            pass
        
        try:
            cursor.execute('ALTER TABLE player_scores ADD COLUMN skats_value TEXT')
        except:
            pass
        
        try:
            cursor.execute('ALTER TABLE player_scores ADD COLUMN league TEXT DEFAULT "monday"')
        except:
            pass
        
        # Update existing NULL league values to 'monday' as default
        try:
            cursor.execute('UPDATE player_scores SET league = "monday" WHERE league IS NULL')
            conn.commit()
        except:
            pass

        conn.commit()
        conn.close()

    def add_score(self, last, date, score, handicap=None, golf_course=None, skats_value=None, skat_number=None):
        conn = sqlite3.connect(self.db_name)
        cursor = conn.cursor()

        try:
            if handicap is None:
                handicap = self.get_player_handicap(last)
            
            # Check count for this player in this league only (handle NULL league values as monday)
            cursor.execute("SELECT COUNT(*) FROM player_scores WHERE last = ? AND (league = ? OR league IS NULL)", (last, self.selected_league))
            score_count = cursor.fetchone()[0]
            
            print(f"DEBUG: Player {last} has {score_count} scores in league {self.selected_league}")
            
            # If player has 20 scores in this league, delete the last row that would be displayed (EOF)
            if score_count >= 20:
                print(f"DEBUG: Deleting last displayed row (EOF) for {last} in league {self.selected_league}")
                # Delete the last row as it appears in the UI (sorted by date DESC, then by id DESC)
                # This matches exactly what the user sees as the "last row" in the table
                cursor.execute("""
                    DELETE FROM player_scores 
                    WHERE last = ? AND (league = ? OR league IS NULL) AND id = (
                        SELECT id FROM player_scores 
                        WHERE last = ? AND (league = ? OR league IS NULL)
                        ORDER BY date DESC, id DESC
                        LIMIT 1 OFFSET 19
                    )
                """, (last, self.selected_league, last, self.selected_league))
                print(f"DEBUG: Deleted {cursor.rowcount} rows")
            
            cursor.execute("""
                INSERT INTO player_scores (last, date, score, handicap, golf_course, skats_value, skat_number, league)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, (last, date, score, handicap, golf_course, skats_value, skat_number, self.selected_league))
            conn.commit()
            
            # Firebase sync attempt
            try:
                cursor.execute("SELECT id_number FROM players WHERE last = ?", (last,))
                id_result = cursor.fetchone()
                
                if id_result:
                    player_id_number = id_result[0]
                    from Misc_Old_Files.firebase_sync import FirebaseSync
                    firebase_sync = FirebaseSync()
                    firebase_sync.sync_score_to_firebase(
                        player_id_number=player_id_number,
                        date=date,
                        gross_score=score,
                        handicap=handicap
                    )
            except:
                pass
            
            return True
        except sqlite3.Error:
            return False
        finally:
            conn.close()

    def get_scores_by_player(self, last):
        conn = sqlite3.connect(self.db_name)
        cursor = conn.cursor()

        cursor.execute("""
            SELECT ps.id, ps.last, ps.date, ps.score, ps.handicap, ps.individual_place, ps.individual_winnings, ps.group_winnings, p.id_number, ps.skat_number, ps.golf_course, ps.skats_value
            FROM player_scores ps
            LEFT JOIN players p ON ps.last = p.last AND p.league = ?
            WHERE ps.last = ? AND (ps.league = ? OR ps.league IS NULL)
        """, (self.selected_league, last, self.selected_league))
        scores = cursor.fetchall()
        conn.close()

        def date_sort_key(score_row):
            try:
                date_str = score_row[2]
                date_obj = datetime.strptime(date_str, '%m/%d/%y')
                return date_obj
            except ValueError:
                return datetime.min

        scores.sort(key=date_sort_key, reverse=True)
        return scores

    def get_all_scores(self):
        conn = sqlite3.connect(self.db_name)
        cursor = conn.cursor()
        cursor.execute("SELECT id, last, date, score, handicap, individual_place, individual_winnings, group_winnings FROM player_scores")
        scores = cursor.fetchall()
        conn.close()
        
        def date_sort_key(score_row):
            try:
                date_str = score_row[2]
                date_obj = datetime.strptime(date_str, '%m/%d/%y')
                return date_obj
            except ValueError:
                return datetime.min

        scores.sort(key=date_sort_key, reverse=True)
        return scores

    def update_score(self, score_id, last, date, score):
        conn = sqlite3.connect(self.db_name)
        cursor = conn.cursor()

        try:
            cursor.execute("""
                SELECT ps.last, ps.date, ps.score, p.id_number 
                FROM player_scores ps
                LEFT JOIN players p ON ps.last = p.last
                WHERE ps.id = ?
            """, (score_id,))
            original_score = cursor.fetchone()
            
            cursor.execute("""
                UPDATE player_scores
                SET last = ?, date = ?, score = ?
                WHERE id = ?
            """, (last, date, score, score_id))
            conn.commit()
            
            success = cursor.rowcount > 0
            
            # Firebase sync attempt
            if success and original_score:
                try:
                    original_last, original_date, original_score_value, player_id_number = original_score
                    
                    if player_id_number:
                        cursor.execute("SELECT id_number FROM players WHERE last = ?", (last,))
                        new_id_result = cursor.fetchone()
                        new_player_id_number = new_id_result[0] if new_id_result else player_id_number
                        
                        from Misc_Old_Files.firebase_sync import FirebaseSync
                        firebase_sync = FirebaseSync()
                        firebase_sync.update_score_in_firebase(
                            player_id_number=player_id_number,
                            old_date=original_date,
                            new_date=date if date != original_date else None,
                            new_gross_score=score if score != original_score_value else None
                        )
                except:
                    pass
            
            return success
        except sqlite3.Error:
            return False
        finally:
            conn.close()

    def delete_score(self, score_id):
        conn = sqlite3.connect(self.db_name)
        cursor = conn.cursor()

        try:
            cursor.execute("""
                SELECT ps.last, ps.date, ps.score, p.id_number 
                FROM player_scores ps
                LEFT JOIN players p ON ps.last = p.last
                WHERE ps.id = ?
            """, (score_id,))
            score_info = cursor.fetchone()
            
            cursor.execute("DELETE FROM player_scores WHERE id = ?", (score_id,))
            conn.commit()
            success = cursor.rowcount > 0
            
            # Firebase sync attempt
            if success and score_info:
                try:
                    last_name, date, score_value, player_id_number = score_info
                    
                    if player_id_number:
                        from Misc_Old_Files.firebase_sync import FirebaseSync
                        firebase_sync = FirebaseSync()
                        firebase_sync.delete_score_from_firebase(
                            player_id_number=player_id_number,
                            date=date
                        )
                except:
                    pass
            
            return success
            
        except sqlite3.Error:
            return False
        finally:
            conn.close()
    
    def set_league(self, league_type):
        """Set the league type for filtering operations."""
        self.selected_league = league_type

    def get_players(self):
        conn = sqlite3.connect(self.db_name)
        cursor = conn.cursor()
        # Filter players by selected league
        cursor.execute("SELECT last, first FROM players WHERE league = ? ORDER BY last", (self.selected_league,))
        players = cursor.fetchall()
        conn.close()
        return players

    def get_player_handicap(self, last_name):
        conn = sqlite3.connect(self.db_name)
        cursor = conn.cursor()
        cursor.execute("SELECT handicap FROM players WHERE last = ? AND league = ?", (last_name, self.selected_league))
        result = cursor.fetchone()
        conn.close()
        return result[0] if result and result[0] is not None else 0

    def calculate_handicap(self, last_name, course_rating=70, slope_rating=113):
        scores = self.get_scores_by_player(last_name)
        if not scores:
            return None

        conn = sqlite3.connect(self.db_name)
        cursor = conn.cursor()
        cursor.execute("SELECT handicap FROM players WHERE last = ?", (last_name,))
        result = cursor.fetchone()
        current_handicap = result[0] if result and result[0] is not None else 0

        score_values = [score[3] for score in scores]
        num_scores = len(score_values)

        if num_scores == 0:
            conn.close()
            return current_handicap

        differentials = []
        for i, score in enumerate(score_values):
            # Get the golf course for this score (index 10 in the scores tuple)
            golf_course_name = scores[i][10] if len(scores[i]) > 10 and scores[i][10] else None
            
            # Get slope rating for this golf course
            if golf_course_name:
                cursor.execute("SELECT slope FROM golf_courses WHERE name = ?", (golf_course_name,))
                slope_result = cursor.fetchone()
                actual_slope = slope_result[0] if slope_result and slope_result[0] else slope_rating
            else:
                actual_slope = slope_rating  # Use default if no golf course specified
            
            eighteen_hole_score = score * 2
            differential = (eighteen_hole_score - course_rating) * 113 / actual_slope
            differentials.append(differential)
        
        conn.close()

        if num_scores < 5:
            avg_differential = sum(differentials) / len(differentials)
            blend_factors = [0.2, 0.4, 0.6, 0.8]
            blend_factor = blend_factors[num_scores - 1]
            current_18_hole_handicap = current_handicap * 2
            new_handicap = (1 - blend_factor) * current_18_hole_handicap + blend_factor * avg_differential
        else:
            differentials.sort()

            if num_scores >= 20:
                scores_to_use = 8
            elif num_scores >= 18:
                scores_to_use = 7
            elif num_scores >= 15:
                scores_to_use = 6
            elif num_scores >= 12:
                scores_to_use = 5
            elif num_scores >= 9:
                scores_to_use = 4
            elif num_scores >= 7:
                scores_to_use = 3
            elif num_scores >= 6:
                scores_to_use = 2
            else:
                scores_to_use = 1

            lowest_differentials = differentials[:scores_to_use]
            avg_differential = sum(lowest_differentials) / len(lowest_differentials)
            new_handicap = avg_differential * 0.96

        nine_hole_handicap = new_handicap / 2
        return round(nine_hole_handicap, 1)

    def update_player_handicap(self, last_name, new_handicap):
        conn = sqlite3.connect(self.db_name)
        cursor = conn.cursor()

        try:
            cursor.execute("""
                UPDATE players
                SET handicap = ?
                WHERE last = ?
            """, (new_handicap, last_name))
            conn.commit()
            return cursor.rowcount > 0
        except sqlite3.Error:
            return False
        finally:
            conn.close()

    def recalculate_all_handicaps(self):
        players = self.get_players()
        updated_count = 0

        for player in players:
            last_name = player[0]
            new_handicap = self.calculate_handicap(last_name)
            if new_handicap is not None:
                if self.update_player_handicap(last_name, new_handicap):
                    updated_count += 1

        return updated_count

    def get_golf_courses(self):
        """Get list of golf courses from database."""
        conn = sqlite3.connect(self.db_name)
        cursor = conn.cursor()
        cursor.execute("SELECT name FROM golf_courses ORDER BY name")
        courses = cursor.fetchall()
        conn.close()
        return [course[0] for course in courses]


class PlayerScoresScreen(Screen):
    """
    Player Scores screen for managing golf scores and handicaps.
    Converted from Player_Scores.py to work with ScreenManager.
    """
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        
        # Initialize database and variables
        self.db = PlayerScoresDB()
        self.selected_league = 'monday'  # Default league
        self.current_player = None
        self.selected_score_id = None
        self.selected_row = None
        
        # Initialize state variables
        self.date_has_entry = False
        self.score_has_entry = False
        self.user_edited_fields = False
        self.date_visible = True
        self.score_visible = True
        self.add_score_button_visible = True
        self.edit_score_button_visible = True
        self.delete_score_button_visible = True
        
        # Editing state variables
        self.is_editing = False
        self.editing_row = None
        self.editing_inputs = {}  # Store TextInput widgets for editing
        
        # Build the UI
        Clock.schedule_once(self.build_ui, 0)
    
    def set_league(self, league_type):
        """Set the league type (monday/wednesday) for this screen."""
        self.selected_league = league_type
        # Update database league filter and refresh player list
        if hasattr(self.db, 'set_league'):
            self.db.set_league(league_type)
        self.refresh_scores_list()
    
    def build_ui(self, dt):
        """Build the user interface after screen is ready."""
        self.clear_widgets()
        
        main_layout = BoxLayout(orientation='vertical', padding=20, spacing=20)
        
        # Set light grey background
        with main_layout.canvas.before:
            Color(0.9, 0.9, 0.9, 1)  # Light grey background
            main_layout.bg_rect = Rectangle(pos=main_layout.pos, size=main_layout.size)
        main_layout.bind(pos=self.update_bg, size=self.update_bg)
        
        # Title
        title_label = Label(
            text='Player Scores',
            font_size='28sp',
            bold=True,
            size_hint=(1, 0.1),
            color=(0, 0, 0, 1)
        )
        main_layout.add_widget(title_label)
        
        # Main content area with left frame and right side
        content_layout = BoxLayout(orientation='horizontal', spacing=20, size_hint=(1, 0.9))
        
        # Left side - Player list (15% width, full height)
        self.setup_player_list_section(content_layout)
        
        # Right side - Scores display and footer (85% width)
        right_side_layout = BoxLayout(orientation='vertical', size_hint=(0.85, 1), spacing=20)
        
        # Scores display section (takes remaining space)
        self.setup_scores_section(right_side_layout)
        
        # Footer section (fixed height)
        self.setup_footer_section(right_side_layout)
        
        content_layout.add_widget(right_side_layout)
        main_layout.add_widget(content_layout)
        
        self.add_widget(main_layout)
        
        # Initialize data
        Clock.schedule_once(self.delayed_init, 0.1)
    
    def get_default_date_placeholder(self):
        """Get the default date placeholder."""
        return "__/__/__"
    
    def delayed_init(self, dt):
        """Initialize data after UI is ready."""
        self.populate_listbox()
        
        # Note: Handicaps are now only updated when scores are added/edited/deleted
        
        # Force refresh of scores list to show all scores initially
        self.refresh_scores_list()
        
        # Force final layout update after everything is loaded
        Clock.schedule_once(lambda dt: None, 0.5)
    
    def setup_player_list_section(self, parent_layout):
        """Set up the player list section."""
        form_layout = BoxLayout(orientation='vertical', size_hint=(0.15, 1), spacing=0, padding=5)
        
        # Player listbox with simple scrolling
        self.player_scroll_view = ScrollView(
            size_hint=(1, 1),
            do_scroll_x=False,
            do_scroll_y=True,
            bar_width='15dp',
            bar_color=[0, 0, 0, 1],
            bar_inactive_color=[0, 0, 0, 0.6],
            scroll_type=['bars', 'content'],
            always_overscroll=False
        )
        # Content layout with right padding to avoid scroll bar overlap
        content_container = BoxLayout(orientation='horizontal', size_hint_y=None, pos_hint={'top': 1}, spacing=0, padding=0)
        content_container.bind(minimum_height=content_container.setter('height'))
        
        self.scrollable_layout = BoxLayout(orientation='vertical', size_hint=(1, None), size_hint_y=None, spacing=0, pos_hint={'top': 1})
        self.scrollable_layout.bind(minimum_height=self.scrollable_layout.setter('height'))
        content_container.add_widget(self.scrollable_layout)
        
        # Add spacer to push content away from scroll bar
        spacer = Widget(size_hint=(None, 1), width='20dp')
        content_container.add_widget(spacer)
        
        self.player_scroll_view.add_widget(content_container)
        form_layout.add_widget(self.player_scroll_view)
        
        parent_layout.add_widget(form_layout)
    
    def setup_footer_section(self, parent_layout):
        """Set up the footer section with buttons."""
        footer_layout = BoxLayout(orientation='vertical', size_hint=(1, None), height='80dp', spacing=10, padding=5)
        
        # Buttons row 1 - Add, Edit, Delete
        button_row1 = BoxLayout(orientation='horizontal', size_hint=(1, None), height='35dp', spacing=10)
        
        # Left spacer for centering
        button_row1.add_widget(Widget(size_hint=(0.1, 1)))
        
        add_btn = ColoredButton(
            text='Add',
            bg_color=(0.7, 1.0, 0.7, 1),  # Light green
            color=(0, 0, 0, 1),
            font_size='16sp',
            size_hint=(0.2, 1)
        )
        add_btn.bind(on_press=lambda x: self.add_empty_row())
        button_row1.add_widget(add_btn)
        
        edit_btn = ColoredButton(
            text='Edit',
            bg_color=(0.8, 0.8, 1.0, 1),  # Light blue
            color=(0, 0, 0, 1),
            font_size='16sp',
            size_hint=(0.2, 1)
        )
        edit_btn.bind(on_press=lambda x: self.edit_score())
        button_row1.add_widget(edit_btn)
        
        delete_btn = ColoredButton(
            text='Delete',
            bg_color=(1.0, 0.7, 0.7, 1),  # Light red
            color=(0, 0, 0, 1),
            font_size='16sp',
            size_hint=(0.2, 1)
        )
        delete_btn.bind(on_press=lambda x: self.delete_score())
        button_row1.add_widget(delete_btn)
        
        clear_btn = ColoredButton(
            text='Clear',
            bg_color=(1.0, 0.84, 0, 1),  # Light gold
            color=(0, 0, 0, 1),
            font_size='16sp',
            size_hint=(0.2, 1)
        )
        clear_btn.bind(on_press=lambda x: self.clear_selection())
        button_row1.add_widget(clear_btn)
        
        # Right spacer for centering
        button_row1.add_widget(Widget(size_hint=(0.1, 1)))
        
        footer_layout.add_widget(button_row1)
        
        # Return to Main Menu button (centered)
        button_row2 = BoxLayout(orientation='horizontal', size_hint=(1, None), height='50dp', spacing=10)
        button_row2.add_widget(Widget(size_hint=(0.25, 1)))  # Left spacer
        
        return_btn = ColoredButton(
            text="Return to Main Menu",
            size_hint=(0.3, 1),
            font_size='16sp',
            bold=True,
            bg_color=(1.0, 0.7, 0.7, 1),  # Light red
            color=(0, 0, 0, 1)
        )
        return_btn.bind(on_press=lambda x: self.return_to_main_menu())
        button_row2.add_widget(return_btn)
        
        button_row2.add_widget(Widget(size_hint=(0.25, 1)))  # Right spacer
        footer_layout.add_widget(button_row2)
        
        parent_layout.add_widget(footer_layout)
    
    def update_bg(self, instance, value):
        """Update background rectangle when widget moves or resizes."""
        if hasattr(instance, 'bg_rect'):
            instance.bg_rect.pos = instance.pos
            instance.bg_rect.size = instance.size
    
    def update_form_border(self, instance, value):
        """Update the form border when size or position changes."""
        if hasattr(instance, 'border'):
            instance.border.rectangle = (instance.x, instance.y, instance.width, instance.height)
    
    def setup_scores_section(self, parent_layout):
        """Set up the scores display section."""
        scores_layout = BoxLayout(orientation='vertical', size_hint=(1, 1), spacing=10)
        
        # Two-line header
        header_container = BoxLayout(orientation='vertical', size_hint=(0.70, None), height='40dp', spacing=-5)
        
        # First line headers
        header_line1 = BoxLayout(orientation='horizontal', size_hint=(1.0, None), height='20dp')
        headers_line1 = ['Name', 'Date', 'Current', 'Current', 'Golf Course', 'Gross', 'SKATS', 'CLOSE PIN', 'Monday-Skat', 'Wed-Single', 'Wed-Group']
        column_widths = [0.08, 0.08, 0.08, 0.10, 0.12, 0.06, 0.06, 0.11, 0.12, 0.11, 0.10]
        
        for i, header in enumerate(headers_line1):
            header_label = Label(
                text=header,
                bold=True,
                color=(0, 0, 0, 1),
                size_hint=(column_widths[i], 1),
                font_size='16sp'
            )
            header_line1.add_widget(header_label)
            
            if i < len(headers_line1) - 1:
                divider = Widget(size_hint=(None, 1), width='1dp')
                with divider.canvas:
                    Color(0, 0, 0, 1)
                    divider.line = Line(points=[0, 0, 0, 35], width=1)
                
                def update_divider_line(instance, value):
                    if hasattr(instance, 'line'):
                        instance.line.points = [instance.x, instance.y, instance.x, instance.y + instance.height]
                
                divider.bind(pos=update_divider_line, size=update_divider_line)
                header_line1.add_widget(divider)
        
        # Second line headers
        header_line2 = BoxLayout(orientation='horizontal', size_hint=(1.0, None), height='20dp')
        headers_line2 = ['', '', 'HC', 'SKAT#', '', '', '', 'Winnings', 'Winnings', 'Winnings', 'Winnings']
        
        for i, header in enumerate(headers_line2):
            header_label = Label(
                text=header,
                bold=True,
                color=(0, 0, 0, 1),
                size_hint=(column_widths[i], 1),
                font_size='16sp'
            )
            header_line2.add_widget(header_label)
            
            if i < len(headers_line2) - 1:
                divider = Widget(size_hint=(None, 1), width='1dp')
                with divider.canvas:
                    Color(0, 0, 0, 1)
                    divider.line = Line(points=[0, 0, 0, 35], width=1)
                
                def update_divider_line2(instance, value):
                    if hasattr(instance, 'line'):
                        instance.line.points = [instance.x, instance.y, instance.x, instance.y + instance.height]
                
                divider.bind(pos=update_divider_line2, size=update_divider_line2)
                header_line2.add_widget(divider)
        
        header_container.add_widget(header_line1)
        header_container.add_widget(header_line2)
        scores_layout.add_widget(header_container)
        
        # Scrollable scores list
        self.scores_scroll = ScrollView(
            do_scroll_x=False,
            do_scroll_y=True,
            bar_width='15dp',
            bar_color=[0, 0, 0, 1],
            bar_inactive_color=[0, 0, 0, 0.6],
            scroll_type=['bars', 'content'],
            always_overscroll=False
        )
        self.scores_list_layout = BoxLayout(orientation='vertical', size_hint_y=None, spacing=2)
        self.scores_list_layout.bind(minimum_height=self.scores_list_layout.setter('height'))
        self.scores_scroll.add_widget(self.scores_list_layout)
        scores_layout.add_widget(self.scores_scroll)
        
        parent_layout.add_widget(scores_layout)
    
    # Core functionality methods
    def populate_listbox(self):
        """Populate the player listbox."""
        self.scrollable_layout.clear_widgets()
        self.current_player = None
        
        players = self.db.get_players()
        for last, first in players:
            full_name = f"{first} {last}"
            
            player_btn = ColoredButton(
                text=full_name,
                size_hint_y=None,
                height='30dp',
                font_size='14sp',
                bg_color=(0.95, 0.95, 0.95, 1),
                color=(0, 0, 0, 1)
            )
            player_btn.player_last = last
            player_btn.bind(on_press=self.select_player)
            self.scrollable_layout.add_widget(player_btn)
        
        # Scroll layout automatically starts at top
    
    def select_player(self, player_btn):
        """Handle player selection."""
        # Reset all player button colors
        for child in self.scrollable_layout.children:
            if hasattr(child, 'bg_color'):
                child.canvas.before.clear()
                with child.canvas.before:
                    Color(0.95, 0.95, 0.95, 1)
                    child.rect = Rectangle(size=child.size, pos=child.pos)
        
        # Highlight selected player
        player_btn.canvas.before.clear()
        with player_btn.canvas.before:
            Color(0.7, 1.0, 0.7, 1)
            player_btn.rect = Rectangle(size=player_btn.size, pos=player_btn.pos)
        
        self.current_player = player_btn.player_last
        self.refresh_scores_list()
        
        # Reset selection states
        self.selected_score_id = None
        self.selected_row = None
    
    def clear_selection(self):
        """Clear the current selection."""
        # Clear player selection
        self.current_player = None
        self.selected_score_id = None
        self.selected_row = None
        
        # Reset all player button colors
        for child in self.scrollable_layout.children:
            if hasattr(child, 'bg_color'):
                child.canvas.before.clear()
                with child.canvas.before:
                    Color(0.95, 0.95, 0.95, 1)
                    child.rect = Rectangle(size=child.size, pos=child.pos)
        
        # Refresh to show all scores
        self.refresh_scores_list()
    
    def placeholder_action(self, action_name):
        """Placeholder action for Add, Edit, Delete buttons."""
        QuickPopup.info("Placeholder", f"{action_name} functionality not yet implemented.")
    
    def refresh_scores_list(self):
        """Refresh the scores display."""
        # Check if UI elements exist before trying to use them
        if not hasattr(self, 'scores_list_layout') or self.scores_list_layout is None:
            return
            
        self.scores_list_layout.clear_widgets()
        self.selected_row = None
        
        if self.current_player:
            scores = self.db.get_scores_by_player(self.current_player)
            player_handicap = self.db.get_player_handicap(self.current_player)
        else:
            scores = []
            player_handicap = 0
        
        if scores:
            # Limit to maximum of 20 rows
            scores = scores[:20]
        
        for i, (score_id, last, date, gross, stored_handicap, db_individual_place, db_individual_winnings, db_group_winnings, player_id_number, db_skat_number, db_golf_course, db_skats_value) in enumerate(scores):
            # Create a simple row layout with click handling
            row_layout = BoxLayout(
                orientation='horizontal',
                size_hint=(0.70, None), 
                height='30dp'
            )
            
            # Add background color
            with row_layout.canvas.before:
                Color(0.95, 0.95, 0.95, 1)  # Light gray background
                row_layout.bg_rect = Rectangle(size=row_layout.size, pos=row_layout.pos)
            
            # Fix closure issue with direct assignment
            def update_bg_rect(instance, value):
                if hasattr(instance, 'bg_rect'):
                    instance.bg_rect.size = instance.size
                    instance.bg_rect.pos = instance.pos
            row_layout.bind(size=update_bg_rect, pos=update_bg_rect)
            
            # Store the score data on the layout
            row_layout.score_data = (score_id, last, date, gross)
            
            # Add simple click handling using bind
            def on_row_touched(instance, touch):
                if instance.collide_point(*touch.pos):
                    self.select_score_row_data(instance.score_data)
                    return True
                return False
            
            row_layout.bind(on_touch_down=on_row_touched)
            
            hc_value = stored_handicap if stored_handicap is not None else 0
            hc_display = str(hc_value)
            
            individual_winnings = f"${db_individual_winnings:.2f}" if db_individual_winnings is not None else "$0.00"
            group_winnings = f"${db_group_winnings:.2f}" if db_group_winnings is not None else "$0.00"
            skat_number = str(db_skat_number) if db_skat_number is not None else ""
            
            # Use actual golf course or placeholder
            golf_course = db_golf_course if db_golf_course else "TBD"
            skats_value = db_skats_value if db_skats_value else "TBD"  # Use actual SKATS value from database
            close_pin_winnings = "$0.00"  # Replace with actual CLOSE PIN winnings when available
            monday_individual_winnings = "$0.00"  # Replace with actual Monday individual winnings when available
            
            data = [last, date, hc_display, skat_number, golf_course, str(gross), skats_value, close_pin_winnings, monday_individual_winnings, individual_winnings, group_winnings]
            column_widths = [0.08, 0.08, 0.08, 0.10, 0.12, 0.06, 0.06, 0.11, 0.12, 0.11, 0.10]
            
            for j, item in enumerate(data):
                item_label = Label(
                    text=str(item),
                    color=(0, 0, 0, 1),
                    size_hint=(column_widths[j], 1),
                    font_size='14sp',
                    halign='center',
                    valign='middle'
                )
                
                # Set text_size for proper alignment using lambda to avoid closure issues
                item_label.bind(size=lambda instance, value: setattr(instance, 'text_size', instance.size))
                
                row_layout.add_widget(item_label)
                
                if j < len(data) - 1:
                    divider = Widget(size_hint=(None, 1), width='1dp')
                    with divider.canvas:
                        Color(0.7, 0.7, 0.7, 1)
                        divider.line = Line(points=[0, 0, 0, 30], width=1)
                    
                    # Fix closure issue with lambda
                    divider.bind(pos=lambda instance, value: setattr(instance.line, 'points', [instance.x, instance.y, instance.x, instance.y + instance.height]) if hasattr(instance, 'line') else None)
                    divider.bind(size=lambda instance, value: setattr(instance.line, 'points', [instance.x, instance.y, instance.x, instance.y + instance.height]) if hasattr(instance, 'line') else None)
                    row_layout.add_widget(divider)
            
            self.scores_list_layout.add_widget(row_layout)
        
        # Force layout update
        def force_layout_update(dt):
            if hasattr(self, 'scores_list_layout') and self.scores_list_layout:
                self.scores_list_layout.do_layout()
        
        Clock.schedule_once(force_layout_update, 0.1)
    
    def save_new_row_if_exists(self):
        """Save any existing new row (with score_id = None) to the database."""
        if not hasattr(self, 'scores_list_layout') or not self.scores_list_layout:
            return False
        
        # Look for rows with score_data[0] = None (new unsaved rows)
        rows_to_remove = []
        for row_layout in self.scores_list_layout.children:
            if hasattr(row_layout, 'score_data') and row_layout.score_data[0] is None:
                # This is a new row - collect data from all widgets (Labels, TextInput, and Spinner)
                all_widgets = []
                for child in row_layout.children:
                    # Get all widgets with text (Labels, TextInput, Spinner), skip dividers
                    if hasattr(child, 'text') and not hasattr(child, 'line'):
                        all_widgets.append(child)
                
                if len(all_widgets) >= 6:  # Need at least name, date, hc, skat, course, score
                    # Reverse order since BoxLayout children are in reverse order
                    all_widgets.reverse()
                    
                    try:
                        # Extract data from widgets (Labels and TextInput)
                        # Format: [last, date, hc_display, skat_number, golf_course, str(gross), skats_value, ...]
                        last_name = all_widgets[0].text.strip()
                        date = all_widgets[1].text.strip()
                        handicap = all_widgets[2].text.strip()
                        skat_number = all_widgets[3].text.strip()
                        golf_course = all_widgets[4].text.strip()
                        gross_score = all_widgets[5].text.strip()
                        skats_value = all_widgets[6].text.strip() if len(all_widgets) > 6 else ""
                        
                        # Validate required fields
                        if not last_name or not date or not gross_score:
                            continue  # Skip if missing required data
                        
                        # Validate gross score is exactly 2 digits (10-99)
                        try:
                            score_value = int(gross_score)
                            if score_value < 10 or score_value > 99:
                                continue  # Skip if not exactly 2 digits
                        except ValueError:
                            continue  # Skip if score is not numeric
                        
                        # Save to database with current handicap (before recalculation)
                        current_handicap_value = float(handicap) if handicap else 0
                        skat_number_value = int(skat_number) if skat_number and skat_number.isdigit() else None
                        success = self.db.add_score(last_name, date, score_value, current_handicap_value, golf_course, skats_value, skat_number_value)
                        
                        if success:
                            # Only calculate and update handicap when a score is actually added
                            new_handicap = self.db.calculate_handicap(last_name)
                            if new_handicap is not None:
                                # Update ONLY the player's profile handicap, not the score record
                                self.db.update_player_handicap(last_name, new_handicap)
                            
                            # Mark row for removal
                            rows_to_remove.append(row_layout)
                            
                    except Exception as e:
                        print(f"Error saving new row: {e}")
                        continue
        
        # Remove saved rows
        for row_layout in rows_to_remove:
            self.scores_list_layout.remove_widget(row_layout)
        
        # If we removed any rows, refresh the scores list to show the saved scores
        if rows_to_remove:
            self.refresh_scores_list()
            return True  # Indicate that rows were saved
        
        return False  # No rows were saved
    
    def add_empty_row(self):
        """Add an empty row to the top of the scores table."""
        # Check if a player is selected
        if not self.current_player:
            QuickPopup.warning("No Player Selected", "Please select a player first before adding a score!")
            return
        
        # First, save any existing new row before creating another one
        saved_existing_row = self.save_new_row_if_exists()
        
        # If we saved an existing row, don't create a new one
        if saved_existing_row:
            return
            
        # Create a row layout matching existing score rows exactly
        row_layout = BoxLayout(
            orientation='horizontal',
            size_hint=(0.70, None), 
            height='30dp'
        )
        
        # Add background color (light green for new empty row, matching Add Player button)
        with row_layout.canvas.before:
            Color(0.7, 1.0, 0.7, 1)  # Light green background for empty row
            row_layout.bg_rect = Rectangle(size=row_layout.size, pos=row_layout.pos)
        
        # Fix closure issue with direct assignment (match existing code)
        def update_bg_rect(instance, value):
            if hasattr(instance, 'bg_rect'):
                instance.bg_rect.size = instance.size
                instance.bg_rect.pos = instance.pos
        row_layout.bind(size=update_bg_rect, pos=update_bg_rect)
        
        # Get today's date in MM/DD/YY format
        today = datetime.now()
        today_str = today.strftime("%m/%d/%y")
        
        # Get the selected player's name and profile data
        player_name = self.current_player if isinstance(self.current_player, str) else str(self.current_player)
        
        # Get player profile data from database using proper methods
        try:
            # Get current handicap from PlayerProfileScreen HC field
            current_handicap = self.db.get_player_handicap(self.current_player)
            player_handicap = str(current_handicap) if current_handicap is not None else "0"
            
            # Get SKAT number from players table
            conn = sqlite3.connect(self.db.db_name)
            cursor = conn.cursor()
            cursor.execute("SELECT skat_number FROM players WHERE last = ?", (self.current_player,))
            result = cursor.fetchone()
            conn.close()
            
            if result:
                skat_value = result[0] if result[0] is not None else ""
                player_skat_number = str(skat_value) if skat_value else ""
            else:
                player_skat_number = ""
                
        except Exception as e:
            # If database query fails, use empty values
            player_handicap = "0"
            player_skat_number = ""
        
        # Store empty score data on the layout (using None for new entry)
        row_layout.score_data = (None, player_name, today_str, "")
        
        # Don't add touch handling for new empty rows - let TextInputs handle their own touch events
        # Only existing rows need selection behavior
        
        # Define data matching existing format: [last, date, hc_display, skat_number, golf_course, str(gross), skats_value, close_pin_winnings, monday_individual_winnings, individual_winnings, group_winnings]
        # Prefill HC (index 2) and SKAT# (index 3) from player profile
        data = [player_name, today_str, player_handicap, player_skat_number, "", "", "", "", "", "", ""]
        column_widths = [0.08, 0.08, 0.08, 0.10, 0.12, 0.06, 0.06, 0.11, 0.12, 0.11, 0.10]
        
        # Get golf courses for dropdown
        golf_courses = self.db.get_golf_courses()
        
        # Create widgets for each field - Gross Score (index 5) and SKATS (index 6) are TextInput, Golf Course (index 4) is Spinner
        gross_score_input = None
        skats_input = None
        for j, item in enumerate(data):
            if j == 5:  # Gross Score field - make editable with validation
                item_widget = TextInput(
                    text="",  # Start empty for user input
                    size_hint=(column_widths[j], 1),
                    font_size='14sp',
                    multiline=False,
                    background_color=(1, 1, 1, 0.9),  # White background for visibility
                    foreground_color=(0, 0, 0, 1),
                    cursor_color=(0, 0, 0, 1),  # Black cursor
                    selection_color=(0.5, 0.5, 1, 0.5),  # Light blue selection
                    padding=[5, 2, 5, 2],  # Add some padding for better text visibility
                    halign='center',  # Center text horizontally
                    input_filter='int'  # Only allow integer input
                )
                
                # Store reference for focusing later
                gross_score_input = item_widget
                
                # Add validation for 2-digit numbers and auto-focus to SKATS
                def validate_score_input(instance, value):
                    # Remove any non-digit characters
                    digits_only = ''.join(filter(str.isdigit, value))
                    # Limit to 2 digits
                    if len(digits_only) > 2:
                        digits_only = digits_only[:2]
                    # Update the text if it changed
                    if digits_only != value:
                        instance.text = digits_only
                    
                    # Move focus to SKATS field when 2 digits entered
                    if len(digits_only) == 2 and skats_input:
                        def move_focus(dt):
                            skats_input.focus = True
                        Clock.schedule_once(move_focus, 0.1)
                
                item_widget.bind(text=validate_score_input)
                
                # Set text_size to enable alignment
                item_widget.bind(size=lambda instance, value: setattr(instance, 'text_size', instance.size))
            elif j == 4:  # Golf Course field - make dropdown/spinner
                # Set default to "The Hideout" if available, otherwise first course
                default_course = "The Hideout" if "The Hideout" in golf_courses else (golf_courses[0] if golf_courses else "Select Course")
                
                item_widget = Spinner(
                    text=default_course,
                    values=golf_courses,
                    size_hint=(column_widths[j], 1),
                    font_size='14sp',
                    background_color=(1, 1, 1, 1),  # Fully opaque white background
                    background_normal='',  # Remove default background
                    color=(0, 0, 0, 1),  # Black text
                    markup=False  # Disable markup to prevent text issues
                )
                
                # Add a visual dropdown indicator (black square in lower right)
                with item_widget.canvas.after:
                    Color(0, 0, 0, 1)  # Black color
                    item_widget.dropdown_indicator = Rectangle(size=(dp(8), dp(8)), pos=(0, 0))
                
                # Update the indicator position when widget size/position changes
                def update_dropdown_indicator(instance, value):
                    if hasattr(instance, 'dropdown_indicator'):
                        # Position in lower right corner with small margin
                        instance.dropdown_indicator.pos = (
                            instance.x + instance.width - dp(10), 
                            instance.y + dp(2)
                        )
                
                item_widget.bind(size=update_dropdown_indicator, pos=update_dropdown_indicator)
            elif j == 6:  # SKATS field - make editable
                item_widget = TextInput(
                    text="",  # Start empty for user input
                    size_hint=(column_widths[j], 1),
                    font_size='14sp',
                    multiline=False,
                    background_color=(1, 1, 1, 0.9),  # White background for visibility
                    foreground_color=(0, 0, 0, 1),
                    cursor_color=(0, 0, 0, 1),  # Black cursor
                    selection_color=(0.5, 0.5, 1, 0.5),  # Light blue selection
                    padding=[5, 2, 5, 2],  # Add some padding for better text visibility
                    halign='center'  # Center text horizontally
                )
                
                # Store reference for focusing later
                skats_input = item_widget
                
                # Set text_size to enable alignment
                item_widget.bind(size=lambda instance, value: setattr(instance, 'text_size', instance.size))
            else:
                # All other fields - display as labels (not editable)
                item_widget = Label(
                    text=str(item),
                    color=(0, 0, 0, 1),
                    size_hint=(column_widths[j], 1),
                    font_size='14sp',
                    halign='center',
                    valign='middle'
                )
                # Set text_size for proper alignment
                item_widget.bind(size=lambda instance, value: setattr(instance, 'text_size', instance.size))
            
            row_layout.add_widget(item_widget)
            
            # Add divider between columns (match existing code exactly)
            if j < len(data) - 1:
                divider = Widget(size_hint=(None, 1), width='1dp')
                with divider.canvas:
                    Color(0.7, 0.7, 0.7, 1)
                    divider.line = Line(points=[0, 0, 0, 30], width=1)
                
                # Fix closure issue with lambda (match existing)
                divider.bind(pos=lambda instance, value: setattr(instance.line, 'points', [instance.x, instance.y, instance.x, instance.y + instance.height]) if hasattr(instance, 'line') else None)
                divider.bind(size=lambda instance, value: setattr(instance.line, 'points', [instance.x, instance.y, instance.x, instance.y + instance.height]) if hasattr(instance, 'line') else None)
                row_layout.add_widget(divider)
        
        # Insert the empty row at the top of the scores list (add at end to appear at top)
        self.scores_list_layout.add_widget(row_layout, len(self.scores_list_layout.children))
        
        # Force layout update and focus on gross score input
        def force_layout_update_and_focus(dt):
            if hasattr(self, 'scores_list_layout') and self.scores_list_layout:
                self.scores_list_layout.do_layout()
            # Focus on the gross score input field with additional delay
            def set_focus(dt2):
                if gross_score_input:
                    gross_score_input.focus = True
            Clock.schedule_once(set_focus, 0.2)
        
        Clock.schedule_once(force_layout_update_and_focus, 0.1)
    
    def select_score_row_data(self, score_data):
        """Handle score row selection."""
        # If in editing mode, exit it first
        if self.is_editing:
            self.exit_edit_mode()
        
        # This is called when a row is clicked
        score_id, last, date, gross = score_data
        self.selected_score_id = score_id
        
        # Clear previous row highlights and highlight the selected row
        self.highlight_selected_row(score_id)
    
    def edit_score(self, instance=None):
        """Toggle edit mode for the selected score."""
        if not self.selected_score_id and not self.is_editing:
            QuickPopup.warning("No Selection", "Please select a score to edit!")
            return
        
        if not self.is_editing:
            # Enter edit mode
            self.enter_edit_mode()
        else:
            # Exit edit mode and save changes
            self.exit_edit_mode()
    
    def enter_edit_mode(self):
        """Enter edit mode for the selected score."""
        if not self.selected_score_id:
            return
        
        # Find the selected row
        selected_row = None
        for row_layout in self.scores_list_layout.children:
            if hasattr(row_layout, 'score_data') and row_layout.score_data[0] == self.selected_score_id:
                selected_row = row_layout
                break
        
        if not selected_row:
            QuickPopup.error("Error", "Selected score row not found!")
            return
        
        # Set editing state
        self.is_editing = True
        self.editing_row = selected_row
        self.editing_inputs = {}
        
        # Change highlight to light blue
        light_blue_color = (0.8, 0.9, 1.0, 1)
        self.highlight_selected_row(self.selected_score_id, light_blue_color)
        
        # Convert editable fields to TextInputs
        # Fields: [0]Name(readonly), [1]Date, [2]HC, [3]SKAT#, [4]Golf Course, [5]Gross, [6]SKATS(readonly), 
        #         [7]CLOSE PIN, [8]Monday-Individual, [9]Wed-Single, [10]Wed-Group
        editable_fields = [1, 2, 3, 4, 5, 7, 8, 9, 10]  # Skip name (0) and SKATS (6) as readonly
        
        row_children = [child for child in selected_row.children if not hasattr(child, 'line')]  # Skip dividers
        
        for i, field_index in enumerate(editable_fields):
            if field_index < len(row_children):
                widget_index = len(row_children) - 1 - field_index  # Reverse index due to BoxLayout order
                if widget_index >= 0 and widget_index < len(row_children):
                    label_widget = row_children[widget_index]
                    if hasattr(label_widget, 'text'):
                        # Create TextInput to replace Label
                        text_input = TextInput(
                            text=label_widget.text,
                            multiline=False,
                            size_hint=label_widget.size_hint,
                            font_size='14sp',
                            background_color=(1, 1, 1, 1),
                            foreground_color=(0, 0, 0, 1),
                            halign='center'
                        )
                        
                        # Store original label and input for later
                        self.editing_inputs[field_index] = {
                            'original_label': label_widget,
                            'text_input': text_input,
                            'widget_index': widget_index
                        }
                        
                        # Replace label with text input
                        selected_row.remove_widget(label_widget)
                        selected_row.add_widget(text_input, index=widget_index)
        
        QuickPopup.info("Edit Mode", "You are now in edit mode. Make your changes and click Edit again to save.")
    
    def exit_edit_mode(self):
        """Exit edit mode and save changes."""
        if not self.is_editing or not self.editing_row:
            return
        
        try:
            # Collect data from TextInputs
            updated_data = {}
            field_mapping = {
                1: 'date',
                2: 'handicap', 
                3: 'skat_number',
                4: 'golf_course',
                5: 'gross_score',
                7: 'close_pin_winnings',
                8: 'monday_individual_winnings',
                9: 'wednesday_single_winnings', 
                10: 'wednesday_group_winnings'
            }
            
            for field_index, input_data in self.editing_inputs.items():
                text_input = input_data['text_input']
                field_name = field_mapping.get(field_index)
                if field_name:
                    updated_data[field_name] = text_input.text
            
            # Validate and save to database
            success = self.save_score_changes(updated_data)
            
            if success:
                # Restore labels with updated values
                for field_index, input_data in self.editing_inputs.items():
                    text_input = input_data['text_input']
                    original_label = input_data['original_label']
                    widget_index = input_data['widget_index']
                    
                    # Update label text with new value
                    original_label.text = text_input.text
                    
                    # Replace text input back with label
                    self.editing_row.remove_widget(text_input)
                    self.editing_row.add_widget(original_label, index=widget_index)
                
                # Reset editing state
                self.is_editing = False
                self.editing_row = None
                self.editing_inputs = {}
                
                # Change highlight back to normal selection color
                self.highlight_selected_row(self.selected_score_id)
                
                # Refresh the scores list to show updated data
                self.refresh_scores_list()
                
                QuickPopup.success("Success", "Score updated successfully!")
            else:
                QuickPopup.error("Error", "Failed to save changes!")
                
        except Exception as e:
            QuickPopup.error("Error", f"Error saving changes: {str(e)}")
    
    def save_score_changes(self, updated_data):
        """Save the updated score data to database."""
        try:
            # Get current score data
            scores = self.db.get_scores_by_player(self.current_player)
            selected_score = None
            for score in scores:
                if score[0] == self.selected_score_id:
                    selected_score = score
                    break
            
            if not selected_score:
                return False
            
            # Build update query based on available fields
            update_fields = []
            update_values = []
            
            # Map fields to database columns
            if 'date' in updated_data:
                update_fields.append("date = ?")
                update_values.append(updated_data['date'])
            
            if 'gross_score' in updated_data:
                update_fields.append("score = ?")
                update_values.append(int(updated_data['gross_score']) if updated_data['gross_score'].isdigit() else selected_score[3])
            
            if 'handicap' in updated_data:
                update_fields.append("handicap = ?")
                update_values.append(float(updated_data['handicap']) if updated_data['handicap'].replace('.', '').isdigit() else selected_score[4])
            
            if 'skat_number' in updated_data:
                update_fields.append("skat_number = ?")
                update_values.append(int(updated_data['skat_number']) if updated_data['skat_number'].isdigit() else selected_score[9])
            
            # Handle winnings fields (map multiple UI fields to database fields)
            individual_winnings = None
            if 'monday_individual_winnings' in updated_data:
                individual_winnings = float(updated_data['monday_individual_winnings'].replace('$', '')) if updated_data['monday_individual_winnings'].replace('$', '').replace('.', '').isdigit() else 0.0
            elif 'wednesday_single_winnings' in updated_data:
                individual_winnings = float(updated_data['wednesday_single_winnings'].replace('$', '')) if updated_data['wednesday_single_winnings'].replace('$', '').replace('.', '').isdigit() else 0.0
            
            if individual_winnings is not None:
                update_fields.append("individual_winnings = ?")
                update_values.append(individual_winnings)
            
            if 'wednesday_group_winnings' in updated_data:
                update_fields.append("group_winnings = ?")
                update_values.append(float(updated_data['wednesday_group_winnings'].replace('$', '')) if updated_data['wednesday_group_winnings'].replace('$', '').replace('.', '').isdigit() else 0.0)
            
            if not update_fields:
                return True  # Nothing to update
            
            # Execute update
            update_values.append(self.selected_score_id)  # WHERE clause
            query = f"UPDATE player_scores SET {', '.join(update_fields)} WHERE id = ?"
            
            conn = sqlite3.connect(os.path.join(os.path.dirname(__file__), '..', 'GoldenOaks.db'))
            cursor = conn.cursor()
            cursor.execute(query, update_values)
            conn.commit()
            conn.close()
            
            # Only recalculate handicap if gross score was actually changed
            if 'gross_score' in updated_data:
                new_handicap = self.db.calculate_handicap(self.current_player)
                if new_handicap is not None:
                    self.db.update_player_handicap(self.current_player, new_handicap)
            
            return True
            
        except Exception as e:
            print(f"Error saving score changes: {e}")
            return False
    
    def delete_score(self, instance=None):
        """Delete the selected score."""
        if not self.selected_score_id:
            QuickPopup.warning("No Selection", "Please select a score to delete!")
            return
        
        # Change highlight to light-red to indicate delete mode
        light_red_color = (1.0, 0.8, 0.8, 1)
        self.highlight_selected_row(self.selected_score_id, light_red_color)
        
        # Get the score details for confirmation
        if self.current_player:
            scores = self.db.get_scores_by_player(self.current_player)
            selected_score = None
            for score in scores:
                if score[0] == self.selected_score_id:  # score[0] is the ID
                    selected_score = score
                    break
            
            if selected_score:
                score_id, last_name, date, gross = selected_score[0], selected_score[1], selected_score[2], selected_score[3]
                
                def on_confirm():
                    if self.db.delete_score(score_id):
                        # Only update handicap when a score is actually deleted
                        new_handicap = self.db.calculate_handicap(last_name)
                        if new_handicap is not None:
                            self.db.update_player_handicap(last_name, new_handicap)
                        
                        # Clear selection and refresh
                        self.selected_score_id = None
                        self.selected_row = None
                        self.refresh_scores_list()
                    else:
                        QuickPopup.error("Error", "Failed to delete score!")
                
                def on_cancel():
                    # Clear form - reset selection and highlighting
                    self.clear_selection()
                
                # Show confirmation dialog
                popup = UnifiedPopup.show_confirmation(
                    title="Confirm Delete",
                    message=f"Are you sure you want to delete the score {gross} for {last_name} on {date}?",
                    on_yes=on_confirm,
                    on_no=on_cancel
                )
                popup.open()
            else:
                QuickPopup.error("Error", "Selected score not found!")
        else:
            QuickPopup.warning("No Player", "Please select a player first!")
    
    def highlight_selected_row(self, score_id, highlight_color=None):
        """Highlight the selected score row with specified background color."""
        if not hasattr(self, 'scores_list_layout') or not self.scores_list_layout:
            return
        
        # Default to light grey if no color specified
        if highlight_color is None:
            highlight_color = (0.8, 0.8, 0.8, 1)  # Light grey highlight
        
        # Iterate through all score rows in the layout
        for row_layout in self.scores_list_layout.children:
            if hasattr(row_layout, 'score_data') and hasattr(row_layout, 'bg_rect'):
                row_score_id = row_layout.score_data[0]  # First element is score_id
                
                # Clear previous background and set new color
                row_layout.canvas.before.clear()
                with row_layout.canvas.before:
                    if row_score_id == score_id:
                        # Highlight selected row with specified color
                        Color(*highlight_color)
                    else:
                        # Normal background for unselected rows
                        Color(0.95, 0.95, 0.95, 1)  # Default light gray
                    
                    row_layout.bg_rect = Rectangle(size=row_layout.size, pos=row_layout.pos)
                
                # Rebind the update function to maintain background on resize/move
                def update_bg_rect(instance, value):
                    if hasattr(instance, 'bg_rect'):
                        instance.bg_rect.size = instance.size
                        instance.bg_rect.pos = instance.pos
                row_layout.bind(size=update_bg_rect, pos=update_bg_rect)
    
    def return_to_main_menu(self, instance=None):
        """Return to the main menu screen."""
        self.clear_selection()
        self.manager.current = 'unified_main_menu'