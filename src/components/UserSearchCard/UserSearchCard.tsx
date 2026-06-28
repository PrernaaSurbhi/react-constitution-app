import React from 'react';

import styles from './UserSearchCard.module.css';
import { useUserSearch } from '../../hooks/useUserSearch';
import type { User } from '../../hooks/useUserSearch';

// ─── Sub-component: UserListItem ──────────────────────────────────────────────
// Small, focused component — Rule 3. Extracted to avoid >150 line JSX — §2.

interface UserListItemProps {
  user: User;
  isSelected: boolean;
  onSelect: (user: User) => void;
}

const UserListItem = ({ user, isSelected, onSelect }: UserListItemProps): React.JSX.Element => {
  // Keep handler out of JSX — Rule 7
  const handleClick = (): void => onSelect(user);
  const handleKeyDown = (e: React.KeyboardEvent<HTMLLIElement>): void => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      onSelect(user);
    }
  };

  return (
    <li
      // §4 — role + tabIndex + keyboard handler for interactive non-button element
      role="option"
      aria-selected={isSelected}
      tabIndex={0}
      className={`${styles.listItem} ${isSelected ? styles.listItemSelected : ''}`}
      onClick={handleClick}
      onKeyDown={handleKeyDown}
    >
      {/* §4 — decorative avatar uses aria-hidden */}
      <div className={styles.avatar} aria-hidden="true">
        {user.avatarInitials}
      </div>
      <div>
        <div className={styles.userName}>{user.name}</div>
        <div className={styles.userRole}>{user.role}</div>
      </div>
    </li>
  );
};

// ─── Sub-component: UserDetail ────────────────────────────────────────────────

interface UserDetailProps {
  user: User;
  onDismiss: () => void;
}

const UserDetail = ({ user, onDismiss }: UserDetailProps): React.JSX.Element => (
  <section className={styles.detail} aria-label={`Details for ${user.name}`}>
    <div className={styles.detailHeader}>
      {/* §4 — decorative avatar */}
      <div className={styles.detailAvatarLg} aria-hidden="true">
        {user.avatarInitials}
      </div>
      <div>
        <h3 className={styles.detailName}>{user.name}</h3>
        <span className={styles.detailBadge}>{user.role}</span>
      </div>
    </div>

    {/* §4 — email link is descriptive */}
    <a
      href={`mailto:${user.email}`}
      className={styles.detailEmail}
      aria-label={`Send email to ${user.name}`}
    >
      {user.email}
    </a>

    <button
      type="button"
      className={styles.dismissBtn}
      onClick={onDismiss}
      aria-label="Close user detail"
    >
      ✕ Close
    </button>
  </section>
);

// ─── Main Component: UserSearchCard ───────────────────────────────────────────
// One responsibility: let users search and inspect a user — Rule 1.
// All business logic lives in useUserSearch — Rule 7, 8.

/**
 * UserSearchCard — interactive user search + detail panel.
 *
 * CONSTITUTION compliance:
 *  §1  — explicit prop interfaces, typed event handlers, no `any`
 *  §2  — single responsibility, sub-components extracted (<150 lines each)
 *  §3  — hooks called at top level; useMemo + useDeferredValue in hook
 *  §4  — listbox role, aria-label on input, keyboard navigation
 *  §6  — PascalCase names, handle* handlers, is* booleans
 *  §9  — CSS Modules, CSS custom properties, no inline style
 */
export const UserSearchCard = (): React.JSX.Element => {
  const {
    query,
    handleQueryChange,
    handleClear,
    results,
    selectedUser,
    handleSelectUser,
    handleDismiss,
  } = useUserSearch();

  // Early return pattern (Rule 6) is not needed here (no loading/error state)
  // because data is static — avoid unnecessary state §3 Rule 9.
  const hasQuery = query.trim().length > 0;

  return (
    <article className={styles.card} aria-label="User search">
      {/* ── Header + Search ── */}
      <header className={styles.header}>
        <h2 className={styles.title}>Find a Team Member</h2>

        {/* §4 — input has aria-label, wrapped in a visible group */}
        <div className={styles.searchGroup} role="search">
          <label htmlFor="user-search" className="sr-only">
            Search users by name, role, or email
          </label>
          <input
            id="user-search"
            type="search"
            className={styles.searchInput}
            placeholder="Search by name, role, or email…"
            value={query}
            onChange={handleQueryChange}
            autoComplete="off"
            aria-controls="user-listbox"
            aria-label="Search users by name, role, or email"
          />
          {/* Only render clear button when there is a query — early return pattern Rule 6 */}
          {hasQuery && (
            <button
              type="button"
              className={styles.clearBtn}
              onClick={handleClear}
              aria-label="Clear search"
            >
              ✕
            </button>
          )}
        </div>
      </header>

      {/* ── Results count ── */}
      <p className={styles.resultsCount} aria-live="polite">
        {results.length} {results.length === 1 ? 'member' : 'members'} found
      </p>

      {/* ── User list ── */}
      {results.length > 0 ? (
        // §4 — listbox role for the interactive option list
        <ul id="user-listbox" className={styles.list} role="listbox" aria-label="User results">
          {results.map((user) => (
            // §5 — stable unique key (user.id, not array index)
            <UserListItem
              key={user.id}
              user={user}
              isSelected={selectedUser?.id === user.id}
              onSelect={handleSelectUser}
            />
          ))}
        </ul>
      ) : (
        <p className={styles.empty} role="status">
          No members match &ldquo;{query}&rdquo;
        </p>
      )}

      {/* ── Detail panel — shown only when a user is selected (early return) ── */}
      {selectedUser !== null && <UserDetail user={selectedUser} onDismiss={handleDismiss} />}
    </article>
  );
};
