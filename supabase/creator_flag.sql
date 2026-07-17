-- MedicaClic — "Devenir créateur" : débloquer les publications sans compte business
-- À exécuter dans Supabase (Project > SQL Editor > New query), APRÈS family_members.sql.

alter table public.profiles add column if not exists is_creator boolean not null default false;
