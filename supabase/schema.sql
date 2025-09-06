-- Apaga o bucket de armazenamento se ele existir, junto com todos os seus objetos.
-- O CASCADE garante que as políticas que dependem dele também sejam removidas.
drop bucket if exists covers cascade;

-- Apaga as tabelas se elas existirem.
-- O CASCADE garante que quaisquer funções, gatilhos ou políticas que dependem delas sejam removidos primeiro.
drop table if exists public.profiles cascade;
drop table if exists public.contents cascade;
drop table if exists public.video_lessons cascade;

-- Cria um tipo ENUM customizado para garantir que a coluna 'role' só possa ter valores específicos.
create type public.user_role as enum ('admin', 'user', 'demo');

-- Cria a tabela de perfis de usuário.
create table public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  email text,
  role public.user_role default 'user' not null
);
-- Altera a tabela para que o RLS (Row Level Security) seja ativado.
alter table public.profiles enable row level security;

-- Cria a tabela de conteúdos (livros e audiolivros).
create table public.contents (
    id uuid default gen_random_uuid() primary key,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    title text not null,
    theme text not null,
    type text check (type in ('book', 'audiobook')) not null,
    cover_url text not null,
    download_url text not null
);
-- Altera a tabela para que o RLS (Row Level Security) seja ativado.
alter table public.contents enable row level security;

-- Cria a tabela de videoaulas.
create table public.video_lessons (
    id uuid default gen_random_uuid() primary key,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    title text not null,
    youtube_url text not null
);
-- Altera a tabela para que o RLS (Row Level Security) seja ativado.
alter table public.video_lessons enable row level security;


-- Função para criar um perfil para um novo usuário.
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, role)
  values (new.id, new.email, 'user');
  return new;
end;
$$ language plpgsql security definer;

-- Gatilho (trigger) que executa a função handle_new_user após a criação de um novo usuário.
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Cria o bucket de armazenamento para as capas dos livros.
insert into storage.buckets (id, name, public)
values ('covers', 'covers', true);

-- Políticas de Segurança para a tabela PROFILES
-- Permite que os usuários leiam seus próprios perfis.
create policy "Users can read their own profile." on public.profiles for select using (auth.uid() = id);

-- Políticas de Segurança para a tabela CONTENTS
-- Permite que QUALQUER usuário autenticado (admin, user, demo) veja a lista de conteúdos.
create policy "Allow authenticated users to view content" on public.contents for select to authenticated using (true);
-- Permite que APENAS administradores insiram, atualizem ou deletem conteúdos.
create policy "Allow admins to manage content" on public.contents for all to authenticated
  using ((select role from public.profiles where id = auth.uid()) = 'admin')
  with check ((select role from public.profiles where id = auth.uid()) = 'admin');

-- Políticas de Segurança para a tabela VIDEO_LESSONS
-- Permite que QUALQUER usuário autenticado (admin, user, demo) veja a lista de videoaulas.
create policy "Allow authenticated users to view video lessons" on public.video_lessons for select to authenticated using (true);
-- Permite que APENAS administradores insiram, atualizem ou deletem videoaulas.
create policy "Admin users can manage all video lessons." on public.video_lessons for all to authenticated 
  using ((select role from public.profiles where id = auth.uid()) = 'admin') 
  with check ((select role from public.profiles where id = auth.uid()) = 'admin');

-- Políticas de Segurança para o STORAGE (bucket 'covers')
-- Permite que QUALQUER pessoa (incluindo não autenticados) veja as imagens de capa.
create policy "Allow public read access to covers" on storage.objects for select using (bucket_id = 'covers');
-- Permite que APENAS administradores façam upload de novas imagens de capa.
create policy "Allow admin users to upload covers" on storage.objects for insert to authenticated
  with check (bucket_id = 'covers' and (select role from public.profiles where id = auth.uid()) = 'admin');
-- Permite que APENAS administradores atualizem imagens de capa.
create policy "Allow admin users to update covers" on storage.objects for update to authenticated
  using (bucket_id = 'covers' and (select role from public.profiles where id = auth.uid()) = 'admin');
-- Permite que APENAS administradores deletem imagens de capa.
create policy "Allow admin users to delete covers" on storage.objects for delete to authenticated
  using (bucket_id = 'covers' and (select role from public.profiles where id = auth.uid()) = 'admin');
