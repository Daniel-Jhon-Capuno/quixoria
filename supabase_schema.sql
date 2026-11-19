-- ============================================================================
-- QUIXORIA • SUPABASE POSTGRESQL SCHEMA & ROW-LEVEL SECURITY (RLS)
-- Safe to re-run! Paste and run this script in Supabase Dashboard -> SQL Editor
-- ============================================================================

-- 1. User Profiles, Streaks, Owned Books & Full State Snapshot (Email Accounts)
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  full_name text not null,
  email text not null,
  streak_days int default 1,
  gems int default 650,
  golden_keys int default 0,
  owned_books text[] default array['lit_secret_garden', 'lit_wind_in_willows', 'lit_hope_feathers'],
  state_json jsonb,
  updated_at timestamp with time zone default now()
);

alter table public.profiles add column if not exists state_json jsonb;
alter table public.profiles alter column golden_keys set default 0;
alter table public.profiles enable row level security;

drop policy if exists "Users can view and update their own profile" on public.profiles;
create policy "Users can view and update their own profile"
  on public.profiles for all
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- 2. Spaced-Repetition Word Bank Table
create table if not exists public.vocab_cards (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  word text not null,
  definition text not null,
  example text,
  literature_id text,
  literature_title text,
  box int default 0,
  due_at timestamp with time zone default now()
);

create unique index if not exists vocab_cards_user_word_idx
  on public.vocab_cards (user_id, word);

alter table public.vocab_cards enable row level security;

drop policy if exists "Users manage their own word bank" on public.vocab_cards;
create policy "Users manage their own word bank"
  on public.vocab_cards for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- 3. Reading Notes & Reflections Table
create table if not exists public.reading_notes (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  client_note_id text,
  literature_id text not null,
  literature_title text not null,
  chapter_title text not null,
  note_type text not null,
  title text not null,
  content text not null,
  created_at timestamp with time zone default now()
);

alter table public.reading_notes add column if not exists client_note_id text;
create unique index if not exists reading_notes_user_client_idx
  on public.reading_notes (user_id, client_note_id);

alter table public.reading_notes enable row level security;

drop policy if exists "Users manage their own reading notes" on public.reading_notes;
create policy "Users manage their own reading notes"
  on public.reading_notes for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- 4. Username + Password Cloud Accounts (No Email Required!)
-- Stores salted SHA-256 password hash + full JSONB progress so users without an
-- email can still delete/reinstall the app and restore all their progress.
create table if not exists public.username_accounts (
  username text primary key,
  display_name text not null,
  password_salt text not null,
  password_hash text not null,
  state_json jsonb,
  updated_at timestamp with time zone default now()
);

alter table public.username_accounts enable row level security;

drop policy if exists "App clients can manage username accounts" on public.username_accounts;
create policy "App clients can manage username accounts"
  on public.username_accounts for all
  using (true)
  with check (true);
