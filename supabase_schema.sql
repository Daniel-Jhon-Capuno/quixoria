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

-- 5. Live Global Leaderboard Table (Unified for Email & No-Email Username Accounts!)
create table if not exists public.leaderboard_entries (
  account_key text primary key,
  display_name text not null,
  scholar_title text default 'Knight Errant of Letters',
  frame_id text default 'frame_classic',
  weekly_xp int default 0,
  streak_days int default 1,
  books_completed int default 0,
  levels_completed int default 0,
  updated_at timestamp with time zone default now()
);

create index if not exists leaderboard_weekly_xp_idx
  on public.leaderboard_entries (weekly_xp desc);

alter table public.leaderboard_entries enable row level security;

drop policy if exists "Anyone can view and update leaderboard entries" on public.leaderboard_entries;
create policy "Anyone can view and update leaderboard entries"
  on public.leaderboard_entries for all
  using (true)
  with check (true);


-- ============================================================================
-- LIVE COMMUNITY FEED, COMMENTS, REACTIONS & FOLLOW SYSTEM
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.user_follows (
  follower_handle TEXT NOT NULL,
  target_handle TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (follower_handle, target_handle)
);

CREATE TABLE IF NOT EXISTS public.community_posts (
  id TEXT PRIMARY KEY,
  author_handle TEXT NOT NULL,
  author_name TEXT NOT NULL,
  author_title TEXT DEFAULT 'Scholar',
  content TEXT NOT NULL,
  book_tag TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.community_comments (
  id TEXT PRIMARY KEY,
  post_id TEXT NOT NULL REFERENCES public.community_posts(id) ON DELETE CASCADE,
  author_handle TEXT NOT NULL,
  author_name TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.community_reactions (
  post_id TEXT NOT NULL REFERENCES public.community_posts(id) ON DELETE CASCADE,
  user_handle TEXT NOT NULL,
  emoji TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (post_id, user_handle, emoji)
);

ALTER TABLE public.user_follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_reactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read follows" ON public.user_follows;
CREATE POLICY "Public read follows" ON public.user_follows FOR SELECT USING (true);
DROP POLICY IF EXISTS "Public write follows" ON public.user_follows;
CREATE POLICY "Public write follows" ON public.user_follows FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public read posts" ON public.community_posts;
CREATE POLICY "Public read posts" ON public.community_posts FOR SELECT USING (true);
DROP POLICY IF EXISTS "Public write posts" ON public.community_posts;
CREATE POLICY "Public write posts" ON public.community_posts FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public read comments" ON public.community_comments;
CREATE POLICY "Public read comments" ON public.community_comments FOR SELECT USING (true);
DROP POLICY IF EXISTS "Public write comments" ON public.community_comments;
CREATE POLICY "Public write comments" ON public.community_comments FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public read reactions" ON public.community_reactions;
CREATE POLICY "Public read reactions" ON public.community_reactions FOR SELECT USING (true);
DROP POLICY IF EXISTS "Public write reactions" ON public.community_reactions;
CREATE POLICY "Public write reactions" ON public.community_reactions FOR ALL USING (true) WITH CHECK (true);

-- Enable live Realtime broadcasts for feed posts, comments, reactions & follows
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.community_posts;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.community_comments;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.community_reactions;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.user_follows;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Author cosmetic profile & flex stat columns on community_posts
ALTER TABLE public.community_posts
  ADD COLUMN IF NOT EXISTS author_avatar_icon_id TEXT DEFAULT 'don_quixote',
  ADD COLUMN IF NOT EXISTS author_frame_id TEXT DEFAULT 'frame_parchment',
  ADD COLUMN IF NOT EXISTS author_banner_id TEXT DEFAULT 'banner_classic',
  ADD COLUMN IF NOT EXISTS author_streak INTEGER DEFAULT 1,
  ADD COLUMN IF NOT EXISTS author_xp INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS author_achievements INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS author_books INTEGER DEFAULT 0;
