-- Drop existing tables, functions, and triggers to ensure a clean slate.
-- Using CASCADE to automatically drop dependent objects like policies and triggers.
DROP TABLE IF EXISTS public.contents CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;

-- Create profiles table
-- This table will store user data, including their role.
CREATE TABLE public.profiles (
    id uuid NOT NULL PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR(255),
    role TEXT DEFAULT 'user'
);

-- Create contents table
-- This table will store the digital library content.
CREATE TABLE public.contents (
    id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    title text NOT NULL,
    theme text NOT NULL,
    cover_url text NOT NULL,
    type text NOT NULL,
    download_url text NOT NULL
);

-- Secure the tables by enabling Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contents ENABLE ROW LEVEL SECURITY;
 
-- Function to create a new profile for a new user upon registration.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role)
  VALUES (new.id, new.email, 'user'); -- New users are assigned the 'user' role by default.
  RETURN new;
END;
$$;

-- Trigger to execute the handle_new_user function when a new user signs up.
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Define Row Level Security policies for the 'profiles' table.
CREATE POLICY "Public profiles are viewable by everyone." ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can insert their own profile." ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update their own profile." ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Define Row Level Security policies for the 'contents' table.
CREATE POLICY "Authenticated users can view all content." ON public.contents FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admins can manage all content." ON public.contents FOR ALL
    USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin')
    WITH CHECK ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin');

-- Define Row Level Security policies for the 'storage.objects' (for cover images).
CREATE POLICY "Authenticated users can view covers." ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'covers');
CREATE POLICY "Admins can upload covers." ON storage.objects FOR INSERT TO authenticated 
    WITH CHECK (bucket_id = 'covers' AND (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin');
CREATE POLICY "Admins can update covers." ON storage.objects FOR UPDATE TO authenticated 
    USING (bucket_id = 'covers' AND (SELECT role FROM public.profiles WHERE id = auth.uid()));
CREATE POLICY "Admins can delete covers." ON storage.objects FOR DELETE TO authenticated 
    USING (bucket_id = 'covers' AND (SELECT role FROM public.profiles WHERE id = auth.uid()));