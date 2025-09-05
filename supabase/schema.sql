-- Create profiles table
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  role text default 'user'
);
-- Create contents table
create table if not exists contents (
  id uuid primary key default uuid_generate_v4(),
  title text not null,
  theme text not null,
  cover_url text not null,
  type text check (type in ('book', 'audiobook')),
  download_url text not null,
  created_at timestamptz default now()
);

-- Create video_lessons table
create table if not exists video_lessons (
  id uuid primary key default uuid_generate_v4(),
  title text not null,
  youtube_url text not null,
  created_at timestamptz default now()
);

-- Function to handle new user
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

-- Trigger for new user
create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Storage bucket
insert into storage.buckets (id, name, public)
values ('covers', 'covers', true)
on conflict (id) do nothing;

-- Enable RLS
alter table profiles enable row level security;
alter table contents enable row level security;
alter table video_lessons enable row level security;

-- Policies for profiles
create policy "Users can view their own profile." on profiles for select using (auth.uid() = id);
create policy "Users can update their own profile." on profiles for update using (auth.uid() = id);

-- Policies for contents
create policy "Authenticated users can view content." on contents for select to authenticated using (true);
create policy "Admin users can manage all content." on contents for all using ((select role from profiles where id = auth.uid()) = 'admin') with check ((select role from profiles where id = auth.uid()) = 'admin');

-- Policies for video_lessons
create policy "Authenticated users can view video lessons." on video_lessons for select to authenticated using (true);
create policy "Admin users can manage video lessons." on video_lessons for all using ((select role from profiles where id = auth.uid()) = 'admin') with check ((select role from profiles where id = auth.uid()) = 'admin');

-- Policies for storage
create policy "Authenticated users can view covers." on storage.objects for select to authenticated using (bucket_id = 'covers');
create policy "Admin users can upload covers." on storage.objects for insert to authenticated with check ((select role from profiles where id = auth.uid()) = 'admin' and bucket_id = 'covers');
create policy "Admin users can update covers." on storage.objects for update to authenticated using ((select role from profiles where id = auth.uid()) = 'admin' and bucket_id = 'covers');
create policy "Admin users can delete covers." on storage.objects for delete to authenticated using ((select role from profiles where id = auth.uid()) = 'admin' and bucket_id = 'covers');
