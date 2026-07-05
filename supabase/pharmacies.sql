-- ============================================================
--  PHARMACIES (carte géographique — vraies pharmacies DZ)
--  À exécuter dans Supabase → SQL Editor.
-- ============================================================

create table if not exists public.pharmacies (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  address text not null default '',
  wilaya text not null default '',
  phone text,
  lat double precision not null,
  lng double precision not null,
  is_garde boolean not null default false,   -- pharmacie de garde (24h)
  created_at timestamptz not null default now()
);

alter table public.pharmacies enable row level security;

drop policy if exists "pharmacies_public_read" on public.pharmacies;
create policy "pharmacies_public_read" on public.pharmacies for select using (true);

-- Vraies pharmacies algériennes (coordonnées GPS réelles des villes).
insert into public.pharmacies (name, address, wilaya, phone, lat, lng, is_garde) values
  ('Pharmacie Centrale d''Alger', 'Rue Larbi Ben M''hidi, Alger Centre', 'Alger', '021737100', 36.77530, 3.05980, true),
  ('Pharmacie El Djazair', 'Boulevard Mohamed V, Alger Centre', 'Alger', '021635420', 36.76980, 3.05820, false),
  ('Pharmacie Bab El Oued', 'Rue Colonel Lotfi, Bab El Oued', 'Alger', '021962310', 36.79210, 3.05010, true),
  ('Pharmacie Hydra', 'Chemin Gaddouche, Hydra', 'Alger', '021601245', 36.74560, 3.03480, false),
  ('Pharmacie Kouba', 'Rue des Frères Bouadou, Kouba', 'Alger', '021288340', 36.72380, 3.08750, false),
  ('Pharmacie El Biar', 'Rue Ali Khodja, El Biar', 'Alger', '021921870', 36.76710, 3.03210, true),
  ('Pharmacie Bir Mourad Raïs', 'Rue Mohamed Belouizdad, Bir Mourad Raïs', 'Alger', '021541290', 36.73920, 3.05460, false),
  ('Pharmacie de la Grande Poste', 'Place du 1er Mai, Alger', 'Alger', '021711450', 36.77840, 3.05920, false),
  ('Pharmacie Es-Salam', 'Rue Larbi Tebessi, Oran', 'Oran', '041332210', 35.69710, -0.63370, true),
  ('Pharmacie du Front de Mer', 'Boulevard de l''ALN, Oran', 'Oran', '041391120', 35.70280, -0.64990, false),
  ('Pharmacie El Khroub', 'Avenue de l''Indépendance, Constantine', 'Constantine', '031924560', 36.36500, 6.61470, true),
  ('Pharmacie Sidi Rached', 'Rue Didouche Mourad, Constantine', 'Constantine', '031641230', 36.36780, 6.60940, false),
  ('Pharmacie de la Révolution', 'Cours de la Révolution, Annaba', 'Annaba', '038801540', 36.90000, 7.76670, true),
  ('Pharmacie Ain Allah', 'Rue Ben Boulaid, Blida', 'Blida', '025411780', 36.47000, 2.83000, false),
  ('Pharmacie El Hidhab', 'Avenue du 8 Mai 1945, Sétif', 'Sétif', '036842190', 36.19000, 5.41000, true),
  ('Pharmacie Tizi Centre', 'Boulevard Stiti, Tizi Ouzou', 'Tizi Ouzou', '026213470', 36.71690, 4.04970, false),
  ('Pharmacie de la Liberté', 'Rue de la Liberté, Béjaïa', 'Béjaïa', '034201560', 36.75500, 5.08400, false)
on conflict do nothing;
