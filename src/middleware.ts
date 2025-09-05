import { NextResponse, type NextRequest } from 'next/server';
import { updateSession } from '@/lib/supabase/middleware';
import { createServerClient } from './lib/supabase/server';

export async function middleware(request: NextRequest) {
  // A função updateSession atualiza o cookie de sessão do usuário
  // e o retorna na resposta. É crucial executá-la primeiro.
  const { response, supabase } = await updateSession(request);

  const {
    data: { user },
  } = await supabase.auth.getUser();

  const isAuthPage = request.nextUrl.pathname.startsWith('/login') || request.nextUrl.pathname.startsWith('/signup');

  // Se o usuário não estiver logado e tentar acessar uma página protegida,
  // redireciona para a página de login.
  if (!user && !isAuthPage) {
    return NextResponse.redirect(new URL('/login', request.url));
  }

  // Se o usuário estiver logado, lida com os redirecionamentos.
  if (user) {
    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single();

    const isAdmin = profile?.role === 'admin';

    // Se um usuário logado estiver em uma página de autenticação, redireciona para a página apropriada.
    if (isAuthPage) {
      return NextResponse.redirect(new URL(isAdmin ? '/admin' : '/', request.url));
    }

    // Se um não-admin tentar acessar /admin, redireciona para a home.
    if (request.nextUrl.pathname.startsWith('/admin') && !isAdmin) {
      return NextResponse.redirect(new URL('/', request.url));
    }

    // Se um admin estiver na home, redireciona para /admin.
    if (request.nextUrl.pathname === '/' && isAdmin) {
      return NextResponse.redirect(new URL('/admin', request.url));
    }
  }

  // Retorna a resposta com o cookie de sessão atualizado.
  return response;
}

export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * Feel free to modify this pattern to include more paths.
     */
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
};
