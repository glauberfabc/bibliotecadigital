-- Create profiles table
create table profiles (
  id uuid references auth.users on delete cascade not null primary key,
  email varchar(255),
  role user_role default 'user'::user_role not null
);

-- Create contents table
create table contents (
  id uuid primary key default uuid_generate_v4(),
  title varchar(255) not null,
  theme varchar(100) not null,
  cover_url text not null,
  type content_type not null,
  download_url text not null,
  created_at timestamptz default now()
);

-- Create video_lessons table
create table video_lessons (
    id uuid primary key default uuid_generate_v4(),
    title varchar(255) not null,
    youtube_url text not null,
    created_at timestamptz default now()
);

-- Create user_role type
create type user_role as enum ('user', 'admin', 'demo');
create type content_type as enum ('book', 'audiobook');

-- Create function to handle new user
create or replace function handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, role)
  values (new.id, new.raw_user_meta_data->>'email', 'user');
  return new;
end;
$$;

-- Create trigger on new user
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Create storage bucket for covers
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('covers', 'covers', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']);

-- Enable Row Level Security for tables
alter table profiles enable row level security;
alter table contents enable row level security;
alter table video_lessons enable row level security;

-- Policies for profiles
create policy "Users can view their own profile." on profiles for select using (auth.uid() = id);
create policy "Users can update their own profile." on profiles for update using (auth.uid() = id);

-- Policies for contents
create policy "Allow authenticated users to view content." on contents for select to authenticated using (true);
create policy "Admin users can manage all content." on contents for all using ((select role from profiles where id = auth.uid()) = 'admin');

-- Policies for video_lessons
create policy "Allow authenticated users to view lessons." on video_lessons for select to authenticated using (true);
create policy "Admin users can manage all video lessons." on video_lessons for all using ((select role from profiles where id = auth.uid()) = 'admin');

-- Policies for storage
create policy "Allow authenticated users to view covers" on storage.objects for select to authenticated using (bucket_id = 'covers');
create policy "Allow admin users to manage all covers" on storage.objects for all using (bucket_id = 'covers' and (select role from profiles where id = auth.uid()) = 'admin');
