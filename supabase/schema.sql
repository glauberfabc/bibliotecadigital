-- Drop dependent objects first
drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user();

-- Create the handle_new_user function
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, role)
  values (new.id, new.email, 'user');
  return new;
end;
$$ language plpgsql security definer;

-- Create the trigger to call the function
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Grant permissions for the function
grant execute on function public.handle_new_user() to postgres, service_role;

-- Drop existing policies before creating new ones to avoid conflicts
drop policy if exists "Authenticated users can select own profile" on public.profiles;
drop policy if exists "Admin users can do anything" on public.profiles;
drop policy if exists "Authenticated users can select all content" on public.contents;
drop policy if exists "Admin users can do anything" on public.contents;

-- Enable Row Level Security if not already enabled
alter table public.profiles enable row level security;
alter table public.contents enable row level security;

-- Add policies for profiles table
create policy "Authenticated users can select own profile"
on public.profiles for select
using (auth.uid() = id);

create policy "Admin users can do anything"
on public.profiles for all
using (
  (select role from public.profiles where id = auth.uid()) = 'admin'
)
with check (
  (select role from public.profiles where id = auth.uid()) = 'admin'
);

-- Add policies for contents table
create policy "Authenticated users can select all content"
on public.contents for select
using (auth.role() = 'authenticated');

create policy "Admin users can do anything"
on public.contents for all
using (
  (select role from public.profiles where id = auth.uid()) = 'admin'
)
with check (
  (select role from public.profiles where id = auth.uid()) = 'admin'
);
