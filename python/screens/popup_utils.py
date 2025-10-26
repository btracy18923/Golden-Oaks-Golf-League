"""
Popup Utilities for Golden Oaks Golf League
==========================================

This module provides unified popup message functionality for all screens
to ensure consistent styling and behavior throughout the application.
"""

from kivy.uix.popup import Popup
from kivy.uix.label import Label
from kivy.uix.button import Button
from kivy.uix.boxlayout import BoxLayout
from kivy.graphics import Color, Rectangle
from kivy.metrics import dp


class UnifiedPopup:
    """
    Unified popup class for consistent messaging across all screens.
    Provides different popup types with standardized styling.
    """
    
    # Color schemes for different popup types
    COLORS = {
        'info': (0.8, 0.9, 1.0, 1),      # Light blue
        'success': (0.8, 1.0, 0.8, 1),   # Light green
        'warning': (1.0, 0.9, 0.5, 1),   # Light gold/yellow
        'error': (1.0, 0.8, 0.8, 1),     # Light red
        'confirm': (0.9, 0.9, 0.9, 1)    # Light gray
    }
    
    @staticmethod
    def show_info(title, message, callback=None):
        """Show an information popup."""
        return UnifiedPopup._create_popup(title, message, 'info', callback)
    
    @staticmethod
    def show_success(title, message, callback=None):
        """Show a success popup."""
        return UnifiedPopup._create_popup(title, message, 'success', callback)
    
    @staticmethod
    def show_warning(title, message, callback=None):
        """Show a warning popup."""
        return UnifiedPopup._create_popup(title, message, 'warning', callback)
    
    @staticmethod
    def show_error(title, message, callback=None):
        """Show an error popup."""
        return UnifiedPopup._create_popup(title, message, 'error', callback)
    
    @staticmethod
    def show_confirmation(title, message, on_yes=None, on_no=None):
        """Show a confirmation popup with Yes/No buttons."""
        return UnifiedPopup._create_confirmation_popup(title, message, on_yes, on_no)
    
    @staticmethod
    def _create_popup(title, message, popup_type='info', callback=None):
        """Create a standard popup with OK button."""
        # Get color for popup type
        bg_color = UnifiedPopup.COLORS.get(popup_type, UnifiedPopup.COLORS['info'])
        
        # Create content layout
        content = BoxLayout(orientation='vertical', padding=dp(20), spacing=dp(15))
        
        # Add background color to content
        with content.canvas.before:
            Color(*bg_color)
            content.bg_rect = Rectangle(pos=content.pos, size=content.size)
        content.bind(pos=UnifiedPopup._update_bg, size=UnifiedPopup._update_bg)
        
        # Message label
        message_label = Label(
            text=message,
            font_size='16sp',
            color=(0, 0, 0, 1),
            halign='center',
            valign='middle',
            text_size=(None, None)
        )
        content.add_widget(message_label)
        
        # OK button
        ok_button = Button(
            text='OK',
            size_hint=(None, None),
            size=(dp(100), dp(40)),
            pos_hint={'center_x': 0.5},
            background_color=(0.7, 0.7, 0.7, 1)
        )
        content.add_widget(ok_button)
        
        # Create popup
        popup = Popup(
            title=title,
            content=content,
            size_hint=(0.3, 0.2), #(0.6, 0.4)
            auto_dismiss=True,
            title_color=(1, 1, 1, 1),
            title_size='18sp'
        )
        
        # Bind button to close popup and call callback
        def on_ok(instance):
            popup.dismiss()
            if callback:
                callback()
        
        ok_button.bind(on_press=on_ok)
        
        # Update message label text_size after popup is created
        def update_text_size(popup_instance, content_size):
            if hasattr(popup_instance, 'content') and popup_instance.content:
                # Calculate available width for text (popup width - padding)
                available_width = popup_instance.width * 0.8  # 80% of popup width
                message_label.text_size = (available_width, None)
        
        popup.bind(size=update_text_size)
        
        return popup
    
    @staticmethod
    def _create_confirmation_popup(title, message, on_yes=None, on_no=None):
        """Create a confirmation popup with Yes/No buttons."""
        bg_color = UnifiedPopup.COLORS['confirm']
        
        # Create content layout
        content = BoxLayout(orientation='vertical', padding=dp(20), spacing=dp(15))
        
        # Add background color to content
        with content.canvas.before:
            Color(*bg_color)
            content.bg_rect = Rectangle(pos=content.pos, size=content.size)
        content.bind(pos=UnifiedPopup._update_bg, size=UnifiedPopup._update_bg)
        
        # Message label
        message_label = Label(
            text=message,
            font_size='16sp',
            color=(0, .0, .0, 1),
            halign='center',
            valign='middle',
            text_size=(None, None)
        )
        content.add_widget(message_label)
        
        # Button layout
        button_layout = BoxLayout(orientation='horizontal', spacing=dp(20), size_hint_y=None, height=dp(40))
        
        # Yes button
        yes_button = Button(
            text='Yes',
            size_hint=(0.5, 1),
            background_color=(0.8, 1.0, 0.8, 1)  # Light green
        )
        button_layout.add_widget(yes_button)
        
        # No button
        no_button = Button(
            text='No',
            size_hint=(0.5, 1),
            background_color=(1.0, 0.8, 0.8, 1)  # Light red
        )
        button_layout.add_widget(no_button)
        
        content.add_widget(button_layout)
        
        # Create popup
        popup = Popup(
            title=title,
            content=content,
            size_hint=(0.3, 0.2),
            auto_dismiss=False,  # Don't auto-dismiss confirmation dialogs
            title_color=(0, 0, 0, 1),
            title_size='18sp'
        )
        
        # Bind buttons
        def on_yes_click(instance):
            popup.dismiss()
            if on_yes:
                on_yes()
        
        def on_no_click(instance):
            popup.dismiss()
            if on_no:
                on_no()
        
        yes_button.bind(on_press=on_yes_click)
        no_button.bind(on_press=on_no_click)
        
        # Update message label text_size after popup is created
        def update_text_size(popup_instance, content_size):
            if hasattr(popup_instance, 'content') and popup_instance.content:
                # Calculate available width for text (popup width - padding)
                available_width = popup_instance.width * 0.8  # 80% of popup width
                message_label.text_size = (available_width, None)
        
        popup.bind(size=update_text_size)
        
        return popup
    
    @staticmethod
    def _update_bg(instance, value):
        """Update background rectangle when widget moves or resizes."""
        if hasattr(instance, 'bg_rect'):
            instance.bg_rect.pos = instance.pos
            instance.bg_rect.size = instance.size


