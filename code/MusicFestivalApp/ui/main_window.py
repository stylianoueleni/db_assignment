"""
Main window module for the Music Festival Database App.

This module defines the MainWindow class that serves as the primary UI container.
It creates the application layout, handles query selection and execution,
and manages the display of query results, including performance analysis features.
"""
import json
import tkinter as tk
from tkinter import ttk, messagebox
import pandas as pd
from datetime import datetime
import matplotlib.pyplot as plt
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg

from ui.styles import *
from ui.query_frame import QueryFrame
from queries import QUERIES, SPECIAL_QUERIES, QUERY_LIST


class MainWindow(tk.Tk):
    """
    Main application window class that contains all UI components and handles user interactions.
    Creates a two-panel layout with query selection on the left and results on the right.
    """
    
    def __init__(self, database):
        """Initialize the main window."""
        super().__init__()
        
        self.database = database
        
        self._configure_window()
        self._init_ui()
        self._populate_query_list()
    
    def _configure_window(self):
        """
        Configure the main window properties including size, theme, and grid layout.
        Sets up the visual appearance of the application window.
        """
        self.title("Music Festival Database App")
        self.geometry("1200x800")
        self.minsize(800, 600)
        
        # Configure the theme
        self.style = ttk.Style()
        self.style.theme_use("clam")  # Use clam theme as base
        configure_ttk_styles(self.style)
        
        # Configure grid layout
        self.columnconfigure(0, weight=1)  # Left panel (queries)
        self.columnconfigure(1, weight=3)  # Right panel (results)
        self.rowconfigure(0, weight=1)     # Main content area
    
    def _init_ui(self):
        """
        Initialize all UI components and create the application layout.
        Sets up panels, frames, and controls for query selection and result display.
        """
        # Create main panels
        self.left_panel = ttk.Frame(self, style="TFrame")
        self.left_panel.grid(row=0, column=0, sticky="nsew", padx=5, pady=5)
        
        self.right_panel = ttk.Frame(self, style="TFrame")
        self.right_panel.grid(row=0, column=1, sticky="nsew", padx=5, pady=5)
        
        # Configure grid for panels
        self.left_panel.columnconfigure(0, weight=1)
        self.left_panel.rowconfigure(0, weight=0)  # Query selector area (fixed height)
        self.left_panel.rowconfigure(1, weight=0)  # Parameters area (fixed height)
        self.left_panel.rowconfigure(2, weight=1)  # Query details area (flexible)
        
        self.right_panel.columnconfigure(0, weight=1)
        self.right_panel.rowconfigure(0, weight=1)  # Results area (flexible)
        
        # Create query selector area
        self.selector_frame = ttk.LabelFrame(self.left_panel, text="Select Query", style="TFrame")
        self.selector_frame.grid(row=0, column=0, sticky="nsew", padx=5, pady=5)
        
        # Create parameters area
        self.params_frame = ttk.LabelFrame(self.left_panel, text="Query Parameters", style="TFrame")
        self.params_frame.grid(row=1, column=0, sticky="nsew", padx=5, pady=5)
        
        # Create query details area
        self.details_frame = ttk.LabelFrame(self.left_panel, text="Query Details", style="TFrame")
        self.details_frame.grid(row=2, column=0, sticky="nsew", padx=5, pady=5)
        
        # Create results area
        self.results_frame = ttk.LabelFrame(self.right_panel, text="Query Results", style="TFrame")
        self.results_frame.grid(row=0, column=0, sticky="nsew", padx=5, pady=5)
        
        # Setup query selector
        self.query_listbox = tk.Listbox(self.selector_frame, exportselection=0, **LISTBOX_STYLE)
        self.query_listbox.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        self.query_listbox.bind("<<ListboxSelect>>", self.on_query_selected)
        
        # Setup parameters frame (will be populated dynamically)
        self.param_entries = {}
        self.param_labels = {}
        
        # Setup query details - without duplicate wrap parameter
        self.query_description = tk.Text(self.details_frame, height=5, **TEXT_STYLE)
        self.query_description.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        self.query_description.config(state=tk.DISABLED)
        
        self.sql_text = tk.Text(self.details_frame, height=10, **TEXT_STYLE)
        self.sql_text.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        self.sql_text.config(state=tk.DISABLED)
        
        # Add execution buttons
        # Create a frame for the button area with a fixed height - place this at the bottom of your window
        self.button_area = ttk.Frame(self)
        self.button_area.grid(row=2, column=0, columnspan=2, sticky="ew", padx=5, pady=5)
        
        # Create an inner frame to hold the buttons
        self.button_inner_frame = ttk.Frame(self.button_area)
        self.button_inner_frame.pack(fill=tk.X)
        
        # Create a scrollable frame - this is a simpler approach that works well for horizontal button lists
        self.button_canvas = tk.Canvas(self.button_inner_frame, height=40)
        self.button_canvas.pack(side=tk.TOP, fill=tk.X, expand=True)
        
        # Add horizontal scrollbar
        self.button_scrollbar = ttk.Scrollbar(self.button_inner_frame, orient="horizontal", command=self.button_canvas.xview)
        self.button_scrollbar.pack(side=tk.BOTTOM, fill=tk.X)
        self.button_canvas.configure(xscrollcommand=self.button_scrollbar.set)
        
        # Create frame for buttons
        self.button_frame = ttk.Frame(self.button_canvas)
        self.button_window = self.button_canvas.create_window((0, 0), window=self.button_frame, anchor="nw")
        
        # Add buttons to the button_frame
        buttons = [
            ("Execute Query", self.execute_query),
            ("Execute With Trace", self.execute_query_with_trace),
            ("Compare Query Plans", self.compare_query_plans),
            ("Export Current Query", self.export_current_sql),
            ("Compare Join Strategies", self.compare_join_strategies)
        ]
        
        for text, command in buttons:
            btn = ttk.Button(self.button_frame, text=text, command=command)
            btn.pack(side=tk.LEFT, padx=5, pady=5)
        
        # Function to update the scrollable area
        def update_scroll_region(event):
            self.button_canvas.configure(scrollregion=self.button_canvas.bbox("all"))
            # Ensure the window is wide enough
            width = self.button_frame.winfo_reqwidth()
            self.button_canvas.itemconfig(self.button_window, width=width)
            
        # Update scroll region when button frame changes
        self.button_frame.bind("<Configure>", update_scroll_region)
        
        # Make sure canvas adapts to window width
        def on_canvas_resize(event):
            # Make sure buttons stay at top of canvas
            self.button_canvas.itemconfig(self.button_window, height=self.button_frame.winfo_reqheight())
            
        self.button_canvas.bind("<Configure>", on_canvas_resize)
    
        # Add a status bar at the bottom
        self.status_bar = ttk.Label(self, text="Ready", style="Status.TLabel")
        self.status_bar.grid(row=1, column=0, columnspan=2, sticky="ew")
        
        # Create query frame for results
        self.query_frame = QueryFrame(self.results_frame)
        self.query_frame.pack(fill=tk.BOTH, expand=True)
        
        # Initialize variables
        self.selected_query = None
    
    def _populate_query_list(self):
        """Populate the query listbox with available queries."""
        for query in QUERY_LIST:
            self.query_listbox.insert(tk.END, query["name"])
    
    def on_query_selected(self, event):
        """Handle query selection from the listbox."""
        selection = self.query_listbox.curselection()
        if not selection:
            return
        
        index = selection[0]
        self.selected_query = QUERY_LIST[index]
        
        # Update query description
        self.query_description.config(state=tk.NORMAL)
        self.query_description.delete(1.0, tk.END)
        self.query_description.insert(tk.END, self.selected_query["description"])
        self.query_description.config(state=tk.DISABLED)
        
        # Update SQL display
        self.sql_text.config(state=tk.NORMAL)
        self.sql_text.delete(1.0, tk.END)
        
        query_text = QUERIES.get(self.selected_query["id"], "Query not found")
        self.sql_text.insert(tk.END, query_text)
        self.sql_text.config(state=tk.DISABLED)
        
        # Update parameters
        self._update_parameter_frame()
    
    def _update_parameter_frame(self):
        """Update the parameter frame based on the selected query."""
        # Clear existing parameters
        for widget in self.params_frame.winfo_children():
            widget.destroy()
        
        self.param_entries = {}
        self.param_labels = {}
        
        # Add parameters for the selected query
        if not self.selected_query or not self.selected_query.get("params"):
            no_params_label = ttk.Label(self.params_frame, text="No parameters required for this query.")
            no_params_label.pack(padx=10, pady=10)
            return
        
        # Create a frame for each parameter
        for i, param in enumerate(self.selected_query["params"]):
            param_frame = ttk.Frame(self.params_frame)
            param_frame.pack(fill=tk.X, padx=5, pady=5)
            
            # Parameter label
            label = ttk.Label(param_frame, text=f"{param['name']}:")
            label.pack(side=tk.LEFT, padx=5)
            
            # Parameter entry
            entry = ttk.Entry(param_frame)
            entry.pack(side=tk.LEFT, fill=tk.X, expand=True, padx=5)
            
            # If there's a description, add a tooltip
            if param.get("description"):
                tip_label = ttk.Label(param_frame, text="?", width=2)
                tip_label.pack(side=tk.LEFT, padx=5)
                self._create_tooltip(tip_label, param["description"])
            
            # Store references
            self.param_entries[param["name"]] = entry
            self.param_labels[param["name"]] = label
    
    def _create_tooltip(self, widget, text):
        """Create a tooltip for a widget."""
        def enter(event):
            x, y, _, _ = widget.bbox("insert")
            x += widget.winfo_rootx() + 25
            y += widget.winfo_rooty() + 25
            
            # Create a toplevel window
            self.tooltip = tk.Toplevel(widget)
            self.tooltip.wm_overrideredirect(True)
            self.tooltip.wm_geometry(f"+{x}+{y}")
            
            label = ttk.Label(self.tooltip, text=text, background="#ffffe0", relief="solid", borderwidth=1)
            label.pack()
        
        def leave(event):
            if hasattr(self, "tooltip"):
                self.tooltip.destroy()
        
        widget.bind("<Enter>", enter)
        widget.bind("<Leave>", leave)
    
    def _get_query_parameters(self):
        """Get parameter values from the UI."""
        if not self.selected_query or not self.selected_query.get("params"):
            return []
        
        parameters = []
        
        for param in self.selected_query["params"]:
            param_name = param["name"]
            param_type = param.get("type", "str")
            
            if param_name not in self.param_entries:
                messagebox.showerror("Parameter Error", f"Parameter {param_name} is missing.")
                return None
            
            entry = self.param_entries[param_name]
            value = entry.get().strip()
            
            # Validate required parameters
            if not value:
                messagebox.showerror("Parameter Error", f"Parameter {param_name} is required.")
                return None
            
            # Convert to appropriate type
            try:
                if param_type == "int":
                    value = int(value)
                elif param_type == "float":
                    value = float(value)
                elif param_type == "date":
                    # Validate date format
                    try:
                        value = datetime.strptime(value, "%Y-%m-%d").date()
                    except ValueError:
                        messagebox.showerror(
                            "Parameter Error", 
                            f"Parameter {param_name} must be a valid date in format YYYY-MM-DD."
                        )
                        return None
                # Add more type conversions as needed
            except ValueError:
                messagebox.showerror(
                    "Parameter Error", 
                    f"Parameter {param_name} must be a valid {param_type}."
                )
                return None
            
            parameters.append(value)
        
        return parameters
    
    def execute_query(self):
        """
        Execute the selected query and display results.
        Retrieves query parameters from UI components, executes the query,
        and updates the result display with the returned data.
        """

        if not self.selected_query:
            messagebox.showinfo("Execute Query", "Please select a query first.")
            return
    
        # Get parameters
        parameters = self._get_query_parameters()
        if parameters is None:  # Error occurred
           return
    
        # Update status
        self.status_bar.config(text=f"Executing query: {self.selected_query['name']}...")
        self.update_idletasks()
    
        try:
            # Get the query text
            query_id = self.selected_query["id"]
            query_text = QUERIES[query_id]
        
            # Add time measurement
            import time
            start_time = time.time()
        
            # Execute the query
            result_df = self.database.execute_query(query_text, parameters if parameters else None)
        
            # Calculate execution time
            execution_time = time.time() - start_time
        
            if result_df is None:
                messagebox.showerror("Query Error", "An error occurred while executing the query.")
                self.status_bar.config(text="Query execution failed.")
                return
        
            # Display results
            self.query_frame.display_results(result_df, self.selected_query["name"], execution_time=execution_time)
        
            # Update status
            self.status_bar.config(text=f"Query executed successfully. {len(result_df)} rows returned. Execution time: {execution_time:.4f} seconds")
        
        except Exception as e:
            messagebox.showerror("Query Error", f"An error occurred: {str(e)}")
            self.status_bar.config(text="Query execution failed.")
    

    def execute_query_with_trace(self):
        """Execute the selected query with performance trace."""
        if not self.selected_query:
            messagebox.showinfo("Execute Query", "Please select a query first.")
            return
    
        # Get parameters
        parameters = self._get_query_parameters()
        if parameters is None:  # Error occurred
            return
    
        # Update status
        self.status_bar.config(text=f"Executing query with trace: {self.selected_query['name']}...")
        self.update_idletasks()
    
        try:
            # Get the query text
            query_id = self.selected_query["id"]
        
            # Check if there's a special query for tracing
            if self.selected_query.get("special") and query_id in SPECIAL_QUERIES:
                query_text = SPECIAL_QUERIES[query_id]
            else:
                query_text = QUERIES[query_id]
        
            # Add time measurement
            import time
            start_time = time.time()
        
            # Execute the query with trace
            result_df, trace_data = self.database.execute_query_with_trace(
                query_text, 
                parameters if parameters else None
            )
        
            # Calculate execution time
            execution_time = time.time() - start_time
        
            if result_df is None:
                messagebox.showerror("Query Error", "An error occurred while executing the query.")
                self.status_bar.config(text="Query execution failed.")
                return
        
            # Display results with trace data and execution time
            self.query_frame.display_results(result_df, self.selected_query["name"], trace_data, execution_time=execution_time)
        
            # Update status
            self.status_bar.config(text=f"Query executed with trace. {len(result_df)} rows returned. Execution time: {execution_time:.4f} seconds")
        
        except Exception as e:
            messagebox.showerror("Query Error", f"An error occurred: {str(e)}")
            self.status_bar.config(text="Query execution failed.")

    def compare_query_plans(self):
        """Compare regular and optimized query plans for special queries."""
        iterations = 1 
        if not self.selected_query or not self.selected_query.get("special"):
            messagebox.showinfo("Compare Query Plans", "This feature is only available for queries with optimized versions.")
            return
        
        # Get parameters
        parameters = self._get_query_parameters()
        if parameters is None:  # Error occurred
            return
        
        # Get query IDs
        query_id = self.selected_query["id"]
        
        # Ensure we have the regular version
        if query_id not in QUERIES:
            messagebox.showinfo("Compare Query Plans", "Query not found.")
            return

        # Check for optimized version with "_with_index" suffix
        optimized_id = f"{query_id}_with_index"
        if optimized_id not in SPECIAL_QUERIES:
            messagebox.showinfo("Compare Query Plans", "Optimized version not available for this query.")
            return
        
        # Get query texts
        regular_query = QUERIES[query_id]
        optimized_query = SPECIAL_QUERIES[optimized_id]
        
        # Update status
        self.status_bar.config(text=f"Comparing query plans for: {self.selected_query['name']}...")
        self.update_idletasks()
        
        try:
            import time
            import statistics
            
            # Arrays to store execution times
            regular_times = []
            optimized_times = []
            
            # Run multiple iterations
            for i in range(iterations):
                # Execute regular query
                start_time = time.time()
                regular_df, regular_trace = self.database.execute_query_with_trace(
                    regular_query, 
                    parameters if parameters else None
                )
                end_time = time.time()
                regular_times.append(end_time - start_time)
                
                # Keep the last trace and result
                if i == iterations - 1:
                    last_regular_df = regular_df
                    last_regular_trace = regular_trace
                
                # Execute optimized query
                start_time = time.time()
                optimized_df, optimized_trace = self.database.execute_query_with_trace(
                    optimized_query, 
                    parameters if parameters else None
                )
                end_time = time.time()
                optimized_times.append(end_time - start_time)
                
                # Keep the last trace and result
                if i == iterations - 1:
                    last_optimized_df = optimized_df
                    last_optimized_trace = optimized_trace
            
            # Calculate statistics
            avg_regular_time = statistics.mean(regular_times)
            avg_optimized_time = statistics.mean(optimized_times)
            
            # Display comparison results
            self._show_comparison_results(
                last_regular_df, last_regular_trace, avg_regular_time,
                last_optimized_df, last_optimized_trace, avg_optimized_time,
                regular_times, optimized_times
            )
            
            # Update status
            self.status_bar.config(text=f"Query plan comparison completed. Regular: {avg_regular_time:.4f}s, Optimized: {avg_optimized_time:.4f}s")
            
        except Exception as e:
            self.status_bar.config(text=f"Error while comparing query plans: {str(e)}")
            self.update_idletasks()

    def export_current_sql(self):
        """Export only the currently selected query to SQL file using user-entered parameters."""
        import os
        
        if not self.selected_query:
            messagebox.showinfo("Export Error", "Please select a query first.")
            return
        
        # Get query details
        query_id = self.selected_query["id"]
        query_text = QUERIES.get(query_id)
        
        if not query_text:
            messagebox.showerror("Export Error", f"Query {query_id} not found.")
            return
        
        # Determine the query index
        query_idx = list(QUERIES.keys()).index(query_id) + 1
        
        # Format the filenames
        sql_filename = f"sql/Q{query_idx:02d}.sql"
        out_filename = f"sql/Q{query_idx:02d}_out.txt"
        
        # Create sql directory if it doesn't exist
        os.makedirs("sql", exist_ok=True)
        
        # Get parameter values from UI
        parameters = None
        if self.selected_query.get("params"):
            parameters = self._get_query_parameters()
            if parameters is None:  # Error occurred
                messagebox.showerror("Parameter Error", 
                                    "Please enter valid parameter values first.")
                return
        
        # Save query to file
        with open(sql_filename, "w") as f:
            # Add a comment showing which query this is
            f.write(f"-- Query {query_idx}: {query_id}\n\n")
            
            # If it's a parameterized query, include the user's parameter values as comments
            if parameters:
                param_descriptions = [p["name"] for p in self.selected_query["params"]]
                param_values = []
                for i, param in enumerate(parameters):
                    param_values.append(f"{param_descriptions[i]}={param}")
                
                f.write(f"-- Parameters: {', '.join(param_values)}\n\n")
            
            f.write(query_text)
        
        # Run the query and save output
        try:
            # Update status
            self.status_bar.config(text=f"Running query for export...")
            self.update_idletasks()
            
            # Execute query with or without parameters
            result_df = self.database.execute_query(query_text, parameters)
            
            # Save result to output file
            if result_df is not None and not result_df.empty:
                with open(out_filename, "w") as f:
                    f.write(f"-- Results for Query {query_idx}: {query_id}\n\n")
                    if parameters:
                        f.write(f"-- Parameters: {', '.join(param_values)}\n\n")
                    f.write(result_df.to_string())
                
                # Also check if there's an optimized version
                optimized_id = f"{query_id}_with_index"
                if optimized_id in SPECIAL_QUERIES and hasattr(self.selected_query, "special") and self.selected_query.get("special"):
                    optimized_text = SPECIAL_QUERIES[optimized_id]
                    
                    opt_sql_filename = f"sql/Q{query_idx:02d}_optimized.sql"
                    opt_out_filename = f"sql/Q{query_idx:02d}_optimized_out.txt"
                    
                    # Save optimized query
                    with open(opt_sql_filename, "w") as f:
                        f.write(f"-- Optimized version of Query {query_idx}: {query_id}\n\n")
                        
                        if parameters:
                            f.write(f"-- Parameters: {', '.join(param_values)}\n\n")
                        
                        f.write(optimized_text)
                    
                    # Run optimized query
                    try:
                        opt_result_df = self.database.execute_query(optimized_text, parameters)
                        
                        if opt_result_df is not None and not opt_result_df.empty:
                            with open(opt_out_filename, "w") as f:
                                f.write(f"-- Results for Optimized Query {query_idx}: {query_id}\n\n")
                                if parameters:
                                    f.write(f"-- Parameters: {', '.join(param_values)}\n\n")
                                f.write(opt_result_df.to_string())
                    except Exception as e:
                        self.status_bar.config(text=f"Error running optimized query: {str(e)}")
                
                messagebox.showinfo("Export Complete", f"Exported Query {query_idx} to:\n{sql_filename}\n{out_filename}")
            else:
                messagebox.showwarning("No Results", f"Query {query_idx} returned no results.")
                # Still save the empty result
                with open(out_filename, "w") as f:
                    f.write(f"-- Results for Query {query_idx}: {query_id}\n\n")
                    if parameters:
                        f.write(f"-- Parameters: {', '.join(param_values)}\n\n")
                    f.write("No results returned.")
        except Exception as e:
            messagebox.showerror("Export Error", f"Error executing query: {str(e)}")
            
        # Update status
        self.status_bar.config(text=f"Exported Query {query_idx} to SQL file.")

    def _show_comparison_results(self, regular_df, regular_trace, regular_time, 
                            optimized_df, optimized_trace, optimized_time,
                            regular_times, optimized_times):
        """Show a comparison of regular and optimized query plans."""
        # Create a new window
        comparison_window = tk.Toplevel(self)
        comparison_window.title("Query Plan Comparison")
        comparison_window.geometry("900x700")
        
        # Configure the window
        comparison_window.columnconfigure(0, weight=1)
        comparison_window.rowconfigure(0, weight=0)  # Summary area
        comparison_window.rowconfigure(1, weight=1)  # Details area
        
        # Create summary frame
        summary_frame = ttk.LabelFrame(comparison_window, text="Performance Comparison")
        summary_frame.grid(row=0, column=0, padx=10, pady=10, sticky="nsew")
        
        # Show performance metrics
        performance_text = f"""
    Regular Query: {regular_time:.4f} seconds
    Optimized Query: {optimized_time:.4f} seconds
    Difference: {abs(regular_time - optimized_time):.4f} seconds
    Improvement: {(1 - optimized_time/regular_time) * 100:.2f}%
        """
        
        summary_label = ttk.Label(summary_frame, text=performance_text, justify=tk.LEFT, font=("Helvetica", 12))
        summary_label.pack(padx=10, pady=10)
        
        # Create notebook for detailed comparisons
        notebook = ttk.Notebook(comparison_window)
        notebook.grid(row=1, column=0, padx=10, pady=10, sticky="nsew")
        
        # Add tabs
        trace_frame = ttk.Frame(notebook)
        stats_frame = ttk.Frame(notebook)
        notebook.add(trace_frame, text="Execution Traces")
        notebook.add(stats_frame, text="Performance Statistics")
        
        # Configure trace frame
        trace_frame.columnconfigure(0, weight=1)
        trace_frame.columnconfigure(1, weight=1)
        trace_frame.rowconfigure(0, weight=0)
        trace_frame.rowconfigure(1, weight=1)
        
        # Add labels
        ttk.Label(trace_frame, text="Regular Query Trace", font=("Helvetica", 10, "bold")).grid(row=0, column=0, padx=5, pady=5)
        ttk.Label(trace_frame, text="Optimized Query Trace", font=("Helvetica", 10, "bold")).grid(row=0, column=1, padx=5, pady=5)
        
        # Format trace data
        def format_trace(trace_data):
            if isinstance(trace_data, str):
                return trace_data
            
            try:
                if isinstance(trace_data, dict) and 'TRACE' in trace_data:
                    return json.dumps(json.loads(trace_data['TRACE']), indent=2)
                else:
                    return json.dumps(trace_data, indent=2)
            except Exception as e:
                return f"Error formatting trace: {str(e)}\n\nRaw data: {str(trace_data)}"
        
        # Create text widgets for traces
        regular_text = tk.Text(trace_frame, width=50, height=30, wrap=tk.WORD)
        regular_text.grid(row=1, column=0, padx=5, pady=5, sticky="nsew")
        regular_text.insert(tk.END, format_trace(regular_trace))
        regular_text.config(state=tk.DISABLED)
        
        # Add scrollbar for regular trace
        regular_vsb = ttk.Scrollbar(trace_frame, orient="vertical", command=regular_text.yview)
        regular_vsb.grid(row=1, column=0, sticky="nse", padx=(0, 5))
        regular_text.configure(yscrollcommand=regular_vsb.set)
        
        # Same for optimized trace
        optimized_text = tk.Text(trace_frame, width=50, height=30, wrap=tk.WORD)
        optimized_text.grid(row=1, column=1, padx=5, pady=5, sticky="nsew")
        optimized_text.insert(tk.END, format_trace(optimized_trace))
        optimized_text.config(state=tk.DISABLED)
        
        # Add scrollbar for optimized trace
        optimized_vsb = ttk.Scrollbar(trace_frame, orient="vertical", command=optimized_text.yview)
        optimized_vsb.grid(row=1, column=1, sticky="nse", padx=(0, 5))
        optimized_text.configure(yscrollcommand=optimized_vsb.set)
        
        # Configure statistics frame
        stats_frame.columnconfigure(0, weight=1)
        stats_frame.rowconfigure(0, weight=1)
        
        # Create matplotlib figure for statistics visualization
        fig = plt.Figure(figsize=(8, 6), dpi=100)
        ax = fig.add_subplot(111)
        
        # Create box plot
        box_data = [regular_times, optimized_times]
        ax.boxplot(box_data, labels=['Regular Query', 'Optimized Query'])
        ax.set_title('Query Execution Time Comparison')
        ax.set_ylabel('Execution Time (seconds)')
        
        # Add additional statistics as text
        import statistics
        textstr = '\n'.join((
            f'Regular Query Statistics:',
            f'  Min: {min(regular_times):.4f}s',
            f'  Max: {max(regular_times):.4f}s',
            f'  Mean: {statistics.mean(regular_times):.4f}s',
            f'  Median: {statistics.median(regular_times):.4f}s',
            f'  Std Dev: {statistics.stdev(regular_times) if len(regular_times) > 1 else 0:.4f}s',
            f'',
            f'Optimized Query Statistics:',
            f'  Min: {min(optimized_times):.4f}s',
            f'  Max: {max(optimized_times):.4f}s',
            f'  Mean: {statistics.mean(optimized_times):.4f}s',
            f'  Median: {statistics.median(optimized_times):.4f}s',
            f'  Std Dev: {statistics.stdev(optimized_times) if len(optimized_times) > 1 else 0:.4f}s',
        ))
        props = dict(boxstyle='round', facecolor='wheat', alpha=0.5)
        ax.text(0.05, 0.95, textstr, transform=ax.transAxes, fontsize=10,
                verticalalignment='top', bbox=props)
        
        # Embed the matplotlib figure in the tkinter window
        canvas = FigureCanvasTkAgg(fig, stats_frame)
        canvas.draw()
        canvas.get_tk_widget().grid(row=0, column=0, sticky="nsew", padx=10, pady=10)
        
        # Add toolbar for matplotlib
        from matplotlib.backends.backend_tkagg import NavigationToolbar2Tk
        toolbar = NavigationToolbar2Tk(canvas, stats_frame)
        toolbar.update()
        canvas.get_tk_widget().grid(row=0, column=0, sticky="nsew")

    def compare_join_strategies(self):
        """
        Compare different join strategies for the selected query.
        Tests various join optimization approaches (Nested Loop, Hash Join, Merge Join)
        and displays performance comparison results in a detailed visualization.
        This feature is only available for queries 4 and 6 as specified in the assignment.
        """
        if not self.selected_query or self.selected_query["id"] not in ["artist_average_ratings", "visitor_performances_ratings"]:
            messagebox.showinfo("Compare Join Strategies", 
                            "This feature is only available for queries 4 and 6.")
            return
        
        # Get parameters
        parameters = self._get_query_parameters()
        if parameters is None:  # Error occurred
            return
        
        # Get query ID
        query_id = self.selected_query["id"]
        
        # Update status
        self.status_bar.config(text=f"Comparing join strategies for: {self.selected_query['name']}...")
        self.update_idletasks()
        
        try:
            import time
            import statistics
            import json
            
            # Define join strategy queries
            if query_id == "artist_average_ratings":
                strategies = {
                    "Regular": QUERIES[query_id],
                    "Force Index": SPECIAL_QUERIES[f"{query_id}_with_index"],
                    "Nested Loop": SPECIAL_QUERIES[f"{query_id}_nested_loop"],
                    "Hash Join": SPECIAL_QUERIES[f"{query_id}_hash"],
                    "Merge Join": SPECIAL_QUERIES[f"{query_id}_merge"]
                }
                # Settings to influence join strategies
                optimizer_settings = {
                    "Regular": None,
                    "Force Index": None,
                    "Nested Loop": {"optimizer_switch": "'block_nested_loop=on,batched_key_access=off,mrr_cost_based=off'"},
                    "Hash Join": {"optimizer_switch": "'batched_key_access=on,block_nested_loop=off,mrr_cost_based=on'"},
                    "Merge Join": {"optimizer_switch": "'mrr=on,mrr_cost_based=on,batched_key_access=off'"}
                }
            elif query_id == "visitor_performances_ratings":
                strategies = {
                    "Regular": QUERIES[query_id],
                    "Force Index": SPECIAL_QUERIES[f"{query_id}_with_index"],
                    "Nested Loop": SPECIAL_QUERIES[f"{query_id}_nested_loop"],
                    "Hash Join": SPECIAL_QUERIES[f"{query_id}_hash"],
                    "Merge Join": SPECIAL_QUERIES[f"{query_id}_merge"]
                }
                # Settings to influence join strategies
                optimizer_settings = {
                    "Regular": None,
                    "Force Index": None,
                    "Nested Loop": {"optimizer_switch": "'block_nested_loop=on,batched_key_access=off,mrr_cost_based=off'"},
                    "Hash Join": {"optimizer_switch": "'batched_key_access=on,block_nested_loop=off,mrr_cost_based=on'"},
                    "Merge Join": {"optimizer_switch": "'mrr=on,mrr_cost_based=on,batched_key_access=off'"}
                }
            
            # Number of iterations
            iterations = 5
            
            # Store results
            results = {}
            
            # Run tests for each strategy
            for strategy_name, query in strategies.items():
                execution_times = []
                trace = None
                df = None
                settings = optimizer_settings[strategy_name]
                
                for i in range(iterations):
                    start_time = time.time()
                    if settings:
                        df, trace, _ = self.database.execute_query_with_optimizer_settings(
                            query, parameters, settings)
                    else:
                        df, trace = self.database.execute_query_with_trace(
                            query, parameters)
                    end_time = time.time()
                    execution_times.append(end_time - start_time)
                
                # Extract join strategy from the trace
                join_strategy_used = self._extract_join_strategy_from_trace(trace)
                
                results[strategy_name] = {
                    "times": execution_times,
                    "avg_time": statistics.mean(execution_times),
                    "min_time": min(execution_times),
                    "max_time": max(execution_times),
                    "std_dev": statistics.stdev(execution_times) if len(execution_times) > 1 else 0,
                    "trace": trace,
                    "join_strategy": join_strategy_used,
                    "df": df
                }
            
            # Display detailed comparison
            self._show_join_strategy_comparison(results)
            
        except Exception as e:
            messagebox.showerror("Error", f"An error occurred: {str(e)}")
            print(f"Error in compare_join_strategies: {str(e)}")
            self.status_bar.config(text=f"Error while comparing join strategies: {str(e)}")

    def _extract_join_strategy_from_trace(self, trace):
        """Extract join strategies used from the optimizer trace."""
        if not trace or 'TRACE' not in trace:
            return "Unknown"
        
        try:
            trace_json = json.loads(trace['TRACE'])
            join_info = []
            
            # Navigate through the trace to find join method information
            if 'steps' in trace_json:
                for step in trace_json['steps']:
                    if 'join_preparation' in step:
                        for table in step.get('join_preparation', {}).get('tables', []):
                            if 'access_type' in table:
                                join_info.append(f"{table.get('table', 'Unknown')}: {table.get('access_type', 'Unknown')}")
                    if 'join_optimization' in step:
                        for iteration in step.get('join_optimization', {}).get('considered_execution_plans', []):
                            if 'plan' in iteration and 'table' in iteration['plan']:
                                table_info = iteration['plan']['table']
                                if 'access_type' in table_info:
                                    join_info.append(f"{table_info.get('table_name', 'Unknown')}: {table_info.get('access_type', 'Unknown')}")
            
            return ", ".join(join_info) if join_info else "Information not found in trace"
        
        except Exception as e:
            print(f"Error extracting join strategy: {str(e)}")
            return f"Error extracting strategy: {str(e)}"

    def _show_join_strategy_comparison(self, results):
        """Show a comparison of different join strategies with scrollable content."""
        # Create a new window
        comparison_window = tk.Toplevel(self)
        comparison_window.title("Join Strategy Comparison")
        comparison_window.geometry("1000x800")
        
        # Create main canvas with scrollbar for the entire window
        main_canvas = tk.Canvas(comparison_window)
        main_scrollbar = ttk.Scrollbar(comparison_window, orient="vertical", command=main_canvas.yview)
        
        # Configure the canvas
        main_canvas.configure(yscrollcommand=main_scrollbar.set)
        main_canvas.bind('<Configure>', lambda e: main_canvas.configure(scrollregion=main_canvas.bbox("all")))
        
        # Pack canvas and scrollbar
        main_canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        main_scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        
        # Create a frame inside the canvas for all content
        main_frame = ttk.Frame(main_canvas)
        main_canvas.create_window((0, 0), window=main_frame, anchor="nw")
        
        # Configure the main frame
        main_frame.columnconfigure(0, weight=1)
        main_frame.rowconfigure(0, weight=0)  # Summary area
        main_frame.rowconfigure(1, weight=1)  # Details area
        
        # Create summary frame
        summary_frame = ttk.LabelFrame(main_frame, text="Performance Comparison")
        summary_frame.grid(row=0, column=0, padx=10, pady=10, sticky="nsew")
        
        # Create summary
        summary_text = "Join Strategy Performance Summary:\n\n"
        for strategy, data in results.items():
            summary_text += f"{strategy}:\n"
            summary_text += f"  Avg Time: {data['avg_time']:.4f}s\n"
            summary_text += f"  Min Time: {data['min_time']:.4f}s\n"
            summary_text += f"  Max Time: {data['max_time']:.4f}s\n"
            summary_text += f"  Std Dev: {data['std_dev']:.4f}s\n"
            summary_text += f"  Join Strategy: {data['join_strategy']}\n\n"
        
        summary_label = ttk.Label(summary_frame, text=summary_text, justify=tk.LEFT, font=("Helvetica", 11))
        summary_label.pack(padx=10, pady=10)
        
        # Create notebook for detailed comparisons
        notebook = ttk.Notebook(main_frame)
        notebook.grid(row=1, column=0, padx=10, pady=10, sticky="nsew")
        
        # Add tabs
        stats_frame = ttk.Frame(notebook)
        trace_frame = ttk.Frame(notebook)
        notebook.add(stats_frame, text="Performance Statistics")
        notebook.add(trace_frame, text="Execution Traces")
        
        # Configure fixed height for stats frame to ensure it's fully visible
        stats_frame.configure(height=500)
        
        # Create matplotlib figure for statistics visualization
        import matplotlib.pyplot as plt
        from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg, NavigationToolbar2Tk
        
        fig = plt.Figure(figsize=(9, 5), dpi=100)
        ax = fig.add_subplot(111)
        
        # Extract execution times for boxplot
        box_data = [data["times"] for data in results.values()]
        labels = list(results.keys())
        
        # Create box plot
        ax.boxplot(box_data, labels=labels)
        ax.set_title('Query Execution Time Comparison by Join Strategy')
        ax.set_ylabel('Execution Time (seconds)')
        ax.set_xlabel('Join Strategy')
        
        # Rotate x labels for better readability
        plt.setp(ax.get_xticklabels(), rotation=30, ha='right')
        
        # Ensure tight layout
        fig.tight_layout()
        
        # Embed the matplotlib figure
        canvas = FigureCanvasTkAgg(fig, stats_frame)
        canvas.draw()
        canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)
        
        # Add toolbar
        toolbar = NavigationToolbar2Tk(canvas, stats_frame)
        toolbar.update()
        
        # Configure trace frame with tabs for each strategy
        trace_notebook = ttk.Notebook(trace_frame)
        trace_notebook.pack(fill=tk.BOTH, expand=True)
        
        # Add a tab for each strategy's trace
        for strategy, data in results.items():
            strategy_frame = ttk.Frame(trace_notebook)
            trace_notebook.add(strategy_frame, text=strategy)
            
            # Format trace data
            def format_trace(trace_data):
                if isinstance(trace_data, str):
                    return trace_data
                
                try:
                    if isinstance(trace_data, dict) and 'TRACE' in trace_data:
                        return json.dumps(json.loads(trace_data['TRACE']), indent=2)
                    else:
                        return json.dumps(trace_data, indent=2)
                except Exception as e:
                    return f"Error formatting trace: {str(e)}\n\nRaw data: {str(trace_data)}"
            
            # Create a frame with scrollbar for the trace text
            trace_frame_with_scroll = ttk.Frame(strategy_frame)
            trace_frame_with_scroll.pack(fill=tk.BOTH, expand=True)
            
            # Create text widget for trace
            trace_text = tk.Text(trace_frame_with_scroll, wrap=tk.WORD)
            trace_scrollbar_y = ttk.Scrollbar(trace_frame_with_scroll, orient="vertical", command=trace_text.yview)
            trace_scrollbar_x = ttk.Scrollbar(trace_frame_with_scroll, orient="horizontal", command=trace_text.xview)
            
            # Configure text widget with scrollbars
            trace_text.configure(yscrollcommand=trace_scrollbar_y.set, xscrollcommand=trace_scrollbar_x.set)
            
            # Grid layout for text and scrollbars
            trace_text.grid(row=0, column=0, sticky="nsew")
            trace_scrollbar_y.grid(row=0, column=1, sticky="ns")
            trace_scrollbar_x.grid(row=1, column=0, sticky="ew")
            
            # Configure grid weights
            trace_frame_with_scroll.columnconfigure(0, weight=1)
            trace_frame_with_scroll.rowconfigure(0, weight=1)
            
            # Insert trace data
            trace_text.insert(tk.END, format_trace(data["trace"]))
            trace_text.configure(state="disabled")  # Make read-only
        
        # Configure the canvas to adjust to the content size
        main_frame.update_idletasks()
        main_canvas.config(scrollregion=main_canvas.bbox("all"))
        
        # Bind mousewheel to scroll
        def _on_mousewheel(event):
            main_canvas.yview_scroll(int(-1*(event.delta/120)), "units")
        
        main_canvas.bind_all("<MouseWheel>", _on_mousewheel)
        
        # Update status bar
        self.status_bar.config(text="Join strategy comparison completed.")