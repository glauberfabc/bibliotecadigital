-- Drop existing policies and functions if they exist
DROP POLICY IF EXISTS "Enable read access for all users" ON "public"."contents";
DROP POLICY IF EXISTS "Admins can manage all content" ON "public"."contents";
DROP POLICY IF EXISTS "Enable read access for all users" ON "public"."profiles";
DROP POLICY IF EXISTS "Users can update their own profile" ON "public"."profiles";
DROP POLICY IF EXISTS "Admins can manage all profiles" ON "public"."profiles";
DROP FUNCTION IF EXISTS "public"."handle_new_user"() CASCADE;
DROP TABLE IF EXISTS "public"."profiles";
DROP TABLE IF EXISTS "public"."contents";
DROP TYPE IF EXISTS "public"."user_role";

-- Create user_role type
CREATE TYPE public.user_role AS ENUM (
    'user',
    'admin'
);

-- Create profiles table
CREATE TABLE public.profiles (
    id uuid NOT NULL PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email character varying,
    role public.user_role DEFAULT 'user'::public.user_role
);

-- Create contents table
CREATE TABLE public.contents (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    title character varying NOT NULL,
    theme character varying NOT NULL,
    cover_url character varying NOT NULL,
    type character varying NOT NULL,
    download_url character varying NOT NULL
);

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contents ENABLE ROW LEVEL SECURITY;

-- Create handle_new_user function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
  INSERT INTO public.profiles (id, email, role)
  VALUES (new.id, new.email, 'user'); -- Assign 'user' role by default
  RETURN new;
END;
$function$;

-- Create trigger for new users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Policies for profiles
CREATE POLICY "Enable read access for all users" ON "public"."profiles" FOR SELECT USING (true);
CREATE POLICY "Users can update their own profile" ON "public"."profiles" FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Admins can manage all profiles" ON "public"."profiles" FOR ALL USING (
  (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
);

-- Policies for contents
CREATE POLICY "Enable read access for all users" ON "public"."contents" FOR SELECT USING (true);
CREATE POLICY "Admins can manage all content" ON "public"."contents" FOR ALL USING (
  (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
);

-- Grant permissions
GRANT USAGE ON SCHEMA public TO postgres;
GRANT ALL ON TABLE public.profiles TO postgres;
GRANT ALL ON TABLE public.contents TO postgres;
GRANT ALL ON FUNCTION public.handle_new_user() TO postgres;
GRANT ALL ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.profiles TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.contents TO anon, authenticated, service_role;
GRANT ALL ON FUNCTION public.handle_new_user() TO anon, authenticated, service_role;
