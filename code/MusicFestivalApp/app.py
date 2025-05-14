"""
Main application entry point for the Music Festival Database App.

This script initializes the database connection and creates the main application window.
It handles the application lifecycle including startup and shutdown processes.
The application allows users to execute and visualize various SQL queries
for analyzing music festival data as specified in the assignment.
"""

import tkinter as tk
from tkinter import messagebox
import pandas as pd
import numpy as np
import matplotlib
matplotlib.use('TkAgg')  # Set matplotlib backend

from database import Database
from ui.main_window import MainWindow
import config

"""Main function to start the application and handle database connection."""
def main():
    """Main function to start the application."""
    try:
        # Initialize database connection
        db = Database()
        
        if not db.is_connected():
            messagebox.showerror(
                "Database Connection Error",
                "Could not connect to the database. Please check your configuration."
            )
            return
        
        # Create and start the main application window
        app = MainWindow(db)
        
        # Set up window close event
        app.protocol("WM_DELETE_WINDOW", lambda: on_closing(app, db))
        
        # Start the main event loop
        app.mainloop()
        
    except Exception as e:
        messagebox.showerror("Application Error", f"An error occurred: {str(e)}")
        
"""
Handle application closing event.
Ensures proper database connection closure before destroying the application window.
"""
def on_closing(app, db):
    """Handle application closing."""
    # Close database connection
    if db and db.is_connected():
        db.close()
    
    # Destroy the application window
    app.destroy()

if __name__ == "__main__":
    main()