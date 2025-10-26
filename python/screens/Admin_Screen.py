"""
Admin Screen for Golden Oaks Golf League
========================================

This module contains the AdminScreen class for managing administrative settings
for both Monday and Wednesday leagues.
"""

import os
from datetime import date
from kivy.uix.screenmanager import Screen
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.gridlayout import GridLayout
from kivy.uix.label import Label
from kivy.uix.textinput import TextInput
from kivy.uix.behaviors import ButtonBehavior
from kivy.uix.widget import Widget
from kivy.graphics import Color, Rectangle, Line, RoundedRectangle
from kivy.metrics import dp


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


class BorderedLabel(Label):
    """A label with a border around it."""
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.bind(size=self.update_border, pos=self.update_border)
        
    def on_size(self, *args):
        """Called when the widget size changes."""
        self.update_border()
    
    def on_pos(self, *args):
        """Called when the widget position changes."""
        self.update_border()
        
    def update_border(self, *args):
        """Update the border graphics."""
        if self.canvas is None:
            return
        self.canvas.after.clear()
        with self.canvas.after:
            Color(0, 0, 0, 1)  # Black border
            Line(rectangle=(self.x, self.y, self.width, self.height), width=1)


class BorderedTextInput(TextInput):
    """A TextInput with a border around it."""
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.bind(size=self.update_border, pos=self.update_border)
        
    def on_size(self, *args):
        """Called when the widget size changes."""
        self.update_border()
    
    def on_pos(self, *args):
        """Called when the widget position changes."""
        self.update_border()
        
    def update_border(self, *args):
        """Update the border graphics."""
        if self.canvas is None:
            return
        self.canvas.after.clear()
        with self.canvas.after:
            Color(0, 0, 0, 1)  # Black border
            Line(rectangle=(self.x, self.y, self.width, self.height), width=1)


