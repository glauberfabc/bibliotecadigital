-- Drop tables with CASCADE to remove dependent objects like policies
DROP TABLE IF EXISTS public.contents CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

-- Drop trigger and function if they exist
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user;

-- Create profiles table
CREATE TABLE public.profiles (
    id uuid NOT NULL REFERENCES auth.users ON DELETE CASCADE,
    email character varying,
    role text DEFAULT 'user'::text,
    PRIMARY KEY (id)
);
ALTER TABLE public.profiles CLUSTER ON profiles_pkey;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Create contents table
CREATE TABLE public.contents (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    title text NOT NULL,
    theme text NOT NULL,
    type text NOT NULL,
    cover_url text NOT NULL,
    download_url text NOT NULL,
    PRIMARY KEY (id)
);
ALTER TABLE public.contents ENABLE ROW LEVEL SECURITY;

-- Function to create a new profile when a user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
  INSERT INTO public.profiles (id, email, role)
  VALUES (new.id, new.email, 'user');
  RETURN new;
END;
$function$;

-- Trigger to call the function on new user creation
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Policies for profiles table
CREATE POLICY "Allow users to read their own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Allow users to update their own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Admins can manage all profiles" ON public.profiles FOR ALL USING (( SELECT role FROM profiles WHERE id = auth.uid() ) = 'admin');

-- Policies for contents table
CREATE POLICY "Allow authenticated users to read content" ON public.contents FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow admin users to manage all content" ON public.contents FOR ALL USING (( SELECT role FROM profiles WHERE id = auth.uid() ) = 'admin');

-- Policies for storage (book covers)
CREATE POLICY "Allow authenticated users to view covers" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'covers');
CREATE POLICY "Allow admin users to manage covers" ON storage.objects FOR ALL USING (bucket_id = 'covers' AND ( SELECT role FROM profiles WHERE id = auth.uid() ) = 'admin');
