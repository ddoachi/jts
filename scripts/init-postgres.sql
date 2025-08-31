-- Generated from spec: E01-F02-T03 (Docker and Database Services Setup)
-- Spec ID: ce5140df
-- PostgreSQL initialization script for JTS trading system

-- Create schemas
CREATE SCHEMA IF NOT EXISTS trading;
CREATE SCHEMA IF NOT EXISTS analytics;
CREATE SCHEMA IF NOT EXISTS audit;

-- Create enum types
CREATE TYPE trading.order_status AS ENUM (
    'pending',
    'submitted',
    'partial',
    'filled',
    'cancelled',
    'rejected',
    'expired'
);

CREATE TYPE trading.order_side AS ENUM ('buy', 'sell');
CREATE TYPE trading.order_type AS ENUM ('market', 'limit', 'stop', 'stop_limit');

-- Create orders table
CREATE TABLE IF NOT EXISTS trading.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    symbol VARCHAR(20) NOT NULL,
    account_id VARCHAR(50) NOT NULL,
    order_side trading.order_side NOT NULL,
    order_type trading.order_type NOT NULL,
    quantity DECIMAL(18, 8) NOT NULL,
    price DECIMAL(18, 8),
    stop_price DECIMAL(18, 8),
    status trading.order_status NOT NULL DEFAULT 'pending',
    filled_quantity DECIMAL(18, 8) DEFAULT 0,
    average_fill_price DECIMAL(18, 8),
    commission DECIMAL(18, 8) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    executed_at TIMESTAMP WITH TIME ZONE,
    notes TEXT
);

-- Create accounts table
CREATE TABLE IF NOT EXISTS trading.accounts (
    id VARCHAR(50) PRIMARY KEY,
    broker VARCHAR(50) NOT NULL,
    account_type VARCHAR(20) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    balance DECIMAL(18, 8) DEFAULT 0,
    available_balance DECIMAL(18, 8) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create positions table
CREATE TABLE IF NOT EXISTS trading.positions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id VARCHAR(50) NOT NULL REFERENCES trading.accounts(id),
    symbol VARCHAR(20) NOT NULL,
    quantity DECIMAL(18, 8) NOT NULL,
    average_cost DECIMAL(18, 8) NOT NULL,
    current_price DECIMAL(18, 8),
    unrealized_pnl DECIMAL(18, 8),
    realized_pnl DECIMAL(18, 8) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(account_id, symbol)
);

-- Create trades table
CREATE TABLE IF NOT EXISTS trading.trades (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES trading.orders(id),
    account_id VARCHAR(50) NOT NULL,
    symbol VARCHAR(20) NOT NULL,
    side trading.order_side NOT NULL,
    quantity DECIMAL(18, 8) NOT NULL,
    price DECIMAL(18, 8) NOT NULL,
    commission DECIMAL(18, 8) DEFAULT 0,
    executed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    broker_trade_id VARCHAR(100)
);

-- Create strategies table
CREATE TABLE IF NOT EXISTS trading.strategies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    is_active BOOLEAN DEFAULT false,
    config JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create signals table
CREATE TABLE IF NOT EXISTS trading.signals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    strategy_id UUID REFERENCES trading.strategies(id),
    symbol VARCHAR(20) NOT NULL,
    signal_type VARCHAR(20) NOT NULL,
    strength DECIMAL(5, 2),
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create audit log table
CREATE TABLE IF NOT EXISTS audit.activity_log (
    id BIGSERIAL PRIMARY KEY,
    event_type VARCHAR(50) NOT NULL,
    entity_type VARCHAR(50),
    entity_id VARCHAR(100),
    user_id VARCHAR(50),
    details JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create analytics summary table
CREATE TABLE IF NOT EXISTS analytics.daily_summary (
    date DATE NOT NULL,
    account_id VARCHAR(50) NOT NULL,
    total_trades INTEGER DEFAULT 0,
    total_volume DECIMAL(18, 8) DEFAULT 0,
    realized_pnl DECIMAL(18, 8) DEFAULT 0,
    commission_paid DECIMAL(18, 8) DEFAULT 0,
    win_rate DECIMAL(5, 2),
    average_win DECIMAL(18, 8),
    average_loss DECIMAL(18, 8),
    sharpe_ratio DECIMAL(10, 4),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (date, account_id)
);

-- Create indexes
CREATE INDEX idx_orders_account ON trading.orders(account_id);
CREATE INDEX idx_orders_symbol ON trading.orders(symbol);
CREATE INDEX idx_orders_status ON trading.orders(status);
CREATE INDEX idx_orders_created ON trading.orders(created_at DESC);

CREATE INDEX idx_trades_account ON trading.trades(account_id);
CREATE INDEX idx_trades_symbol ON trading.trades(symbol);
CREATE INDEX idx_trades_executed ON trading.trades(executed_at DESC);

CREATE INDEX idx_positions_account ON trading.positions(account_id);
CREATE INDEX idx_positions_symbol ON trading.positions(symbol);

CREATE INDEX idx_signals_strategy ON trading.signals(strategy_id);
CREATE INDEX idx_signals_symbol ON trading.signals(symbol);
CREATE INDEX idx_signals_created ON trading.signals(created_at DESC);

CREATE INDEX idx_audit_event ON audit.activity_log(event_type);
CREATE INDEX idx_audit_entity ON audit.activity_log(entity_type, entity_id);
CREATE INDEX idx_audit_created ON audit.activity_log(created_at DESC);

CREATE INDEX idx_daily_summary_date ON analytics.daily_summary(date DESC);
CREATE INDEX idx_daily_summary_account ON analytics.daily_summary(account_id);

-- Create update trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add update triggers
CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON trading.orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_accounts_updated_at BEFORE UPDATE ON trading.accounts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_positions_updated_at BEFORE UPDATE ON trading.positions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_strategies_updated_at BEFORE UPDATE ON trading.strategies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert sample data for testing
INSERT INTO trading.accounts (id, broker, account_type, balance, available_balance)
VALUES 
    ('KIS_ACCOUNT_1', 'KIS', 'trading', 1000000, 1000000),
    ('KIS_ACCOUNT_2', 'KIS', 'trading', 1000000, 1000000)
ON CONFLICT (id) DO NOTHING;

-- Grant permissions (adjust as needed)
GRANT ALL PRIVILEGES ON SCHEMA trading TO jts_admin;
GRANT ALL PRIVILEGES ON SCHEMA analytics TO jts_admin;
GRANT ALL PRIVILEGES ON SCHEMA audit TO jts_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA trading TO jts_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA analytics TO jts_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA audit TO jts_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA trading TO jts_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA analytics TO jts_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA audit TO jts_admin;