#!/usr/bin/env python3
"""
Golden Oaks Database Analysis Tool
=================================

This script analyzes the existing GoldenOaks.db database to understand
its structure and export data for migration to the Flutter app.
"""

import sqlite3
import json
import os
from datetime import datetime

def analyze_database(db_path):
    """Analyze the existing database structure and data."""
    print(f"Analyzing database: {db_path}")
    
    if not os.path.exists(db_path):
        print(f"Error: Database file not found at {db_path}")
        return None
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Get all table names
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = cursor.fetchall()
        
        print(f"\nFound {len(tables)} tables:")
        for table in tables:
            print(f"  - {table[0]}")
        
        analysis = {
            'database_path': db_path,
            'analyzed_at': datetime.now().isoformat(),
            'tables': {},
            'data_export': {}
        }
        
        # Analyze each table
        for table_name in [t[0] for t in tables]:
            print(f"\n--- Analyzing table: {table_name} ---")
            
            # Get table schema
            cursor.execute(f"PRAGMA table_info({table_name});")
            columns = cursor.fetchall()
            
            print(f"Columns ({len(columns)}):")
            table_info = {
                'columns': [],
                'row_count': 0,
                'sample_data': []
            }
            
            for col in columns:
                col_info = {
                    'name': col[1],
                    'type': col[2],
                    'not_null': bool(col[3]),
                    'default': col[4],
                    'primary_key': bool(col[5])
                }
                table_info['columns'].append(col_info)
                print(f"  {col[1]} ({col[2]}) {'PK' if col[5] else ''} {'NOT NULL' if col[3] else ''}")
            
            # Get row count
            cursor.execute(f"SELECT COUNT(*) FROM {table_name};")
            row_count = cursor.fetchone()[0]
            table_info['row_count'] = row_count
            print(f"Row count: {row_count}")
            
            # Get sample data (first 5 rows)
            if row_count > 0:
                cursor.execute(f"SELECT * FROM {table_name} LIMIT 5;")
                sample_rows = cursor.fetchall()
                
                # Convert to list of dictionaries
                column_names = [col['name'] for col in table_info['columns']]
                for row in sample_rows:
                    row_dict = dict(zip(column_names, row))
                    table_info['sample_data'].append(row_dict)
                
                print("Sample data:")
                for i, row in enumerate(sample_rows):
                    print(f"  Row {i+1}: {row}")
            
            analysis['tables'][table_name] = table_info
        
        conn.close()
        return analysis
        
    except Exception as e:
        print(f"Error analyzing database: {e}")
        return None

def export_all_data(db_path):
    """Export all data from the database for migration."""
    print(f"\nExporting all data from: {db_path}")
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Get all table names
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = [t[0] for t in cursor.fetchall()]
        
        export_data = {
            'exported_at': datetime.now().isoformat(),
            'source_db': db_path,
            'tables': {}
        }
        
        for table_name in tables:
            print(f"Exporting table: {table_name}")
            
            # Get all data from table
            cursor.execute(f"SELECT * FROM {table_name};")
            rows = cursor.fetchall()
            
            # Get column names
            cursor.execute(f"PRAGMA table_info({table_name});")
            columns = [col[1] for col in cursor.fetchall()]
            
            # Convert to list of dictionaries
            table_data = []
            for row in rows:
                row_dict = dict(zip(columns, row))
                table_data.append(row_dict)
            
            export_data['tables'][table_name] = {
                'columns': columns,
                'data': table_data,
                'row_count': len(table_data)
            }
            
            print(f"  Exported {len(table_data)} rows")
        
        conn.close()
        return export_data
        
    except Exception as e:
        print(f"Error exporting data: {e}")
        return None

def save_analysis_report(analysis, output_path):
    """Save analysis report to JSON file."""
    try:
        with open(output_path, 'w') as f:
            json.dump(analysis, f, indent=2, default=str)
        print(f"\nAnalysis report saved to: {output_path}")
        return True
    except Exception as e:
        print(f"Error saving analysis report: {e}")
        return False

def main():
    """Main function to analyze and export database."""
    # Path to your existing database
    python_db_path = os.path.join(os.path.dirname(__file__), '..', '..', '..', 'python', 'GoldenOaks.db')
    python_db_path = os.path.abspath(python_db_path)
    
    print("Golden Oaks Database Migration Tool")
    print("=" * 40)
    
    # Analyze database structure
    analysis = analyze_database(python_db_path)
    if not analysis:
        return
    
    # Export all data
    export_data = export_all_data(python_db_path)
    if not export_data:
        return
    
    # Save reports
    output_dir = os.path.dirname(__file__)
    
    # Save analysis report
    analysis_file = os.path.join(output_dir, 'database_analysis.json')
    save_analysis_report(analysis, analysis_file)
    
    # Save exported data
    export_file = os.path.join(output_dir, 'exported_data.json')
    save_analysis_report(export_data, export_file)
    
    print(f"\nMigration files created:")
    print(f"  - Analysis: {analysis_file}")
    print(f"  - Data Export: {export_file}")
    print(f"\nNext steps:")
    print(f"  1. Review the analysis to understand your data structure")
    print(f"  2. Run the Flutter migration script to import this data")

if __name__ == "__main__":
    main()