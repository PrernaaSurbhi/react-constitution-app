import React from 'react';

import type { Size, Variant } from '../../types';

// ─── Props ────────────────────────────────────────────────────────────────────

export interface ButtonProps {
  /** Visible button label */
  label: string;
  /** Click handler — typed per CONSTITUTION §1 */
  onClick: (event: React.MouseEvent<HTMLButtonElement>) => void;
  /** Visual style variant — defaults to primary */
  variant?: Variant;
  /** Size — defaults to md */
  size?: Size;
  /** Disables the button and prevents interaction */
  isDisabled?: boolean;
  /** Shows a loading spinner and disables interaction */
  isLoading?: boolean;
  /** Additional CSS class names */
  className?: string;
  /** Accessible label override when the visible label is insufficient */
  ariaLabel?: string;
  /** Button type attribute */
  type?: 'button' | 'submit' | 'reset';
}

// ─── Size & variant class maps ────────────────────────────────────────────────

const SIZE_CLASSES: Record<Size, string> = {
  sm: 'btn--sm',
  md: 'btn--md',
  lg: 'btn--lg',
};

const VARIANT_CLASSES: Record<Variant, string> = {
  primary: 'btn--primary',
  secondary: 'btn--secondary',
  danger: 'btn--danger',
  ghost: 'btn--ghost',
};

// ─── Component ────────────────────────────────────────────────────────────────

/**
 * Button — accessible, typed, constitution-compliant button component.
 *
 * CONSTITUTION compliance:
 *  §1  — explicit prop interface, typed event handler, no `any`
 *  §2  — single responsibility, <150 lines
 *  §4  — uses <button>, aria-label, disabled state
 *  §6  — PascalCase name, boolean props prefixed with `is`
 */
export const Button = ({
  label,
  onClick,
  variant = 'primary',
  size = 'md',
  isDisabled = false,
  isLoading = false,
  className = '',
  ariaLabel,
  type = 'button',
}: ButtonProps): React.JSX.Element => {
  const classes = [
    'btn',
    SIZE_CLASSES[size],
    VARIANT_CLASSES[variant],
    isLoading ? 'btn--loading' : '',
    className,
  ]
    .filter(Boolean)
    .join(' ');

  return (
    <button
      // §4 — use native <button> for all interactive actions
      type={type}
      className={classes}
      onClick={onClick}
      disabled={isDisabled || isLoading}
      // §4 — aria-label fallback when label text is not self-describing
      aria-label={ariaLabel ?? label}
      aria-busy={isLoading}
    >
      {isLoading ? (
        // §4 — hide spinner from screen readers; aria-busy on <button> conveys state
        <span aria-hidden="true" className="btn__spinner" />
      ) : null}
      <span>{label}</span>
    </button>
  );
};
