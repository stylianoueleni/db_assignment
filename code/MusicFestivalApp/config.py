"""
Database and application configuration settings for the Music Festival App.

This module defines constants and configuration parameters used throughout
the application, including database connection settings and UI display properties.
These settings can be modified to adapt to different environments.
"""

"""
Database connection configuration for MariaDB/MySQL.
Modify these values to match your local database configuration.
"""
# Database connection settings
DB_CONFIG = {
    'host': 'localhost',      # XAMPP MySQL server host
    'user': 'root',           # Default XAMPP MySQL username
    'password': '',           # Default XAMPP MySQL password (empty)
    'database': 'MusicFestival',  # Your database name
    'port': 3306              # Default MariaDB port
}

"""
Application UI configuration settings.
These settings control the appearance and behavior of the application window.
"""
# Application settings
APP_CONFIG = {
    'title': 'Music Festival Database App',
    'width': 1200,
    'height': 800,
    'theme': 'clam',          # Tkinter theme
    'font_family': 'Helvetica',
    'font_size': 10
}