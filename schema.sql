-- 1. Create tables if they don't exist

-- Create a table for public profiles
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  email VARCHAR(255),
  role VARCHAR(50) DEFAULT 'user',
  PRIMARY KEY (id)
);

-- Create a table for contents
CREATE TABLE IF NOT EXISTS public.contents (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  title VARCHAR(255) NOT NULL,
  theme VARCHAR(255) NOT NULL,
  cover_url TEXT NOT NULL,
  type VARCHAR(50) NOT NULL, -- 'book' or 'audiobook'
  download_url TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (id)
);


-- 2. Set up Row Level Security (RLS)

-- Enable RLS for profiles and contents table if not already enabled
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contents ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Public profiles are viewable by everyone." ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile." ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile." ON public.profiles;
DROP POLICY IF EXISTS "Admins can do anything." ON public.profiles;

DROP POLICY IF EXISTS "Contents are viewable by authenticated users." ON public.contents;
DROP POLICY IF EXISTS "Admins can insert content." ON public.contents;
DROP POLICY IF EXISTS "Admins can update content." ON public.contents;
DROP POLICY IF EXISTS "Admins can delete content." ON public.contents;
DROP POLICY IF EXISTS "Admins can do anything." ON public.contents;

-- Create policies for profiles
CREATE POLICY "Public profiles are viewable by everyone." ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can insert their own profile." ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile." ON public.profiles FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
CREATE POLICY "Admins can do anything." ON public.profiles FOR ALL USING (
  (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
);

-- Create policies for contents
CREATE POLICY "Contents are viewable by authenticated users." ON public.contents FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Admins can insert content." ON public.contents FOR INSERT WITH CHECK (
  (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
);
CREATE POLICY "Admins can update content." ON public.contents FOR UPDATE USING (
  (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
) WITH CHECK (
  (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
);
CREATE POLICY "Admins can delete content." ON public.contents FOR DELETE USING (
  (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
);

-- 3. Create a trigger to create a profile when a new user signs up

-- Drop the function and trigger if they exist to recreate them
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Create the function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role)
  VALUES (new.id, new.email, 'user');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- 4. Set up Supabase Storage and policies

-- Create a bucket for covers if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('covers', 'covers', true)
ON CONFLICT (id) DO NOTHING;

-- Drop existing storage policies to avoid conflicts
DROP POLICY IF EXISTS "Allow authenticated users to view covers" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to manage their own folder in covers" ON storage.objects;

-- Create policies for storage
CREATE POLICY "Allow authenticated users to view covers" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'covers');

CREATE POLICY "Allow authenticated users to manage their own folder in covers"
ON storage.objects FOR ALL
USING (
  bucket_id = 'covers' AND
  auth.uid() = (storage.foldername(name))[1]::uuid
)
WITH CHECK (
  bucket_id = 'covers' AND
  auth.uid() = (storage.foldername(name))[1]::uuid
);
