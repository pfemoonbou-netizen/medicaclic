-- MedicaClic — extension du schéma : Services à Domicile + rôle de compte (utilisateur / prestataire)
-- À exécuter dans Supabase (Project > SQL Editor > New query), APRÈS schema.sql.

-- ============ PROFILES: rôle de compte ============
alter table public.profiles add column if not exists role text not null default 'utilisateur';
alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles add constraint profiles_role_check check (role in ('utilisateur', 'prestataire'));

create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, name, email, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'name', ''),
    new.email,
    coalesce(new.raw_user_meta_data ->> 'role', 'utilisateur')
  );
  return new;
end;
$$ language plpgsql security definer;

-- ============ HOME CARE: catégories de service (catalogue public) ============
create table if not exists public.home_care_categories (
  id text primary key,
  name text not null,
  subtitle text not null default '',
  price_from int not null default 0,
  icon_name text not null default 'medical_services_outlined',
  color_hex text not null default '#1AA88F'
);

-- ============ HOME CARE: prestataires ============
create table if not exists public.home_care_providers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users (id) on delete cascade,
  category_id text not null references public.home_care_categories (id),
  name text not null,
  specialty text not null default '',
  price_per_visit int not null default 0,
  rating numeric(2,1) not null default 0,
  review_count int not null default 0,
  distance_km numeric(4,1) not null default 0,
  eta_range text not null default '20-40 min',
  years_experience int not null default 0,
  tags text[] not null default '{}',
  available boolean not null default true,
  phone text not null default '',
  address text not null default '',
  photo_url text not null default '',
  created_at timestamptz not null default now()
);

-- ============ HOME CARE: réservations ============
create table if not exists public.home_care_bookings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  provider_id uuid not null references public.home_care_providers (id) on delete cascade,
  service_type text not null,
  booking_date text not null,
  time_slot text not null,
  address text not null,
  note text not null default '',
  status text not null default 'pending' check (status in ('pending', 'confirmed', 'cancelled', 'completed')),
  created_at timestamptz not null default now()
);

-- ===================================================================
-- ROW LEVEL SECURITY
-- ===================================================================

alter table public.home_care_categories enable row level security;
alter table public.home_care_providers enable row level security;
alter table public.home_care_bookings enable row level security;

create policy "home_care_categories_public_read" on public.home_care_categories for select using (true);

-- Tout le monde peut parcourir les prestataires (catalogue public).
create policy "home_care_providers_public_read" on public.home_care_providers for select using (true);
-- Un prestataire ne gère que sa propre fiche.
create policy "home_care_providers_owner_insert" on public.home_care_providers for insert with check (auth.uid() = user_id);
create policy "home_care_providers_owner_update" on public.home_care_providers for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "home_care_providers_owner_delete" on public.home_care_providers for delete using (auth.uid() = user_id);

-- Un client gère ses propres réservations.
create policy "home_care_bookings_owner_all" on public.home_care_bookings for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
-- Un prestataire voit les réservations qui le concernent.
create policy "home_care_bookings_provider_read" on public.home_care_bookings for select using (
  auth.uid() = (select user_id from public.home_care_providers where id = provider_id)
);

-- ===================================================================
-- SEED DATA (matches the mock data currently in the app)
-- ===================================================================

insert into public.home_care_categories (id, name, subtitle, price_from, icon_name, color_hex) values
  ('visite_medicale', 'Visite médicale', 'Médecin généraliste', 3500, 'person_outline', '#F2994A'),
  ('soins_infirmiers', 'Soins infirmiers', 'Pansements, injections', 1500, 'medical_services_outlined', '#1AA88F'),
  ('reeducation', 'Rééducation', 'Kiné & rééducation motrice', 3000, 'self_improvement_outlined', '#6C4FE0'),
  ('garde_malade', 'Garde malade', 'Aide soignant à domicile', 2000, 'groups_outlined', '#27AE60'),
  ('prises_de_sang', 'Prises de sang', 'Analyses à domicile', 2500, 'bloodtype_outlined', '#EB5757'),
  ('soins_palliatifs', 'Soins palliatifs', 'Accompagnement', 4000, 'favorite_outline', '#EC5A8D')
on conflict (id) do nothing;

insert into public.home_care_providers (category_id, name, specialty, price_per_visit, rating, review_count, distance_km, eta_range, years_experience, tags, available, phone, address, photo_url)
select * from (values
  ('visite_medicale', 'Dr. Mohamed Ben Yahia', 'Médecin généraliste', 3500, 4.9, 127, 1.2, '20-30 min', 15, array['Consultation générale', 'Tension artérielle', 'Piqûres & injections'], true, '0555100001', 'Alger Centre', 'https://i.pravatar.cc/150?img=12'),
  ('reeducation', 'Kamel Boumediene', 'Kinésithérapeute', 3000, 4.8, 192, 2.1, '30-45 min', 12, array['Rééducation motrice', 'Kiné sport', 'Massages thérapeutiques'], false, '0555100002', 'Hydra, Alger', 'https://i.pravatar.cc/150?img=33'),
  ('garde_malade', 'Amina Belhocine', 'Aide soignante', 1800, 4.7, 145, 1.6, '20-35 min', 5, array['Garde malade', 'Soins palliatifs', 'Hygiène patients'], true, '0555100003', 'Kouba, Alger', 'https://i.pravatar.cc/150?img=47'),
  ('soins_infirmiers', 'Fatima Belkhir', 'Infirmière diplômée', 2000, 4.9, 88, 1.8, '15-25 min', 9, array['Injections', 'Pansements', 'Prise de sang'], true, '0555100004', 'Alger Est, Rouiba, Boumerdès', 'https://i.pravatar.cc/150?img=44'),
  ('prises_de_sang', 'Dr. Yacine Saadi', 'Technicien de laboratoire', 2500, 4.6, 64, 2.4, '25-40 min', 8, array['Bilan sanguin', 'Glycémie', 'Analyses à domicile'], true, '0555100005', 'Bab Ezzouar, Alger', 'https://i.pravatar.cc/150?img=51'),
  ('soins_palliatifs', 'Souad Meziane', 'Infirmière en soins palliatifs', 4000, 4.9, 51, 3.0, '30-50 min', 11, array['Accompagnement', 'Soins de confort', 'Soutien familial'], true, '0555100006', 'Birkhadem, Alger', 'https://i.pravatar.cc/150?img=26')
) as seed
where not exists (select 1 from public.home_care_providers);
