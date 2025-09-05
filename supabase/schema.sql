-- Create a table for public profiles
create table profiles (
  id uuid references auth.users not null primary key,
  email text,
  role text default 'user'
);
alter table profiles enable row level security;

-- Create a table for content
create table contents (
    id uuid default gen_random_uuid() primary key,
    title text not null,
    theme text not null,
    cover_url text not null,
    type text not null,
    download_url text not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);
alter table contents enable row level security;

-- Create a table for video lessons
create table video_lessons (
    id uuid default gen_random_uuid() primary key,
    title text not null,
    youtube_url text not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);
alter table video_lessons enable row level security;

-- Set up Realtime!
begin;
  drop publication if exists supabase_realtime;
  create publication supabase_realtime;
commit;
alter publication supabase_realtime add table contents;
alter publication supabase_realtime add table profiles;
alter publication supabase_realtime add table video_lessons;

-- Set up the GUEST user
create role guest with nologin noinherit;
grant usage on schema public to guest;
grant select on table contents to guest;
grant select on table profiles to guest;
grant select on table video_lessons to guest;

-- Set up the USER user
create role "user" with nologin noinherit;
grant usage on schema public to "user";
grant select, insert, update, delete on table contents to "user";
grant select, insert, update, delete on table profiles to "user";
grant select, insert, update, delete on table video_lessons to "user";

grant guest to "user";
grant "user" to postgres;
grant "user" to service_role;

alter default privileges in schema public grant select on tables to guest;

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

-- Policies for profiles
create policy "Public profiles are viewable by everyone." on profiles for select using (true);
create policy "Users can insert their own profile." on profiles for insert with check (auth.uid() = id);
create policy "Users can update own profile." on profiles for update using (auth.uid() = id);

-- Policies for contents
create policy "Allow authenticated users to view content." on contents for select to authenticated using (true);
create policy "Admin users can manage all content." on contents for all using ((select role from profiles where id = auth.uid()) = 'admin');

-- Policies for video_lessons
create policy "Allow authenticated users to view video lessons." on video_lessons for select to authenticated using (true);
create policy "Admin users can manage all video lessons." on video_lessons for all using ((select role from profiles where id = auth.uid()) = 'admin');


-- Set up Storage!
insert into storage.buckets (id, name, public)
  values ('covers', 'covers', true);

-- Policies for storage
create policy "Allow authenticated users to view covers" on storage.objects for select to authenticated using (bucket_id = 'covers');
create policy "Allow admin users to manage covers" on storage.objects for all using (bucket_id = 'covers' and (select role from profiles where id = auth.uid()) = 'admin');
