
-- Clean up existing objects
drop table if exists profiles cascade;
drop table if exists contents cascade;
drop table if exists video_lessons cascade;
drop type if exists user_role cascade;
drop function if exists handle_new_user cascade;

-- Create the user_role enum type
create type user_role as enum ('admin', 'user', 'demo');

-- Create the profiles table
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  role user_role default 'user' not null
);

-- Create the contents table
create table contents (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  theme text not null,
  cover_url text not null,
  type text check (type in ('book', 'audiobook')) not null,
  download_url text not null,
  created_at timestamptz default now() not null
);

-- Create the video_lessons table
create table video_lessons (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  youtube_url text not null,
  created_at timestamptz default now() not null
);

-- Function to handle new user creation
create function handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, role)
  values (new.id, new.email, 'user');
  return new;
end;
$$;

-- Trigger to call the function on new user signup
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Create the storage bucket for covers
insert into storage.buckets (id, name, public)
values ('covers', 'covers', true)
on conflict (id) do nothing;

-- Enable Row Level Security (RLS) for all tables
alter table profiles enable row level security;
alter table contents enable row level security;
alter table video_lessons enable row level security;

-- Policies for profiles table
create policy "Allow authenticated users to view profiles" on profiles for select to authenticated using (true);
create policy "Allow users to manage their own profile" on profiles for update to authenticated using (auth.uid() = id);

-- Policies for contents table
create policy "Allow authenticated users to view content" on contents for select to authenticated using (true);
create policy "Allow admin users to manage all content" on contents for all to authenticated using ((select role from profiles where id = auth.uid()) = 'admin') with check ((select role from profiles where id = auth.uid()) = 'admin');

-- Policies for video_lessons table
create policy "Allow authenticated users to view video lessons" on video_lessons for select to authenticated using (true);
create policy "Admin users can manage all video lessons." on video_lessons for all to authenticated using ((select role from profiles where id = auth.uid()) = 'admin') with check ((select role from profiles where id = auth.uid()) = 'admin');

-- Policies for storage (covers bucket)
create policy "Allow authenticated users to view covers" on storage.objects for select to authenticated using (bucket_id = 'covers');
create policy "Allow admin users to upload covers" on storage.objects for insert to authenticated with check (bucket_id = 'covers' and (select role from profiles where id = auth.uid()) = 'admin');
create policy "Allow admin users to update covers" on storage.objects for update to authenticated using (bucket_id = 'covers' and (select role from profiles where id = auth.uid()) = 'admin');
create policy "Allow admin users to delete covers" on storage.objects for delete to authenticated using (bucket_id = 'covers' and (select role from profiles where id = auth.uid()) = 'admin');

