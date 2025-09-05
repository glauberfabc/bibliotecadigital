import { createServerClient } from '@/lib/supabase/server';
import { cookies } from 'next/headers';
import ContentGrid from '@/components/ContentGrid';
import Header from '@/components/layout/Header';
import { type Content } from '@/lib/types';

export default async function Home() {
  const cookieStore = cookies();
  const supabase = createServerClient(cookieStore);

  const {
    data: { session },
  } = await supabase.auth.getSession();

  const { data: contents, error } = await supabase
    .from('contents')
    .select('*')
    .order('created_at', { ascending: false });

  if (error) {
    console.error('Error fetching contents:', error);
  }

  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', session?.user?.id)
    .single();

  return (
    <div className="flex min-h-screen w-full flex-col">
      <Header user={session?.user ?? null} profile={profile ?? null} />
      <main className="flex-1 px-4 py-8 md:px-6 lg:px-8">
        <div className="container mx-auto">
          <h1 className="mb-6 font-headline text-3xl font-bold tracking-tight text-foreground sm:text-4xl">
            Sua Biblioteca Digital
          </h1>
          <ContentGrid initialContents={(contents as Content[]) ?? []} />
        </div>
      </main>
    </div>
  );
}
