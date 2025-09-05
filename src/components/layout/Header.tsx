'use client';

import Link from 'next/link';
import { Library, LogOut, User as UserIcon, Shield, Youtube } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { Button } from '@/components/ui/button';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import type { User } from '@supabase/supabase-js';
import type { Profile } from '@/lib/types';

const Logo = () => (
    <Link href="/" className="flex items-center gap-2">
        <Library className="h-6 w-6 text-primary" />
        <span className="hidden font-headline text-xl font-semibold sm:inline-block">
            Biblioteca Digital
        </span>
    </Link>
);

type HeaderProps = {
  user: User | null;
  profile: Profile | null;
};

export default function Header({ user, profile }: HeaderProps) {
  const supabase = createClient();
  
  const handleLogout = async () => {
    await supabase.auth.signOut();
    window.location.href = '/login';
  };

  const isAdmin = profile?.role === 'admin';

  return (
    <header className="sticky top-0 z-50 w-full border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="container flex h-16 items-center justify-between">
        <Logo />
        <nav className="hidden items-center gap-6 text-sm font-medium md:flex">
          <Link href="/" className="transition-colors hover:text-foreground/80 text-foreground/60">Início</Link>
          <Link href="/?type=book" className="transition-colors hover:text-foreground/80 text-foreground/60">Livros</Link>
          <Link href="/?type=audiobook" className="transition-colors hover:text-foreground/80 text-foreground/60">Audiolivros</Link>
          <Link href="/aulas" className="transition-colors hover:text-foreground/80 text-foreground/60">Vídeo Aulas</Link>
          {isAdmin && (
            <Link href="/admin" className="font-semibold text-primary transition-colors hover:text-primary/80">Painel Admin</Link>
          )}
        </nav>

        <div className="flex items-center gap-4">
          {user ? (
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="ghost" size="icon" className="rounded-full">
                  <UserIcon className="h-5 w-5" />
                  <span className="sr-only">Abrir menu do usuário</span>
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end">
                <DropdownMenuLabel>{user.email}</DropdownMenuLabel>
                <DropdownMenuSeparator />
                {isAdmin && (
                  <DropdownMenuItem asChild>
                    <Link href="/admin">
                      <Shield className="mr-2 h-4 w-4" />
                      <span>Painel Admin</span>
                    </Link>
                  </DropdownMenuItem>
                )}
                <DropdownMenuItem onClick={handleLogout}>
                  <LogOut className="mr-2 h-4 w-4" />
                  <span>Sair</span>
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          ) : (
            <div className="flex items-center gap-2">
              <Button variant="ghost" asChild>
                <Link href="/login">Entrar</Link>
              </Button>
              <Button asChild>
                <Link href="/signup">Cadastrar</Link>
              </Button>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
