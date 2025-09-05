import { createServerClient } from '@/lib/supabase/server';
import { cookies } from 'next/headers';
import ContentGrid from '@/components/ContentGrid';
import { type Content } from '@/lib/types';
import { UserProvider } from '@/context/UserProvider';

export default async function Home() {
  const cookieStore = cookies();
  const supabase = createServerClient(cookieStore);

  const { data: contents, error } = await supabase
    .from('contents')
    .select('*')
    .order('created_at', { ascending: false });

  if (error) {
    console.error('Error fetching contents:', error);
  }

  return (
    <UserProvider>
      <main className="flex-1 px-4 py-8 md:px-6 lg:px-8">
        <div className="container mx-auto">
          <h1 className="mb-6 font-headline text-3xl font-bold tracking-tight text-foreground sm:text-4xl">
            Sua Biblioteca Digital
          </h1>
          <ContentGrid initialContents={(contents as Content[]) ?? []} />
        </div>
      </main>
    </UserProvider>
  );
}
