-- Drop existing policies and functions if they exist to ensure a clean slate
DROP POLICY IF EXISTS "Allow authenticated users to read content" ON public.contents;
DROP POLICY IF EXISTS "Allow admins to do anything on content" ON public.contents;
DROP POLICY IF EXISTS "Allow users to read their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow users to update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow admins to do anything on profiles" ON public.profiles;

DROP FUNCTION IF EXISTS public.handle_new_user();
DROP FUNCTION IF EXISTS public.is_admin();


-- Create profiles table
CREATE TABLE public.profiles (
    id uuid NOT NULL PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email character varying,
    role text DEFAULT 'user'::text NOT NULL
);
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE public.profiles IS 'Stores public profile information for each user.';

-- Create contents table
CREATE TABLE public.contents (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    title text NOT NULL,
    theme text NOT NULL,
    cover_url text NOT NULL,
    type text NOT NULL,
    download_url text NOT NULL
);
ALTER TABLE public.contents ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE public.contents IS 'Stores the digital content like books and audiobooks.';


-- Function to create a new profile for a new user
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
  INSERT INTO public.profiles (id, email, role)
  VALUES (new.id, new.email, 'user');
  return new;
END;
$function$;

-- Trigger to call handle_new_user on new user signup
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();


-- RLS Policies for profiles table
CREATE POLICY "Allow users to read their own profile"
ON public.profiles FOR SELECT
USING (auth.uid() = id);

CREATE POLICY "Allow users to update their own profile"
ON public.profiles FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- RLS Policies for contents table
CREATE POLICY "Allow authenticated users to read content"
ON public.contents FOR SELECT
TO authenticated
USING (true);


-- Grant permissions to postgres role
GRANT ALL ON TABLE public.profiles TO postgres;
GRANT ALL ON TABLE public.contents TO postgres;
GRANT ALL ON FUNCTION public.handle_new_user() TO postgres;

-- Grant usage to anon and authenticated roles
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON TABLE public.profiles TO anon, authenticated;
GRANT ALL ON TABLE public.contents TO anon, authenticated;
GRANT ALL ON FUNCTION public.handle_new_user() TO anon, authenticated;

-- Grant permissions for Supabase storage
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('covers', 'covers', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp'])
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Allow anyone to view cover images"
ON storage.objects FOR SELECT
USING (bucket_id = 'covers');

CREATE POLICY "Allow authenticated users to upload cover images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'covers');

CREATE POLICY "Allow authenticated users to update their own cover images"
ON storage.objects FOR UPDATE
TO authenticated
USING (auth.uid() = owner);

CREATE POLICY "Allow authenticated users to delete their own cover images"
ON storage.objects FOR DELETE
TO authenticated
USING (auth.uid() = owner);
