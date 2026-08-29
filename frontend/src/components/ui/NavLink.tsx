"use client";

import type { AnchorHTMLAttributes, ReactNode } from "react";
import { usePathname } from "next/navigation";
import clsx from "clsx";

type Match = "exact" | "prefix";

export type NavLinkProps = Omit<AnchorHTMLAttributes<HTMLAnchorElement>, "href"> & {
  href: string;
  children: ReactNode;
  /** `"exact"` (default) lights only on `pathname === href`; `"prefix"` also lights on nested routes (`/admin/users`). */
  match?: Match;
};

/**
 * NavLink — a top-level navbar link that knows whether it is the current section.
 * When the current path matches `href` (`match="exact"`, the default) or sits
 * under it (`match="prefix"`), the link gets `aria-current="page"` plus a
 * two-cue active treatment — heavier weight (non-colour) *and* an underline bar
 * — so it reads for colour-blind users and in both themes. Client leaf:
 * `usePathname()` is the only client API used, keeping the rest of `Navbar`
 * non-client. `usePathname()` returns `null` with no router context (it does not
 * throw), so a path-less render is simply inactive.
 */
export function NavLink({ href, children, match = "exact", className, ...props }: NavLinkProps) {
  const pathname = usePathname();
  const active =
    !!pathname && (pathname === href || (match === "prefix" && pathname.startsWith(href + "/")));

  return (
    <a
      href={href}
      aria-current={active ? "page" : undefined}
      className={clsx(
        "relative inline-flex min-h-[44px] items-center px-1 -mx-1 transition-colors",
        "after:absolute after:inset-x-1 after:bottom-1.5 after:h-0.5 after:rounded-full after:content-['']",
        active
          ? "font-semibold text-ink after:bg-brand-600 dark:after:bg-brand-300"
          : "text-muted hover:text-brand-600 after:bg-transparent",
        className,
      )}
      {...props}
    >
      {children}
    </a>
  );
}
