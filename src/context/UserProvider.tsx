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
  const [loading, setLoading] = useState(false); // Start with false as initial data is provided

  useEffect(() => {
    const { data: authListener } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        const currentUser = session?.user ?? null;
        setUser(currentUser);

        if (currentUser) {
          // If the user exists but the profile is not loaded or doesn't match, fetch it.
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

    return () => {
      authListener.subscription.unsubscribe();
    };
  }, [profile, supabase]); // Depend on profile to refetch if it's missing

  const value = {
    user,
    profile,
    loading: loading || (user !== null && profile === null), // Loading is true if user is logged in but profile is still being fetched
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
