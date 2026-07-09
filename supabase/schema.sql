-- ─────────────────────────────────────────────────────────────────────────────
-- LINCOO – Supabase Schema
-- Run this in the Supabase SQL Editor (Dashboard > SQL Editor > New query)
-- ─────────────────────────────────────────────────────────────────────────────

-- ── Profiles ─────────────────────────────────────────────────────────────────
-- One row per auth.users row. Created manually at sign-up (no trigger).

create table if not exists public.profiles (
  id                   uuid primary key references auth.users(id) on delete cascade,
  email                text,
  full_name            text,
  nom_complet          text,
  avatar_url           text,
  pro_role             text not null default 'none',
  pro_status           text not null default 'none',
  onboarding_complete  boolean not null default false,
  is_admin             boolean not null default false,
  store_name           text,
  wilaya               text,
  category             text,
  kyc_cin_url          text,
  kyc_selfie_url       text,
  created_at           timestamptz not null default now()
);

-- Safe migration: add any missing columns to an existing profiles table
alter table public.profiles add column if not exists store_name     text;
alter table public.profiles add column if not exists wilaya         text;
alter table public.profiles add column if not exists category       text;
alter table public.profiles add column if not exists kyc_cin_url    text;
alter table public.profiles add column if not exists kyc_selfie_url text;
alter table public.profiles add column if not exists is_admin       boolean not null default false;
alter table public.profiles add column if not exists nom_complet     text;
alter table public.profiles add column if not exists email           text;
alter table public.profiles add column if not exists telephone          text;
alter table public.profiles add column if not exists contact_links      jsonb not null default '{}'::jsonb;
-- Onboarding extra fields (saved during registration)
alter table public.profiles add column if not exists bio               text;
alter table public.profiles add column if not exists address           text;
alter table public.profiles add column if not exists business_size     text;
alter table public.profiles add column if not exists username_requested text;
alter table public.profiles add column if not exists subcategory       text;
alter table public.profiles add column if not exists niches            text[] default '{}';
alter table public.profiles add column if not exists instagram_url     text;
alter table public.profiles add column if not exists tiktok_url        text;
alter table public.profiles add column if not exists birth_date        date;
alter table public.profiles add column if not exists gender            text; -- 'female' | 'male'

-- ── Store Blocks ──────────────────────────────────────────────────────────────

create table if not exists public.store_blocks (
  store_id        uuid not null references public.stores(id)  on delete cascade,
  blocked_user_id uuid not null references auth.users(id)     on delete cascade,
  created_at      timestamptz not null default now(),
  primary key (store_id, blocked_user_id)
);

alter table public.store_blocks enable row level security;
create policy "blocks_owner_read"   on public.store_blocks for select using (
  auth.uid() = (select owner_id from public.stores where id = store_id)
);
create policy "blocks_owner_manage" on public.store_blocks for all using (
  auth.uid() = (select owner_id from public.stores where id = store_id)
);

-- ── Stores ──────────────────────────────────────────────────────────────────

create table if not exists public.stores (
  id              uuid primary key default gen_random_uuid(),
  owner_id        uuid not null references auth.users(id) on delete cascade,
  store_name      text not null,
  username        text unique,
  logo_url        text,
  cover_url       text,
  bio             text,
  address         text,
  city            text,
  wilaya          text,
  category        text,
  subcategories   text[]   default '{}',
  website         text,
  social_links    jsonb    default '{}'::jsonb,
  contact_links   jsonb    default '{}'::jsonb,
  opening_hours   jsonb    default '{}'::jsonb,
  business_size   text,
  followers_count int      not null default 0,
  products_count  int      not null default 0,
  posts_count     int      not null default 0,
  reels_count     int      not null default 0,
  stories_count   int      not null default 0,
  total_sales     int      not null default 0,
  rating          numeric(3,2) default 0,
  reviews_count   int      not null default 0,
  is_verified     boolean  not null default false,
  created_at      timestamptz not null default now()
);

alter table public.stores enable row level security;

create policy "stores_public_read"   on public.stores for select using (true);
create policy "stores_owner_insert"  on public.stores for insert with check (auth.uid() = owner_id);
create policy "stores_owner_update"  on public.stores for update using (auth.uid() = owner_id);
create policy "stores_owner_delete"  on public.stores for delete using (auth.uid() = owner_id);

