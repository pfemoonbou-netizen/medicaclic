-- =============================================================================
-- Fix: orders table missing columns (buyer_name, items, subtotal, etc.)
--
-- Root cause: patch_commission_orders.sql used
--   CREATE TABLE IF NOT EXISTS orders (...)
-- but `orders` already existed (created by schema.sql with an older,
-- single-product-per-row shape). CREATE TABLE IF NOT EXISTS is a no-op when
-- the table already exists, so none of the newer columns it declared
-- (buyer_name, items, subtotal, delivery_cost, total, delivery_type,
-- delivery_mode, commune, buyer_phone, payment_method, seller_id) were ever
-- added — hence PGRST204 "Could not find the 'buyer_name' column".
--
-- Run once in the Supabase SQL Editor.
-- =============================================================================

ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS seller_id      UUID REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS items          JSONB NOT NULL DEFAULT '[]';
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS subtotal       INTEGER NOT NULL DEFAULT 0;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_cost  INTEGER NOT NULL DEFAULT 0;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS total          INTEGER NOT NULL DEFAULT 0;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_type  TEXT NOT NULL DEFAULT 'home';
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_mode  TEXT NOT NULL DEFAULT 'standard';
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS commune        TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS buyer_name     TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS buyer_phone    TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS payment_method TEXT NOT NULL DEFAULT 'cash';

-- The app's checkout flow (lib/screens/checkout_page.dart) builds orders
-- around the `items` JSONB cart array + subtotal/total, and no longer sends
-- per-row product_id/unit_price/total_price, and only sends store_id when the
-- cart has a single store. Relax the old single-product-row constraints so
-- inserts from the new checkout flow don't fail on NOT NULL violations.
ALTER TABLE public.orders ALTER COLUMN store_id    DROP NOT NULL;
ALTER TABLE public.orders ALTER COLUMN unit_price  DROP NOT NULL;
ALTER TABLE public.orders ALTER COLUMN total_price DROP NOT NULL;

-- Let PostgREST pick up the new columns immediately instead of waiting for
-- its next schema-cache refresh.
NOTIFY pgrst, 'reload schema';
