-- Create Profiles Table
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE,
  role TEXT DEFAULT 'user' NOT NULL
);

-- Create Contents Table
CREATE TABLE contents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  theme TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('book', 'audiobook')),
  cover_url TEXT NOT NULL,
  download_url TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Function to create a profile when a new user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role)
  VALUES (new.id, new.email, 'user');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to call the function on new user creation
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Enable Row Level Security (RLS) for tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE contents ENABLE ROW LEVEL SECURITY;

-- RLS Policies for Profiles
CREATE POLICY "Allow users to view their own profile"
ON profiles FOR SELECT
USING (auth.uid() = id);

-- RLS Policies for Contents
CREATE POLICY "Allow all users to view all content"
ON contents FOR SELECT
USING (true);

CREATE POLICY "Allow admins to insert content"
ON contents FOR INSERT
WITH CHECK ( (select role from profiles where id = auth.uid()) = 'admin' );

CREATE POLICY "Allow admins to update content"
ON contents FOR UPDATE
USING ( (select role from profiles where id = auth.uid()) = 'admin' );

CREATE POLICY "Allow admins to delete content"
ON contents FOR DELETE
USING ( (select role from profiles where id = auth.uid()) = 'admin' );


-- Supabase Storage Bucket and Policies
-- 1. Create a bucket named 'covers'
INSERT INTO storage.buckets (id, name, public)
VALUES ('covers', 'covers', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Create RLS policies for the 'covers' bucket

-- Policy: Allow all users to view images
CREATE POLICY "Allow public read access to covers"
ON storage.objects FOR SELECT
USING ( bucket_id = 'covers' );

-- Policy: Allow authenticated users to upload images into their own folder
CREATE POLICY "Allow authenticated users to upload covers"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'covers' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy: Allow authenticated users to update their own images
CREATE POLICY "Allow authenticated users to update their own covers"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'covers' AND
  (storage.foldername(name))[1] = auth.uid()::text
);


-- Policy: Allow authenticated users to delete their own images
CREATE POLICY "Allow authenticated users to delete their own covers"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'covers' AND
  (storage.foldername(name))[1] = auth.uid()::text
);
