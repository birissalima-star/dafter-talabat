-- =====================================================================
--  دفتر الطلبيات — إعداد قاعدة البيانات في Supabase
--  انسخي هذا الملف كاملاً، والصقيه في: SQL Editor ← New query ← Run
--  (يمكن تشغيله أكثر من مرة بلا مشكلة)
-- =====================================================================

create extension if not exists pgcrypto with schema extensions;

-- ---------- المستخدمون (الإدارة والبائعات) ----------
create table if not exists public.workers (
  id          bigint generated always as identity primary key,
  full_name   text not null,
  username    text not null unique,
  password    text not null,               -- تُحفظ مشفّرة تلقائياً
  phone       text default '',
  role        text not null default 'Seller' check (role in ('Admin','Manager','Seller')),
  code        text default '',
  status      text not null default 'Active',
  created_at  timestamptz not null default now()
);

-- تشفير كلمة المرور تلقائياً عند الإضافة أو التغيير
create or replace function public.hash_worker_password()
returns trigger language plpgsql
set search_path = public, extensions as $$
begin
  if new.password is not null and new.password !~ '^\$2[abxy]\$' then
    new.password := crypt(new.password, gen_salt('bf'));
  end if;
  return new;
end $$;

drop trigger if exists trg_hash_worker_password on public.workers;
create trigger trg_hash_worker_password
  before insert or update of password on public.workers
  for each row execute function public.hash_worker_password();

-- التحقق من الدخول (يرجع الاسم والدور فقط، وماشي كلمة المرور)
create or replace function public.app_login(p_username text, p_password text)
returns table (full_name text, username text, role text)
language sql security definer
set search_path = public, extensions as $$
  select w.full_name, w.username, w.role
  from public.workers w
  where w.username = p_username
    and w.status <> 'Inactive'
    and w.password = crypt(p_password, w.password);
$$;

-- ---------- الطلبيات ----------
create sequence if not exists public.order_seq;

create table if not exists public.orders (
  id                text primary key default ('D' || lpad(nextval('public.order_seq')::text, 6, '0')),
  created_at        timestamptz not null default now(),
  seller_name       text default '',
  worker_code       text default '',
  customer_name     text default '',
  phone             text default '',
  wilaya            text default '',
  commune           text default '',
  delivery_type     text default 'office',      -- home / office
  promo             text default 'none',        -- none / third_free / free_delivery
  items             jsonb default '{}'::jsonb,  -- الكمية لكل تركيز {"0":1,"1":0,"2":2}
  price             numeric default 0,
  status            text default 'pending',
  notes             jsonb default '[]'::jsonb,  -- التعليقات
  driver_phone      text default '',
  exchange_product  text default '',
  office_maps_link  text default '',
  order_log         text default '',
  hidden            boolean not null default false
);
create index if not exists orders_created_at_idx on public.orders (created_at desc);
create index if not exists orders_seller_idx on public.orders (seller_name);

-- ---------- الإعدادات المشتركة (المنتج، أسعار التوصيل، التحديات) ----------
create table if not exists public.app_settings (
  key         text primary key,
  value       jsonb not null,
  updated_at  timestamptz not null default now()
);

-- ---------- سجل النشاط ----------
create table if not exists public.activity_log (
  id          bigint generated always as identity primary key,
  created_at  timestamptz not null default now(),
  user_name   text,
  action      text,
  order_id    text,
  details     text
);

-- ---------- الصلاحيات ----------
alter table public.workers      enable row level security;
alter table public.orders       enable row level security;
alter table public.app_settings enable row level security;
alter table public.activity_log enable row level security;

drop policy if exists "app access" on public.workers;
drop policy if exists "app access" on public.orders;
drop policy if exists "app access" on public.app_settings;
drop policy if exists "app access" on public.activity_log;
create policy "app access" on public.workers      for all to anon, authenticated using (true) with check (true);
create policy "app access" on public.orders       for all to anon, authenticated using (true) with check (true);
create policy "app access" on public.app_settings for all to anon, authenticated using (true) with check (true);
create policy "app access" on public.activity_log for all to anon, authenticated using (true) with check (true);

-- كلمة المرور لا يمكن قراءتها من الموقع أبداً
revoke all on table public.workers from anon, authenticated;
grant select (id, full_name, username, phone, role, code, status, created_at) on public.workers to anon, authenticated;
grant insert (full_name, username, password, phone, role, code, status) on public.workers to anon, authenticated;
grant update (full_name, password, phone, role, code, status) on public.workers to anon, authenticated;
grant delete on public.workers to anon, authenticated;

grant select, insert, update, delete on public.orders, public.app_settings, public.activity_log to anon, authenticated;
grant usage, select on sequence public.order_seq to anon, authenticated;
grant execute on function public.app_login(text, text) to anon, authenticated;

-- ---------- التحديث المباشر (Realtime) ----------
do $$
begin
  begin
    alter publication supabase_realtime add table public.orders;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table public.app_settings;
  exception when duplicate_object then null;
  end;
end $$;

-- ---------- رسائل التحفيز ----------
create table if not exists public.messages (
  id          bigint generated always as identity primary key,
  created_at  timestamptz not null default now(),
  from_name   text default '',
  to_name     text not null,                  -- اسم البائعة، أو all لكل البائعات
  text        text not null,
  read_by     jsonb not null default '[]'::jsonb
);

alter table public.messages enable row level security;
drop policy if exists "app access" on public.messages;
create policy "app access" on public.messages for all to anon, authenticated using (true) with check (true);
grant select, insert, update, delete on public.messages to anon, authenticated;

do $$
begin
  begin
    alter publication supabase_realtime add table public.messages;
  exception when duplicate_object then null;
  end;
end $$;
