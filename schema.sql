-- Create a table for public profiles
CREATE TABLE profiles (
  id uuid NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  email TEXT,
  role TEXT DEFAULT 'user',
  PRIMARY KEY (id)
);
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create policies for profiles
CREATE POLICY "Public profiles are viewable by everyone." ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can insert their own profile." ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile." ON profiles FOR UPDATE USING (auth.uid() = id);

-- Set up a trigger to automatically create a profile when a new user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role)
  VALUES (new.id, new.email, 'user');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Create a table for contents (books, audiobooks)
CREATE TABLE contents (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    theme TEXT NOT NULL,
    cover_url TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('book', 'audiobook')),
    download_url TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
ALTER TABLE contents ENABLE ROW LEVEL SECURITY;

-- Create policies for contents
CREATE POLICY "Allow public read access to contents" ON contents FOR SELECT USING (true);
CREATE POLICY "Allow admin users to insert content" ON contents FOR INSERT WITH CHECK (
  (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
);
CREATE POLICY "Allow admin users to update content" ON contents FOR UPDATE USING (
  (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
);
CREATE POLICY "Allow admin users to delete content" ON contents FOR DELETE USING (
  (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
);


-- Set up Storage
-- 1. Create a bucket for covers
INSERT INTO storage.buckets (id, name, public)
VALUES ('covers', 'covers', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Set up policies for the covers bucket
-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Allow authenticated users to view covers" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to upload covers" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to update their own covers" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to delete their own covers" ON storage.objects;

-- Create a single, comprehensive policy for all actions
CREATE POLICY "Allow users to manage their own files in covers bucket"
ON storage.objects FOR ALL
TO authenticated
USING (
  bucket_id = 'covers' AND
  (storage.folder(name))[1] = auth.uid()::text
)
WITH CHECK (
  bucket_id = 'covers' AND
  (storage.folder(name))[1] = auth.uid()::text
);

-- Allow public read access to all files in the covers bucket
CREATE POLICY "Allow public read access to covers"
ON storage.objects FOR SELECT
USING ( bucket_id = 'covers' );