-- ── Products ─────────────────────────────────────────────────────────────────

create table if not exists public.products (
  id           uuid primary key default gen_random_uuid(),
  store_id     uuid not null references public.stores(id) on delete cascade,
  name         text not null,
  description  text,
  price        numeric(10,2) not null,
  promo_price  numeric(10,2),
  images       text[] default '{}',
  category     text,
  subcategory  text,
  available    boolean not null default true,
  sold_count   int not null default 0,
  rating       numeric(3,2) default 0,
  reviews_count int not null default 0,
  created_at   timestamptz not null default now()
);

alter table public.products enable row level security;

create policy "products_public_read" on public.products for select using (true);
create policy "products_store_owner" on public.products for all using (
  auth.uid() = (select owner_id from public.stores where id = store_id)
);

-- trigger: update products_count on stores
create or replace function public.update_store_products_count()
returns trigger language plpgsql as $$
begin
  if TG_OP = 'INSERT' then
    update public.stores set products_count = products_count + 1 where id = NEW.store_id;
  elsif TG_OP = 'DELETE' then
    update public.stores set products_count = greatest(0, products_count - 1) where id = OLD.store_id;
  end if;
  return coalesce(NEW, OLD);
end;
$$;

create or replace trigger trg_products_count
after insert or delete on public.products
for each row execute function public.update_store_products_count();

-- ── Posts (publications + reels + stories) ────────────────────────────────────

create table if not exists public.store_posts (
  id             uuid primary key default gen_random_uuid(),
  store_id       uuid not null references public.stores(id) on delete cascade,
  post_type      text not null check (post_type in ('classic','commercial','reel','story')),
  caption        text,
  media_urls     text[] default '{}',
  cover_url      text,
  product_id     uuid references public.products(id) on delete set null,
  price          numeric(10,2),
  promo_price    numeric(10,2),
  hashtags       text[] default '{}',
  location       text,
  likes_count    int not null default 0,
  comments_count int not null default 0,
  views_count    int not null default 0,
  expires_at     timestamptz,  -- for stories: created_at + 24h
  created_at     timestamptz not null default now()
);

alter table public.store_posts enable row level security;

create policy "posts_public_read" on public.store_posts for select using (
  (post_type != 'story') or (expires_at is null) or (expires_at > now())
);
create policy "posts_store_owner" on public.store_posts for all using (
  auth.uid() = (select owner_id from public.stores where id = store_id)
);

-- trigger: update posts_count / reels_count on stores
create or replace function public.update_store_posts_count()
returns trigger language plpgsql as $$
begin
  if TG_OP = 'INSERT' then
    if NEW.post_type = 'reel' then
      update public.stores set reels_count = reels_count + 1 where id = NEW.store_id;
    elsif NEW.post_type != 'story' then
      update public.stores set posts_count = posts_count + 1 where id = NEW.store_id;
    else
      update public.stores set stories_count = stories_count + 1 where id = NEW.store_id;
    end if;
  elsif TG_OP = 'DELETE' then
    if OLD.post_type = 'reel' then
      update public.stores set reels_count = greatest(0, reels_count - 1) where id = OLD.store_id;
    elsif OLD.post_type != 'story' then
      update public.stores set posts_count = greatest(0, posts_count - 1) where id = OLD.store_id;
    else
      update public.stores set stories_count = greatest(0, stories_count - 1) where id = OLD.store_id;
    end if;
  end if;
  return coalesce(NEW, OLD);
end;
$$;

create or replace trigger trg_posts_count
after insert or delete on public.store_posts
for each row execute function public.update_store_posts_count();

-- ── Post Likes ────────────────────────────────────────────────────────────────

create table if not exists public.post_likes (
  user_id  uuid not null references auth.users(id) on delete cascade,
  post_id  uuid not null references public.store_posts(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, post_id)
);

alter table public.post_likes enable row level security;
create policy "likes_public_read"  on public.post_likes for select using (true);
create policy "likes_user_manage"  on public.post_likes for all using (auth.uid() = user_id);

create or replace function public.toggle_post_like(p_post_id uuid)
returns boolean language plpgsql security definer as $$
declare
  already_liked boolean;
