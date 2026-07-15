-- MedicaClic — extension du profil utilisateur : bio, groupe sanguin, compte pro, publications
-- À exécuter dans Supabase (Project > SQL Editor > New query), APRÈS schema.sql et home_care_schema.sql.

-- ============ PROFILES: bio, infos médicales, infos boutique ============
alter table public.profiles add column if not exists bio text not null default '';
alter table public.profiles add column if not exists blood_type text;
alter table public.profiles add column if not exists shop_name text;
alter table public.profiles add column if not exists shop_phone text;
alter table public.profiles add column if not exists shop_bio text;

alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles add constraint profiles_role_check
  check (role in ('utilisateur', 'prestataire', 'vendeur', 'medecin', 'patient', 'admin'));

-- ============ PUBLICATIONS (page profil des comptes pro) ============
create table if not exists public.user_posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  content text not null default '',
  image_url text,
  created_at timestamptz not null default now()
);

create index if not exists user_posts_user_idx on public.user_posts (user_id, created_at desc);

alter table public.user_posts enable row level security;

drop policy if exists "user_posts_read_all" on public.user_posts;
drop policy if exists "user_posts_owner_insert" on public.user_posts;
drop policy if exists "user_posts_owner_update" on public.user_posts;
drop policy if exists "user_posts_owner_delete" on public.user_posts;

create policy "user_posts_read_all" on public.user_posts for select using (true);
create policy "user_posts_owner_insert" on public.user_posts for insert with check (auth.uid() = user_id);
create policy "user_posts_owner_update" on public.user_posts for update using (auth.uid() = user_id);
create policy "user_posts_owner_delete" on public.user_posts for delete using (auth.uid() = user_id);
