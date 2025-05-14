"""
Styles module for the Music Festival Database App UI.

This module defines colors, styles, and themes used throughout the application.
It provides consistent styling for all UI components and configures the Tkinter
ttk styles for a modern, cohesive appearance.
"""

import tkinter as tk
from tkinter import ttk

"""
Main color palette for the application.
These colors are used consistently throughout the UI for visual coherence.
"""
PRIMARY_COLOR = "#3498db"  # Blue
SECONDARY_COLOR = "#2ecc71"  # Green
ACCENT_COLOR = "#e74c3c"  # Red
BG_COLOR = "#f8f9fa"  # Light gray
TEXT_COLOR = "#2c3e50"  # Dark blue-gray
HIGHLIGHT_COLOR = "#f39c12"  # Orange

"""
Style definitions for frame components.
These dictionaries define visual properties like background color, padding, and borders.
"""
FRAME_STYLE = {
    "bg": BG_COLOR,
    "relief": "flat",
    "padx": 10,
    "pady": 10
}

# Button styles
BUTTON_STYLE = {
    "bg": PRIMARY_COLOR,
    "fg": "white",
    "activebackground": SECONDARY_COLOR,
    "activeforeground": "white",
    "font": ("Helvetica", 10),
    "relief": "raised",
    "borderwidth": 1,
    "padx": 10,
    "pady": 5,
    "cursor": "hand2"
}

# Label styles
LABEL_STYLE = {
    "bg": BG_COLOR,
    "fg": TEXT_COLOR,
    "font": ("Helvetica", 10),
    "padx": 5,
    "pady": 5
}

TITLE_STYLE = {
    "bg": BG_COLOR,
    "fg": TEXT_COLOR,
    "font": ("Helvetica", 14, "bold"),
    "padx": 5,
    "pady": 5
}

# Entry styles
ENTRY_STYLE = {
    "bg": "white",
    "fg": TEXT_COLOR,
    "font": ("Helvetica", 10),
    "relief": "solid",
    "borderwidth": 1
}

# Treeview styles (for data display)
TREEVIEW_STYLE = {
    "background": "white",
    "foreground": TEXT_COLOR,
    "rowheight": 25,
    "font": ("Helvetica", 10)
}

TREEVIEW_HEADING_STYLE = {
    "background": PRIMARY_COLOR,
    "foreground": "white",
    "font": ("Helvetica", 10, "bold")
}

# Text styles
TEXT_STYLE = {
    "bg": "white",
    "fg": TEXT_COLOR,
    "font": ("Courier New", 10),
    "relief": "solid",
    "borderwidth": 1,
    "padx": 5,
    "pady": 5,
    "wrap": tk.WORD  # Using tkinter constant instead of string
}

# List box styles
LISTBOX_STYLE = {
    "bg": "white",
    "fg": TEXT_COLOR,
    "font": ("Helvetica", 10),
    "relief": "solid",
    "borderwidth": 1,
    "activestyle": "dotbox",
    "selectbackground": PRIMARY_COLOR,
    "selectforeground": "white"
}

# Status bar styles
STATUS_STYLE = {
    "font": ("Helvetica", 9),
    "relief": "sunken",
    "borderwidth": 1,
    "anchor": "w",
    "padx": 5,
    "pady": 2
}

"""
Function to apply custom styles to ttk widgets.
Configures all ttk components with consistent colors, fonts, and visual properties
to create a cohesive application appearance.
"""
def configure_ttk_styles(style):
    """Configure ttk styles for the application."""
    
    # Configure the main theme
    style.configure(".", 
                   background=BG_COLOR,
                   foreground=TEXT_COLOR,
                   font=("Helvetica", 10))
    
    # Configure TButton
    style.configure("TButton",
                  background=PRIMARY_COLOR,
                  foreground="white",
                  padding=(10, 5),
                  font=("Helvetica", 10))
    
    style.map("TButton",
            background=[("active", SECONDARY_COLOR)],
            foreground=[("active", "white")])
    
    # Configure TLabel
    style.configure("TLabel",
                  background=BG_COLOR,
                  foreground=TEXT_COLOR,
                  padding=(5, 5),
                  font=("Helvetica", 10))
    
    # Configure Title Label
    style.configure("Title.TLabel",
                  background=BG_COLOR,
                  foreground=TEXT_COLOR,
                  padding=(5, 5),
                  font=("Helvetica", 14, "bold"))
    
    # Configure TEntry
    style.configure("TEntry",
                  background="white",
                  fieldbackground="white",
                  foreground=TEXT_COLOR,
                  padding=(5, 5),
                  font=("Helvetica", 10))
    
    # Configure Treeview
    style.configure("Treeview",
                  background="white",
                  foreground=TEXT_COLOR,
                  rowheight=25,
                  fieldbackground="white",
                  font=("Helvetica", 10))
    
    style.configure("Treeview.Heading",
                  background=PRIMARY_COLOR,
                  foreground="white",
                  relief="flat",
                  font=("Helvetica", 10, "bold"))
    
    style.map("Treeview",
            background=[("selected", PRIMARY_COLOR)],
            foreground=[("selected", "white")])
    
    # Configure TFrame
    style.configure("TFrame",
                  background=BG_COLOR,
                  relief="flat")
    
    # Configure TNotebook
    style.configure("TNotebook",
                  background=BG_COLOR,
                  tabmargins=[2, 5, 2, 0])
    
    style.configure("TNotebook.Tab",
                  background="#d3d3d3",
                  foreground=TEXT_COLOR,
                  padding=[10, 5],
                  font=("Helvetica", 10))
    
    # Configure Status Label
    style.configure("Status.TLabel",
                  background="#ecf0f1",  # Light gray
                  foreground=TEXT_COLOR,
                  padding=(5, 2),
                  font=("Helvetica", 9),
                  relief="sunken")
    
    # Configure TNotebook.Tab
    style.configure("TNotebook.Tab",
                  background="#d3d3d3",
                  foreground=TEXT_COLOR,
                  padding=[10, 5],
                  font=("Helvetica", 10))
    
    style.map("TNotebook.Tab",
            background=[("selected", PRIMARY_COLOR)],
            foreground=[("selected", "white")],
            expand=[("selected", [1, 1, 1, 0])])
            
    # Configure Status Label
    style.configure("Status.TLabel",
                  background="#ecf0f1",  # Light gray
                  foreground=TEXT_COLOR,
                  padding=(5, 2),
                  font=("Helvetica", 9),
                  relief="sunken")
    
    style.map("TNotebook.Tab",
            background=[("selected", PRIMARY_COLOR)],
            foreground=[("selected", "white")],
            expand=[("selected", [1, 1, 1, 0])])