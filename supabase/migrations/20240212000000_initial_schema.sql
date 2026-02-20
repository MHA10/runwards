-- Create users table (extends auth.users)
create table if not exists public.users (
  id uuid references auth.users not null primary key,
  display_name text,
  city text,
  total_steps bigint default 0,
  current_rc bigint default 0,
  vouchers_redeemed int default 0,
  created_at timestamptz default now()
);

alter table public.users enable row level security;

-- Policies for users table
-- Allow users to view their own profile
create policy "Users can view own profile" on public.users for select using (auth.uid() = id);
-- Allow users to update their own profile
create policy "Users can update own profile" on public.users for update using (auth.uid() = id);
-- Allow users to insert their own profile (on signup/first login)
create policy "Users can insert own profile" on public.users for insert with check (auth.uid() = id);
-- Allow all authenticated users to view basic info for leaderboard (display_name, total_steps, city)
create policy "Users can view leaderboard data" on public.users for select using (true);


-- Create step_logs table
create table if not exists public.step_logs (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users not null,
  date date not null,
  steps int not null,
  created_at timestamptz default now(),
  unique(user_id, date)
);

alter table public.step_logs enable row level security;
create policy "Users can crud own step logs" on public.step_logs for all using (auth.uid() = user_id);


-- Create rewards table
create table if not exists public.rewards (
  id uuid default gen_random_uuid() primary key,
  brand_name text not null,
  description text not null,
  cost_rc int not null,
  category text not null, 
  image_url text,
  expiry_date timestamptz,
  created_at timestamptz default now()
);

alter table public.rewards enable row level security;
create policy "Authenticated users can view rewards" on public.rewards for select to authenticated using (true);


-- Create redemptions table
create table if not exists public.redemptions (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users not null,
  reward_id uuid references public.rewards not null,
  voucher_code text not null,
  redeemed_at timestamptz default now()
);

alter table public.redemptions enable row level security;
create policy "Users can see own redemptions" on public.redemptions for select using (auth.uid() = user_id);
create policy "Users can insert own redemptions" on public.redemptions for insert with check (auth.uid() = user_id);


-- Create ad_views table
create table if not exists public.ad_views (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users not null,
  viewed_at timestamptz default now()
);

alter table public.ad_views enable row level security;
create policy "Users can see own ad views" on public.ad_views for select using (auth.uid() = user_id);
create policy "Users can insert own ad views" on public.ad_views for insert with check (auth.uid() = user_id);


-- Create events table
create table if not exists public.events (
  id uuid default gen_random_uuid() primary key,
  title text not null,
  organization text not null,
  description text,
  goal_steps bigint not null,
  current_steps bigint default 0,
  start_date timestamptz,
  end_date timestamptz,
  join_code text unique, 
  image_url text,
  created_at timestamptz default now()
);

alter table public.events enable row level security;
create policy "Authenticated users can view events" on public.events for select to authenticated using (true);


-- Create event_participants table
create table if not exists public.event_participants (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users not null,
  event_id uuid references public.events not null,
  joined_at timestamptz default now(),
  credits_donated int default 0,
  steps_contributed int default 0, 
  unique(user_id, event_id)
);

alter table public.event_participants enable row level security;
create policy "Users can see own participations" on public.event_participants for select using (auth.uid() = user_id);
create policy "Users can join events" on public.event_participants for insert with check (auth.uid() = user_id);
create policy "Users can update own participation" on public.event_participants for update using (auth.uid() = user_id);
create policy "Users can view event participants for leaderboard" on public.event_participants for select using (true);
