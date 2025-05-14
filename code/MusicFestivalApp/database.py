"""
Database connection and query execution module for the Music Festival App.

This module provides a Database class that encapsulates all database operations
including connection management, query execution, and performance optimization.
It supports various query execution modes including traced execution and 
optimizer setting adjustments for performance analysis.
"""

import mysql.connector
from mysql.connector import Error
import pandas as pd
from config import DB_CONFIG


class Database:
    """
    Class that handles all database operations for the Music Festival application.
    Provides methods for connecting to the database, executing queries, and analyzing
    query performance through optimizer traces.
    """
    
    def __init__(self):
        """Initialize database connection."""
        self.connection = None
        self.connect()
    
    
    def connect(self):
        """
        Establish connection to the MariaDB database using settings from config.py.
        Prints success or error messages based on connection result.
        """
        try:
            self.connection = mysql.connector.connect(
                host=DB_CONFIG['host'],
                user=DB_CONFIG['user'],
                password=DB_CONFIG['password'],
                database=DB_CONFIG['database'],
                port=DB_CONFIG['port']
            )
            print("Successfully connected to the database!")
            
        except Error as e:
            print(f"Error connecting to MariaDB: {e}")
            self.connection = None
    
    def is_connected(self):
        """Check if the database connection is active."""
        return self.connection is not None and self.connection.is_connected()
    
    def reconnect_if_needed(self):
        """Reconnect to the database if the connection is lost."""
        if not self.is_connected():
            print("Connection lost. Attempting to reconnect...")
            self.connect()
            return self.is_connected()
        return True
    
    def execute_query(self, query, params=None):
        """
        Execute an SQL query and return the results as a pandas DataFrame.


        Args:
            query (str): The SQL query to execute
            params (tuple, optional): Parameters for parameterized queries
            
        Returns:
            pandas.DataFrame: Query results as a DataFrame, or None if query fails
        """
        if not self.reconnect_if_needed():
            return None
        
        try:
            cursor = self.connection.cursor(dictionary=True)
            
            if params:
                cursor.execute(query, params)
            else:
                cursor.execute(query)
                
            # Fetch results
            result = cursor.fetchall()
            
            # Convert to pandas DataFrame
            df = pd.DataFrame(result) if result else pd.DataFrame()
            
            cursor.close()
            return df
            
        except Error as e:
            print(f"Error executing query: {e}")
            return None
    
    def execute_query_with_trace(self, query, params=None):
        """
        Execute a query with optimizer trace information for performance analysis.
        This method enables MySQL optimizer trace to capture query execution details.

        Args:
            query (str): The SQL query to execute
            params (tuple, optional): Parameters for parameterized queries
            
        Returns:
            tuple: (DataFrame of results, Trace information dictionary)
        """
        if not self.reconnect_if_needed():
            return None, "Not connected to database"
        
        try:
            cursor = self.connection.cursor(dictionary=True)
            
            # Enable optimizer trace
            cursor.execute("SET optimizer_trace='enabled=on'")
            cursor.execute("SET optimizer_trace_max_mem_size=1000000")
            
            # Execute the actual query
            if params:
                cursor.execute(query, params)
            else:
                cursor.execute(query)
                
            # Fetch results
            result = cursor.fetchall()
            
            # Get trace information
            cursor.execute("SELECT * FROM information_schema.optimizer_trace")
            trace_result = cursor.fetchone()
            
            # Convert to pandas DataFrame
            df = pd.DataFrame(result) if result else pd.DataFrame()
            
            # Disable optimizer trace
            cursor.execute("SET optimizer_trace='enabled=off'")
            
            cursor.close()
            return df, trace_result
            
        except Error as e:
            print(f"Error executing traced query: {e}")
            return None, str(e)
    
    def close(self):
        """Close the database connection."""
        if self.connection and self.connection.is_connected():
            self.connection.close()
            print("Database connection closed.")

    def execute_query_with_optimizer_settings(self, query, params=None, optimizer_settings=None):
        """
        Execute a query with specific optimizer settings to test different join strategies.
        This method allows testing how different optimizer settings affect query performance.

        Args:
            query (str): The SQL query to execute
            params (tuple, optional): Parameters for parameterized queries
            optimizer_settings (dict, optional): Dictionary of optimizer settings to apply
            
        Returns:
            tuple: (DataFrame of results, Trace information, Optimizer settings used)
        """
        if not self.reconnect_if_needed():
            return None, "Not connected to database", None
        
        try:
            cursor = self.connection.cursor(dictionary=True)
            
            # Save original settings to restore later
            original_settings = {}
            if optimizer_settings:
                # Get current settings
                for var in optimizer_settings.keys():
                    cursor.execute(f"SELECT @@{var} AS value")
                    result = cursor.fetchone()
                    original_settings[var] = result['value']
                
                # Apply new settings
                for var, value in optimizer_settings.items():
                    cursor.execute(f"SET {var}={value}")
            
            # Enable optimizer trace
            cursor.execute("SET optimizer_trace='enabled=on'")
            cursor.execute("SET optimizer_trace_max_mem_size=1000000")
            
            # Execute the actual query
            if params:
                cursor.execute(query, params)
            else:
                cursor.execute(query)
                
            # Fetch results
            result = cursor.fetchall()
            
            # Get trace information
            cursor.execute("SELECT * FROM information_schema.optimizer_trace")
            trace_result = cursor.fetchone()
            
            # Convert to pandas DataFrame
            df = pd.DataFrame(result) if result else pd.DataFrame()
            
            # Disable optimizer trace
            cursor.execute("SET optimizer_trace='enabled=off'")
            
            # Restore original settings
            if optimizer_settings:
                for var, value in original_settings.items():
                    cursor.execute(f"SET {var}={value}")
            
            cursor.close()
            return df, trace_result, optimizer_settings
                
        except Error as e:
            print(f"Error executing traced query with optimizer settings: {e}")
            return None, str(e), None