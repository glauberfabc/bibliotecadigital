--
-- Tabela de Perfis de Usuário
-- Armazena informações públicas sobre os usuários.
--
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email VARCHAR(255),
  role TEXT DEFAULT 'user' NOT NULL
);
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Políticas de Segurança para a Tabela de Perfis
CREATE POLICY "Os usuários podem ver todos os perfis" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Os usuários podem inserir seu próprio perfil" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Os usuários podem atualizar seu próprio perfil" ON public.profiles FOR UPDATE USING (auth.uid() = id);

--
-- Função e Gatilho para Sincronização de Usuários
-- Cria um perfil para um novo usuário automaticamente.
--
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role)
  VALUES (new.id, new.email, 'user');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

--
-- Tabela de Conteúdos
-- Armazena os livros e audiolivros.
--
CREATE TABLE public.contents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  theme TEXT NOT NULL,
  cover_url TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('book', 'audiobook')),
  download_url TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.contents ENABLE ROW LEVEL SECURITY;

-- Políticas de Segurança para a Tabela de Conteúdos
CREATE POLICY "Permitir acesso de leitura a todos" ON public.contents FOR SELECT USING (true);
CREATE POLICY "Permitir inserção para administradores" ON public.contents FOR INSERT WITH CHECK (
  (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
);
CREATE POLICY "Permitir atualização para administradores" ON public.contents FOR UPDATE USING (
  (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
);
CREATE POLICY "Permitir exclusão para administradores" ON public.contents FOR DELETE USING (
  (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
);

--
-- Configuração do Supabase Storage para Capas
--
-- Cria o bucket 'covers' se ele não existir
INSERT INTO storage.buckets (id, name, public)
VALUES ('covers', 'covers', true)
ON CONFLICT (id) DO NOTHING;

-- Políticas de Segurança para o Bucket 'covers'
CREATE POLICY "Permitir que usuários autenticados vejam todas as capas" ON storage.objects FOR SELECT USING (bucket_id = 'covers');

CREATE POLICY "Permitir que administradores autenticados façam upload de capas" ON storage.objects FOR INSERT WITH CHECK (
    bucket_id = 'covers' AND
    (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
);

CREATE POLICY "Permitir que administradores autenticados atualizem capas" ON storage.objects FOR UPDATE USING (
    bucket_id = 'covers' AND
    (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
);

CREATE POLICY "Permitir que administradores autenticados deletem capas" ON storage.objects FOR DELETE USING (
    bucket_id = 'covers' AND
    (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
);
