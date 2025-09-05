-- Create a table for public profiles
CREATE TABLE public.profiles (
  id uuid NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  email TEXT,
  role TEXT DEFAULT 'user',
  PRIMARY KEY (id)
);
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Create a table for contents
CREATE TABLE public.contents (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    theme TEXT NOT NULL,
    cover_url TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('book', 'audiobook')),
    download_url TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
ALTER TABLE public.contents ENABLE ROW LEVEL SECURITY;

-- Set up Storage!
INSERT INTO storage.buckets (id, name, public)
VALUES ('covers', 'covers', true);

CREATE POLICY "Cover images are publicly accessible." ON storage.objects
AS PERMISSIVE FOR SELECT
TO public
USING (bucket_id = 'covers');

CREATE POLICY "Anyone can upload a cover." ON storage.objects
AS PERMISSIVE FOR INSERT
TO public
WITH CHECK (bucket_id = 'covers');

CREATE POLICY "Anyone can update their own cover." ON storage.objects
AS PERMISSIVE FOR UPDATE
TO public
USING (auth.uid() = owner);

CREATE POLICY "Anyone can delete their own cover." ON storage.objects
AS PERMISSIVE FOR DELETE
TO public
USING (auth.uid() = owner);

-- Custom Claims
CREATE OR REPLACE FUNCTION public.custom_user_claims()
RETURNS jsonb
LANGUAGE sql STABLE
AS $$
  SELECT
    jsonb_build_object(
      'claims', jsonb_agg(
        jsonb_build_object(
          'role', role
        )
      )
    )
  FROM public.profiles
  WHERE id = auth.uid()
$$;

-- Function to check if a user is an admin
CREATE OR REPLACE FUNCTION is_admin(user_id uuid)
RETURNS boolean AS $$
DECLARE
  user_role TEXT;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN FALSE;
  END IF;

  SELECT role INTO user_role FROM public.profiles WHERE id = user_id;
  RETURN user_role = 'admin';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- Set up Realtime!
BEGIN;
  DROP PUBLICATION IF EXISTS supabase_realtime;
  CREATE PUBLICATION supabase_realtime;
COMMIT;
ALTER PUBLICATION supabase_realtime ADD TABLE public.contents;
ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;

-- Function to create a new profile for a new user
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role)
  VALUES (new.id, new.email, 'user');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to call handle_new_user on new user sign up
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Grant usage on the DDL schema to the postgres user
GRANT USAGE ON SCHEMA ddl TO postgres;
GRANT USAGE ON SCHEMA auth TO postgres;
GRANT SELECT ON ALL TABLES IN SCHEMA auth TO postgres;

-- Policies for profiles table
CREATE POLICY "Allow authenticated users to read their own profile" ON public.profiles
AS PERMISSIVE FOR SELECT
TO authenticated
USING (auth.uid() = id);

CREATE POLICY "Allow admin users to have full access to all profiles" ON public.profiles
AS PERMISSIVE FOR ALL
TO public
USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin')
WITH CHECK ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin');

-- Policies for contents table
CREATE POLICY "Allow public read access to all contents" ON public.contents
AS PERMISSIVE FOR SELECT
TO public
USING (true);

CREATE POLICY "Allow admin full access to contents" ON public.contents
AS PERMISSIVE FOR ALL
TO public
USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin')
WITH CHECK ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin');
