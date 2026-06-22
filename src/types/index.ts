// src/types/index.ts — shared TypeScript types (CONSTITUTION §1 & §7)

// Common API response wrapper
export interface ApiResponse<T> {
  data: T;
  error: string | null;
  isLoading: boolean;
}

// Common component size variants
export type Size = 'sm' | 'md' | 'lg';

// Common component variants
export type Variant = 'primary' | 'secondary' | 'danger' | 'ghost';

// Common status types
export type Status = 'idle' | 'loading' | 'success' | 'error';
