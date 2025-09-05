import { createServerClient } from '@/lib/supabase/server';
import { cookies } from 'next/headers';
import ContentDataTable from '@/components/admin/ContentDataTable';
import { columns } from '@/components/admin/columns';
import { type Content } from '@/lib/types';
import { UserProvider } from '@/context/UserProvider';

export default async function AdminDashboard() {
  const cookieStore = cookies();
  const supabase = createServerClient(cookieStore);

  const { data, error } = await supabase
    .from('contents')
    .select('*')
    .order('created_at', { ascending: false });

  if (error) {
    console.error('Error fetching content for admin:', error);
  }
  
  const contents: Content[] = data || [];

  return (
    <UserProvider>
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
    </UserProvider>
  );
}
