-- =============================================================================
-- PATCH: Restrict Smart Delivery to verified sellers only
-- Run this in Supabase SQL Editor if migration_delivery_system.sql was already applied
-- =============================================================================

-- 1. is_seller_user() helper function
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

-- 2. Drop old policies (no seller role check)
DROP POLICY IF EXISTS "seller_own_settings"  ON public.seller_delivery_settings;
DROP POLICY IF EXISTS "seller_own_smart_req" ON public.seller_smart_delivery_requests;
DROP POLICY IF EXISTS "seller_own_items"     ON public.smart_delivery_items;
DROP POLICY IF EXISTS "seller_read_groups"   ON public.smart_delivery_groups;
DROP POLICY IF EXISTS "seller_own_pickups"   ON public.pickup_requests;
DROP POLICY IF EXISTS "seller_own_labels"    ON public.shipping_labels;
DROP POLICY IF EXISTS "seller_own_inventory" ON public.fulfillment_inventory;
DROP POLICY IF EXISTS "read_own_tracking"    ON public.delivery_tracking;
DROP POLICY IF EXISTS "own_disputes"         ON public.delivery_disputes;
DROP POLICY IF EXISTS "system_insert_labels" ON public.shipping_labels;

-- 3. Re-create policies with is_seller_user() check

CREATE POLICY "seller_own_settings" ON public.seller_delivery_settings
  FOR ALL TO authenticated
  USING  (seller_id = auth.uid() AND public.is_seller_user())
  WITH CHECK (seller_id = auth.uid() AND public.is_seller_user());

CREATE POLICY "seller_own_smart_req" ON public.seller_smart_delivery_requests
  FOR ALL TO authenticated
  USING  (seller_id = auth.uid() AND public.is_seller_user())
  WITH CHECK (seller_id = auth.uid() AND public.is_seller_user());

CREATE POLICY "seller_own_items" ON public.smart_delivery_items
  FOR ALL TO authenticated
  USING  (seller_id = auth.uid() AND public.is_seller_user())
  WITH CHECK (seller_id = auth.uid() AND public.is_seller_user());

CREATE POLICY "seller_read_groups" ON public.smart_delivery_groups
  FOR SELECT TO authenticated USING (
    (buyer_id = auth.uid())
    OR (public.is_seller_user() AND
        EXISTS (SELECT 1 FROM public.smart_delivery_items
                WHERE group_id = id AND seller_id = auth.uid()))
    OR public.is_admin_user()
  );

CREATE POLICY "seller_own_pickups" ON public.pickup_requests
  FOR ALL TO authenticated
  USING  (seller_id = auth.uid() AND public.is_seller_user())
  WITH CHECK (seller_id = auth.uid() AND public.is_seller_user());

CREATE POLICY "seller_own_labels" ON public.shipping_labels
  FOR SELECT TO authenticated
  USING (
    (seller_id = auth.uid() AND public.is_seller_user())
    OR public.is_admin_user()
  );

CREATE POLICY "seller_insert_labels" ON public.shipping_labels
  FOR INSERT TO authenticated
  WITH CHECK (seller_id = auth.uid() AND public.is_seller_user());

CREATE POLICY "seller_own_inventory" ON public.fulfillment_inventory
  FOR ALL TO authenticated
  USING  (seller_id = auth.uid() AND (public.is_seller_user() OR public.is_admin_user()))
  WITH CHECK (seller_id = auth.uid() AND public.is_seller_user());

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

CREATE POLICY "own_notifications" ON public.delivery_notifications
  FOR ALL TO authenticated
  USING  (recipient_id = auth.uid())
  WITH CHECK (recipient_id = auth.uid());

CREATE POLICY "own_disputes" ON public.delivery_disputes
  FOR ALL TO authenticated
  USING  (reporter_id = auth.uid() OR public.is_admin_user())
  WITH CHECK (reporter_id = auth.uid() AND public.is_seller_user());

CREATE POLICY "system_insert_labels" ON public.shipping_labels
  FOR INSERT TO authenticated
  WITH CHECK (seller_id = auth.uid() AND public.is_seller_user());

CREATE POLICY "system_insert_tracking" ON public.delivery_tracking
  FOR INSERT TO authenticated WITH CHECK (true);
