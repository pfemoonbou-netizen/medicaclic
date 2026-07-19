-- MedicaClic — vendeurs : publication d'articles et demandes d'achat
-- À exécuter dans Supabase (Project > SQL Editor > New query), APRÈS creator_flag.sql.

-- ============ PRODUCTS: lien vers le vendeur qui publie ============
alter table public.products add column if not exists seller_id uuid references auth.users (id) on delete set null;

drop policy if exists "products_seller_insert" on public.products;
drop policy if exists "products_seller_update" on public.products;
drop policy if exists "products_seller_delete" on public.products;

create policy "products_seller_insert" on public.products for insert with check (auth.uid() = seller_id);
create policy "products_seller_update" on public.products for update using (auth.uid() = seller_id) with check (auth.uid() = seller_id);
create policy "products_seller_delete" on public.products for delete using (auth.uid() = seller_id);

-- ============ PRODUCT REQUESTS: demandes des acheteurs aux vendeurs ============
create table if not exists public.product_requests (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products (id) on delete cascade,
  product_name text not null default '',
  seller_id uuid not null references auth.users (id) on delete cascade,
  buyer_id uuid not null references auth.users (id) on delete cascade,
  buyer_name text not null default '',
  buyer_phone text not null default '',
  message text not null default '',
  status text not null default 'pending' check (status in ('pending', 'accepted', 'declined')),
  created_at timestamptz not null default now()
);

create index if not exists product_requests_seller_idx on public.product_requests (seller_id, created_at desc);

alter table public.product_requests enable row level security;

drop policy if exists "product_requests_read_own" on public.product_requests;
drop policy if exists "product_requests_buyer_insert" on public.product_requests;
drop policy if exists "product_requests_seller_update" on public.product_requests;

create policy "product_requests_read_own" on public.product_requests for select using (auth.uid() = seller_id or auth.uid() = buyer_id);
create policy "product_requests_buyer_insert" on public.product_requests for insert with check (auth.uid() = buyer_id);
create policy "product_requests_seller_update" on public.product_requests for update using (auth.uid() = seller_id) with check (auth.uid() = seller_id);
