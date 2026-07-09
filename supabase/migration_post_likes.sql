-- ─────────────────────────────────────────────────────────────────────────────
-- LINCOO – Post Likes Migration
-- Run in Supabase Dashboard → SQL Editor → New query
-- Safe to re-run: all statements use IF NOT EXISTS / OR REPLACE
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.post_likes (
  post_id    uuid NOT NULL,
  user_id    uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (post_id, user_id)
);

ALTER TABLE public.post_likes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "post_likes: public read"  ON public.post_likes;
DROP POLICY IF EXISTS "post_likes: auth insert"  ON public.post_likes;
DROP POLICY IF EXISTS "post_likes: own delete"   ON public.post_likes;

CREATE POLICY "post_likes: public read"
  ON public.post_likes FOR SELECT USING (true);

CREATE POLICY "post_likes: auth insert"
  ON public.post_likes FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL AND user_id = auth.uid());

CREATE POLICY "post_likes: own delete"
  ON public.post_likes FOR DELETE
  USING (user_id = auth.uid());

-- Trigger: keep store_posts.likes_count in sync
CREATE OR REPLACE FUNCTION public.sync_post_likes_count()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_post_id uuid;
BEGIN
  v_post_id := COALESCE(NEW.post_id, OLD.post_id);
  UPDATE public.store_posts
  SET likes_count = (
    SELECT COUNT(*) FROM public.post_likes WHERE post_id = v_post_id
  )
  WHERE id = v_post_id;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_post_likes ON public.post_likes;
CREATE TRIGGER trg_sync_post_likes
  AFTER INSERT OR DELETE ON public.post_likes
  FOR EACH ROW EXECUTE FUNCTION public.sync_post_likes_count();

-- Trigger: keep store_posts.comments_count in sync
CREATE OR REPLACE FUNCTION public.sync_post_comments_count()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_post_id uuid;
BEGIN
  v_post_id := COALESCE(NEW.post_id, OLD.post_id);
  UPDATE public.store_posts
  SET comments_count = (
    SELECT COUNT(*) FROM public.post_comments WHERE post_id = v_post_id
  )
  WHERE id = v_post_id;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_post_comments ON public.post_comments;
CREATE TRIGGER trg_sync_post_comments
  AFTER INSERT OR DELETE ON public.post_comments
  FOR EACH ROW EXECUTE FUNCTION public.sync_post_comments_count();

-- Backfill current comment counts
UPDATE public.store_posts sp
SET comments_count = (
  SELECT COUNT(*) FROM public.post_comments pc WHERE pc.post_id = sp.id
);
