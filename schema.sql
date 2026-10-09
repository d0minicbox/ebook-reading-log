-- 이북 독서기록 DB 설정
-- Supabase 대시보드 > SQL Editor 에 붙여넣고 실행하세요. 여러 번 실행해도 안전합니다.
-- 새 프로젝트에서도, 이미 쓰던 프로젝트에서도 같은 구조가 됩니다.

-- 1) 책 테이블
create table if not exists public.books (
  id          bigint generated always as identity primary key,
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title       text not null,
  author      text,
  status      text not null default 'reading',   -- reading | done | dropped | wish
  start_date  date,                              -- 시작일 (캘린더에 시작일~완독일 매일 표시)
  end_date    date,                              -- 완독일(읽은 날)
  progress    int  not null default 0,
  pages       int  not null default 0,
  ridi        text,                              -- 리디북스 책 번호 (ridibooks.com/books/번호)
  cover_days  jsonb,                             -- 날짜별 이미지 { "2021-05-16": "https://..." }
  price       int  not null default 0,           -- 책값(원)
  chars       numeric(10,4) not null default 0,  -- 글자 수(만자). 4자리 소수 = 글자 단위까지 정확히
  volumes     int  not null default 0,           -- 권수
  rating      int  not null default 0,
  memo        text,
  created_at  timestamptz not null default now()
);

-- 2) 이전 버전으로 만든 테이블 보정 (이미 있으면 그대로 두고, 빠진 것만 추가)
alter table public.books add column if not exists pages      int  not null default 0;
alter table public.books add column if not exists ridi       text;
alter table public.books add column if not exists cover_days jsonb;
alter table public.books add column if not exists price      int  not null default 0;
alter table public.books add column if not exists chars      numeric(10,4) not null default 0;
alter table public.books add column if not exists volumes    int  not null default 0;
alter table public.books alter column chars type numeric(10,4);

-- 3) 값 범위 검사
alter table public.books drop constraint if exists books_status_check;
alter table public.books add  constraint books_status_check   check (status in ('reading','done','wish','dropped'));
alter table public.books drop constraint if exists books_progress_check;
alter table public.books add  constraint books_progress_check check (progress between 0 and 100);
alter table public.books drop constraint if exists books_pages_check;
alter table public.books add  constraint books_pages_check    check (pages >= 0);
alter table public.books drop constraint if exists books_price_check;
alter table public.books add  constraint books_price_check    check (price >= 0);
alter table public.books drop constraint if exists books_chars_check;
alter table public.books add  constraint books_chars_check    check (chars >= 0);
alter table public.books drop constraint if exists books_volumes_check;
alter table public.books add  constraint books_volumes_check  check (volumes >= 0);
alter table public.books drop constraint if exists books_rating_check;
alter table public.books add  constraint books_rating_check   check (rating between 0 and 5);

-- 4) 보안: 로그인한 사용자는 자기 기록만 읽고 쓸 수 있습니다 (RLS)
alter table public.books enable row level security;

drop policy if exists "own books select" on public.books;
drop policy if exists "own books insert" on public.books;
drop policy if exists "own books update" on public.books;
drop policy if exists "own books delete" on public.books;
create policy "own books select" on public.books for select using (auth.uid() = user_id);
create policy "own books insert" on public.books for insert with check (auth.uid() = user_id);
create policy "own books update" on public.books for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own books delete" on public.books for delete using (auth.uid() = user_id);
