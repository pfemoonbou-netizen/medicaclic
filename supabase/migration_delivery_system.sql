-- =============================================================================
-- LINCOO SMART DELIVERY — Full Database Migration
-- =============================================================================

-- ── 1. Delivery Partners ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.delivery_partners (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                     TEXT NOT NULL,
  code                     TEXT UNIQUE NOT NULL,
  logo_url                 TEXT,
  api_endpoint             TEXT,
  api_key_encrypted        TEXT,
  webhook_secret           TEXT,
  is_active                BOOLEAN DEFAULT true,
  supports_smart           BOOLEAN DEFAULT false,
  supports_express         BOOLEAN DEFAULT false,
  supports_fulfillment     BOOLEAN DEFAULT false,
  supports_pickup          BOOLEAN DEFAULT true,
  supports_dropoff         BOOLEAN DEFAULT false,
  last_sync_at             TIMESTAMPTZ,
  zones                    JSONB DEFAULT '[]',
  rate_limit_per_min       INTEGER DEFAULT 60,
  metadata                 JSONB DEFAULT '{}',
  created_at               TIMESTAMPTZ DEFAULT NOW(),
  updated_at               TIMESTAMPTZ DEFAULT NOW()
);

-- ── 2. Delivery Zones ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.delivery_zones (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_id           UUID REFERENCES public.delivery_partners(id) ON DELETE SET NULL,
  wilaya_code          INTEGER NOT NULL,
  wilaya_name          TEXT NOT NULL,
  communes             JSONB DEFAULT '[]',
  is_active            BOOLEAN DEFAULT true,
  delivery_days        INTEGER DEFAULT 3,
  is_smart_eligible    BOOLEAN DEFAULT false,
  created_at           TIMESTAMPTZ DEFAULT NOW()
);

-- ── 3. Delivery Pricing ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.delivery_pricing (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_id       UUID REFERENCES public.delivery_partners(id) ON DELETE CASCADE,
  zone_id          UUID REFERENCES public.delivery_zones(id) ON DELETE CASCADE,
  delivery_type    TEXT NOT NULL CHECK (delivery_type IN ('standard','express','smart','pickup','dropoff')),
  base_price_dzd   INTEGER NOT NULL DEFAULT 0,
  price_per_kg_dzd INTEGER DEFAULT 0,
  max_weight_kg    NUMERIC(6,2),
  max_dims_cm      JSONB DEFAULT '{"l":100,"w":60,"h":60}',
  is_active        BOOLEAN DEFAULT true,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW()
);

-- ── 4. Delivery Rule Engine ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.delivery_rules (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rule_key     TEXT UNIQUE NOT NULL,
  rule_value   JSONB NOT NULL,
  description  TEXT,
  category     TEXT DEFAULT 'global',
  updated_by   UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  updated_at   TIMESTAMPTZ DEFAULT NOW()
);

-- Seed default rules
INSERT INTO public.delivery_rules (rule_key, rule_value, description, category) VALUES
  ('smart.max_products',          '6',      'Max products per Smart Delivery basket',          'smart'),
  ('smart.max_sellers',           '4',      'Max sellers per Smart Delivery basket',            'smart'),
  ('smart.confirmation_hours',    '6',      'Hours seller has to confirm',                      'smart'),
  ('smart.basket_expiry_days',    '10',     'Days before unconfirmed basket expires',           'smart'),
  ('smart.max_weight_kg',         '30',     'Max total weight for smart basket (kg)',           'smart'),
  ('smart.savings_percent',       '40',     'Typical savings % vs individual delivery',         'smart'),
  ('standard.max_weight_kg',      '50',     'Max weight for standard delivery (kg)',            'standard'),
  ('express.max_weight_kg',       '20',     'Max weight for express delivery (kg)',             'express'),
  ('express.delivery_hours',      '24',     'Max hours for express delivery',                  'express'),
  ('global.prep_default_hours',   '24',     'Default seller preparation time (hours)',          'global'),
  ('global.max_dims_l',           '100',    'Max length in cm',                                'global'),
  ('global.max_dims_w',           '60',     'Max width in cm',                                 'global'),
  ('global.max_dims_h',           '60',     'Max height in cm',                                'global'),
  ('fulfillment.storage_fee_dzd', '50',     'Daily storage fee per unit (DZD)',                'fulfillment'),
  ('pricing.smart_base_dzd',      '350',    'Base price Smart Delivery (DZD)',                  'pricing'),
  ('pricing.standard_base_dzd',   '450',    'Base price Standard Delivery (DZD)',              'pricing'),
  ('pricing.express_base_dzd',    '700',    'Base price Express Delivery (DZD)',               'pricing')
