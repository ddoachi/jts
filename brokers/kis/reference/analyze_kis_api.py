import pandas as pd
import json

# Read Excel file
excel_file = 'brokers/kis/reference/KIS_API_20250817_030000.xlsx'

try:
    # Read the API list sheet
    df_api = pd.read_excel(excel_file, sheet_name='API 목록')
    
    print("=== KIS API Summary ===")
    print(f"Total APIs: {len(df_api)}")
    print(f"\nColumns: {list(df_api.columns)}")
    print("\nFirst 10 rows:")
    print(df_api.head(10))
    
    # Read specific important sheets for trading
    important_sheets = [
        '주식주문(현금)',           # Stock order (cash)
        '주식주문(정정취소)',        # Stock order (modify/cancel)
        '주식잔고조회',             # Stock balance inquiry
        '주식현재가 시세',          # Stock current price
        '주식현재가 호가_예상체결',  # Stock orderbook/expected execution
        '매수가능조회',             # Buyable amount inquiry
        '주식일별주문체결조회'       # Daily order execution inquiry
    ]
    
    print("\n" + "="*60)
    print("=== Important Trading APIs ===")
    
    for sheet_name in important_sheets:
        try:
            df = pd.read_excel(excel_file, sheet_name=sheet_name)
            print(f"\n--- {sheet_name} ---")
            print(f"Shape: {df.shape}")
            
            # Try to find API endpoint info
            for col in df.columns:
                if 'URL' in str(col).upper() or 'PATH' in str(col).upper():
                    print(f"URL Column: {col}")
                    if not df[col].isna().all():
                        print(f"URL: {df[col].dropna().iloc[0] if len(df[col].dropna()) > 0 else 'N/A'}")
                
                if 'METHOD' in str(col).upper():
                    print(f"Method Column: {col}")
                    if not df[col].isna().all():
                        print(f"Method: {df[col].dropna().iloc[0] if len(df[col].dropna()) > 0 else 'N/A'}")
            
            # Show first few rows
            print("\nFirst 3 rows:")
            print(df.head(3).to_string())
            
        except Exception as e:
            print(f"Error reading sheet '{sheet_name}': {e}")
    
    # Analyze rate limits
    print("\n" + "="*60)
    print("=== Rate Limit Analysis ===")
    
    # Look for rate limit information in all sheets
    for sheet_name in ['API 목록', 'Hashkey', '접근토큰발급(P)']:
        try:
            df = pd.read_excel(excel_file, sheet_name=sheet_name)
            for col in df.columns:
                if any(keyword in str(col).upper() for keyword in ['RATE', 'LIMIT', '제한', '횟수']):
                    print(f"\nFound in {sheet_name} - {col}:")
                    print(df[col].value_counts().head())
        except:
            pass
            
except Exception as e:
    print(f"Error: {e}")