-- ============================================================
--  BANNIÈRES PUBLICITAIRES (gérées par l'Admin)
--  L'admin crée une bannière depuis l'app ; tous les utilisateurs
--  la voient dans la boutique. À exécuter dans Supabase → SQL Editor.
-- ============================================================

create table if not exists public.promo_banners (
  id uuid primary key default gen_random_uuid(),
  title text not null default '',
  subtitle text not null default '',
  image_url text,
  color_hex text not null default '#6C5FE0',
  active boolean not null default true,
  created_at timestamptz not null default now()
);

-- Type de média : 'image' ou 'video'
alter table public.promo_banners add column if not exists media_type text not null default 'image';

alter table public.promo_banners enable row level security;

drop policy if exists "promo_banners_public_read" on public.promo_banners;
create policy "promo_banners_public_read" on public.promo_banners for select using (true);

drop policy if exists "promo_banners_admin_insert" on public.promo_banners;
create policy "promo_banners_admin_insert" on public.promo_banners for insert
  with check (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

drop policy if exists "promo_banners_admin_delete" on public.promo_banners;
create policy "promo_banners_admin_delete" on public.promo_banners for delete
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

-- Bucket public pour les images de bannières
insert into storage.buckets (id, name, public) values ('banner-images', 'banner-images', true)
  on conflict (id) do nothing;

drop policy if exists "banner_images_public_read" on storage.objects;
create policy "banner_images_public_read" on storage.objects for select using (bucket_id = 'banner-images');

drop policy if exists "banner_images_admin_insert" on storage.objects;
create policy "banner_images_admin_insert" on storage.objects for insert
  with check (bucket_id = 'banner-images' and exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

-- ------------------------------------------------------------
-- Pour tester : transforme TON compte en admin (mets ton email)
-- update public.profiles set role = 'admin' where email = 'anis123@gmail.com';
-- ------------------------------------------------------------
