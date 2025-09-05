-- 1. Create profiles table
create table public.profiles (
  id uuid not null references auth.users on delete cascade,
  email text,
  role text default 'user',
  primary key (id)
);
alter table public.profiles enable row level security;

-- 2. Create contents table
create table public.contents (
    id uuid default gen_random_uuid() primary key,
    title text not null,
    theme text not null,
    cover_url text not null,
    type text not null check (type in ('book', 'audiobook')),
    download_url text not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);
alter table public.contents enable row level security;

-- 3. Set up trigger for new users
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

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- 4. Set up RLS policies
create policy "Public profiles are viewable by everyone."
on public.profiles for select
using ( true );

create policy "Users can insert their own profile."
on public.profiles for insert
with check ( auth.uid() = id );

create policy "Users can update own profile."
on public.profiles for update
using ( auth.uid() = id );

create policy "Contents are viewable by authenticated users."
on public.contents for select
to authenticated
using ( true );

create policy "Admins can insert content."
on public.contents for insert
to authenticated
with check ( (select role from profiles where id = auth.uid()) = 'admin' );

create policy "Admins can update content."
on public.contents for update
to authenticated
using ( (select role from profiles where id = auth.uid()) = 'admin' );

create policy "Admins can delete content."
on public.contents for delete
to authenticated
using ( (select role from profiles where id = auth.uid()) = 'admin' );

-- 5. Create Storage bucket and policies
insert into storage.buckets (id, name, public)
values ('covers', 'covers', true);

create policy "Allow authenticated users to view covers"
on storage.objects for select
to authenticated
using ( bucket_id = 'covers' );

create policy "Allow authenticated users to upload covers into their own folder"
on storage.objects for insert
to authenticated
with check ( bucket_id = 'covers' and (storage.foldername(name))[1] = auth.uid()::text );

create policy "Allow authenticated users to update their own covers"
on storage.objects for update
to authenticated
using ( auth.uid() = owner )
with check ( bucket_id = 'covers' );

create policy "Allow authenticated users to delete their own covers"
on storage.objects for delete
to authenticated
using ( auth.uid() = owner );
