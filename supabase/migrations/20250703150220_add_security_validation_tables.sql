-- Add security validation tables for enhanced wallet payment security

-- Table for tracking payment attempts (rate limiting)
CREATE TABLE IF NOT EXISTS payment_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
    payment_method TEXT NOT NULL,
    amount DECIMAL(10,2),
    status TEXT NOT NULL CHECK (status IN ('attempted', 'succeeded', 'failed')),
    error_code TEXT,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table for security audit logging
CREATE TABLE IF NOT EXISTS security_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type TEXT NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    event_data JSONB,
    ip_address INET,
    user_agent TEXT,
    severity TEXT DEFAULT 'info' CHECK (severity IN ('info', 'warning', 'error', 'critical')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_payment_attempts_user_created
    ON payment_attempts(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_payment_attempts_status_created
    ON payment_attempts(status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_security_audit_log_user_created
    ON security_audit_log(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_security_audit_log_event_type_created
    ON security_audit_log(event_type, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_security_audit_log_severity_created
    ON security_audit_log(severity, created_at DESC);

-- Add last_activity_at column to stakeholder_wallets if it doesn't exist
ALTER TABLE stakeholder_wallets
ADD COLUMN IF NOT EXISTS last_activity_at TIMESTAMPTZ DEFAULT NOW();

-- Create index for wallet activity tracking
CREATE INDEX IF NOT EXISTS idx_stakeholder_wallets_user_activity
    ON stakeholder_wallets(user_id, last_activity_at DESC);

-- Add payment_status and payment_failure_reason columns to orders if they don't exist
ALTER TABLE orders
ADD COLUMN IF NOT EXISTS payment_status TEXT DEFAULT 'pending'
    CHECK (payment_status IN ('pending', 'processing', 'paid', 'failed', 'refunded')),
ADD COLUMN IF NOT EXISTS payment_failure_reason TEXT;

-- Create index for payment status tracking
CREATE INDEX IF NOT EXISTS idx_orders_payment_status_created
    ON orders(payment_status, created_at DESC);

-- RLS Policies for payment_attempts
ALTER TABLE payment_attempts ENABLE ROW LEVEL SECURITY;

-- Users can only see their own payment attempts
CREATE POLICY "Users can view their own payment attempts" ON payment_attempts
    FOR SELECT TO authenticated
    USING (user_id = auth.uid());

-- Only the system can insert payment attempts (via service role)
CREATE POLICY "System can insert payment attempts" ON payment_attempts
    FOR INSERT TO service_role
    WITH CHECK (true);

-- RLS Policies for security_audit_log
ALTER TABLE security_audit_log ENABLE ROW LEVEL SECURITY;

-- Only admins can view security audit logs
CREATE POLICY "Admins can view security audit logs" ON security_audit_log
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM user_profiles
            WHERE user_id = auth.uid() AND role = 'admin'
        )
    );

-- Only the system can insert security audit logs (via service role)
CREATE POLICY "System can insert security audit logs" ON security_audit_log
    FOR INSERT TO service_role
    WITH CHECK (true);

-- Function to automatically log payment attempts
CREATE OR REPLACE FUNCTION log_payment_attempt()
RETURNS TRIGGER AS $$
BEGIN
    -- Log payment attempt when order payment is processed
    IF TG_OP = 'UPDATE' AND OLD.payment_status != NEW.payment_status THEN
        INSERT INTO payment_attempts (
            user_id,
            order_id,
            payment_method,
            amount,
            status,
            error_code
        ) VALUES (
            NEW.customer_id,
            NEW.id,
            NEW.payment_method,
            NEW.total_amount,
            CASE
                WHEN NEW.payment_status = 'paid' THEN 'succeeded'
                WHEN NEW.payment_status = 'failed' THEN 'failed'
                ELSE 'attempted'
            END,
            NEW.payment_failure_reason
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for automatic payment attempt logging
DROP TRIGGER IF EXISTS trigger_log_payment_attempt ON orders;
CREATE TRIGGER trigger_log_payment_attempt
    AFTER UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION log_payment_attempt();

-- Function to clean up old security logs (for maintenance)
CREATE OR REPLACE FUNCTION cleanup_old_security_logs()
RETURNS void AS $$
BEGIN
    -- Delete security audit logs older than 90 days
    DELETE FROM security_audit_log
    WHERE created_at < NOW() - INTERVAL '90 days';

    -- Delete payment attempts older than 30 days
    DELETE FROM payment_attempts
    WHERE created_at < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enhanced wallet security function
CREATE OR REPLACE FUNCTION validate_wallet_ownership(wallet_id UUID, user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    wallet_owner UUID;
BEGIN
    -- Get the wallet owner
    SELECT sw.user_id INTO wallet_owner
    FROM stakeholder_wallets sw
    WHERE sw.id = wallet_id;

    -- Return true if the user owns the wallet
    RETURN wallet_owner = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user has exceeded daily transaction limits
CREATE OR REPLACE FUNCTION check_daily_transaction_limit(user_id UUID, amount DECIMAL)
RETURNS BOOLEAN AS $$
DECLARE
    daily_total DECIMAL;
    daily_limit DECIMAL := 5000.00; -- RM 5,000 daily limit
BEGIN
    -- Calculate today's total transactions
    SELECT COALESCE(SUM(wt.amount), 0) INTO daily_total
    FROM wallet_transactions wt
    WHERE wt.user_id = user_id
    AND wt.transaction_type = 'payment'
    AND wt.created_at >= CURRENT_DATE;

    -- Check if adding this amount would exceed the limit
    RETURN (daily_total + amount) <= daily_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to detect suspicious transaction patterns
CREATE OR REPLACE FUNCTION detect_suspicious_pattern(user_id UUID, amount DECIMAL)
RETURNS TEXT AS $$
DECLARE
    recent_count INTEGER;
    large_count INTEGER;
    pattern_detected TEXT := 'none';
BEGIN
    -- Check for rapid successive transactions (more than 3 in 10 minutes)
    SELECT COUNT(*) INTO recent_count
    FROM wallet_transactions wt
    WHERE wt.user_id = user_id
    AND wt.created_at >= NOW() - INTERVAL '10 minutes';

    IF recent_count >= 3 THEN
        pattern_detected := 'rapid_transactions';
    END IF;

    -- Check for multiple large transactions (more than 2 transactions > RM 1000 in 1 hour)
    SELECT COUNT(*) INTO large_count
    FROM wallet_transactions wt
    WHERE wt.user_id = user_id
    AND wt.amount >= 1000.00
    AND wt.created_at >= NOW() - INTERVAL '1 hour';

    IF large_count >= 2 AND amount >= 1000.00 THEN
        pattern_detected := 'multiple_large_transactions';
    END IF;

    RETURN pattern_detected;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enhanced RLS policy for stakeholder_wallets to prevent unauthorized access
DROP POLICY IF EXISTS "Users can only access their own wallets" ON stakeholder_wallets;
CREATE POLICY "Users can only access their own wallets" ON stakeholder_wallets
    FOR ALL TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- Grant necessary permissions
GRANT SELECT, INSERT ON payment_attempts TO authenticated;
GRANT SELECT ON security_audit_log TO authenticated;
GRANT EXECUTE ON FUNCTION cleanup_old_security_logs() TO service_role;
GRANT EXECUTE ON FUNCTION validate_wallet_ownership(UUID, UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION check_daily_transaction_limit(UUID, DECIMAL) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION detect_suspicious_pattern(UUID, DECIMAL) TO authenticated, service_role;