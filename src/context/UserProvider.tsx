'use client';

import { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import { createClient } from '@/lib/supabase/client';
import type { User } from '@supabase/supabase-js';
import type { Profile } from '@/lib/types';

type UserContextType = {
  user: User | null;
  profile: Profile | null;
  loading: boolean;
};

const UserContext = createContext<UserContextType>({
  user: null,
  profile: null,
  loading: true,
});

type UserProviderProps = {
  children: ReactNode;
  user: User | null;
  profile: Profile | null;
};

export function UserProvider({ children, user: initialUser, profile: initialProfile }: UserProviderProps) {
  const supabase = createClient();
  const [user, setUser] = useState<User | null>(initialUser);
  const [profile, setProfile] = useState<Profile | null>(initialProfile);
  // O carregamento é verdadeiro até que a primeira verificação seja concluída.
  const [loading, setLoading] = useState(initialUser === null);

  useEffect(() => {
    const { data: authListener } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        setLoading(true);
        const currentUser = session?.user ?? null;
        setUser(currentUser);

        if (currentUser) {
          if (!profile || profile.id !== currentUser.id) {
            const { data: userProfile } = await supabase
              .from('profiles')
              .select('*')
              .eq('id', currentUser.id)
              .single();
            setProfile(userProfile as Profile);
          }
        } else {
          setProfile(null);
        }
        setLoading(false);
      }
    );
    
    // Garante que o estado de carregamento termine após a configuração inicial do listener.
    if(initialUser) {
        setLoading(false);
    }

    return () => {
      authListener.subscription.unsubscribe();
    };
  }, [profile, supabase, initialUser]);

  const value = {
    user,
    profile,
    // Loading é verdadeiro se o usuário não foi carregado OU se o usuário existe, mas o perfil ainda não.
    loading: loading || (user != null && profile === null),
  };

  return <UserContext.Provider value={value}>{children}</UserContext.Provider>;
}

export const useUser = () => {
  const context = useContext(UserContext);
  if (context === undefined) {
    throw new Error('useUser must be used within a UserProvider.');
  }
  return context;
};
