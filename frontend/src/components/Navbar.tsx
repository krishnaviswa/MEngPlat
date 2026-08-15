import type { User } from "@/lib/api";
import { NotificationBell } from "@/components/NotificationBell";
import { ThemeToggle } from "@/components/ThemeToggle";

interface NavbarProps {
  user?: User | null;
  onLogout?: () => void;
}

/**
 * Navbar — global navigation with role-aware links.
 * Props: user (auth state), onLogout callback.
 * State: none (presentational; auth from layout). NotificationBell is client-side.
 */
export function Navbar({ user, onLogout }: NavbarProps) {
  return (
    <header className="border-b border-border bg-surface-raised shadow-sm">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-4 py-4">
        <a href="/" className="font-display text-xl font-bold text-brand-700">
          MerchantHub AI
        </a>
        <nav className="flex items-center gap-4 text-sm">
          <a href="/search" className="text-muted hover:text-brand-600">
            Search
          </a>
          {user?.role === "merchant" && (
            <a href="/merchant/dashboard" className="text-muted hover:text-brand-600">
              Dashboard
            </a>
          )}
          {user?.role === "admin" && (
            <a href="/admin" className="text-muted hover:text-brand-600">
              Admin
            </a>
          )}
          {user ? (
            <>
              <NotificationBell />
              <a href="/profile" className="text-muted hover:text-brand-600">
                {user.full_name}
              </a>
              <button
                onClick={onLogout}
                className="rounded bg-gray-100 px-3 py-1 hover:bg-gray-200 dark:bg-gray-800 dark:hover:bg-gray-700"
              >
                Logout
              </button>
            </>
          ) : (
            <>
              <a href="/login" className="text-muted hover:text-brand-600">
                Login
              </a>
              <a href="/register" className="rounded bg-brand-600 px-3 py-1 text-white hover:bg-brand-700">
                Sign Up
              </a>
            </>
          )}
          <ThemeToggle />
        </nav>
      </div>
    </header>
  );
}
