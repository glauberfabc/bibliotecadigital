import type { Metadata } from 'next';
import './globals.css';
import { Toaster } from '@/components/ui/toaster';
import { cn } from '@/lib/utils';
import Header from '@/components/layout/Header';
import { createServerClient } from '@/lib/supabase/server';
import { cookies } from 'next/headers';
import type { Profile } from '@/lib/types';
import { UserProvider } from '@/hooks/use-user';

export const metadata: Metadata = {
  title: 'Biblioteca Digital',
  description: 'Sua coleção pessoal de livros e audiolivros.',
};

export default async function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const cookieStore = cookies();
  const supabase = createServerClient(cookieStore);

  const {
    data: { user },
  } = await supabase.auth.getUser();

  const { data: profile } = user
    ? await supabase.from('profiles').select('*').eq('id', user.id).single()
    : { data: null };

  return (
    <html lang="pt-BR" suppressHydrationWarning>
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;700&display=swap" rel="stylesheet" />
        <link href="https://fonts.googleapis.com/css2?family=Belleza&display=swap" rel="stylesheet" />
      </head>
      <body className={cn('font-body antialiased')}>
        <UserProvider profile={profile as Profile | null}>
          <div className="flex min-h-screen w-full flex-col">
            <Header user={user} profile={profile as Profile | null} />
            {children}
            <Toaster />
          </div>
        </UserProvider>
      </body>
    </html>
  );
}
