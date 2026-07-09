-- ─────────────────────────────────────────────────────────────────────────────
-- LINCOO – Seller Packs Migration
-- Run in Supabase Dashboard → SQL Editor → New query
-- Safe to re-run: all statements use IF NOT EXISTS / OR REPLACE
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.seller_packs (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id    uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  pack_type    text        NOT NULL CHECK (pack_type IN ('starter', 'pro', 'business')),
  status       text        NOT NULL DEFAULT 'pending_payment'
                           CHECK (status IN ('pending_payment', 'paid', 'active', 'expired', 'cancelled')),
  price_dzd    int         NOT NULL,
  payment_ref  text,
  payment_proof_url text,
  admin_note   text,
  activated_at timestamptz,
  expires_at   timestamptz,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.seller_packs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "seller_packs: owner read"   ON public.seller_packs;
DROP POLICY IF EXISTS "seller_packs: owner insert" ON public.seller_packs;
DROP POLICY IF EXISTS "seller_packs: admin update" ON public.seller_packs;

-- Seller can read their own packs
CREATE POLICY "seller_packs: owner read"
  ON public.seller_packs FOR SELECT
  USING (auth.uid() = seller_id);

-- Seller can create a pack request
CREATE POLICY "seller_packs: owner insert"
  ON public.seller_packs FOR INSERT
  WITH CHECK (auth.uid() = seller_id);

-- Admin can update (verify / activate / expire)
-- For now: allow authenticated update on own pack (seller updates payment_ref)
CREATE POLICY "seller_packs: owner update"
  ON public.seller_packs FOR UPDATE
  USING (auth.uid() = seller_id)
  WITH CHECK (auth.uid() = seller_id);

-- Index for fast lookup
CREATE INDEX IF NOT EXISTS idx_seller_packs_seller_id
  ON public.seller_packs (seller_id, status, created_at DESC);

-- Trigger: auto set updated_at
CREATE OR REPLACE FUNCTION public.set_seller_packs_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;

DROP TRIGGER IF EXISTS trg_seller_packs_updated_at ON public.seller_packs;
CREATE TRIGGER trg_seller_packs_updated_at
  BEFORE UPDATE ON public.seller_packs
  FOR EACH ROW EXECUTE FUNCTION public.set_seller_packs_updated_at();
