"""
Query frame module for result display in the Music Festival Database App.

This module defines the QueryFrame class that handles displaying query results
in a tabular format, visualizing data with charts, and showing query execution traces.
It provides data visualization capabilities for selected queries.
"""

import tkinter as tk
from tkinter import ttk, messagebox
import pandas as pd
from datetime import datetime
import matplotlib.pyplot as plt
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
import json

from ui.styles import *


class QueryFrame(ttk.Frame):
    """
    Frame for displaying and visualizing query results.
    Provides tabular display of data, export functionality, and data visualization
    with various chart types depending on the query.
    """
    
    def __init__(self, parent):
        """Initialize the query frame."""
        super().__init__(parent, style="TFrame")
        
        self.parent = parent
        self.trace_window = None
        
        self._init_ui()
    
    def _init_ui(self):
        """Initialize the UI components."""
        # Create main layout frames
        self.controls_frame = ttk.Frame(self, style="TFrame")
        self.controls_frame.pack(fill=tk.X, padx=10, pady=5)
        
        self.results_frame = ttk.Frame(self, style="TFrame")
        self.results_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=5)
        
        # Add control buttons
        self.button_frame = ttk.Frame(self.controls_frame, style="TFrame")
        self.button_frame.pack(side=tk.LEFT, fill=tk.X)
        
        self.export_btn = ttk.Button(self.button_frame, text="Export Results", command=self.export_results)
        self.export_btn.pack(side=tk.LEFT, padx=5)
        
        self.show_trace_btn = ttk.Button(self.button_frame, text="Show Execution Trace", command=self.show_trace)
        self.show_trace_btn.pack(side=tk.LEFT, padx=5)
        self.show_trace_btn.config(state=tk.DISABLED)  # Disabled until results with trace are available
        
        self.visualize_btn = ttk.Button(self.button_frame, text="Visualize Data", command=self.visualize_data)
        self.visualize_btn.pack(side=tk.LEFT, padx=5)
        self.visualize_btn.config(state=tk.DISABLED)  # Disabled until results are available
        
        # Status info on the right
        self.status_frame = ttk.Frame(self.controls_frame, style="TFrame")
        self.status_frame.pack(side=tk.RIGHT, fill=tk.X)
        
        self.status_label = ttk.Label(self.status_frame, text="Ready")
        self.status_label.pack(side=tk.RIGHT, padx=5)
        
        self.rows_label = ttk.Label(self.status_frame, text="")
        self.rows_label.pack(side=tk.RIGHT, padx=5)
        
        # Create treeview for results
        self.tree_frame = ttk.Frame(self.results_frame, style="TFrame")
        self.tree_frame.pack(fill=tk.BOTH, expand=True)
        
        # Add scrollbars
        self.vsb = ttk.Scrollbar(self.tree_frame, orient="vertical")
        self.vsb.pack(side=tk.RIGHT, fill=tk.Y)
        
        self.hsb = ttk.Scrollbar(self.tree_frame, orient="horizontal")
        self.hsb.pack(side=tk.BOTTOM, fill=tk.X)
        
        # Create treeview
        self.tree = ttk.Treeview(self.tree_frame, 
                              yscrollcommand=self.vsb.set,
                              xscrollcommand=self.hsb.set)
        
        self.tree.pack(fill=tk.BOTH, expand=True)
        
        # Configure scrollbars
        self.vsb.config(command=self.tree.yview)
        self.hsb.config(command=self.tree.xview)
        
        # Initialize instance variables
        self.results_df = None
        self.trace_data = None
    
    def display_results(self, results_df, query_name=None, trace_data=None, execution_time=None):
        """
        Display query results in the treeview component.
        
        Args:
            results_df (pandas.DataFrame): Query results as a DataFrame
            query_name (str, optional): Name of the executed query
            trace_data (dict, optional): Query execution trace data
            execution_time (float, optional): Query execution time in seconds
        """
        self.results_df = results_df
        self.trace_data = trace_data
        self.execution_time = execution_time
        self.query_name = query_name  # Store the query name
        
        # Clear existing data
        for i in self.tree.get_children():
            self.tree.delete(i)
        
        # Configure columns
        self.tree["columns"] = list(results_df.columns)
        self.tree["show"] = "headings"  # Hide the first empty column
        
        # Format columns
        for column in results_df.columns:
            self.tree.heading(column, text=column)
            
            # Set column width based on content
            max_width = max(
                len(str(column)),
                *[len(str(x)) for x in results_df[column].values if pd.notna(x)]
            )
            self.tree.column(column, width=max_width * 10, minwidth=50)
        
        # Insert data
        for _, row in results_df.iterrows():
            values = []
            for col in results_df.columns:
                # Handle special cases for display
                if pd.isna(row[col]):
                    values.append("")
                elif isinstance(row[col], (pd.Timestamp, datetime)):
                    values.append(row[col].strftime("%Y-%m-%d %H:%M:%S"))
                else:
                    values.append(str(row[col]))
            
            self.tree.insert("", "end", values=values)
        
        # Update status
        if len(results_df) == 0:
            self.rows_label.config(text="No results found")
        else:
            self.rows_label.config(text=f"{len(results_df)} rows")
        
        status_text = []
        if query_name:
            status_text.append(f"Query: {query_name}")
        if execution_time is not None:
            status_text.append(f"Time: {execution_time:.4f}s")
        
        self.status_label.config(text=" | ".join(status_text))
        
        # Enable/disable trace button
        if trace_data is not None:
            self.show_trace_btn.config(state=tk.NORMAL)
        else:
            self.show_trace_btn.config(state=tk.DISABLED)
        
        # Enable/disable visualize button based on the query
        # Only enable visualization for specified queries
        visualize_enabled_queries = [
            "1. Festival Revenue by Year and Payment Method",
            "3. Artists with Multiple Warm-up Performances",
            "5. Young Artists with Most Festival Participations",
            "6. Visitor Attended Performances and Ratings",
            "11. Artists with Fewer Performances Than Top Artist",
            "13. Artists Who Performed on Multiple Continents"
        ]
        
        if not results_df.empty and query_name in visualize_enabled_queries:
            self.visualize_btn.config(state=tk.NORMAL)
        else:
            self.visualize_btn.config(state=tk.DISABLED)
    

    def export_results(self):
        """Export the query results to a CSV file."""
        if self.results_df is None or self.results_df.empty:
            messagebox.showinfo("Export", "No results to export.")
            return
        
        from tkinter import filedialog
        filename = filedialog.asksaveasfilename(
            defaultextension=".csv",
            filetypes=[("CSV files", "*.csv"), ("Excel files", "*.xlsx"), ("All files", "*.*")]
        )
        
        if not filename:
            return
        
        try:
            if filename.endswith(".csv"):
                self.results_df.to_csv(filename, index=False)
            elif filename.endswith(".xlsx"):
                self.results_df.to_excel(filename, index=False)
            else:
                self.results_df.to_csv(filename, index=False)
            
            messagebox.showinfo("Export", f"Results exported successfully to {filename}")
        except Exception as e:
            messagebox.showerror("Export Error", f"Error exporting results: {str(e)}")
    
    def show_trace(self):
        """Show the query execution trace in a new window."""
        if self.trace_data is None:
            messagebox.showinfo("Trace", "No trace data available for this query.")
            return
        
        # Close the existing trace window if open
        if self.trace_window and self.trace_window.winfo_exists():
            self.trace_window.destroy()
        
        # Create a new window
        self.trace_window = tk.Toplevel(self.parent)
        self.trace_window.title("Query Execution Trace")
        self.trace_window.geometry("800x600")
        
        # Configure the window
        self.trace_window.columnconfigure(0, weight=1)
        self.trace_window.rowconfigure(0, weight=1)
        
        # Create a text widget to display the trace - without duplicate wrap parameter
        trace_text = tk.Text(self.trace_window, **TEXT_STYLE)
        
        # Add scrollbars
        vsb = ttk.Scrollbar(self.trace_window, orient="vertical", command=trace_text.yview)
        hsb = ttk.Scrollbar(self.trace_window, orient="horizontal", command=trace_text.xview)
        
        trace_text.configure(yscrollcommand=vsb.set, xscrollcommand=hsb.set)
        
        # Grid layout
        trace_text.grid(row=0, column=0, sticky=(tk.N, tk.S, tk.E, tk.W))
        vsb.grid(row=0, column=1, sticky=(tk.N, tk.S))
        hsb.grid(row=1, column=0, sticky=(tk.E, tk.W))
        
        # Format and display the trace data
        if isinstance(self.trace_data, str):
            formatted_trace = self.trace_data
        else:
            try:
                # Try to convert to string if it's an object
                if isinstance(self.trace_data, dict) and 'TRACE' in self.trace_data:
                    trace_json = json.loads(self.trace_data['TRACE'])
                    formatted_trace = json.dumps(trace_json, indent=2)
                else:
                    formatted_trace = json.dumps(self.trace_data, indent=2)
            except Exception as e:
                formatted_trace = f"Error formatting trace data: {str(e)}\n\nRaw trace data: {str(self.trace_data)}"
        
        trace_text.insert(tk.END, formatted_trace)
        trace_text.config(state=tk.DISABLED)  # Make it read-only
    
    def visualize_data(self):
        """
        Visualize query results using appropriate chart types.
        Creates a new window with visualization tabs based on the query type,
        generating different charts (bar, pie, line) as appropriate for the data.
        Only enabled for specific queries that have meaningful visualizations.
        """
        if self.results_df is None or self.results_df.empty:
            messagebox.showinfo("Visualize", "No results to visualize.")
            return
        
        # Create a new window
        viz_window = tk.Toplevel(self.parent)
        viz_window.title("Data Visualization")
        viz_window.geometry("900x650")
        
        # Create a notebook for tabs
        notebook = ttk.Notebook(viz_window)
        notebook.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Determine which visualizations to use based on the query name
        if "1. Festival Revenue by Year and Payment Method" in self.query_name:
            # Revenue visualizations - bar, pie, and line
            bar_frame = ttk.Frame(notebook)
            pie_frame = ttk.Frame(notebook)
            line_frame = ttk.Frame(notebook)
            
            notebook.add(bar_frame, text="Bar Chart")
            notebook.add(pie_frame, text="Pie Chart")
            notebook.add(line_frame, text="Line Chart")
            
            self._create_revenue_by_year_bar(bar_frame)
            self._create_revenue_by_payment_pie(pie_frame)
            self._create_revenue_by_year_line(line_frame)
        
        elif "3. Artists with Multiple Warm-up Performances" in self.query_name:
            # Artist warmup charts - bar and pie
            bar_frame = ttk.Frame(notebook)
            pie_frame = ttk.Frame(notebook)
            
            notebook.add(bar_frame, text="Bar Chart")
            notebook.add(pie_frame, text="Pie Chart")
            
            self._create_artist_warmup_bar(bar_frame)
            self._create_artist_warmup_pie(pie_frame)
        
        elif "5. Young Artists with Most Festival Participations" in self.query_name:
            # Festival count charts - bar and pie
            bar_frame = ttk.Frame(notebook)
            pie_frame = ttk.Frame(notebook)
            
            notebook.add(bar_frame, text="Bar Chart")
            notebook.add(pie_frame, text="Pie Chart")
            
            self._create_festival_count_bar(bar_frame)
            self._create_festival_count_pie(pie_frame)
        
        elif "6. Visitor Attended Performances and Ratings" in self.query_name:
            # Average rating charts - bar and pie
            bar_frame = ttk.Frame(notebook)
            pie_frame = ttk.Frame(notebook)
            
            notebook.add(bar_frame, text="Bar Chart")
            notebook.add(pie_frame, text="Pie Chart")
            
            self._create_rating_per_performance_bar(bar_frame)
            self._create_rating_per_performance_pie(pie_frame)
        
        elif "11. Artists with Fewer Performances Than Top Artist" in self.query_name:
            # Artist festival count charts - bar and pie
            bar_frame = ttk.Frame(notebook)
            pie_frame = ttk.Frame(notebook)
            
            notebook.add(bar_frame, text="Bar Chart")
            notebook.add(pie_frame, text="Pie Chart")
            
            self._create_artist_festival_count_bar(bar_frame)
            self._create_artist_festival_count_pie(pie_frame)
        
        elif "13. Artists Who Performed on Multiple Continents" in self.query_name:
            # Continent count charts - bar and pie
            bar_frame = ttk.Frame(notebook)
            pie_frame = ttk.Frame(notebook)
            
            notebook.add(bar_frame, text="Bar Chart")
            notebook.add(pie_frame, text="Pie Chart")
            
            self._create_artist_continent_bar(bar_frame)
            self._create_artist_continent_pie(pie_frame)
        
        else:
            # Fallback (shouldn't happen due to our button enabling logic)
            single_frame = ttk.Frame(notebook)
            notebook.add(single_frame, text="Visualization")
            ttk.Label(single_frame, text="No visualization available for this query.").pack(pady=20)

    def _create_revenue_by_year_bar(self, parent):
        """Create a bar chart for revenue by year (Query 1)."""
        fig, ax = plt.subplots(figsize=(10, 6))
        
        try:
            # Print raw data for debugging
            print("Raw data for Query 1 bar chart:")
            print(self.results_df.head())
            print(self.results_df.dtypes)
            
            # Find columns to use
            year_col = None
            revenue_col = None
            
            # Check column names explicitly
            for col in self.results_df.columns:
                col_name = str(col).lower()
                if 'year' in col_name:
                    year_col = col
                elif 'revenue' in col_name or 'total' in col_name:
                    revenue_col = col
            
            # If we still don't have columns, try positional approach
            if not year_col or not revenue_col:
                cols = list(self.results_df.columns)
                print(f"Columns in results: {cols}")
                if len(cols) >= 3:
                    year_col = cols[0]       # First column likely year
                    revenue_col = cols[2]    # Third column likely revenue
            
            print(f"Selected columns: year_col={year_col}, revenue_col={revenue_col}")
            
            if year_col is not None and revenue_col is not None:
                # Copy data to avoid modifying original
                df_copy = self.results_df.copy()
                
                # Try to convert year to numeric or string (in case it's categorical)
                try:
                    df_copy[year_col] = pd.to_numeric(df_copy[year_col], errors='coerce')
                except:
                    df_copy[year_col] = df_copy[year_col].astype(str)
                
                # Convert revenue to numeric, with special handling for common formats
                try:
                    # First, if the column is object type (string), remove commas and $ symbols
                    if df_copy[revenue_col].dtype == 'object':
                        df_copy[revenue_col] = df_copy[revenue_col].astype(str).str.replace(',', '')
                        df_copy[revenue_col] = df_copy[revenue_col].astype(str).str.replace('$', '')
                        
                    # Then convert to numeric
                    df_copy[revenue_col] = pd.to_numeric(df_copy[revenue_col], errors='coerce')
                    print(f"Converted revenue: {df_copy[revenue_col].head()}")
                except Exception as e:
                    print(f"Error converting revenue: {e}")
                    
                # Remove any rows with NaN values
                df_copy = df_copy.dropna(subset=[year_col, revenue_col])
                
                # Check if we have valid data
                if not df_copy.empty:
                    # Aggregate revenue by year
                    yearly_revenue = df_copy.groupby(year_col)[revenue_col].sum().reset_index()
                    print(f"Yearly revenue data: {yearly_revenue}")
                    
                    # Create the bar chart
                    yearly_revenue.plot(kind='bar', x=year_col, y=revenue_col, ax=ax, color=PRIMARY_COLOR)
                    
                    ax.set_title("Total Revenue by Year")
                    ax.set_xlabel("Year")
                    ax.set_ylabel("Total Revenue")
                    
                    # Add data labels
                    for p in ax.patches:
                        ax.annotate(f"{p.get_height():.2f}",
                                (p.get_x() + p.get_width() / 2., p.get_height()),
                                ha='center', va='center', 
                                xytext=(0, 10),
                                textcoords='offset points')
                else:
                    ax.text(0.5, 0.5, "No valid numeric data after conversion", 
                        ha='center', va='center', transform=ax.transAxes,
                        fontsize=12, color='red')
                    print("ERROR: No data after conversion and cleaning")
            else:
                ax.text(0.5, 0.5, f"Could not find appropriate columns for year and revenue", 
                    ha='center', va='center', transform=ax.transAxes,
                    fontsize=12, color='red')
                print(f"ERROR: Could not identify columns for visualization")
                
        except Exception as e:
            print(f"Error in revenue bar chart: {str(e)}")
            ax.text(0.5, 0.5, f"Error creating chart: {str(e)}", 
                ha='center', va='center', transform=ax.transAxes,
                fontsize=12, color='red')
        
        plt.tight_layout()
        
        # Embed plot in tkinter
        canvas = FigureCanvasTkAgg(fig, master=parent)
        canvas.draw()
        canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)

    #pie chart methods
    def _create_revenue_by_payment_pie(self, parent):
        """Create a pie chart for revenue by payment method (Query 1)."""
        fig, ax = plt.subplots(figsize=(10, 6))
        
        try:
            # Debug output
            print("Raw data for Query 1 pie chart:")
            print(self.results_df.head())
            print(self.results_df.dtypes)
            
            # Find appropriate columns
            payment_col = None
            revenue_col = None
            
            for col in self.results_df.columns:
                col_name = str(col).lower()
                if 'payment' in col_name or 'method' in col_name:
                    payment_col = col
                elif 'revenue' in col_name or 'total' in col_name:
                    revenue_col = col
            
            # Fallback to positional if needed
            if not payment_col or not revenue_col:
                cols = list(self.results_df.columns)
                print(f"Columns in results: {cols}")
                if len(cols) >= 3:
                    payment_col = cols[1]  # Second column is likely payment method
                    revenue_col = cols[2]  # Third column is likely total revenue
            
            print(f"Selected columns: payment_col={payment_col}, revenue_col={revenue_col}")
            
            if payment_col is not None and revenue_col is not None:
                # Make a copy to avoid modifying original data
                df_copy = self.results_df.copy()
                
                # Convert revenue to numeric
                try:
                    # First, if the column is object type (string), remove commas and $ symbols
                    if df_copy[revenue_col].dtype == 'object':
                        df_copy[revenue_col] = df_copy[revenue_col].astype(str).str.replace(',', '')
                        df_copy[revenue_col] = df_copy[revenue_col].astype(str).str.replace('$', '')
                        
                    # Then convert to numeric
                    df_copy[revenue_col] = pd.to_numeric(df_copy[revenue_col], errors='coerce')
                    print(f"Converted revenue: {df_copy[revenue_col].head()}")
                except Exception as e:
                    print(f"Error converting revenue: {e}")
                
                # Remove any rows with NaN values
                df_copy = df_copy.dropna(subset=[payment_col, revenue_col])
                
                if not df_copy.empty:
                    # Group by payment method
                    payment_revenue = df_copy.groupby(payment_col)[revenue_col].sum()
                    print(f"Payment revenue data: {payment_revenue}")
                    
                    if payment_revenue.sum() > 0:
                        # Create pie chart
                        payment_revenue.plot(kind='pie', ax=ax, autopct='%1.1f%%', startangle=90, shadow=False)
                        
                        ax.set_title("Revenue Distribution by Payment Method")
                        ax.set_ylabel('')  # Hide y label
                    else:
                        ax.text(0.5, 0.5, "Cannot create pie chart: total revenue is zero", 
                            ha='center', va='center', transform=ax.transAxes,
                            fontsize=12, color='red')
                else:
                    ax.text(0.5, 0.5, "No valid numeric data after conversion", 
                        ha='center', va='center', transform=ax.transAxes,
                        fontsize=12, color='red')
                    print("ERROR: No data after conversion and cleaning")
            else:
                ax.text(0.5, 0.5, "Could not identify payment or revenue columns",
                    ha='center', va='center', transform=ax.transAxes,
                    fontsize=12, color='red')
                print(f"ERROR: Could not identify columns for visualization")
        
        except Exception as e:
            print(f"Error in pie chart: {str(e)}")
            ax.text(0.5, 0.5, f"Error creating chart: {str(e)}",
                ha='center', va='center', transform=ax.transAxes,
                fontsize=12, color='red')
        
        plt.tight_layout()
        
        # Embed plot in tkinter
        canvas = FigureCanvasTkAgg(fig, master=parent)
        canvas.draw()
        canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)

    # New line chart methods
    def _create_revenue_by_year_line(self, parent):
        """Create a line chart for revenue by year (Query 1)."""
        fig, ax = plt.subplots(figsize=(10, 6))
        
        try:
            # Debug output
            print("Line Chart - Columns in DataFrame:", self.results_df.columns.tolist())
            print("Line Chart - Data types:", self.results_df.dtypes)
            print("Line Chart - First few rows:", self.results_df.head())
            
            # For Query 1, identify columns and convert to proper types
            year_col = None
            revenue_col = None
            
            # Find appropriate columns
            for col in self.results_df.columns:
                if 'year' in col.lower():
                    year_col = col
                elif 'revenue' in col.lower() or 'total' in col.lower():
                    revenue_col = col
            
            if not year_col or not revenue_col:
                # If we can't find columns by name, use positional (assuming year is first, revenue is third)
                columns = self.results_df.columns.tolist()
                if len(columns) >= 3:
                    year_col = columns[0]  # First column is likely year
                    revenue_col = columns[2]  # Third column is likely total revenue
            
            print(f"Line Chart - Using columns: year_col={year_col}, revenue_col={revenue_col}")
            
            # Ensure numeric conversion
            if year_col and revenue_col:
                # Make a copy to avoid modifying original data
                df_copy = self.results_df.copy()
                
                # Convert revenue to numeric, coercing errors to NaN
                df_copy[revenue_col] = pd.to_numeric(df_copy[revenue_col], errors='coerce')
                
                # Drop any rows with NaN values
                df_copy = df_copy.dropna(subset=[revenue_col])
                
                if not df_copy.empty:
                    # Group by year
                    yearly_revenue = df_copy.groupby(year_col)[revenue_col].sum().reset_index()
                    
                    # Sort by year for line chart
                    # First ensure year column is numeric for proper sorting
                    try:
                        yearly_revenue[year_col] = pd.to_numeric(yearly_revenue[year_col], errors='coerce')
                        yearly_revenue = yearly_revenue.sort_values(year_col)
                    except:
                        # If conversion fails, try to sort as is
                        try:
                            yearly_revenue = yearly_revenue.sort_values(year_col)
                        except:
                            print(f"Warning: Could not sort by {year_col}")
                    
                    # Create line chart
                    yearly_revenue.plot(kind='line', x=year_col, y=revenue_col, ax=ax, 
                                    marker='o', linewidth=2, color=PRIMARY_COLOR)
                    
                    ax.set_title("Revenue Trend by Year")
                    ax.set_xlabel("Year")
                    ax.set_ylabel("Total Revenue")
                    
                    # Add data labels
                    for i, point in yearly_revenue.iterrows():
                        ax.annotate(f"{point[revenue_col]:.2f}",
                                (point[year_col], point[revenue_col]),
                                ha='center', va='bottom',
                                xytext=(0, 10),
                                textcoords='offset points')
                    
                    plt.grid(True, linestyle='--', alpha=0.7)
                else:
                    ax.text(0.5, 0.5, "No numeric data available after conversion",
                        ha='center', va='center', transform=ax.transAxes)
                    print("Line Chart - No valid data after numeric conversion")
            else:
                ax.text(0.5, 0.5, "Could not identify year or revenue columns",
                    ha='center', va='center', transform=ax.transAxes)
                print("Line Chart - Could not identify appropriate columns for visualization")
        
        except Exception as e:
            print(f"Error in line chart: {str(e)}")
            ax.text(0.5, 0.5, f"Error creating chart: {str(e)}",
                ha='center', va='center', transform=ax.transAxes)
        
        plt.tight_layout()
        
        # Embed plot in tkinter
        canvas = FigureCanvasTkAgg(fig, master=parent)
        canvas.draw()
        canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)

    def _create_artist_warmup_bar(self, parent):
        """Create a bar chart for artists by warm-up count (Query 3)."""
        fig, ax = plt.subplots(figsize=(10, 6))
        
        # Sort by warmup count
        df_sorted = self.results_df.sort_values(by='warmup_count', ascending=False)
        
        # Create bar chart
        df_sorted.plot(kind='bar', x='name', y='warmup_count', ax=ax, color=PRIMARY_COLOR)
        
        ax.set_title("Artists by Warm-up Performance Count")
        ax.set_xlabel("Artist")
        ax.set_ylabel("Warm-up Count")
        
        # Rotate x labels for better readability
        plt.xticks(rotation=45, ha='right')
        
        # Add data labels
        for p in ax.patches:
            ax.annotate(str(int(p.get_height())),
                    (p.get_x() + p.get_width() / 2., p.get_height()),
                    ha='center', va='center',
                    xytext=(0, 10),
                    textcoords='offset points')
        
        plt.tight_layout()
        
        # Embed plot in tkinter
        canvas = FigureCanvasTkAgg(fig, master=parent)
        canvas.draw()
        canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)

    def _create_artist_warmup_pie(self, parent):
        """Create a pie chart for artists by warm-up count (Query 3)."""
        fig, ax = plt.subplots(figsize=(10, 6))
        
        # Get the counts for pie chart
        artist_warmups = self.results_df.set_index('name')['warmup_count']
        
        # Create pie chart
        artist_warmups.plot(kind='pie', ax=ax, autopct='%1.1f%%', startangle=90, shadow=False)
        
        ax.set_title("Warm-up Performances Distribution by Artist")
        ax.set_ylabel('')  # Hide y label
        
        plt.tight_layout()
        
        # Embed plot in tkinter
        canvas = FigureCanvasTkAgg(fig, master=parent)
        canvas.draw()
        canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)
    

    def _create_festival_count_bar(self, parent):
        """Create a bar chart for young artists by festival count (Query 5)."""
        fig, ax = plt.subplots(figsize=(10, 6))
        
        # Sort by festival count
        df_sorted = self.results_df.sort_values(by='festival_count', ascending=False)
        
        # Limit to top 15 for readability if needed
        if len(df_sorted) > 15:
            df_sorted = df_sorted.head(15)
        
        # Create bar chart
        df_sorted.plot(kind='bar', x='name', y='festival_count', ax=ax, color=PRIMARY_COLOR)
        
        ax.set_title("Young Artists by Festival Participation Count")
        ax.set_xlabel("Artist")
        ax.set_ylabel("Festival Count")
        
        # Rotate x labels for better readability
        plt.xticks(rotation=45, ha='right')
        
        # Add data labels
        for p in ax.patches:
            ax.annotate(str(int(p.get_height())),
                    (p.get_x() + p.get_width() / 2., p.get_height()),
                    ha='center', va='center',
                    xytext=(0, 10),
                    textcoords='offset points')
        
        plt.tight_layout()
        
        # Embed plot in tkinter
        canvas = FigureCanvasTkAgg(fig, master=parent)
        canvas.draw()
        canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)

    def _create_festival_count_pie(self, parent):
        """Create a pie chart for young artists by festival count (Query 5)."""
        fig, ax = plt.subplots(figsize=(10, 6))
        
        # Get the counts for pie chart
        artist_festivals = self.results_df.set_index('name')['festival_count']
        
        # Limit to top 10 for readability in pie chart
        if len(artist_festivals) > 10:
            others = artist_festivals.iloc[10:].sum()
            artist_festivals = artist_festivals.iloc[:10]
            artist_festivals['Others'] = others
        
        # Create pie chart
        artist_festivals.plot(kind='pie', ax=ax, autopct='%1.1f%%', startangle=90, shadow=False)
        
        ax.set_title("Festival Participation Distribution by Young Artist")
        ax.set_ylabel('')  # Hide y label
        
        plt.tight_layout()
        
        # Embed plot in tkinter
        canvas = FigureCanvasTkAgg(fig, master=parent)
        canvas.draw()
        canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)


    def _create_rating_per_performance_bar(self, parent):
        """Create a bar chart for avg rating per performance (Query 6)."""
        fig, ax = plt.subplots(figsize=(10, 6))
        
        try:
            # Debug output
            print("Query 6 Bar Chart - Columns in DataFrame:", self.results_df.columns.tolist())
            print("Query 6 Bar Chart - Data types:", self.results_df.dtypes)
            print("Query 6 Bar Chart - First few rows:", self.results_df.head())
            
            # Find appropriate columns for event/performance name and ratings
            name_col = None
            rating_col = None
            
            # Try to find appropriate columns by name
            for col in self.results_df.columns:
                col_lower = col.lower()
                # Look for name column
                if 'event' in col_lower or 'performance' in col_lower or 'name' in col_lower:
                    name_col = col
                # Look for rating column
                elif 'rating' in col_lower or 'avg' in col_lower or 'average' in col_lower or 'score' in col_lower:
                    rating_col = col
            
            # If we couldn't find by name, try some common column positions
            if not name_col or not rating_col:
                cols = self.results_df.columns.tolist()
                if len(cols) >= 2:
                    if not name_col:
                        # First column is often the entity name
                        name_col = cols[0]
                    if not rating_col:
                        # Look for a numeric column for rating
                        for col in cols:
                            if pd.api.types.is_numeric_dtype(self.results_df[col]):
                                rating_col = col
                                break
                        # If still not found, use the last column
                        if not rating_col and len(cols) > 1:
                            rating_col = cols[-1]
            
            print(f"Query 6 Bar Chart - Using columns: name_col={name_col}, rating_col={rating_col}")
            
            if name_col and rating_col:
                # Make a copy to avoid modifying original data
                df_copy = self.results_df.copy()
                
                # Ensure rating column is numeric
                df_copy[rating_col] = pd.to_numeric(df_copy[rating_col], errors='coerce')
                df_copy = df_copy.dropna(subset=[rating_col])
                
                if not df_copy.empty:
                    # Sort for better visualization
                    df_sorted = df_copy.sort_values(by=rating_col, ascending=False)
                    
                    # Limit to reasonable number of bars if needed
                    if len(df_sorted) > 15:
                        df_sorted = df_sorted.head(15)
                        ax.set_title(f"Top 15 Performances by {rating_col}")
                    else:
                        ax.set_title(f"Performances by {rating_col}")
                    
                    # Create bar chart
                    df_sorted.plot(kind='bar', x=name_col, y=rating_col, ax=ax, color=PRIMARY_COLOR)
                    
                    ax.set_xlabel("Performance")
                    ax.set_ylabel("Rating")
                    
                    # Rotate x labels for better readability
                    plt.xticks(rotation=45, ha='right')
                    
                    # Add data labels
                    for p in ax.patches:
                        ax.annotate(f"{p.get_height():.2f}",
                                (p.get_x() + p.get_width() / 2., p.get_height()),
                                ha='center', va='center',
                                xytext=(0, 10),
                                textcoords='offset points')
                else:
                    ax.text(0.5, 0.5, "No numeric rating data available",
                        ha='center', va='center', transform=ax.transAxes)
                    print("Query 6 Bar Chart - No valid data after numeric conversion")
            else:
                ax.text(0.5, 0.5, "Could not identify performance name or rating columns",
                    ha='center', va='center', transform=ax.transAxes)
                print("Query 6 Bar Chart - Could not identify appropriate columns")
        
        except Exception as e:
            print(f"Error in Query 6 bar chart: {str(e)}")
            ax.text(0.5, 0.5, f"Error creating chart: {str(e)}",
                ha='center', va='center', transform=ax.transAxes)
        
        plt.tight_layout()
        
        # Embed plot in tkinter
        canvas = FigureCanvasTkAgg(fig, master=parent)
        canvas.draw()
        canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)

    def _create_rating_per_performance_pie(self, parent):
        """Create a pie chart for performance ratings (Query 6)."""
        fig, ax = plt.subplots(figsize=(10, 6))
        
        try:
            # Debug output
            print("Query 6 Pie Chart - Columns in DataFrame:", self.results_df.columns.tolist())
            
            # Find appropriate columns for names and ratings
            name_col = None
            rating_col = None
            
            # Look for column names
            for col in self.results_df.columns:
                col_lower = col.lower()
                if ('event' in col_lower or 'performance' in col_lower or 'name' in col_lower or 
                    'performer' in col_lower):
                    name_col = col
                elif 'rating' in col_lower or 'avg' in col_lower or 'average' in col_lower:
                    rating_col = col
            
            # Fallback to position
            if not name_col or not rating_col:
                cols = self.results_df.columns.tolist()
                if len(cols) >= 2:
                    name_col = cols[0]  # Usually first column is name/event
                    # Find numeric column for rating
                    for col in cols:
                        if pd.api.types.is_numeric_dtype(self.results_df[col]):
                            rating_col = col
                            break
                    if not rating_col and len(cols) > 1:
                        rating_col = cols[-1]  # Last column
            
            print(f"Query 6 Pie Chart - Using columns: name_col={name_col}, rating_col={rating_col}")
            
            if name_col and rating_col:
                # Make a copy to avoid modifying original data
                df_copy = self.results_df.copy()
                
                # Ensure rating column is numeric
                df_copy[rating_col] = pd.to_numeric(df_copy[rating_col], errors='coerce')
                df_copy = df_copy.dropna(subset=[rating_col])
                
                if not df_copy.empty:
                    # For pie chart, limit to top performances if there are many
                    if len(df_copy) > 10:
                        df_sorted = df_copy.sort_values(by=rating_col, ascending=False).head(10)
                        title = "Top 10 Performances by Rating"
                    else:
                        df_sorted = df_copy
                        title = "Performances by Rating"
                    
                    # Calculate percentage of total ratings
                    total_rating = df_sorted[rating_col].sum()
                    if total_rating > 0:
                        # Create the pie chart using the name and rating
                        rating_data = df_sorted.set_index(name_col)[rating_col]
                        rating_data = rating_data / total_rating * 100  # Convert to percentages
                        
                        # Plot pie chart
                        rating_data.plot(kind='pie', ax=ax, autopct='%1.1f%%', 
                                    startangle=90, shadow=False)
                        
                        ax.set_title(title)
                        ax.set_ylabel('')  # Hide ylabel
                    else:
                        ax.text(0.5, 0.5, "Cannot create pie chart: Total rating is zero",
                            ha='center', va='center', transform=ax.transAxes)
                else:
                    ax.text(0.5, 0.5, "No numeric rating data available",
                        ha='center', va='center', transform=ax.transAxes)
                    print("Query 6 Pie Chart - No valid data after numeric conversion")
            else:
                ax.text(0.5, 0.5, "Could not identify appropriate columns for visualization",
                    ha='center', va='center', transform=ax.transAxes)
                print("Query 6 Pie Chart - Could not identify appropriate columns")
        
        except Exception as e:
            print(f"Error in Query 6 pie chart: {str(e)}")
            ax.text(0.5, 0.5, f"Error creating chart: {str(e)}",
                ha='center', va='center', transform=ax.transAxes)
        
        plt.tight_layout()
        
        # Embed plot in tkinter
        canvas = FigureCanvasTkAgg(fig, master=parent)
        canvas.draw()
        canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)

    def _create_artist_festival_count_bar(self, parent):
        """Create a bar chart for artists by festival count (Query 11)."""
        fig, ax = plt.subplots(figsize=(10, 6))
        
        # Sort by festival_count for better visualization
        df_sorted = self.results_df.sort_values(by='festival_count', ascending=False)
        
        # Limit to top 15 for readability if needed
        if len(df_sorted) > 15:
            df_sorted = df_sorted.head(15)
        
        # Create bar chart
        df_sorted.plot(kind='bar', x='name', y='festival_count', ax=ax, color=PRIMARY_COLOR)
        
        ax.set_title("Artists by Festival Count")
        ax.set_xlabel("Artist")
        ax.set_ylabel("Festival Count")
        
        # Rotate x labels for better readability
        plt.xticks(rotation=45, ha='right')
        
        # Add data labels
        for p in ax.patches:
            ax.annotate(str(int(p.get_height())),
                    (p.get_x() + p.get_width() / 2., p.get_height()),
                    ha='center', va='center',
                    xytext=(0, 10),
                    textcoords='offset points')
        
        plt.tight_layout()
        
        # Embed plot in tkinter
        canvas = FigureCanvasTkAgg(fig, master=parent)
        canvas.draw()
        canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)

    def _create_artist_festival_count_pie(self, parent):
        """Create a pie chart for artists by festival count (Query 11)."""
        fig, ax = plt.subplots(figsize=(10, 6))
        
        # Get the counts for pie chart
        artist_festivals = self.results_df.set_index('name')['festival_count']
        
        # Limit to top 10 for readability in pie chart
        if len(artist_festivals) > 10:
            others = artist_festivals.iloc[10:].sum()
            artist_festivals = artist_festivals.iloc[:10]
            artist_festivals['Others'] = others
        
        # Create pie chart
        artist_festivals.plot(kind='pie', ax=ax, autopct='%1.1f%%', startangle=90, shadow=False)
        
        ax.set_title("Festival Count Distribution by Artist")
        ax.set_ylabel('')  # Hide y label
        
        plt.tight_layout()
        
        # Embed plot in tkinter
        canvas = FigureCanvasTkAgg(fig, master=parent)
        canvas.draw()
        canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)


    def _create_artist_continent_bar(self, parent):
        """Create a bar chart for artists by continent count (Query 13)."""
        fig, ax = plt.subplots(figsize=(10, 6))
        
        # Sort by continent_count
        df_sorted = self.results_df.sort_values(by='continent_count', ascending=False)
        
        # Create bar chart
        df_sorted.plot(kind='bar', x='name', y='continent_count', ax=ax, color=PRIMARY_COLOR)
        
        ax.set_title("Artists by Number of Continents Performed")
        ax.set_xlabel("Artist")
        ax.set_ylabel("Number of Continents")
        
        # Rotate x labels for better readability
        plt.xticks(rotation=45, ha='right')
        
        # Add data labels
        for p in ax.patches:
            ax.annotate(str(int(p.get_height())),
                    (p.get_x() + p.get_width() / 2., p.get_height()),
                    ha='center', va='center',
                    xytext=(0, 10),
                    textcoords='offset points')
        
        plt.tight_layout()
        
        # Embed plot in tkinter
        canvas = FigureCanvasTkAgg(fig, master=parent)
        canvas.draw()
        canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)

    def _create_artist_continent_pie(self, parent):
        """Create a pie chart for artists by continent count (Query 13)."""
        fig, ax = plt.subplots(figsize=(10, 6))
        
        # Get the counts for pie chart
        artist_continents = self.results_df.set_index('name')['continent_count']
        
        # Create pie chart
        artist_continents.plot(kind='pie', ax=ax, autopct='%1.1f%%', startangle=90, shadow=False)
        
        ax.set_title("Distribution of Continents Performed by Artist")
        ax.set_ylabel('')  # Hide y label
        
        plt.tight_layout()
        
        # Embed plot in tkinter
        canvas = FigureCanvasTkAgg(fig, master=parent)
        canvas.draw()
        canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)