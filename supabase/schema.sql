-- MedicaClic database schema for Supabase (PostgreSQL)
-- Run this in the Supabase SQL editor (Project > SQL Editor > New query).

create extension if not exists "pgcrypto";

-- ============ PROFILES ============
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null default '',
  email text not null,
  birth_date date,
  gender text,
  role text not null default 'utilisateur',
  adresse text,
  wilaya text,
  photo_url text,
  carte_identite_url text,
  profile_completed boolean not null default false,
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, name, email, birth_date, gender)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'name', ''),
    new.email,
    (new.raw_user_meta_data ->> 'birth_date')::date,
    new.raw_user_meta_data ->> 'gender'
  );
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ============ DOCTORS (public catalog) ============
create table if not exists public.doctors (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  specialty text not null,
  rating numeric(2,1) not null default 0,
  location text not null default '',
  distance numeric(4,1) not null default 0,
  about text not null default '',
  image text
);

-- ============ PRODUCTS (boutique catalog) ============
create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  brand text not null default '',
  category text not null default 'Achat',
  description text not null default '',
  price numeric(10,2) not null,
  original_price numeric(10,2),
  image text,
  rating numeric(2,1) not null default 0,
  review_count int not null default 0,
  seller text not null default '',
  phone text not null default ''
);

-- ============ PROMO OFFERS (boutique banners) ============
create table if not exists public.promo_offers (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  discount_text text not null,
  delivery_text text not null,
  promo_code text not null,
  color_hex text not null default '#1AA88F'
);

-- ============ CART (per user) ============
create table if not exists public.cart_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  product_id uuid not null references public.products (id) on delete cascade,
  quantity int not null default 1,
  created_at timestamptz not null default now(),
  unique (user_id, product_id)
);

-- ============ YEMMA: pain tracking ============
create table if not exists public.pain_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  entry_date date not null default current_date,
  location text not null,
  type text not null,
  duration text not null,
  severity int not null check (severity between 1 and 10)
);

-- ============ YEMMA: baby profile ============
create table if not exists public.baby_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users (id) on delete cascade,
  name text not null,
  birth_date date not null,
  gender text not null default 'Fille',
  weight_kg numeric(5,2),
  weight_delta_kg numeric(5,2),
  height_cm numeric(5,2),
  height_delta_cm numeric(5,2),
  head_circumference text
);

-- ============ YEMMA: vaccines ============
create table if not exists public.vaccines (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  age_label text not null,
  due_date date not null,
  done boolean not null default false,
  due_soon boolean not null default false
);

-- ============ YEMMA: pregnancy info ============
create table if not exists public.pregnancy_info (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users (id) on delete cascade,
  week int not null,
  trimester text not null,
  baby_size_cm numeric(5,2),
  baby_weight_kg numeric(5,2),
  appointment_title text,
  appointment_doctor text,
  appointment_date timestamptz
);

-- ============ YEMMA: daily symptoms ============
create table if not exists public.daily_symptoms (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  symptom text not null,
  log_date date not null default current_date,
  unique (user_id, symptom, log_date)
);

-- ============ YEMMA: community posts ============
create table if not exists public.community_posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid references auth.users (id) on delete set null,
  author_name text not null,
  question text not null,
  likes int not null default 0,
  replies int not null default 0,
  created_at timestamptz not null default now()
);

-- ===================================================================
-- ROW LEVEL SECURITY
-- ===================================================================

alter table public.profiles enable row level security;
alter table public.doctors enable row level security;
alter table public.products enable row level security;
alter table public.promo_offers enable row level security;
alter table public.cart_items enable row level security;
alter table public.pain_entries enable row level security;
alter table public.baby_profiles enable row level security;
alter table public.vaccines enable row level security;
alter table public.pregnancy_info enable row level security;
alter table public.daily_symptoms enable row level security;
alter table public.community_posts enable row level security;

-- Profiles: a user can read/update only their own profile
create policy "profiles_select_own" on public.profiles for select using (auth.uid() = id);
create policy "profiles_update_own" on public.profiles for update using (auth.uid() = id);

-- ============ STORAGE: profile photos & ID cards ============
insert into storage.buckets (id, name, public)
values ('profile-photos', 'profile-photos', true)
on conflict (id) do nothing;

create policy "profile_photos_public_read" on storage.objects for select using (bucket_id = 'profile-photos');
create policy "profile_photos_owner_insert" on storage.objects for insert with check (bucket_id = 'profile-photos' and auth.uid()::text = (storage.foldername(name))[1]);
create policy "profile_photos_owner_update" on storage.objects for update using (bucket_id = 'profile-photos' and auth.uid()::text = (storage.foldername(name))[1]);
create policy "profile_photos_owner_delete" on storage.objects for delete using (bucket_id = 'profile-photos' and auth.uid()::text = (storage.foldername(name))[1]);

