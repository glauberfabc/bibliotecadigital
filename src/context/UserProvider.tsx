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
  const [loading, setLoading] = useState(initialUser === null);

  useEffect(() => {
    const { data: authListener } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        const currentUser = session?.user ?? null;
        setUser(currentUser);

        if (currentUser) {
          const { data: userProfile } = await supabase
            .from('profiles')
            .select('*')
            .eq('id', currentUser.id)
            .single();
          setProfile(userProfile as Profile);
        } else {
          setProfile(null);
        }
        setLoading(false);
      }
    );
    
    // If there was no initial user, we might be waiting for the client-side auth check
    if (!initialUser) {
        setLoading(false);
    }

    return () => {
      authListener.subscription.unsubscribe();
    };
  }, [supabase, initialUser]);

  const value = {
    user,
    profile,
    loading,
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
