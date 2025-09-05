-- 
-- profiles table
-- 
CREATE TABLE public.profiles (
    id uuid NOT NULL REFERENCES auth.users ON DELETE CASCADE,
    email character varying,
    role text DEFAULT 'user'::text,
    CONSTRAINT profiles_pkey PRIMARY KEY (id),
    CONSTRAINT profiles_role_check CHECK ((role = ANY (ARRAY['user'::text, 'admin'::text])))
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

--
-- contents table
--
CREATE TABLE public.contents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    title text NOT NULL,
    theme text NOT NULL,
    type text NOT NULL,
    cover_url text NOT NULL,
    download_url text NOT NULL
);

ALTER TABLE public.contents ENABLE ROW LEVEL SECURITY;

--
-- handle_new_user function
--
create function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, role)
  values (new.id, new.email, 'user');
  return new;
end;
$$;

--
-- new user trigger
--
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();


--
-- Storage bucket and policies
--
INSERT INTO storage.buckets (id, name, public)
VALUES ('covers', 'covers', true);

CREATE POLICY "Allow public read access to covers" ON storage.objects
FOR SELECT TO anon, authenticated
USING (bucket_id = 'covers');

CREATE POLICY "Allow authenticated users to upload covers" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'covers');

CREATE POLICY "Allow users to update their own covers" ON storage.objects
FOR UPDATE TO authenticated
USING (auth.uid() = owner);

CREATE POLICY "Allow users to delete their own covers" ON storage.objects
FOR DELETE TO authenticated
USING (auth.uid() = owner);


--
-- RLS POLICIES
--

-- Policies for profiles
CREATE POLICY "Users can view their own profile" ON public.profiles
FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON public.profiles
FOR UPDATE USING (auth.uid() = id);

-- Policies for contents
CREATE POLICY "Authenticated users can view content" ON public.contents
FOR SELECT TO authenticated USING (true);

CREATE POLICY "Admin users can manage all content" ON public.contents
FOR ALL USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin')
WITH CHECK ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin');