-- Public read-only catalogs: anyone (incl. anonymous) can read
create policy "doctors_public_read" on public.doctors for select using (true);
create policy "products_public_read" on public.products for select using (true);
create policy "promo_offers_public_read" on public.promo_offers for select using (true);

-- Cart: each user manages only their own cart
create policy "cart_items_owner_all" on public.cart_items for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Yemma personal data: each user manages only their own rows
create policy "pain_entries_owner_all" on public.pain_entries for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "baby_profiles_owner_all" on public.baby_profiles for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "vaccines_owner_all" on public.vaccines for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "pregnancy_info_owner_all" on public.pregnancy_info for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "daily_symptoms_owner_all" on public.daily_symptoms for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Community posts: everyone authenticated can read, only the author can write/edit/delete their own post
create policy "community_posts_read_all" on public.community_posts for select using (auth.role() = 'authenticated');
create policy "community_posts_insert_own" on public.community_posts for insert with check (auth.uid() = author_id);
create policy "community_posts_update_own" on public.community_posts for update using (auth.uid() = author_id);
create policy "community_posts_delete_own" on public.community_posts for delete using (auth.uid() = author_id);

-- ===================================================================
-- SEED DATA (matches the mock data currently in the app)
-- ===================================================================

insert into public.doctors (name, specialty, rating, location, distance, about, image) values
  ('Dr. Marcus Horizon', 'Cardiologue', 4.7, 'Alexandria, VA', 0.8, 'Specialiste en cardiologie', 'MH'),
  ('Dr. Maria Dona', 'Generaliste', 4.5, 'Alexandria, VA', 1.2, 'Medecin generaliste', 'MD'),
  ('Dr. Stevi', 'Dentiste', 4.3, 'Alexandria, VA', 0.95, 'Dentiste experimente', 'ST'),
  ('Dr. Carly Carl', 'Pneumologue', 4.6, 'Alexandria, VA', 1.5, 'Specialiste respiratoire', 'CC'),
  ('Dr. Miranda', 'Dermatologue', 4.4, 'Alexandria, VA', 1.1, 'Specialiste en dermatologie', 'MI')
on conflict do nothing;

insert into public.products (name, brand, category, description, price, original_price, image, rating, review_count, seller, phone) values
  ('Aspirine 500mg', 'Sanofi DZ', 'Achat', 'Analgésique et anti-inflammatoire utilisé pour soulager les douleurs légères à modérées, la fièvre et les inflammations. Boîte de 20 comprimés.', 150, null, 'ASP', 4.8, 234, 'Pharmacie Centrale', '0555000001'),
  ('Doliprane 1000mg', 'Sanofi', 'Achat', 'Traitement de la douleur et de la fièvre à base de paracétamol. Convient aux adultes et adolescents de plus de 50kg. Boîte de 8 comprimés.', 280, 350, 'DOL', 4.9, 156, 'MedPharm', '0555000002'),
  ('Tensiomètre digital', 'Omron', 'Location', 'Tensiomètre digital de bras pour mesurer la pression artérielle à domicile. Mesure précise et écran de lecture facile. Location à la semaine ou au mois.', 500, 640, 'TEN', 4.6, 89, 'Boutique Médicale DZ', '0555000003'),
  ('Vitamine C 1000mg', 'Bayer', 'Vitamines', 'Complément alimentaire pour renforcer le système immunitaire et réduire la fatigue. Comprimés effervescents, boîte de 20.', 890, null, 'VTC', 4.7, 312, 'Pharmacie Centrale', '0555000004'),
  ('Fauteuil roulant pliable', 'MedEquip', 'Location', 'Fauteuil roulant pliable léger, accoudoirs et repose-pieds réglables. Idéal pour la mobilité à domicile ou en déplacement. Location à la semaine.', 1500, null, 'FRP', 4.4, 41, 'MedPharm', '0555000005'),
  ('Bétadine antiseptique', 'Meda', 'Achat', 'Solution antiseptique et désinfectante pour le traitement des plaies superficielles et la prévention des infections. Flacon de 125ml.', 320, null, 'BET', 4.3, 95, 'Pharmacie Centrale', '0555000006')
on conflict do nothing;

insert into public.promo_offers (title, discount_text, delivery_text, promo_code, color_hex) values
  ('Pharmacie Centrale Algérie', '-20% sur tous les antibiotiques', 'Livraison 24h — Code promo : PC20', 'PC20', '#6C4FE0'),
  ('Vitamines & Compléments', '-30% sur la gamme bien-être', 'Livraison offerte dès 2000 DA', 'VITA30', '#F2994A')
on conflict do nothing;