ON CONFLICT (rule_key) DO NOTHING;

-- ── 5. Seller Delivery Settings ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.seller_delivery_settings (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id             UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  store_id              UUID,
  wilaya_code           INTEGER,
  wilaya_name           TEXT,
  commune               TEXT,
  address               TEXT,
  pickup_address        TEXT,
  pickup_schedule       JSONB DEFAULT '{}',
  avg_prep_hours        INTEGER DEFAULT 24,
  max_weight_kg         NUMERIC(6,2) DEFAULT 30,
  max_dims_cm           JSONB DEFAULT '{"l":100,"w":60,"h":60}',
  preferred_partner_id  UUID REFERENCES public.delivery_partners(id) ON DELETE SET NULL,
  dropoff_point_id      UUID,
  is_pickup_enabled     BOOLEAN DEFAULT true,
  is_dropoff_enabled    BOOLEAN DEFAULT false,
  created_at            TIMESTAMPTZ DEFAULT NOW(),
  updated_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── 6. Seller Smart Delivery Requests ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.seller_smart_delivery_requests (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  store_id          UUID,
  store_name        TEXT,
  status            TEXT NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending','approved','rejected','suspended')),
  contract_signed   BOOLEAN DEFAULT false,
  contract_version  TEXT DEFAULT '1.0',
  admin_note        TEXT,
  reviewed_by       UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  reviewed_at       TIMESTAMPTZ,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  updated_at        TIMESTAMPTZ DEFAULT NOW()
);

-- ── 7. Drop-off Points ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.dropoff_points (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_id       UUID REFERENCES public.delivery_partners(id) ON DELETE SET NULL,
  name             TEXT NOT NULL,
  address          TEXT NOT NULL,
  wilaya_code      INTEGER,
  wilaya_name      TEXT,
  commune          TEXT,
  lat              NUMERIC(10,7),
  lng              NUMERIC(10,7),
  working_hours    JSONB DEFAULT '{}',
  is_active        BOOLEAN DEFAULT true,
  capacity_per_day INTEGER DEFAULT 50,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

-- ── 8. Fulfillment Centers (Hubs) ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.fulfillment_centers (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name             TEXT NOT NULL,
  address          TEXT NOT NULL,
  wilaya_code      INTEGER,
  wilaya_name      TEXT,
  commune          TEXT,
  lat              NUMERIC(10,7),
  lng              NUMERIC(10,7),
  capacity_units   INTEGER DEFAULT 1000,
  current_units    INTEGER DEFAULT 0,
  manager_name     TEXT,
  manager_phone    TEXT,
  is_active        BOOLEAN DEFAULT true,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

-- ── 9. Fulfillment Inventory ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.fulfillment_inventory (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  center_id               UUID NOT NULL REFERENCES public.fulfillment_centers(id) ON DELETE RESTRICT,
  seller_id               UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  product_id              UUID,
  product_name            TEXT NOT NULL,
  sku                     TEXT,
  quantity_stored         INTEGER DEFAULT 0,
  quantity_reserved       INTEGER DEFAULT 0,
  quantity_shipped        INTEGER DEFAULT 0,
  weight_kg               NUMERIC(6,2),
  unit_storage_price_dzd  INTEGER DEFAULT 0,
  entered_at              TIMESTAMPTZ DEFAULT NOW(),
  updated_at              TIMESTAMPTZ DEFAULT NOW()
);

-- ── 10. Smart Delivery Groups (Baskets) ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.smart_delivery_groups (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_code            TEXT UNIQUE NOT NULL,
  partner_id            UUID REFERENCES public.delivery_partners(id) ON DELETE SET NULL,
  zone_id               UUID REFERENCES public.delivery_zones(id) ON DELETE SET NULL,
  buyer_id              UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  status                TEXT NOT NULL DEFAULT 'pending_confirmation'
                        CHECK (status IN ('pending_confirmation','confirmed','in_preparation',
                                          'picked_up','in_transit','delivered','cancelled','disputed')),
  delivery_type         TEXT DEFAULT 'smart' CHECK (delivery_type IN ('smart','standard','express')),
  total_sellers         INTEGER DEFAULT 0,
  total_products        INTEGER DEFAULT 0,
  total_weight_kg       NUMERIC(6,2),
  total_price_dzd       INTEGER DEFAULT 0,
  delivery_fee_dzd      INTEGER DEFAULT 0,
  savings_dzd           INTEGER DEFAULT 0,
  estimated_delivery_at TIMESTAMPTZ,
  confirmed_at          TIMESTAMPTZ,
  picked_up_at          TIMESTAMPTZ,
  delivered_at          TIMESTAMPTZ,
  tracking_number       TEXT,
  expires_at            TIMESTAMPTZ,
  buyer_address         TEXT,
  buyer_wilaya          TEXT,
  buyer_phone           TEXT,
  notes                 TEXT,
  created_at            TIMESTAMPTZ DEFAULT NOW(),
  updated_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── 11. Smart Delivery Items (per seller in a group) ──────────────────────────
CREATE TABLE IF NOT EXISTS public.smart_delivery_items (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id          UUID NOT NULL REFERENCES public.smart_delivery_groups(id) ON DELETE CASCADE,
  seller_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  order_id          UUID,
  store_id          UUID,
  store_name        TEXT,
  status            TEXT NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending','confirmed','rejected','prepared','picked_up','cancelled')),
  products          JSONB DEFAULT '[]',
  subtotal_dzd      INTEGER DEFAULT 0,
  weight_kg         NUMERIC(6,2),
  prep_notes        TEXT,
  confirmed_at      TIMESTAMPTZ,
  rejected_at       TIMESTAMPTZ,
  rejection_reason  TEXT,
  prepared_at       TIMESTAMPTZ,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  updated_at        TIMESTAMPTZ DEFAULT NOW()
);

-- ── 12. Pickup Requests ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.pickup_requests (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  partner_id        UUID REFERENCES public.delivery_partners(id) ON DELETE SET NULL,
  smart_group_id    UUID REFERENCES public.smart_delivery_groups(id) ON DELETE SET NULL,
  status            TEXT NOT NULL DEFAULT 'scheduled'
                    CHECK (status IN ('scheduled','confirmed','driver_assigned',
                                      'en_route','completed','failed','cancelled')),
  pickup_date       DATE NOT NULL,
  pickup_from       TIME NOT NULL,
  pickup_to         TIME NOT NULL,
  address           TEXT NOT NULL,
  wilaya_code       INTEGER,
  commune           TEXT,
  driver_name       TEXT,
  driver_phone      TEXT,
  packages_count    INTEGER DEFAULT 1,
  notes             TEXT,
  completed_at      TIMESTAMPTZ,
  failure_reason    TEXT,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  updated_at        TIMESTAMPTZ DEFAULT NOW()
);

-- ── 13. Shipping Labels ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.shipping_labels (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id              UUID REFERENCES public.smart_delivery_groups(id) ON DELETE SET NULL,
  item_id               UUID REFERENCES public.smart_delivery_items(id) ON DELETE SET NULL,
  seller_id             UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  tracking_number       TEXT UNIQUE NOT NULL,
  barcode               TEXT,
  qr_data               JSONB DEFAULT '{}',
  label_url             TEXT,
  partner_id            UUID REFERENCES public.delivery_partners(id) ON DELETE SET NULL,
  partner_tracking_id   TEXT,
  printed_at            TIMESTAMPTZ,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── 14. Delivery Tracking ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.delivery_tracking (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  label_id             UUID REFERENCES public.shipping_labels(id) ON DELETE CASCADE,
  group_id             UUID REFERENCES public.smart_delivery_groups(id) ON DELETE SET NULL,
  tracking_number      TEXT,
  current_status       TEXT,
  current_location     TEXT,
  current_lat          NUMERIC(10,7),
  current_lng          NUMERIC(10,7),
  hub_id               UUID REFERENCES public.fulfillment_centers(id) ON DELETE SET NULL,
  estimated_delivery   TIMESTAMPTZ,
  last_update          TIMESTAMPTZ DEFAULT NOW(),
  raw_partner_data     JSONB DEFAULT '{}'
);

-- ── 15. Delivery Events (audit trail) ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.delivery_events (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id     UUID REFERENCES public.smart_delivery_groups(id) ON DELETE SET NULL,
  item_id      UUID REFERENCES public.smart_delivery_items(id) ON DELETE SET NULL,
  tracking_id  UUID REFERENCES public.delivery_tracking(id) ON DELETE SET NULL,
  event_type   TEXT NOT NULL,
  event_data   JSONB DEFAULT '{}',
  actor_id     UUID,
  actor_type   TEXT DEFAULT 'system',
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ── 16. Delivery Notifications ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.delivery_notifications (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id            UUID REFERENCES public.smart_delivery_groups(id) ON DELETE SET NULL,
  recipient_id        UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  recipient_type      TEXT NOT NULL,
  notification_type   TEXT NOT NULL,
  title               TEXT NOT NULL,
  body                TEXT NOT NULL,
  data                JSONB DEFAULT '{}',
  sent_at             TIMESTAMPTZ DEFAULT NOW(),
  read_at             TIMESTAMPTZ
);

-- ── 17. Delivery Disputes ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.delivery_disputes (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id         UUID REFERENCES public.smart_delivery_groups(id) ON DELETE SET NULL,
  item_id          UUID REFERENCES public.smart_delivery_items(id) ON DELETE SET NULL,
  reporter_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  reporter_type    TEXT NOT NULL,
  dispute_type     TEXT NOT NULL CHECK (dispute_type IN ('lost','damaged','delayed','wrong_item','not_received','other')),
  description      TEXT,
  evidence_urls    JSONB DEFAULT '[]',
  status           TEXT DEFAULT 'open' CHECK (status IN ('open','investigating','resolved','rejected')),
  resolution       TEXT,
  refund_amount    INTEGER DEFAULT 0,
  resolved_by      UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  resolved_at      TIMESTAMPTZ,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- INDEXES
-- =============================================================================
CREATE INDEX IF NOT EXISTS idx_smart_groups_buyer     ON public.smart_delivery_groups(buyer_id);
CREATE INDEX IF NOT EXISTS idx_smart_groups_status    ON public.smart_delivery_groups(status);
CREATE INDEX IF NOT EXISTS idx_smart_items_group      ON public.smart_delivery_items(group_id);
CREATE INDEX IF NOT EXISTS idx_smart_items_seller     ON public.smart_delivery_items(seller_id);
CREATE INDEX IF NOT EXISTS idx_smart_items_status     ON public.smart_delivery_items(status);
CREATE INDEX IF NOT EXISTS idx_pickup_seller          ON public.pickup_requests(seller_id);
CREATE INDEX IF NOT EXISTS idx_pickup_date            ON public.pickup_requests(pickup_date);
CREATE INDEX IF NOT EXISTS idx_labels_seller          ON public.shipping_labels(seller_id);
CREATE INDEX IF NOT EXISTS idx_labels_tracking        ON public.shipping_labels(tracking_number);
CREATE INDEX IF NOT EXISTS idx_tracking_group         ON public.delivery_tracking(group_id);
CREATE INDEX IF NOT EXISTS idx_events_group           ON public.delivery_events(group_id);
CREATE INDEX IF NOT EXISTS idx_notifs_recipient       ON public.delivery_notifications(recipient_id);
CREATE INDEX IF NOT EXISTS idx_smart_req_seller       ON public.seller_smart_delivery_requests(seller_id);
CREATE INDEX IF NOT EXISTS idx_fulfillment_seller     ON public.fulfillment_inventory(seller_id);

-- =============================================================================
-- RLS POLICIES
-- =============================================================================
ALTER TABLE public.delivery_partners              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_zones                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_pricing               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_rules                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.seller_delivery_settings       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.seller_smart_delivery_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dropoff_points                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fulfillment_centers            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fulfillment_inventory          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.smart_delivery_groups          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.smart_delivery_items           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pickup_requests                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shipping_labels                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_tracking              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_events                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_notifications         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_disputes              ENABLE ROW LEVEL SECURITY;

-- Helper: returns true when the current user is a seller
-- SECURITY DEFINER avoids RLS recursion when called from other table policies
CREATE OR REPLACE FUNCTION public.is_seller_user()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
      AND pro_role = 'seller'
      AND pro_status = 'verified'
  );
$$;

-- Public read for partners/zones/pricing/rules (reference data)
CREATE POLICY "public_read_partners"   ON public.delivery_partners  FOR SELECT USING (true);
CREATE POLICY "public_read_zones"      ON public.delivery_zones     FOR SELECT USING (true);
CREATE POLICY "public_read_pricing"    ON public.delivery_pricing   FOR SELECT USING (true);
CREATE POLICY "public_read_rules"      ON public.delivery_rules     FOR SELECT USING (true);
CREATE POLICY "public_read_dropoffs"   ON public.dropoff_points     FOR SELECT USING (true);
CREATE POLICY "public_read_hubs"       ON public.fulfillment_centers FOR SELECT USING (true);

-- Seller (verified, pro_role='seller'): own delivery settings
CREATE POLICY "seller_own_settings" ON public.seller_delivery_settings
  FOR ALL TO authenticated
  USING  (seller_id = auth.uid() AND public.is_seller_user())
  WITH CHECK (seller_id = auth.uid() AND public.is_seller_user());

-- Seller: own smart delivery request
CREATE POLICY "seller_own_smart_req" ON public.seller_smart_delivery_requests
  FOR ALL TO authenticated
  USING  (seller_id = auth.uid() AND public.is_seller_user())
  WITH CHECK (seller_id = auth.uid() AND public.is_seller_user());

-- Seller: own items in smart groups
CREATE POLICY "seller_own_items" ON public.smart_delivery_items
  FOR ALL TO authenticated
  USING  (seller_id = auth.uid() AND public.is_seller_user())
  WITH CHECK (seller_id = auth.uid() AND public.is_seller_user());

-- Seller: read groups they belong to (as item seller or as buyer)
CREATE POLICY "seller_read_groups" ON public.smart_delivery_groups
  FOR SELECT TO authenticated USING (
    (buyer_id = auth.uid())
    OR (public.is_seller_user() AND
        EXISTS (SELECT 1 FROM public.smart_delivery_items
                WHERE group_id = id AND seller_id = auth.uid()))
    OR public.is_admin_user()
  );

-- Seller: own pickup requests
CREATE POLICY "seller_own_pickups" ON public.pickup_requests
  FOR ALL TO authenticated
  USING  (seller_id = auth.uid() AND public.is_seller_user())
  WITH CHECK (seller_id = auth.uid() AND public.is_seller_user());

-- Seller: own shipping labels
CREATE POLICY "seller_own_labels" ON public.shipping_labels
  FOR SELECT TO authenticated
  USING (
    (seller_id = auth.uid() AND public.is_seller_user())
    OR public.is_admin_user()
  );

CREATE POLICY "seller_insert_labels" ON public.shipping_labels
  FOR INSERT TO authenticated
  WITH CHECK (seller_id = auth.uid() AND public.is_seller_user());

-- Seller: own fulfillment inventory
CREATE POLICY "seller_own_inventory" ON public.fulfillment_inventory
  FOR ALL TO authenticated
  USING  (seller_id = auth.uid() AND (public.is_seller_user() OR public.is_admin_user()))
  WITH CHECK (seller_id = auth.uid() AND public.is_seller_user());

-- Seller/buyer: read tracking for their groups
CREATE POLICY "read_own_tracking" ON public.delivery_tracking
  FOR SELECT TO authenticated USING (
    EXISTS (
      SELECT 1 FROM public.smart_delivery_groups g
      WHERE g.id = group_id
        AND (g.buyer_id = auth.uid()
             OR (public.is_seller_user() AND
                 EXISTS (SELECT 1 FROM public.smart_delivery_items
                         WHERE group_id = g.id AND seller_id = auth.uid())))
    )
    OR public.is_admin_user()
  );

-- Notifications: own (sellers + buyers receive them)
CREATE POLICY "own_notifications" ON public.delivery_notifications
  FOR ALL TO authenticated
  USING  (recipient_id = auth.uid())
  WITH CHECK (recipient_id = auth.uid());

-- Disputes: reporter is seller or admin reads
CREATE POLICY "own_disputes" ON public.delivery_disputes
  FOR ALL TO authenticated
  USING  (reporter_id = auth.uid() OR public.is_admin_user())
  WITH CHECK (reporter_id = auth.uid() AND public.is_seller_user());

-- Own fulfillment inventory
CREATE POLICY "seller_own_inventory" ON public.fulfillment_inventory
  FOR ALL TO authenticated USING (seller_id = auth.uid() OR public.is_admin_user())
  WITH CHECK (seller_id = auth.uid());

-- Admin: full access to all delivery tables
CREATE POLICY "admin_all_partners"    ON public.delivery_partners    FOR ALL TO authenticated USING (public.is_admin_user()) WITH CHECK (public.is_admin_user());
CREATE POLICY "admin_all_zones"       ON public.delivery_zones       FOR ALL TO authenticated USING (public.is_admin_user()) WITH CHECK (public.is_admin_user());
CREATE POLICY "admin_all_pricing"     ON public.delivery_pricing     FOR ALL TO authenticated USING (public.is_admin_user()) WITH CHECK (public.is_admin_user());
CREATE POLICY "admin_all_rules"       ON public.delivery_rules       FOR ALL TO authenticated USING (public.is_admin_user()) WITH CHECK (public.is_admin_user());
CREATE POLICY "admin_all_smart_reqs"  ON public.seller_smart_delivery_requests FOR ALL TO authenticated USING (public.is_admin_user()) WITH CHECK (public.is_admin_user());
CREATE POLICY "admin_all_pickups"     ON public.pickup_requests      FOR ALL TO authenticated USING (public.is_admin_user()) WITH CHECK (public.is_admin_user());
CREATE POLICY "admin_all_labels"      ON public.shipping_labels      FOR ALL TO authenticated USING (public.is_admin_user()) WITH CHECK (public.is_admin_user());
CREATE POLICY "admin_all_groups"      ON public.smart_delivery_groups FOR ALL TO authenticated USING (public.is_admin_user()) WITH CHECK (public.is_admin_user());
CREATE POLICY "admin_all_events"      ON public.delivery_events      FOR ALL TO authenticated USING (public.is_admin_user()) WITH CHECK (public.is_admin_user());
CREATE POLICY "admin_all_disputes"    ON public.delivery_disputes    FOR ALL TO authenticated USING (public.is_admin_user()) WITH CHECK (public.is_admin_user());

-- System INSERT for events/notifications/labels/tracking
CREATE POLICY "system_insert_events"   ON public.delivery_events   FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "system_insert_notifs"   ON public.delivery_notifications FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "system_insert_labels"   ON public.shipping_labels   FOR INSERT TO authenticated WITH CHECK (seller_id = auth.uid() OR public.is_admin_user());
CREATE POLICY "system_insert_tracking" ON public.delivery_tracking FOR INSERT TO authenticated WITH CHECK (true);
