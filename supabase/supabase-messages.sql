-- =====================================================================
--  دفتر الطلبيات — إضافة رسائل التحفيز
--  الصقيه في: SQL Editor ← New query ← Run   (مرة وحدة برك)
-- =====================================================================
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
