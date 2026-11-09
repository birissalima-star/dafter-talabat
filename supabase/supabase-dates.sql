-- =====================================================================
--  دفتر الطلبيات — تاريخ الروتور لكل طلبية (باش الحساب يتحسب بالتاريخ)
--  الصقيه في: SQL Editor ← New query ← Run   (مرة وحدة برك)
-- =====================================================================
alter table public.orders add column if not exists returned_at timestamptz;
update public.orders set returned_at = created_at where status = 'returned' and returned_at is null;

create or replace function public.set_returned_at()
returns trigger language plpgsql as $$
begin
  if new.status = 'returned' then
    if tg_op = 'INSERT' or old.status is distinct from 'returned' or new.returned_at is null then
      new.returned_at := now();
    end if;
  else
    new.returned_at := null;
  end if;
  return new;
end $$;

drop trigger if exists trg_returned_at on public.orders;
create trigger trg_returned_at
  before insert or update of status on public.orders
  for each row execute function public.set_returned_at();
