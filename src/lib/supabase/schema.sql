-- Create the 'contents' table
CREATE TABLE IF NOT EXISTS public.contents (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    title text NOT NULL,
    theme text NOT NULL,
    cover_url text NOT NULL,
    type public.content_type NOT NULL,
    download_url text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

-- Create the 'profiles' table
CREATE TABLE IF NOT EXISTS public.profiles (
    id uuid NOT NULL PRIMARY KEY,
    email text,
    role public.user_role DEFAULT 'user'::public.user_role NOT NULL,
    CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users (id) ON DELETE CASCADE
);

--
-- RLS Policies for 'contents' table
--
ALTER TABLE public.contents ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read access to all content" ON public.contents;
CREATE POLICY "Allow public read access to all content" ON public.contents FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow admin users to manage all content" ON public.contents;
CREATE POLICY "Allow admin users to manage all content" ON public.contents FOR ALL
USING (
  (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
)
WITH CHECK (
  (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
);


--
-- RLS Policies for 'profiles' table
--
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow authenticated users to read their own profile" ON public.profiles;
CREATE POLICY "Allow authenticated users to read their own profile" ON public.profiles FOR SELECT
TO authenticated
USING (auth.uid() = id);

DROP POLICY IF EXISTS "Allow admins to manage all profiles" ON public.profiles;
CREATE POLICY "Allow admins to manage all profiles" ON public.profiles FOR ALL
TO authenticated
USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin')
WITH CHECK ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin');

--
-- Function and Trigger to create a profile for a new user
--
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role)
  VALUES (new.id, new.email, 'user');
  return new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Grant permissions for the handle_new_user function
GRANT SELECT ON auth.users TO postgres;
