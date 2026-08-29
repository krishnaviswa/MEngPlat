import type { User } from "@/lib/api";
import { NotificationBell } from "@/components/NotificationBell";
import { ThemeToggle } from "@/components/ThemeToggle";
import { NavbarMobileMenu } from "@/components/NavbarMobileMenu";
import { Avatar } from "@/components/ui/Avatar";
import { NavLink } from "@/components/ui/NavLink";

interface NavbarProps {
  user?: User | null;
  onLogout?: () => void;
}

/**
 * Navbar — global navigation with role-aware links.
 * Props: user (auth state), onLogout callback.
 * State: none here — the current-page cue lives in <NavLink> and the sub-`md`
 * disclosure in <NavbarMobileMenu> (both "use client" leaves). NotificationBell
 * and ThemeToggle sit outside the collapsible group so they stay reachable at
 * every width.
 */
export function Navbar({ user, onLogout }: NavbarProps) {
  return (
    <header className="border-b border-border bg-surface-raised shadow-sm">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-4 py-1">
        <a
          href="/"
          className="inline-flex min-h-[44px] items-center font-display text-xl font-bold text-brand-700"
        >
          MerchantHub AI
        </a>
        <nav className="flex items-center gap-4 text-sm">
          <NavbarMobileMenu>
            <NavLink href="/search">Search</NavLink>
            {user?.role === "merchant" && (
              <NavLink href="/merchant/dashboard" match="prefix">
                Dashboard
              </NavLink>
            )}
            {user?.role === "admin" && (
              <NavLink href="/admin" match="prefix">
                Admin
              </NavLink>
            )}
            {user ? (
              <>
                <a
                  href="/profile"
                  className="inline-flex min-h-[44px] items-center gap-2 text-muted hover:text-brand-600"
                >
                  <Avatar user={user} size="sm" />
                  <span className="hidden sm:inline">{user.full_name}</span>
                </a>
                <button
                  onClick={onLogout}
                  className="inline-flex min-h-[44px] items-center rounded bg-gray-100 px-3 hover:bg-gray-200 dark:bg-gray-800 dark:hover:bg-gray-700"
                >
                  Logout
                </button>
              </>
            ) : (
              <>
                <a
                  href="/login"
                  className="inline-flex min-h-[44px] items-center px-2 -mx-2 text-muted hover:text-brand-600"
                >
                  Login
                </a>
                <a
                  href="/register"
                  className="inline-flex min-h-[44px] items-center rounded bg-brand-600 px-3 text-white hover:bg-brand-700"
                >
                  Sign Up
                </a>
              </>
            )}
          </NavbarMobileMenu>
          {user && <NotificationBell />}
          <ThemeToggle />
        </nav>
      </div>
    </header>
  );
}