class AdminScreen(Screen):
    """
    Administrative settings screen combining Enter Scores and Player Payout settings
    for both Monday and Wednesday golf leagues.
    """
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.current_league = None
        
        # Setup UI immediately
        self.add_widget(self.setup_ui())
    
    def setup_ui(self):
        """Set up the admin screen user interface."""
        main_layout = BoxLayout(orientation='vertical', padding=0, spacing=0)
        
        # Title with light grey background
        title_label = Label(
            text="ADMIN SCREEN - GAME SETTINGS",
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
        content_area = self.setup_admin_content()
        main_layout.add_widget(content_area)
        
        # Footer with back button
        footer_layout = BoxLayout(
            orientation='horizontal',
            size_hint=(1, None),
            height='100dp',
            padding=(30, 15, 30, 15),
            spacing=20
        )
        
        # Set light grey background for footer
        with footer_layout.canvas.before:
            Color(0.9, 0.9, 0.9, 1)  # Light grey background
            footer_layout.bg_rect = Rectangle(pos=footer_layout.pos, size=footer_layout.size)
        footer_layout.bind(pos=self.update_footer_bg, size=self.update_footer_bg)
        
        # Back button
        back_btn = ColoredButton(
            text="← Back to Main Menu",
            size_hint=(None, 1),
            width='350dp',
            font_size='25sp',
            bold=True,
            bg_color=(0.7, 1.0, 1.0, 1),  # Light-cyan
            color=(0, 0, 0, 1)
        )
        back_btn.bind(on_press=lambda x: self.go_back())
        footer_layout.add_widget(back_btn)
        
        # Add spacer to push back button to the left
        spacer = Widget()
        footer_layout.add_widget(spacer)
        
        main_layout.add_widget(footer_layout)
        
        return main_layout
    
    def setup_admin_content(self):
        """Setup the combined admin content from Enter Scores and Player Payout screens."""
        main_container = BoxLayout(orientation='vertical', padding=10, spacing=10)
        
        # Add white background
        with main_container.canvas.before:
            Color(1, 1, 1, 1)  # White background
            self.admin_rect = Rectangle(size=main_container.size, pos=main_container.pos)
        main_container.bind(size=self.update_admin_rect, pos=self.update_admin_rect)
        
        # Two-column layout
        two_column_layout = BoxLayout(orientation='horizontal', spacing=20)
        
        # Left Column - Game Settings (from Enter Scores Screen)
        left_column = self.setup_game_settings_column()
        two_column_layout.add_widget(left_column)
        
        # Right Column - Payout Settings (from Player Payout Screen) 
        right_column = self.setup_payout_settings_column()
        two_column_layout.add_widget(right_column)
        
        main_container.add_widget(two_column_layout)
        
        return main_container
    
    def setup_game_settings_column(self):
        """Setup the left column with game settings from Enter Scores Screen."""
        left_layout = BoxLayout(orientation='vertical', size_hint=(0.5, 1), spacing=20, padding=[0, 0, 20, 0])
        
        # Add right border to left frame
        with left_layout.canvas.after:
            Color(0, 0, 0, 1)  # Black border
            left_layout.right_border = Line(width=2)
        
        def update_right_border(instance, *args):
            left_layout.right_border.points = [instance.x + instance.width, instance.y, 
                                              instance.x + instance.width, instance.y + instance.height]
        
        left_layout.bind(pos=update_right_border, size=update_right_border)
        
        # Game Settings title
        settings_title = Label(
            text='Game Settings',
            font_size='20sp',
            bold=True,
            size_hint=(1, None),
            height='40dp',
            color=(0, 0, 0, 1)
        )
        left_layout.add_widget(settings_title)
        
        # Date setting
        date_layout = BoxLayout(orientation='horizontal', size_hint=(1, None), height='40dp')
        date_label = Label(text='Date', color=(0, 0, 0, 1), size_hint=(.7, 1), halign='left', valign='middle', font_size='20sp')
        date_label.bind(size=date_label.setter('text_size'))
        date_layout.add_widget(date_label)
        self.date_input = GoldenTextInput(
            text=date.today().strftime('%m/%d/%y'),
            multiline=False,
            size_hint=(0.3, 1),
            input_filter=None
        )
        date_layout.add_widget(self.date_input)
        left_layout.add_widget(date_layout)
        
        # Ante setting
        ante_layout = BoxLayout(orientation='horizontal', size_hint=(1, None), height='40dp')
        ante_label = Label(text='Player\'s Ante $', color=(0, 0, 0, 1), size_hint=(0.7, 1), halign='left', valign='middle', font_size='20sp')
        ante_label.bind(size=ante_label.setter('text_size'))
        ante_layout.add_widget(ante_label)
        self.ante_input = GoldenTextInput(
            text='$6.00',
            multiline=False,
            size_hint=(0.3, 1),
            input_filter=None
        )
        self.ante_input.bind(text=self.update_total_purse)
        ante_layout.add_widget(self.ante_input)
        left_layout.add_widget(ante_layout)
        
        # Number of players
        players_layout = BoxLayout(orientation='horizontal', size_hint=(1, None), height='40dp')
        players_text_label = Label(text='# Players', color=(0, 0, 0, 1), size_hint=(0.7, 1), halign='left', valign='middle', font_size='20sp')
        players_text_label.bind(size=players_text_label.setter('text_size'))
        players_layout.add_widget(players_text_label)
        self.players_label = Label(text='0', color=(0, 0, 0, 1), size_hint=(0.3, 1), halign='center', valign='middle', font_size='20sp')
        self.players_label.bind(size=self.players_label.setter('text_size'))
        players_layout.add_widget(self.players_label)
        left_layout.add_widget(players_layout)
        
        # Total purse
        purse_layout = BoxLayout(orientation='horizontal', size_hint=(1, None), height='40dp')
        purse_text_label = Label(text='Total Purse', color=(0, 0, 0, 1), size_hint=(0.7, 1), halign='left', valign='middle', font_size='20sp')
        purse_text_label.bind(size=purse_text_label.setter('text_size'))
        purse_layout.add_widget(purse_text_label)
        self.purse_label = Label(text='$0.00', color=(0, 0, 0, 1), size_hint=(0.3, 1), halign='center', valign='middle', font_size='20sp')
        self.purse_label.bind(size=self.purse_label.setter('text_size'))
        purse_layout.add_widget(self.purse_label)
        left_layout.add_widget(purse_layout)
        
        # Add spacer to push Game Settings to top
        left_layout.add_widget(Widget())
        
        return left_layout
    
    def setup_payout_settings_column(self):
        """Setup the right column with payout settings from Player Payout Screen."""
        right_layout = BoxLayout(orientation='vertical', size_hint=(0.5, 1), spacing=20)
        
        # Payout Settings title
        settings_title = Label(
            text='Payout Settings',
            font_size='20sp',
            bold=True,
            size_hint=(1, None),
            height='40dp',
            color=(0, 0, 0, 1)
        )
        right_layout.add_widget(settings_title)
        
        # Individual Prefill Ratio
        prefill_layout = BoxLayout(orientation='horizontal', size_hint=(1, None), height='40dp')
        prefill_label = Label(text='Individual Prefill Ratio%', color=(0, 0, 0, 1), size_hint=(0.7, 1), halign='left', valign='middle', font_size='18sp')
        prefill_label.bind(size=prefill_label.setter('text_size'))
        prefill_layout.add_widget(prefill_label)
        self.prefill_input = GoldenTextInput(
            text='40',
            multiline=False,
            size_hint=(0.3, 1),
            input_filter='int'
        )
        self.prefill_input.bind(text=self.update_percentages_from_prefill)
        prefill_layout.add_widget(self.prefill_input)
        right_layout.add_widget(prefill_layout)
        
        # Individual percentage
        individual_layout = BoxLayout(orientation='horizontal', size_hint=(1, None), height='40dp')
        individual_label = Label(text='Individual %', color=(0, 0, 0, 1), size_hint=(0.7, 1), halign='left', valign='middle', font_size='18sp')
        individual_label.bind(size=individual_label.setter('text_size'))
        individual_layout.add_widget(individual_label)
        self.individual_percent_label = Label(text='40%', color=(0, 0, 0, 1), size_hint=(0.3, 1), halign='center', valign='middle', font_size='18sp')
        self.individual_percent_label.bind(size=self.individual_percent_label.setter('text_size'))
        individual_layout.add_widget(self.individual_percent_label)
        right_layout.add_widget(individual_layout)
        
        # Group percentage
        group_layout = BoxLayout(orientation='horizontal', size_hint=(1, None), height='40dp')
        group_label = Label(text='Group %', color=(0, 0, 0, 1), size_hint=(0.7, 1), halign='left', valign='middle', font_size='18sp')
        group_label.bind(size=group_label.setter('text_size'))
        group_layout.add_widget(group_label)
        self.group_percent_label = Label(text='60%', color=(0, 0, 0, 1), size_hint=(0.3, 1), halign='center', valign='middle', font_size='18sp')
        self.group_percent_label.bind(size=self.group_percent_label.setter('text_size'))
        group_layout.add_widget(self.group_percent_label)
        right_layout.add_widget(group_layout)
        
        # Individual purse
        individual_purse_layout = BoxLayout(orientation='horizontal', size_hint=(1, None), height='40dp')
        individual_purse_label = Label(text='Individual Purse', color=(0, 0, 0, 1), size_hint=(0.7, 1), halign='left', valign='middle', font_size='18sp')
        individual_purse_label.bind(size=individual_purse_label.setter('text_size'))
        individual_purse_layout.add_widget(individual_purse_label)
        self.individual_purse_label = Label(text='0.00', color=(0, 0, 0, 1), size_hint=(0.3, 1), halign='center', valign='middle', font_size='18sp')
        self.individual_purse_label.bind(size=self.individual_purse_label.setter('text_size'))
        individual_purse_layout.add_widget(self.individual_purse_label)
        right_layout.add_widget(individual_purse_layout)
        
        # Group purse
        group_purse_layout = BoxLayout(orientation='horizontal', size_hint=(1, None), height='40dp')
        group_purse_label = Label(text='Group Purse', color=(0, 0, 0, 1), size_hint=(0.7, 1), halign='left', valign='middle', font_size='18sp')
        group_purse_label.bind(size=group_purse_label.setter('text_size'))
        group_purse_layout.add_widget(group_purse_label)
        self.group_purse_label = Label(text='0.00', color=(0, 0, 0, 1), size_hint=(0.3, 1), halign='center', valign='middle', font_size='18sp')
        self.group_purse_label.bind(size=self.group_purse_label.setter('text_size'))
        group_purse_layout.add_widget(self.group_purse_label)
        right_layout.add_widget(group_purse_layout)
        
        # Add spacer to push settings to top
        right_layout.add_widget(Widget())
        
        return right_layout
    
    def update_admin_rect(self, instance, value):
        """Update the admin content background rectangle."""
        self.admin_rect.size = instance.size
        self.admin_rect.pos = instance.pos
    
    def update_footer_bg(self, instance, value):
        """Update footer background rectangle when widget moves or resizes."""
        if hasattr(instance, 'bg_rect'):
            instance.bg_rect.pos = instance.pos
            instance.bg_rect.size = instance.size
    
    def update_total_purse(self, instance, value):
        """Update total purse when ante changes."""
        try:
            # Remove $ sign if present and convert to float
            clean_value = value.replace('$', '') if value else '0'
            ante = float(clean_value) if clean_value else 0.0
            num_players = int(self.players_label.text) if self.players_label.text.isdigit() else 0
            total_purse = ante * num_players
            self.purse_label.text = f'${total_purse:.2f}'
            self.update_purse_splits()
        except ValueError:
            pass
    
    def update_percentages_from_prefill(self, instance, value):
        """Update percentage displays when prefill ratio changes."""
        try:
            prefill_ratio = int(value) if value else 40
            # Ensure ratio is between 0 and 100
            prefill_ratio = max(0, min(100, prefill_ratio))
            
            individual_percent = prefill_ratio
            group_percent = 100 - prefill_ratio
            
            self.individual_percent_label.text = f'{individual_percent}%'
            self.group_percent_label.text = f'{group_percent}%'
            
            self.update_purse_splits()
        except ValueError:
            pass
    
    def update_purse_splits(self):
        """Update individual and group purse amounts based on percentages."""
        try:
            total_purse_text = self.purse_label.text.replace('$', '') if self.purse_label.text else '0'
            total_purse = float(total_purse_text)
            
            individual_percent = int(self.individual_percent_label.text.replace('%', '')) if self.individual_percent_label.text else 40
            group_percent = int(self.group_percent_label.text.replace('%', '')) if self.group_percent_label.text else 60
            
            individual_purse = total_purse * (individual_percent / 100)
            group_purse = total_purse * (group_percent / 100)
            
            self.individual_purse_label.text = f'{individual_purse:.2f}'
            self.group_purse_label.text = f'{group_purse:.2f}'
        except (ValueError, AttributeError):
            pass
    
    def set_league(self, league):
        """Set the current league and update styling."""
        self.current_league = league
        
        # Update input styling based on league
        if league == 'monday':
            # Convert to green styling for Monday
            if hasattr(self, 'date_input'):
                self.date_input.background_color = (0.7, 1.0, 0.7, 1)
            if hasattr(self, 'ante_input'):
                self.ante_input.background_color = (0.7, 1.0, 0.7, 1)
                self.ante_input.text = '$12.00'
            if hasattr(self, 'prefill_input'):
                self.prefill_input.background_color = (0.7, 1.0, 0.7, 1)
        else:
            # Keep golden styling for Wednesday
            if hasattr(self, 'ante_input'):
                self.ante_input.text = '$6.00'
        
        # Update purse calculations
        if hasattr(self, 'ante_input'):
            self.update_total_purse(self.ante_input, self.ante_input.text)
    
    def go_back(self):
        """Navigate back to the main menu."""
        self.manager.current = 'unified_main_menu'