class QuickPopup:
    """
    Quick utility methods for common popup scenarios.
    These automatically open the popup for convenience.
    """
    
    @staticmethod
    def info(title, message, callback=None):
        """Show info popup and open it immediately."""
        popup = UnifiedPopup.show_info(title, message, callback)
        popup.open()
        return popup
    
    @staticmethod
    def success(title, message, callback=None):
        """Show success popup and open it immediately."""
        popup = UnifiedPopup.show_success(title, message, callback)
        popup.open()
        return popup
    
    @staticmethod
    def warning(title, message, callback=None):
        """Show warning popup and open it immediately."""
        popup = UnifiedPopup.show_warning(title, message, callback)
        popup.open()
        return popup
    
    @staticmethod
    def error(title, message, callback=None):
        """Show error popup and open it immediately."""
        popup = UnifiedPopup.show_error(title, message, callback)
        popup.open()
        return popup
    
    @staticmethod
    def confirm(title, message, on_yes=None, on_no=None):
        """Show confirmation popup and open it immediately."""
        popup = UnifiedPopup.show_confirmation(title, message, on_yes, on_no)
        popup.open()
        return popup
    
    # Common scenarios with predefined messages
    @staticmethod
    def database_error(error_message):
        """Standard database error popup."""
        return QuickPopup.error('Database Error', f'Database operation failed:\n{error_message}')
    
    @staticmethod
    def validation_error(message):
        """Standard validation error popup."""
        return QuickPopup.warning('Validation Error', message)
    
    @staticmethod
    def operation_success(operation_name):
        """Standard success popup for operations."""
        return QuickPopup.success('Success', f'{operation_name} completed successfully!')
    
    @staticmethod
    def confirm_delete(item_name, on_confirm=None):
        """Standard delete confirmation popup."""
        return QuickPopup.confirm(
            'Confirm Delete',
            f'Are you sure you want to delete {item_name}?\n\nThis action cannot be undone.',
            on_yes=on_confirm
        )
    
    @staticmethod
    def no_selection(item_type="item"):
        """Standard no selection popup."""
        return QuickPopup.warning('No Selection', f'Please select a {item_type} first.')