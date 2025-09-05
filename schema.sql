-- Cria o tipo ENUM para a função do usuário
CREATE TYPE public.user_role AS ENUM ('user', 'admin');

-- Cria a tabela de perfis
CREATE TABLE public.profiles (
    id uuid NOT NULL PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email character varying,
    role public.user_role DEFAULT 'user'::public.user_role
);

-- Habilita a Segurança em Nível de Linha (RLS) para perfis
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Política: Usuários podem ver seus próprios perfis
CREATE POLICY "Public profiles are viewable by users."
    ON public.profiles FOR SELECT
    USING ( auth.uid() = id );

-- Política: Usuários podem atualizar seus próprios perfis
CREATE POLICY "Users can update their own profile."
    ON public.profiles FOR UPDATE
    USING ( auth.uid() = id );
    
-- Função para criar um perfil para um novo usuário
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email)
  VALUES (new.id, new.email);
  RETURN new;
END;
$$;

-- Gatilho para executar a função quando um novo usuário é criado
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();


-- Cria o tipo ENUM para o tipo de conteúdo
CREATE TYPE public.content_type AS ENUM ('book', 'audiobook');

-- Cria a tabela de conteúdos
CREATE TABLE public.contents (
    id uuid NOT NULL DEFAULT uuid_generate_v4() PRIMARY KEY,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    title character varying NOT NULL,
    theme character varying NOT NULL,
    type public.content_type NOT NULL,
    cover_url character varying NOT NULL,
    download_url character varying NOT NULL
);

-- Habilita a Segurança em Nível de Linha (RLS) para conteúdos
ALTER TABLE public.contents ENABLE ROW LEVEL SECURITY;

-- Política: Usuários autenticados podem ver todos os conteúdos
CREATE POLICY "Authenticated users can view contents."
    ON public.contents FOR SELECT
    USING ( auth.role() = 'authenticated' );

-- Função auxiliar para verificar se o usuário é admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  user_role public.user_role;
BEGIN
  SELECT role INTO user_role FROM public.profiles WHERE id = auth.uid();
  RETURN user_role = 'admin';
END;
$$;

-- Política: Apenas administradores podem inserir conteúdos
CREATE POLICY "Admins can insert contents."
    ON public.contents FOR INSERT
    WITH CHECK ( is_admin() );

-- Política: Apenas administradores podem atualizar conteúdos
CREATE POLICY "Admins can update contents."
    ON public.contents FOR UPDATE
    USING ( is_admin() );

-- Política: Apenas administradores podem deletar conteúdos
CREATE POLICY "Admins can delete contents."
    ON public.contents FOR DELETE
    USING ( is_admin() );


-- Configuração do Storage para as capas
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('covers', 'covers', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']);

-- Política: Permitir visualização pública das capas
CREATE POLICY "Cover images are publicly accessible."
    ON storage.objects FOR SELECT
    USING ( bucket_id = 'covers' );

-- Política: Apenas administradores podem enviar capas
CREATE POLICY "Admins can upload cover images."
    ON storage.objects FOR INSERT
    WITH CHECK ( bucket_id = 'covers' AND is_admin() );

-- Política: Apenas administradores podem atualizar capas
CREATE POLICY "Admins can update cover images."
    ON storage.objects FOR UPDATE
    USING ( bucket_id = 'covers' AND is_admin() );

-- Política: Apenas administradores podem deletar capas
CREATE POLICY "Admins can delete cover images."
    ON storage.objects FOR DELETE
    USING ( bucket_id = 'covers' AND is_admin() );
