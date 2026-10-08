-- Supabase SQL Editor 에서 한 번 실행하세요.
create table if not exists public.books (
  id          bigint generated always as identity primary key,
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title       text not null,
  author      text,
  status      text not null default 'reading' check (status in ('reading','done','wish')),
  start_date  date,
  end_date    date,
  progress    int  not null default 0 check (progress between 0 and 100),
  rating      int  not null default 0 check (rating between 0 and 5),
  memo        text,
  created_at  timestamptz not null default now()
);

alter table public.books enable row level security;

create policy "own books select" on public.books for select using (auth.uid() = user_id);
create policy "own books insert" on public.books for insert with check (auth.uid() = user_id);
create policy "own books update" on public.books for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own books delete" on public.books for delete using (auth.uid() = user_id);
