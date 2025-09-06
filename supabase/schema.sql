-- Drop existing policies on storage.objects if they exist to avoid conflicts
drop policy if exists "Allow authenticated users to view covers" on storage.objects;
drop policy if exists "Allow admin users to manage all covers" on storage.objects;

-- Drop dependent objects first
drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user();

-- Drop tables if they exist, cascading to remove dependent policies
drop table if exists public.video_lessons cascade;
drop table if exists public.contents cascade;
drop table if exists public.profiles cascade;


-- Create the profiles table
create table public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  email text,
  role text
);
-- Add a constraint to ensure the role is one of the allowed values
alter table public.profiles add constraint check_role check (role in ('admin', 'user', 'demo'));


-- This trigger automatically creates a profile for new users.
create function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, role)
  values (new.id, new.raw_user_meta_data->>'email', 'user');
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Create the contents table
create table public.contents (
    id uuid default gen_random_uuid() primary key,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    title text not null,
    theme text not null,
    type text not null,
    cover_url text not null,
    download_url text not null
);

-- Create the video_lessons table
create table public.video_lessons (
    id uuid default gen_random_uuid() primary key,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    title text not null,
    youtube_url text not null
);


-- Set up Row Level Security (RLS) for all tables
alter table public.profiles enable row level security;
alter table public.contents enable row level security;
alter table public.video_lessons enable row level security;


-- Create RLS policies for profiles table
create policy "Public profiles are viewable by everyone." on public.profiles for select using (true);
create policy "Users can insert their own profile." on public.profiles for insert with check (auth.uid() = id);
create policy "Users can update own profile." on public.profiles for update using (auth.uid() = id);

-- Create RLS policies for contents table
create policy "Allow read access to all authenticated users" on public.contents for select to authenticated using (true);
create policy "Admin users can manage all content" on public.contents for all using ((select role from public.profiles where id = auth.uid()) = 'admin') with check ((select role from public.profiles where id = auth.uid()) = 'admin');

-- Create RLS policies for video_lessons table
create policy "Allow read access for authenticated users." on public.video_lessons for select to authenticated using (true);
create policy "Admin users can manage all video lessons." on public.video_lessons for all using ((select role from public.profiles where id = auth.uid()) = 'admin');


-- Set up storage
insert into storage.buckets (id, name, public)
values ('covers', 'covers', true)
on conflict (id) do nothing;

-- Create RLS policies for storage
create policy "Allow authenticated users to view covers" on storage.objects for select to authenticated using (bucket_id = 'covers');
create policy "Allow admin users to manage all covers" on storage.objects for all to authenticated using ((bucket_id = 'covers') and ((select role from public.profiles where id = auth.uid()) = 'admin'));
