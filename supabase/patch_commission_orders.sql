-- =============================================================================
-- Lincoo — Commission system & Orders table
-- Run once in Supabase SQL Editor
-- =============================================================================

-- ── 1. Orders table (create if not exists) ────────────────────────────────────
CREATE TABLE IF NOT EXISTS orders (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_id        UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  seller_id       UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  store_id        UUID,
  items           JSONB        NOT NULL DEFAULT '[]',
  subtotal        INTEGER      NOT NULL DEFAULT 0,
  delivery_cost   INTEGER      NOT NULL DEFAULT 0,
  total           INTEGER      NOT NULL DEFAULT 0,
  delivery_type   TEXT         NOT NULL DEFAULT 'home',
  delivery_mode   TEXT         NOT NULL DEFAULT 'standard',
  wilaya          TEXT,
  commune         TEXT,
  address         TEXT,
  buyer_name      TEXT,
  buyer_phone     TEXT,
  status          TEXT         NOT NULL DEFAULT 'pending',
  payment_method  TEXT         NOT NULL DEFAULT 'cash',
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- ── 2. Commission columns (safe to re-run) ────────────────────────────────────
ALTER TABLE orders ADD COLUMN IF NOT EXISTS commission_rate    DECIMAL(5,4) DEFAULT 0.05;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS commission_amount  INTEGER      DEFAULT 0;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS seller_revenue     INTEGER      DEFAULT 0;

-- ── 3. Commission trigger function ────────────────────────────────────────────
-- Auto-compute commission_rate from seller's active pack on INSERT
CREATE OR REPLACE FUNCTION compute_order_commission()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_pack_type TEXT;
  v_rate      DECIMAL(5,4) := 0.05; -- default: Starter = 5%
BEGIN
  IF NEW.seller_id IS NOT NULL THEN
    SELECT pack_type INTO v_pack_type
    FROM   seller_packs
    WHERE  seller_id = NEW.seller_id
      AND  status    = 'active'
    ORDER  BY created_at DESC
    LIMIT  1;

    v_rate := CASE v_pack_type
      WHEN 'essentiel'   THEN 0.03   -- Essentiel = 3%
      WHEN 'pro'         THEN 0.03   -- Pro       = 3%
      WHEN 'lincoo_plus' THEN 0.03   -- legacy
      WHEN 'business'    THEN 0.03   -- legacy
      ELSE                    0.05   -- starter or no pack = 5%
    END;
  END IF;

  NEW.commission_rate   := v_rate;
  NEW.commission_amount := ROUND(NEW.total::NUMERIC * v_rate)::INTEGER;
  NEW.seller_revenue    := NEW.total - NEW.commission_amount;

  RETURN NEW;
END;
$$;

-- ── 4. Attach trigger ─────────────────────────────────────────────────────────
DROP TRIGGER IF EXISTS trg_order_commission ON orders;
CREATE TRIGGER trg_order_commission
  BEFORE INSERT ON orders
  FOR EACH ROW
  EXECUTE FUNCTION compute_order_commission();

-- ── 5. updated_at auto-refresh ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$;

DROP TRIGGER IF EXISTS trg_orders_updated_at ON orders;
CREATE TRIGGER trg_orders_updated_at
  BEFORE UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ── 6. Row Level Security ─────────────────────────────────────────────────────
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Buyer: create & read own orders
DROP POLICY IF EXISTS "orders_buyer_insert"  ON orders;
DROP POLICY IF EXISTS "orders_buyer_select"  ON orders;
CREATE POLICY "orders_buyer_insert"  ON orders FOR INSERT WITH CHECK (auth.uid() = buyer_id);
CREATE POLICY "orders_buyer_select"  ON orders FOR SELECT USING  (auth.uid() = buyer_id);

-- Seller: read & update own orders
DROP POLICY IF EXISTS "orders_seller_select" ON orders;
DROP POLICY IF EXISTS "orders_seller_update" ON orders;
CREATE POLICY "orders_seller_select" ON orders FOR SELECT USING  (auth.uid() = seller_id);
CREATE POLICY "orders_seller_update" ON orders FOR UPDATE USING  (auth.uid() = seller_id);

-- ── 7. Useful view for seller dashboard ───────────────────────────────────────
CREATE OR REPLACE VIEW seller_order_stats AS
SELECT
  seller_id,
  COUNT(*)                                    AS total_orders,
  SUM(subtotal)                               AS gross_revenue,
  SUM(commission_amount)                      AS total_commission,
  SUM(seller_revenue)                         AS net_revenue,
  ROUND(AVG(commission_rate) * 100, 2)        AS avg_commission_pct,
  COUNT(*) FILTER (WHERE status = 'pending')  AS pending_orders,
  COUNT(*) FILTER (WHERE status = 'delivered') AS delivered_orders
FROM orders
GROUP BY seller_id;
