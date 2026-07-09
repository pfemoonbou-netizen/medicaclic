-- ─────────────────────────────────────────────────────────────────────────────
-- LINCOO – Ad Approval Workflow Migration
-- Phase 2: Create ad_campaigns (if missing) + payment & approval columns
--
-- Run this in Supabase SQL Editor (Dashboard > SQL Editor > New query)
-- Safe to re-run: all statements use IF NOT EXISTS / DROP IF EXISTS
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. Create ad_campaigns table (if it does not exist yet) ──────────────────

CREATE TABLE IF NOT EXISTS public.ad_campaigns (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id       uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title            text NOT NULL,
  description      text,
  image_url        text,
  cta_label        text,
  cta_route        text,
  status           text NOT NULL DEFAULT 'draft'
                     CHECK (status IN ('draft','submitted','inReview','approved','rejected','active','ended')),
  budget_dzd       int  NOT NULL DEFAULT 0,
  start_date       date,
  end_date         date,
  placement        text NOT NULL DEFAULT 'home_banner',
  payment_method   text CHECK (payment_method IN ('ccp','baridimob','virement','carte')),
  created_at       timestamptz NOT NULL DEFAULT now()
);

-- ── 2. Add new approval/payment columns ──────────────────────────────────────

ALTER TABLE public.ad_campaigns
  ADD COLUMN IF NOT EXISTS receipt_url      text,
  ADD COLUMN IF NOT EXISTS payment_status   text NOT NULL DEFAULT 'pending'
    CHECK (payment_status IN ('pending', 'verified', 'rejected')),
  ADD COLUMN IF NOT EXISTS approval_status  text NOT NULL DEFAULT 'pending'
    CHECK (approval_status IN ('pending', 'approved', 'rejected')),
  ADD COLUMN IF NOT EXISTS approved_at      timestamptz,
  ADD COLUMN IF NOT EXISTS approved_by      uuid REFERENCES auth.users(id) ON DELETE SET NULL;

-- ── 3. Enable RLS ─────────────────────────────────────────────────────────────

ALTER TABLE public.ad_campaigns ENABLE ROW LEVEL SECURITY;

-- ── 4. RLS Policies ───────────────────────────────────────────────────────────

-- Public: only see approved campaigns (or own campaigns)
DROP POLICY IF EXISTS "campaigns_public_read"        ON public.ad_campaigns;
DROP POLICY IF EXISTS "ad_campaigns: active read"    ON public.ad_campaigns;
DROP POLICY IF EXISTS "ad_campaigns: approved read"  ON public.ad_campaigns;
CREATE POLICY "ad_campaigns: approved read"
  ON public.ad_campaigns FOR SELECT
  USING (approval_status = 'approved' OR company_id = auth.uid());

-- Owner: full access to own campaigns
DROP POLICY IF EXISTS "campaigns_owner_all"   ON public.ad_campaigns;
DROP POLICY IF EXISTS "ad_campaigns: own manage" ON public.ad_campaigns;
CREATE POLICY "ad_campaigns: own manage"
  ON public.ad_campaigns FOR ALL
  USING (company_id = auth.uid());

-- Verified sellers/companies: can create campaigns
DROP POLICY IF EXISTS "ad_campaigns: company create" ON public.ad_campaigns;
CREATE POLICY "ad_campaigns: company create"
  ON public.ad_campaigns FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- Admin: can update any campaign (approve/reject)
DROP POLICY IF EXISTS "campaigns_admin_update"      ON public.ad_campaigns;
DROP POLICY IF EXISTS "ad_campaigns: admin update"  ON public.ad_campaigns;
CREATE POLICY "ad_campaigns: admin update"
  ON public.ad_campaigns FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

-- ── 5. Indexes ────────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_ad_campaigns_approval
  ON public.ad_campaigns (approval_status);

CREATE INDEX IF NOT EXISTS idx_ad_campaigns_payment
  ON public.ad_campaigns (payment_status);

-- ── 6. Realtime ───────────────────────────────────────────────────────────────

ALTER PUBLICATION supabase_realtime ADD TABLE ad_campaigns;

-- ── 7. Storage bucket for payment receipts ────────────────────────────────────

INSERT INTO storage.buckets (id, name, public)
VALUES ('ad-receipts', 'ad-receipts', false)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "ad-receipts: owner upload" ON storage.objects;
CREATE POLICY "ad-receipts: owner upload"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'ad-receipts'
    AND auth.uid() IS NOT NULL
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

DROP POLICY IF EXISTS "ad-receipts: owner read" ON storage.objects;
CREATE POLICY "ad-receipts: owner read"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'ad-receipts'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

DROP POLICY IF EXISTS "ad-receipts: admin read" ON storage.objects;
CREATE POLICY "ad-receipts: admin read"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'ad-receipts'
    AND EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

-- ── 8. Admin can SELECT all campaigns (needed for Phase 4 dashboard) ─────────

DROP POLICY IF EXISTS "ad_campaigns: admin read" ON public.ad_campaigns;
CREATE POLICY "ad_campaigns: admin read"
  ON public.ad_campaigns FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- Phase 2 complete.
-- Table:   ad_campaigns (created if missing)
-- Columns: receipt_url, payment_status, approval_status, approved_at, approved_by
-- Bucket:  ad-receipts (private, owner-scoped)
-- ─────────────────────────────────────────────────────────────────────────────
