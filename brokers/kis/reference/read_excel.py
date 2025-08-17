import pandas as pd
import json

# Read Excel file
excel_file = 'brokers/kis/reference/KIS_API_20250817_030000.xlsx'

try:
    # Read all sheets
    xl_file = pd.ExcelFile(excel_file)
    
    print(f"Excel file contains {len(xl_file.sheet_names)} sheets:")
    for sheet_name in xl_file.sheet_names:
        print(f"- {sheet_name}")
    
    # Read first few sheets to understand structure
    for sheet_name in xl_file.sheet_names[:3]:  # First 3 sheets
        print(f"\n{'='*60}")
        print(f"Sheet: {sheet_name}")
        print('='*60)
        
        df = pd.read_excel(excel_file, sheet_name=sheet_name)
        print(f"Shape: {df.shape}")
        print(f"Columns: {list(df.columns)}")
        
        # Show first few rows
        print("\nFirst 5 rows:")
        print(df.head())
        
except Exception as e:
    print(f"Error reading Excel: {e}")
    print("Please install required packages: pip install pandas openpyxl")