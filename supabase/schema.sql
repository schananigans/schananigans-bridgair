-- Cairn cloud storage. Run this in the Supabase SQL Editor.
-- Every exposed table has row-level security and owner-only policies.

create table if not exists public.entries (
  user_id uuid not null references auth.users(id) on delete cascade,
  entry_date date not null,
  prompt_text text,
  entry_text text not null default '',
  free_write text not null default '',
  tomorrow text,
  memorable text check (memorable in ('no', 'maybe', 'yes')),
  mood jsonb,
  agency smallint check (agency between 1 and 5),
  cairn jsonb,
  saved_at timestamptz not null default now(),
  primary key (user_id, entry_date)
);

-- Also upgrades projects that already created entries from an earlier schema.
alter table public.entries add column if not exists free_write text not null default '';
alter table public.entries add column if not exists tomorrow text;
alter table public.entries add column if not exists memorable text check (memorable in ('no', 'maybe', 'yes'));

alter table public.entries enable row level security;
revoke all on table public.entries from anon, authenticated;
grant select, insert, update, delete on table public.entries to authenticated;

drop policy if exists "Users can read their own entries" on public.entries;
drop policy if exists "Users can add their own entries" on public.entries;
drop policy if exists "Users can edit their own entries" on public.entries;
drop policy if exists "Users can delete their own entries" on public.entries;
create policy "Users can read their own entries"
  on public.entries for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "Users can add their own entries"
  on public.entries for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "Users can edit their own entries"
  on public.entries for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "Users can delete their own entries"
  on public.entries for delete to authenticated
  using ((select auth.uid()) = user_id);

create table if not exists public.journaling_goals (
  user_id uuid primary key references auth.users(id) on delete cascade,
  goal jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.journaling_goals enable row level security;
revoke all on table public.journaling_goals from anon, authenticated;
grant select, insert, update, delete on table public.journaling_goals to authenticated;

drop policy if exists "Users can read their own journaling goal" on public.journaling_goals;
drop policy if exists "Users can add their own journaling goal" on public.journaling_goals;
drop policy if exists "Users can edit their own journaling goal" on public.journaling_goals;
drop policy if exists "Users can delete their own journaling goal" on public.journaling_goals;
create policy "Users can read their own journaling goal"
  on public.journaling_goals for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "Users can add their own journaling goal"
  on public.journaling_goals for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "Users can edit their own journaling goal"
  on public.journaling_goals for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "Users can delete their own journaling goal"
  on public.journaling_goals for delete to authenticated
  using ((select auth.uid()) = user_id);
