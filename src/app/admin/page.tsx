import { createServerClient } from '@/lib/supabase/server';
import { cookies } from 'next/headers';
import Header from '@/components/layout/Header';
import ContentDataTable from '@/components/admin/ContentDataTable';
import { columns } from '@/components/admin/columns';
import { type Content } from '@/lib/types';

export default async function AdminDashboard() {
  const cookieStore = cookies();
  const supabase = createServerClient(cookieStore);

  const {
    data: { session },
  } = await supabase.auth.getSession();

  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', session?.user?.id)
    .single();

  const { data, error } = await supabase
    .from('contents')
    .select('*')
    .order('created_at', { ascending: false });

  if (error) {
    console.error('Error fetching content for admin:', error);
  }
  
  const contents: Content[] = data || [];

  return (
    <div className="flex min-h-screen w-full flex-col">
      <Header user={session?.user ?? null} profile={profile ?? null} />
      <main className="flex-1 px-4 py-8 md:px-6 lg:px-8">
        <div className="container mx-auto">
          <div className="mb-6 flex items-center justify-between">
            <h1 className="font-headline text-3xl font-bold tracking-tight text-foreground sm:text-4xl">
              Gerenciamento de Conteúdo
            </h1>
          </div>
          <ContentDataTable columns={columns} data={contents} />
        </div>
      </main>
    </div>
  );
}
