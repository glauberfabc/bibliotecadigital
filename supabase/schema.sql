-- Apaga tabelas e objetos dependentes na ordem correta para evitar erros
drop table if exists contents cascade;
drop table if exists profiles cascade;
drop function if exists handle_new_user cascade;
drop policy if exists "Allow authenticated users to read contents" on contents;
drop policy if exists "Allow admin full access to contents" on contents;
drop policy if exists "Allow users to view their own profile" on profiles;
drop policy if exists "Allow users to update their own profile" on profiles;
drop policy if exists "Allow admin to manage all profiles" on profiles;

-- Cria a tabela para perfis de usuário
create table profiles (
  id uuid references auth.users not null primary key,
  email text,
  role text default 'user'
);

-- Cria a tabela para os conteúdos (livros/audiolivros)
create table contents (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  title text not null,
  theme text not null,
  type text check (type in ('book', 'audiobook')) not null,
  cover_url text not null,
  download_url text not null
);

-- Função para criar um perfil para um novo usuário
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

-- Trigger para executar a função quando um novo usuário é criado
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Concede permissões para a função handle_new_user
grant execute on function public.handle_new_user() to postgres, service_role;

-- POLÍTICAS DE SEGURANÇA PARA A TABELA DE PERFIS
-- Habilita o RLS
alter table profiles enable row level security;
-- Permite que usuários visualizem seus próprios perfis
create policy "Allow users to view their own profile" on profiles
for select using (auth.uid() = id);
-- Permite que usuários atualizem seus próprios perfis
create policy "Allow users to update their own profile" on profiles
for update using (auth.uid() = id);
-- Permite que administradores gerenciem todos os perfis
create policy "Allow admin to manage all profiles" on profiles
for all using ((select role from profiles where id = auth.uid()) = 'admin');

-- POLÍTICAS DE SEGURANÇA PARA A TABELA DE CONTEÚDOS
-- Habilita o RLS
alter table contents enable row level security;
-- Permite que usuários autenticados leiam todos os conteúdos
create policy "Allow authenticated users to read contents" on contents
for select using (auth.role() = 'authenticated');
-- Permite que administradores gerenciem todos os conteúdos
create policy "Allow admin full access to contents" on contents
for all using ((select role from profiles where id = auth.uid()) = 'admin');

-- POLÍTICAS DE SEGURANÇA PARA O ARMAZENAMENTO (STORAGE)
-- Política para uploads de capa
create policy "Allow admin upload to covers"
on storage.objects for insert
with check ( bucket_id = 'covers' and (select role from profiles where id = auth.uid()) = 'admin' );

-- Política para atualizações de capa
create policy "Allow admin update on covers"
on storage.objects for update
using ( bucket_id = 'covers' and (select role from profiles where id = auth.uid()) = 'admin' );

-- Política para exclusões de capa
create policy "Allow admin delete on covers"
on storage.objects for delete
using ( bucket_id = 'covers' and (select role from profiles where id = auth.uid()) = 'admin' );

-- Política para leitura de capa
create policy "Allow anyone to read covers"
on storage.objects for select
using ( bucket_id = 'covers' );
