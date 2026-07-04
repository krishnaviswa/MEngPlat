import type { User } from "@/lib/api";

interface NavbarProps {
  user?: User | null;
  onLogout?: () => void;
}

/**
 * Navbar — global navigation with role-aware links.
 * Props: user (auth state), onLogout callback.
 * State: none (presentational; auth from layout).
 */
export function Navbar({ user, onLogout }: NavbarProps) {
  return (
    <header className="border-b bg-white shadow-sm">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-4 py-4">
        <a href="/" className="text-xl font-bold text-brand-700">
          MerchantHub AI
        </a>
        <nav className="flex items-center gap-4 text-sm">
          <a href="/search" className="text-gray-600 hover:text-brand-600">
            Search
          </a>
          {user?.role === "merchant" && (
            <a href="/merchant/dashboard" className="text-gray-600 hover:text-brand-600">
              Dashboard
            </a>
          )}
          {user?.role === "admin" && (
            <a href="/admin" className="text-gray-600 hover:text-brand-600">
              Admin
            </a>
          )}
          {user ? (
            <>
              <a href="/profile" className="text-gray-600 hover:text-brand-600">
                {user.full_name}
              </a>
              <button onClick={onLogout} className="rounded bg-gray-100 px-3 py-1 hover:bg-gray-200">
                Logout
              </button>
            </>
          ) : (
            <>
              <a href="/login" className="text-gray-600 hover:text-brand-600">
                Login
              </a>
              <a href="/register" className="rounded bg-brand-600 px-3 py-1 text-white hover:bg-brand-700">
                Sign Up
              </a>
            </>
          )}
        </nav>
      </div>
    </header>
  );
}
