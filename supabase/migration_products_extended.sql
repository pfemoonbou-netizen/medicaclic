-- ─────────────────────────────────────────────────────────────────────────────
-- LINCOO – Products Extended Columns Migration
-- Adds variant/stock/tag columns that the Flutter app saves.
-- Safe to re-run: all statements use IF NOT EXISTS / ADD COLUMN IF NOT EXISTS
-- Run in Supabase Dashboard → SQL Editor → New query
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS offer_tag      text,
  ADD COLUMN IF NOT EXISTS size_variants  jsonb  DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS color_variants jsonb  DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS stock_qty      int,
  ADD COLUMN IF NOT EXISTS seller_id      uuid   REFERENCES auth.users(id) ON DELETE SET NULL;

-- Index for quick filtering by available + created_at (home feed query)
CREATE INDEX IF NOT EXISTS idx_products_available_created
  ON public.products (available, created_at DESC);

-- ─────────────────────────────────────────────────────────────────────────────
-- Done. Columns added:
--   offer_tag      text        (e.g. "Nouveauté 🆕")
--   size_variants  jsonb       (array of {size, qty})
--   color_variants jsonb       (array of {name, hex, qty})
--   stock_qty      int         (total stock when no variants)
--   seller_id      uuid        (owner reference)
-- ─────────────────────────────────────────────────────────────────────────────
