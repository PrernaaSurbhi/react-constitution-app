// src/hooks/useUserSearch.ts — CONSTITUTION §3, §7, §8
// Extracts all business logic out of JSX (Rule 7, 8)

import { useDeferredValue, useMemo, useState } from 'react';

// ─── Types ────────────────────────────────────────────────────────────────────

export interface User {
  id: number;
  name: string;
  role: string;
  email: string;
  avatarInitials: string;
}

// ─── Static data (would be an API call in a real app) ─────────────────────────

const USERS: User[] = [
  {
    id: 1,
    name: 'Alice Johnson',
    role: 'Engineer',
    email: 'alice@example.com',
    avatarInitials: 'AJ',
  },
  { id: 2, name: 'Bob Martinez', role: 'Designer', email: 'bob@example.com', avatarInitials: 'BM' },
  {
    id: 3,
    name: 'Carol Williams',
    role: 'Manager',
    email: 'carol@example.com',
    avatarInitials: 'CW',
  },
  { id: 4, name: 'David Lee', role: 'Engineer', email: 'david@example.com', avatarInitials: 'DL' },
  { id: 5, name: 'Eva Chen', role: 'QA', email: 'eva@example.com', avatarInitials: 'EC' },
  { id: 6, name: 'Frank Nguyen', role: 'DevOps', email: 'frank@example.com', avatarInitials: 'FN' },
];

// ─── Hook ─────────────────────────────────────────────────────────────────────

export interface UseUserSearchReturn {
  query: string;
  handleQueryChange: (event: React.ChangeEvent<HTMLInputElement>) => void;
  handleClear: () => void;
  results: User[];
  selectedUser: User | null;
  handleSelectUser: (user: User) => void;
  handleDismiss: () => void;
}

export function useUserSearch(): UseUserSearchReturn {
  const [query, setQuery] = useState('');
  const [selectedUser, setSelectedUser] = useState<User | null>(null);

  // memoised: defer filtering so typing stays instant on large lists (§5)
  const deferredQuery = useDeferredValue(query);

  // memoised: avoid re-filtering on every keystroke (§3, §5)
  const results = useMemo((): User[] => {
    const q = deferredQuery.trim().toLowerCase();
    if (!q) return USERS;
    return USERS.filter(
      (u) =>
        u.name.toLowerCase().includes(q) ||
        u.role.toLowerCase().includes(q) ||
        u.email.toLowerCase().includes(q),
    );
  }, [deferredQuery]);

  // Keep handlers stable — defined once, not recreated in JSX (Rule 7)
  const handleQueryChange = (event: React.ChangeEvent<HTMLInputElement>): void => {
    setQuery(event.target.value);
  };

  const handleClear = (): void => {
    setQuery('');
    setSelectedUser(null);
  };

  const handleSelectUser = (user: User): void => {
    setSelectedUser(user);
  };

  const handleDismiss = (): void => {
    setSelectedUser(null);
  };

  return {
    query,
    handleQueryChange,
    handleClear,
    results,
    selectedUser,
    handleSelectUser,
    handleDismiss,
  };
}
