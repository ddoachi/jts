import pandas as pd
import json

excel_file = 'brokers/kis/reference/KIS_API_20250817_030000.xlsx'

# Read the main API list
df_api = pd.read_excel(excel_file, sheet_name='API 목록')

print("=== KIS API Details for JTS Integration ===\n")

# Filter for essential trading APIs
trading_apis = df_api[df_api['메뉴 위치'].str.contains('주문/계좌|기본시세', na=False)]

print(f"Trading-related APIs: {len(trading_apis)}")
print("\n=== Core Trading APIs ===")

# Group by category
categories = {
    'Order Management': ['주식주문', '정정취소', '예약주문'],
    'Account Info': ['잔고조회', '매수가능', '매도가능', '체결조회'],
    'Market Data': ['현재가', '호가', '체결', '시세'],
    'Real-time': ['실시간']
}

for category, keywords in categories.items():
    print(f"\n--- {category} ---")
    for _, row in df_api.iterrows():
        api_name = str(row['API 명'])
        if any(keyword in api_name for keyword in keywords):
            if category != 'Real-time' or row['API 통신방식'] == 'WebSocket':
                print(f"• {api_name}")
                print(f"  - TR_ID: {row['실전 TR_ID']} (prod) / {row['모의 TR_ID']} (sandbox)")
                print(f"  - Method: {row['HTTP Method']}")
                print(f"  - URL: {row['URL 명']}")

# Extract rate limit information
print("\n=== Rate Limiting Configuration ===")
print("""
Based on KIS API documentation:
- REST API: 1 second / 20 requests (peak)
- REST API: 1 minute / 1,000 requests (sustained)
- WebSocket: 5 concurrent connections
- WebSocket: 40 subscriptions per connection

Recommended Implementation:
1. Use token bucket algorithm with 20 tokens/second
2. Implement priority queue for order execution
3. Batch market data requests when possible
4. Use WebSocket for real-time data to reduce REST load
""")

# Create JSON summary for programmatic use
api_summary = {
    "total_apis": len(df_api),
    "categories": {
        "authentication": 5,
        "domestic_stock_trading": 26,
        "domestic_stock_market_data": 49,
        "real_time_websocket": 22,
        "futures_options": 24,
        "international": 65
    },
    "endpoints": {
        "production": {
            "rest": "https://openapi.koreainvestment.com:9443",
            "websocket": "ws://ops.koreainvestment.com:21000"
        },
        "sandbox": {
            "rest": "https://openapivts.koreainvestment.com:29443",
            "websocket": "ws://ops.koreainvestment.com:31000"
        }
    },
    "rate_limits": {
        "rest_per_second": 20,
        "rest_per_minute": 1000,
        "websocket_connections": 5,
        "websocket_subscriptions_per_connection": 40
    },
    "key_apis": []
}

# Add key APIs to summary
key_api_names = [
    '주식주문(현금)',
    '주식주문(정정취소)',
    '주식잔고조회',
    '주식현재가 시세',
    '매수가능조회',
    '주식일별주문체결조회'
]

for api_name in key_api_names:
    api_row = df_api[df_api['API 명'] == api_name]
    if not api_row.empty:
        api_info = api_row.iloc[0]
        api_summary["key_apis"].append({
            "name": api_name,
            "tr_id_prod": api_info['실전 TR_ID'],
            "tr_id_sandbox": api_info['모의 TR_ID'],
            "method": api_info['HTTP Method'],
            "url": api_info['URL 명']
        })

# Save summary to JSON
with open('brokers/kis/reference/kis_api_summary.json', 'w', encoding='utf-8') as f:
    json.dump(api_summary, f, ensure_ascii=False, indent=2)

print("\n=== Summary saved to kis_api_summary.json ===")
print(json.dumps(api_summary, ensure_ascii=False, indent=2))