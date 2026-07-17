-- MedicaClic — extension profil : poids/taille du patient + membres de la famille
-- À exécuter dans Supabase (Project > SQL Editor > New query), APRÈS profile_extensions.sql.

alter table public.profiles add column if not exists weight_kg numeric(5,2);
alter table public.profiles add column if not exists height_cm numeric(5,2);

create table if not exists public.family_members (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  relation text not null default 'Autre',
  weight_kg numeric(5,2),
  height_cm numeric(5,2),
  blood_type text,
  created_at timestamptz not null default now()
);

create index if not exists family_members_user_idx on public.family_members (user_id, created_at);

alter table public.family_members enable row level security;

drop policy if exists "family_members_owner_all" on public.family_members;
create policy "family_members_owner_all" on public.family_members
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
