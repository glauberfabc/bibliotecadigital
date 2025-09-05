-- Grant usage on the auth schema to the postgres user
grant usage on schema auth to postgres;

-- Grant select on the users table to the postgres user
grant select on auth.users to postgres;

-- Add RLS (Row Level Security) to the profiles table
alter table profiles enable row level security;

-- Create policy to allow users to see their own profile
create policy "Users can view their own profile" on profiles
  for select using (auth.uid() = id);

-- Function to create a profile for a new user
create or replace function public.handle_new_user()
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

-- Trigger to call the function on new user creation
create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
  
-- Set up storage
insert into storage.buckets (id, name, public)
values ('covers', 'covers', true)
on conflict (id) do nothing;

-- Create storage policies
create policy "Public access for covers" on storage.objects for select using (bucket_id = 'covers');

create policy "Users can upload their own covers" on storage.objects for
insert with check (
  bucket_id = 'covers' and auth.uid() = owner
);

create policy "Users can update their own covers" on storage.objects for
update using (
  auth.uid() = owner
);
