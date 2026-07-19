-- MedicaClic — demandes vendeur : adresse client + suivi du paiement
-- À exécuter dans Supabase (Project > SQL Editor > New query), APRÈS seller_products.sql.

alter table public.product_requests add column if not exists buyer_address text not null default '';
alter table public.product_requests add column if not exists payment_received boolean not null default false;
