import type { Metadata } from 'next';
import './globals.css';
import { Toaster } from '@/components/ui/toaster';
import { cn } from '@/lib/utils';
import { createServerClient } from '@/lib/supabase/server';
import { cookies } from 'next/headers';
import Header from '@/components/layout/Header';

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
    data: { session },
  } = await supabase.auth.getSession();

  const { data: profile } = session?.user
    ? await supabase
        .from('profiles')
        .select('role')
        .eq('id', session.user.id)
        .single()
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
        <div className="flex min-h-screen w-full flex-col">
          <Header user={session?.user ?? null} profile={profile ?? null} />
          {children}
          <Toaster />
        </div>
      </body>
    </html>
  );
}
