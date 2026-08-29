"use client";

import { useEffect, useRef, useState, type ReactNode } from "react";
import clsx from "clsx";

const PANEL_ID = "navbar-mobile-menu";

/**
 * NavbarMobileMenu — the responsive wrapper around the navbar's secondary links
 * (Search, role link, account/Logout, or Login + Sign Up when signed out).
 *
 * At >= md it renders its children as a plain inline flex row in source order —
 * the current desktop layout. Below md the children collapse behind a single
 * toggle button and open as a dropdown panel. It is **one subtree reflowed by
 * breakpoint**, never a duplicated set of links, so the accessibility tree (and
 * React Testing Library's single-match queries) always see exactly one of each
 * item. `open` defaults to `false` so SSR and the first client paint agree — no
 * hydration flash. Escape closes and returns focus to the toggle; an outside
 * click closes. Mirrors NotificationBell's ref + document-listener idiom.
 */
export function NavbarMobileMenu({ children }: { children: ReactNode }) {
  const [open, setOpen] = useState(false);
  const rootRef = useRef<HTMLDivElement>(null);
  const toggleRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    if (!open) return;
    function onDocClick(e: MouseEvent) {
      if (rootRef.current && !rootRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    }
    function onKey(e: KeyboardEvent) {
      if (e.key === "Escape") {
        setOpen(false);
        toggleRef.current?.focus();
      }
    }
    document.addEventListener("mousedown", onDocClick);
    document.addEventListener("keydown", onKey);
    return () => {
      document.removeEventListener("mousedown", onDocClick);
      document.removeEventListener("keydown", onKey);
    };
  }, [open]);

  return (
    <div className="relative flex items-center" ref={rootRef}>
      <button
        ref={toggleRef}
        type="button"
        className="inline-flex min-h-[44px] min-w-[44px] items-center justify-center rounded text-muted hover:bg-gray-100 hover:text-brand-600 md:hidden dark:hover:bg-gray-800"
        aria-expanded={open}
        aria-controls={PANEL_ID}
        onClick={() => setOpen((v) => !v)}
      >
        <span className="sr-only">{open ? "Close menu" : "Menu"}</span>
        <svg
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          aria-hidden="true"
          className="h-5 w-5"
        >
          {open ? (
            <path d="M6 6l12 12M18 6L6 18" />
          ) : (
            <path d="M4 7h16M4 12h16M4 17h16" />
          )}
        </svg>
      </button>
      <div
        id={PANEL_ID}
        className={clsx(
          "md:flex md:items-center md:gap-4",
          open
            ? "absolute right-0 top-full z-50 mt-2 flex w-56 flex-col gap-1 rounded-lg border border-border bg-surface-raised p-2 shadow-lg"
            : "hidden",
        )}
      >
        {children}
      </div>
    </div>
  );
}