begin
  select exists(select 1 from public.post_likes where user_id = auth.uid() and post_id = p_post_id)
    into already_liked;
  if already_liked then
    delete from public.post_likes where user_id = auth.uid() and post_id = p_post_id;
    update public.store_posts set likes_count = greatest(0, likes_count - 1) where id = p_post_id;
    return false;
  else
    insert into public.post_likes (user_id, post_id) values (auth.uid(), p_post_id);
    update public.store_posts set likes_count = likes_count + 1 where id = p_post_id;
    return true;
  end if;
end;
$$;

-- ── Store Follows ─────────────────────────────────────────────────────────────

create table if not exists public.store_follows (
  follower_id uuid not null references auth.users(id) on delete cascade,
  store_id    uuid not null references public.stores(id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (follower_id, store_id)
);

alter table public.store_follows enable row level security;
create policy "follows_public_read"  on public.store_follows for select using (true);
create policy "follows_user_manage"  on public.store_follows for all using (auth.uid() = follower_id);

create or replace function public.follow_store(p_store_id uuid)
returns void language plpgsql security definer as $$
begin
  insert into public.store_follows (follower_id, store_id) values (auth.uid(), p_store_id)
    on conflict do nothing;
  update public.stores set followers_count = followers_count + 1 where id = p_store_id;
end;
$$;

create or replace function public.unfollow_store(p_store_id uuid)
returns void language plpgsql security definer as $$
begin
  delete from public.store_follows where follower_id = auth.uid() and store_id = p_store_id;
  update public.stores set followers_count = greatest(0, followers_count - 1) where id = p_store_id;
end;
$$;

-- ── Notifications ─────────────────────────────────────────────────────────────

create table if not exists public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  store_id   uuid references public.stores(id) on delete cascade,
  post_id    uuid references public.store_posts(id) on delete cascade,
  type       text not null, -- order|follow|comment|like|message|review|sale
  title      text,
  message    text,
  is_read    boolean not null default false,
  metadata   jsonb default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.notifications enable row level security;
create policy "notif_user_read"   on public.notifications for select using (auth.uid() = user_id);
create policy "notif_user_manage" on public.notifications for all using (auth.uid() = user_id);

-- ── Orders ────────────────────────────────────────────────────────────────────

create table if not exists public.orders (
  id           uuid primary key default gen_random_uuid(),
  buyer_id     uuid not null references auth.users(id) on delete set null,
  store_id     uuid not null references public.stores(id) on delete cascade,
  product_id   uuid references public.products(id) on delete set null,
  status       text not null default 'pending'
                 check (status in ('pending','confirmed','shipped','delivered','cancelled','refunded')),
  quantity     int not null default 1,
  unit_price   numeric(10,2) not null,
  total_price  numeric(10,2) not null,
  address      text,
  wilaya       text,
  notes        text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

alter table public.orders enable row level security;
create policy "orders_buyer_read"  on public.orders for select using (auth.uid() = buyer_id);
create policy "orders_seller_read" on public.orders for select using (
  auth.uid() = (select owner_id from public.stores where id = store_id)
);
create policy "orders_buyer_insert" on public.orders for insert with check (auth.uid() = buyer_id);
create policy "orders_seller_update" on public.orders for update using (
  auth.uid() = (select owner_id from public.stores where id = store_id)
);

-- ── Store Reviews ─────────────────────────────────────────────────────────────

create table if not exists public.store_reviews (
  id         uuid primary key default gen_random_uuid(),
  store_id   uuid references public.stores(id) on delete set null,
  reviewer_id uuid not null references auth.users(id) on delete cascade,
  order_id   uuid references public.orders(id) on delete set null,
  rating     int not null check (rating between 1 and 5),
  comment    text,
  photos     text[] default '{}',
  created_at timestamptz not null default now(),
  unique (reviewer_id, coalesce(store_id, order_id))
);

create table if not exists public.product_reviews (
  id           uuid primary key default gen_random_uuid(),
  buyer_id     uuid not null references auth.users(id) on delete cascade,
  store_id     uuid references public.stores(id) on delete set null,
  order_id     uuid references public.orders(id) on delete set null,
  product_id   uuid references public.products(id) on delete set null,
  product_name text,
  rating       int not null check (rating between 1 and 5),
  comment      text,
  photos       text[] default '{}',
  created_at   timestamptz not null default now()
);

alter table public.store_reviews enable row level security;
create policy "reviews_public_read"  on public.store_reviews for select using (true);
create policy "reviews_user_insert"  on public.store_reviews for insert with check (auth.uid() = reviewer_id);
create policy "reviews_user_update"  on public.store_reviews for update using (auth.uid() = reviewer_id);

alter table public.product_reviews enable row level security;
create policy "product_reviews_public_read"  on public.product_reviews for select using (true);
create policy "product_reviews_user_insert"  on public.product_reviews for insert with check (auth.uid() = buyer_id);
create policy "product_reviews_user_update"  on public.product_reviews for update using (auth.uid() = buyer_id);

-- update store rating trigger
create or replace function public.update_store_rating()
returns trigger language plpgsql as $$
declare
  avg_rating numeric;
  total_reviews int;
begin
  select avg(rating)::numeric(3,2), count(*)
    into avg_rating, total_reviews
    from public.store_reviews
    where store_id = coalesce(NEW.store_id, OLD.store_id);
  update public.stores
    set rating = coalesce(avg_rating, 0), reviews_count = total_reviews
    where id = coalesce(NEW.store_id, OLD.store_id);
  return coalesce(NEW, OLD);
end;
$$;

create or replace trigger trg_store_rating
after insert or update or delete on public.store_reviews
for each row execute function public.update_store_rating();

-- ── Ad Campaigns ─────────────────────────────────────────────────────────────

create table if not exists public.ad_campaigns (
  id               uuid primary key default gen_random_uuid(),
  company_id       uuid not null references auth.users(id) on delete cascade,
  title            text not null,
  description      text,
  image_url        text,
  cta_label        text,
  cta_route        text,
  status           text not null default 'draft'
                     check (status in ('draft','submitted','inReview','approved','rejected','active','ended')),
  budget_dzd       int not null default 0,
  start_date       date,
  end_date         date,
  placement        text not null default 'home_banner',
  payment_method   text check (payment_method in ('ccp','baridimob','virement','carte')),
  created_at       timestamptz not null default now()
);

alter table public.ad_campaigns enable row level security;

create policy "campaigns_public_read" on public.ad_campaigns
  for select using (status in ('approved','active'));

create policy "campaigns_owner_all" on public.ad_campaigns
  for all using (auth.uid() = company_id);

create policy "campaigns_admin_update" on public.ad_campaigns
  for update using (
    exists (select 1 from public.profiles where id = auth.uid() and is_admin = true)
  );

-- Enable Realtime for ad_campaigns
alter publication supabase_realtime add table ad_campaigns;

-- ── Product extra columns (variantes avec qty, stock, offre) ────────────────
-- size_variants: [{size:'M', qty:10}, ...]   — qty=0 → affiché "Out of Stock"
alter table public.products add column if not exists size_variants  jsonb  default '[]'::jsonb;
-- color_variants: [{name:'Noir', hex:'#1A1A1A', qty:8}, ...]
alter table public.products add column if not exists color_variants jsonb  default '[]'::jsonb;
alter table public.products add column if not exists stock_qty      int;
alter table public.products add column if not exists offer_tag      text;

-- ── Storage buckets ──────────────────────────────────────────────────────────
-- Bucket public pour les images produits
insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do nothing;

-- Lecture publique
create policy "product-images public read"
  on storage.objects for select
  using (bucket_id = 'product-images');

-- Upload autorisé aux utilisateurs connectés
create policy "product-images auth upload"
  on storage.objects for insert
  with check (bucket_id = 'product-images' and auth.uid() is not null);

-- Mise à jour / suppression par le propriétaire du fichier
create policy "product-images owner update"
  on storage.objects for update
  using (bucket_id = 'product-images' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "product-images owner delete"
  on storage.objects for delete
  using (bucket_id = 'product-images' and auth.uid()::text = (storage.foldername(name))[1]);

-- ── Indexes ───────────────────────────────────────────────────────────────────

create index if not exists idx_stores_owner    on public.stores(owner_id);
create index if not exists idx_stores_username on public.stores(username);
create index if not exists idx_products_store  on public.products(store_id);
create index if not exists idx_posts_store     on public.store_posts(store_id);
create index if not exists idx_posts_type      on public.store_posts(post_type);
create index if not exists idx_follows_store   on public.store_follows(store_id);
create index if not exists idx_notif_user      on public.notifications(user_id, is_read);
create index if not exists idx_orders_store    on public.orders(store_id, status);
create index if not exists idx_orders_buyer    on public.orders(buyer_id);
