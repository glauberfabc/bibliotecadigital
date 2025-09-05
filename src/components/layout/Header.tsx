'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Book, Library, LogOut, Mic, User as UserIcon } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { Button } from '@/components/ui/button';
import { useUser } from '@/context/UserProvider';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { type User } from '@supabase/supabase-js';
import { type Profile } from '@/lib/types';

const Logo = () => (
    <Link href="/" className="flex items-center gap-2">
        <Library className="h-6 w-6 text-primary" />
        <span className="hidden font-headline text-xl font-semibold sm:inline-block">
            Digital Library
        </span>
    </Link>
);


export default function Header({ user, profile }: { user: User | null, profile: Profile | null }) {
  const router = useRouter();
  const supabase = createClient();
  const { loading } = useUser();

  const handleLogout = async () => {
    await supabase.auth.signOut();
    router.push('/login');
  };

  const isAdmin = profile?.role === 'admin';

  return (
    <header className="sticky top-0 z-50 w-full border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="container flex h-16 items-center justify-between">
        <Logo />
        <nav className="hidden items-center gap-6 text-sm font-medium md:flex">
          <Link href="/" className="transition-colors hover:text-foreground/80 text-foreground/60">Home</Link>
          <Link href="/?type=book" className="transition-colors hover:text-foreground/80 text-foreground/60">Books</Link>
          <Link href="/?type=audiobook" className="transition-colors hover:text-foreground/80 text-foreground/60">Audiobooks</Link>
          {isAdmin && (
            <Link href="/admin" className="font-semibold text-primary transition-colors hover:text-primary/80">Admin Dashboard</Link>
          )}
        </nav>

        <div className="flex items-center gap-4">
          {loading ? null : user ? (
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="ghost" size="icon" className="rounded-full">
                  <UserIcon className="h-5 w-5" />
                  <span className="sr-only">Toggle user menu</span>
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end">
                <DropdownMenuLabel>{user.email}</DropdownMenuLabel>
                <DropdownMenuSeparator />
                {isAdmin && <DropdownMenuItem asChild><Link href="/admin">Admin Dashboard</Link></DropdownMenuItem>}
                <DropdownMenuItem onClick={handleLogout}>
                  <LogOut className="mr-2 h-4 w-4" />
                  <span>Logout</span>
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          ) : (
            <div className="flex items-center gap-2">
              <Button variant="ghost" asChild>
                <Link href="/login">Login</Link>
              </Button>
              <Button asChild>
                <Link href="/signup">Sign Up</Link>
              </Button>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
