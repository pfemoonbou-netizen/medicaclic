-- ─────────────────────────────────────────────────────────────────────────────
-- LINCOO – Post Comments Migration
-- Run in Supabase Dashboard → SQL Editor → New query
-- Safe to re-run: all statements use IF NOT EXISTS
-- ─────────────────────────────────────────────────────────────────────────────

-- post_id accepts any uuid (store_posts.id OR products.id) — no FK constraint
CREATE TABLE IF NOT EXISTS public.post_comments (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id    uuid        NOT NULL,
  user_id    uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content    text        NOT NULL CHECK (char_length(content) >= 1),
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.post_comments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "post_comments: public read"  ON public.post_comments;
DROP POLICY IF EXISTS "post_comments: auth insert"  ON public.post_comments;
DROP POLICY IF EXISTS "post_comments: own delete"   ON public.post_comments;

CREATE POLICY "post_comments: public read"
  ON public.post_comments FOR SELECT USING (true);

CREATE POLICY "post_comments: auth insert"
  ON public.post_comments FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL AND user_id = auth.uid());

CREATE POLICY "post_comments: own delete"
  ON public.post_comments FOR DELETE
  USING (user_id = auth.uid());

CREATE INDEX IF NOT EXISTS idx_post_comments_post_id
  ON public.post_comments (post_id, created_at ASC);
