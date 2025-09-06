-- Drop existing policies for storage if they exist
drop policy if exists "Allow authenticated users to view covers" on storage.objects;
drop policy if exists "Allow admin to manage covers" on storage.objects;

-- Drop existing tables, types, and functions if they exist to ensure a clean slate
drop table if exists contents cascade;
drop table if exists profiles cascade;
drop table if exists video_lessons cascade;
drop type if exists user_role cascade;
drop function if exists handle_new_user cascade;

-- Create a custom type for user roles
create type user_role as enum ('admin', 'user', 'demo');

-- Create the profiles table to store user data
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  role user_role default 'user' not null
);

-- Create the contents table for books and audiobooks
create table contents (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  theme text not null,
  cover_url text not null,
  type text check (type in ('book', 'audiobook')) not null,
  download_url text not null,
  created_at timestamptz default now()
);

-- Create the video_lessons table
create table video_lessons (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  youtube_url text not null,
  created_at timestamptz default now()
);

-- Function to create a new profile when a user signs up
create or replace function handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public as
$$
begin
  -- For new users, create a profile. For demo@example.com, assign the 'demo' role.
  if new.email = 'demo@example.com' then
    insert into public.profiles (id, email, role)
    values (new.id, new.email, 'demo');
  else
    insert into public.profiles (id, email, role)
    values (new.id, new.email, 'user');
  end if;
  return new;
end;
$$;

-- Trigger to execute the handle_new_user function on new user creation
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Create the 'covers' bucket for storage if it doesn't exist
insert into storage.buckets (id, name, public)
values ('covers', 'covers', true)
on conflict (id) do nothing;

-- Enable Row Level Security (RLS) for all tables
alter table profiles enable row level security;
alter table contents enable row level security;
alter table video_lessons enable row level security;

-- Policies for 'profiles' table
create policy "Users can view their own profile" on profiles for select using (auth.uid() = id);

-- Policies for 'contents' table
create policy "Authenticated users can view contents" on contents for select to authenticated using (true);
create policy "Admin users can manage contents" on contents for all using ((select role from profiles where id = auth.uid()) = 'admin') with check ((select role from profiles where id = auth.uid()) = 'admin');

-- Policies for 'video_lessons' table
create policy "Authenticated users can view video lessons" on video_lessons for select to authenticated using (true);
create policy "Admin users can manage video lessons" on video_lessons for all using ((select role from profiles where id = auth.uid()) = 'admin') with check ((select role from profiles where id = auth.uid()) = 'admin');

-- Policies for 'storage.objects' (covers bucket)
create policy "Allow authenticated users to view covers" on storage.objects for select to authenticated using (bucket_id = 'covers');
create policy "Allow admin to manage covers" on storage.objects for all to authenticated using (bucket_id = 'covers' and (select role from profiles where id = auth.uid()) = 'admin');