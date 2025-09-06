'use client';

import { createContext, useContext } from 'react';
import type { Profile } from '@/lib/types';

type UserContextType = {
  profile: Profile | null;
};

const UserContext = createContext<UserContextType | undefined>(undefined);

export const UserProvider = ({
  children,
  profile,
}: {
  children: React.ReactNode;
  profile: Profile | null;
}) => {
  return (
    <UserContext.Provider value={{ profile }}>
      {children}
    </UserContext.Provider>
  );
};

export const useUser = () => {
  const context = useContext(UserContext);
  if (context === undefined) {
    throw new Error('useUser must be used within a UserProvider');
  }
  return context;
};
