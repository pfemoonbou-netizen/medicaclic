-- ═══════════════════════════════════════════════════════════════════════════
-- LINCOO — Row Level Security Policies
-- Apply in Supabase SQL editor.  Run once; re-run is idempotent (DROP IF EXISTS).
-- ═══════════════════════════════════════════════════════════════════════════

-- ── Helper function: verified role check ────────────────────────────────────

CREATE OR REPLACE FUNCTION auth.is_verified_pro(required_role text)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles
    WHERE id            = auth.uid()
      AND pro_role      = required_role
      AND pro_status    = 'verified'
  );
$$;

-- ── profiles ────────────────────────────────────────────────────────────────

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "profiles: public read"   ON profiles;
DROP POLICY IF EXISTS "profiles: own write"     ON profiles;
DROP POLICY IF EXISTS "profiles: own insert"    ON profiles;

-- Anyone can read any profile (needed for store pages, follower lists, etc.)
CREATE POLICY "profiles: public read"
  ON profiles FOR SELECT
  USING (true);

-- Users can only update their own row
CREATE POLICY "profiles: own write"
  ON profiles FOR UPDATE
  USING (id = auth.uid());

-- Users can insert only their own row (created on sign-up)
CREATE POLICY "profiles: own insert"
  ON profiles FOR INSERT
  WITH CHECK (id = auth.uid());

-- ── posts ───────────────────────────────────────────────────────────────────

ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "posts: public read"      ON posts;
DROP POLICY IF EXISTS "posts: verified create"  ON posts;
DROP POLICY IF EXISTS "posts: own update"       ON posts;
DROP POLICY IF EXISTS "posts: own delete"       ON posts;

-- Published posts are readable by everyone
CREATE POLICY "posts: public read"
  ON posts FOR SELECT
  USING (status = 'published' OR author_id = auth.uid());

-- Only verified seller / creator / company can create posts
CREATE POLICY "posts: verified create"
  ON posts FOR INSERT
  WITH CHECK (
    auth.is_verified_pro('seller')  OR
    auth.is_verified_pro('creator') OR
    auth.is_verified_pro('company')
  );

CREATE POLICY "posts: own update"
  ON posts FOR UPDATE
  USING (author_id = auth.uid());

CREATE POLICY "posts: own delete"
  ON posts FOR DELETE
  USING (author_id = auth.uid());

-- ── products ────────────────────────────────────────────────────────────────

ALTER TABLE products ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "products: public read"     ON products;
DROP POLICY IF EXISTS "products: seller create"   ON products;
DROP POLICY IF EXISTS "products: seller manage"   ON products;

CREATE POLICY "products: public read"
  ON products FOR SELECT
  USING (true);

-- Only verified sellers can create / update / delete products
CREATE POLICY "products: seller create"
  ON products FOR INSERT
  WITH CHECK (auth.is_verified_pro('seller'));

CREATE POLICY "products: seller manage"
  ON products FOR ALL
  USING (
    seller_id = auth.uid() AND
    auth.is_verified_pro('seller')
  );

-- ── ad_campaigns ────────────────────────────────────────────────────────────

ALTER TABLE ad_campaigns ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "ad_campaigns: active read"    ON ad_campaigns;
DROP POLICY IF EXISTS "ad_campaigns: company create" ON ad_campaigns;
DROP POLICY IF EXISTS "ad_campaigns: own manage"     ON ad_campaigns;

-- Everyone can see active campaigns (for the home banner)
CREATE POLICY "ad_campaigns: active read"
  ON ad_campaigns FOR SELECT
  USING (status = 'active' OR company_id = auth.uid());

-- Only verified company and seller accounts can create campaigns
CREATE POLICY "ad_campaigns: company create"
  ON ad_campaigns FOR INSERT
  WITH CHECK (auth.is_verified_pro('company') OR auth.is_verified_pro('seller'));

-- Companies and sellers can only manage their own campaigns
CREATE POLICY "ad_campaigns: own manage"
  ON ad_campaigns FOR ALL
  USING (
    company_id = auth.uid() AND
    (auth.is_verified_pro('company') OR auth.is_verified_pro('seller'))
  );

-- Enable Realtime for ad_campaigns
alter publication supabase_realtime add table ad_campaigns;

-- ── orders ──────────────────────────────────────────────────────────────────

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "orders: buyer read"   ON orders;
DROP POLICY IF EXISTS "orders: buyer create" ON orders;
DROP POLICY IF EXISTS "orders: seller read"  ON orders;

-- Buyers see their own orders
CREATE POLICY "orders: buyer read"
  ON orders FOR SELECT
  USING (buyer_id = auth.uid());

-- Any authenticated user can place an order
CREATE POLICY "orders: buyer create"
  ON orders FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- Sellers can read orders that include their products
CREATE POLICY "orders: seller read"
  ON orders FOR SELECT
  USING (
    seller_id = auth.uid() AND
    auth.is_verified_pro('seller')
  );

-- ── likes / saves / follows (interaction tables) ─────────────────────────────

-- These tables are generally: any authenticated user can interact.
-- Adjust table names to match your schema.

ALTER TABLE post_likes   ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_saves   ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_follows ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "post_likes: auth crud"   ON post_likes;
DROP POLICY IF EXISTS "post_saves: auth crud"   ON post_saves;
DROP POLICY IF EXISTS "user_follows: auth crud" ON user_follows;

CREATE POLICY "post_likes: auth crud"
  ON post_likes FOR ALL
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "post_saves: auth crud"
  ON post_saves FOR ALL
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "user_follows: auth crud"
  ON user_follows FOR ALL
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (follower_id = auth.uid());
