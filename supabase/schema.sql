-- Profiles table
create table public.profiles (
  id uuid not null references auth.users on delete cascade,
  email text,
  role text default 'user' check (role in ('user', 'admin')),
  primary key (id)
);
alter table public.profiles enable row level security; -- Activate RLS

-- Contents table
create table public.contents (
  id uuid not null primary key default gen_random_uuid(),
  title text not null,
  theme text not null,
  cover_url text not null,
  type text not null check (type in ('book', 'audiobook')),
  download_url text not null,
  created_at timestamp with time zone not null default now()
);
alter table public.contents enable row level security; -- Activate RLS

-- Storage bucket for covers
insert into storage.buckets (id, name, public)
values ('covers', 'covers', true);

-- Policies for storage
create policy "Allow public read access on covers" on storage.objects
  for select using (bucket_id = 'covers');

create policy "Allow authenticated users to upload covers" on storage.objects
  for insert with check (bucket_id = 'covers' and auth.role() = 'authenticated');

create policy "Allow admin to update covers" on storage.objects
  for update using (bucket_id = 'covers' and (select role from public.profiles where id = auth.uid()) = 'admin');

create policy "Allow admin to delete covers" on storage.objects
  for delete using (bucket_id = 'covers' and (select role from public.profiles where id = auth.uid()) = 'admin');

-- Function to handle new user sign-ups
create function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email);
  return new;
end;
$$;

-- Trigger to call the function when a new user is created
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Grant usage on schema to postgres user
grant usage on schema public to postgres;
grant usage on schema auth to postgres;

-- Grant select on auth.users to postgres user
grant select on table auth.users to postgres;

-- Policies for profiles table
create policy "Users can read their own profile" on public.profiles
  for select using (auth.uid() = id);

-- Policies for contents table
create policy "Enable read access for all users" on public.contents
  for select using (true);

create policy "Allow admin to insert content" on public.contents
  for insert with check ((select role from public.profiles where id = auth.uid()) = 'admin');

create policy "Allow admin to update content" on public.contents
  for update using ((select role from public.profiles where id = auth.uid()) = 'admin');

create policy "Allow admin to delete content" on public.contents
  for delete using ((select role from public.profiles where id = auth.uid()) = 'admin');
