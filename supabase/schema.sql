-- Create a table for public profiles
create table profiles (
  id uuid references auth.users not null primary key,
  email text,
  role text default 'user'
);
alter table profiles enable row level security;
create policy "Public profiles are viewable by everyone." on profiles for select using (true);
create policy "Users can insert their own profile." on profiles for insert with check (auth.uid() = id);
create policy "Users can update own profile." on profiles for update using (auth.uid() = id);

-- Create a table for contents
create table contents (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  title text not null,
  theme text not null,
  type text not null,
  cover_url text not null,
  download_url text not null
);
alter table contents enable row level security;
create policy "Content is viewable by authenticated users." on contents for select to authenticated using (true);
create policy "Admin users can manage all content." on contents for all to authenticated with check ((select role from profiles where id = auth.uid()) = 'admin') using ((select role from profiles where id = auth.uid()) = 'admin');

-- Create a table for video lessons
create table video_lessons (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  title text not null,
  youtube_url text not null
);
alter table video_lessons enable row level security;
create policy "Video lessons are viewable by authenticated users." on video_lessons for select to authenticated using (true);
create policy "Admin users can manage all video lessons." on video_lessons for all to authenticated with check ((select role from profiles where id = auth.uid()) = 'admin') using ((select role from profiles where id = auth.uid()) = 'admin');

-- Set up Realtime!
begin;
  drop publication if exists supabase_realtime;
  create publication supabase_realtime;
commit;
alter publication supabase_realtime add table contents, profiles, video_lessons;

-- Set up Storage!
insert into storage.buckets (id, name, public)
  values ('covers', 'covers', true);
create policy "Cover images are publicly accessible." on storage.objects for select using (bucket_id = 'covers');
create policy "Admin users can manage all covers." on storage.objects for all to authenticated with check (bucket_id = 'covers' and (select role from profiles where id = auth.uid()) = 'admin') using (bucket_id = 'covers' and (select role from profiles where id = auth.uid()) = 'admin');

-- This trigger automatically creates a profile entry when a new user signs up.
create function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, role)
  values (new.id, new.email, 'user');
  return new;
end;
$$ language plpgsql security definer;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
