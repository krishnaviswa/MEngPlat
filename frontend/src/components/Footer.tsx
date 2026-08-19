/** Footer — multi-column site map: Discover, For merchants, Account, Support. */
export function Footer() {
  const year = new Date().getFullYear();

  return (
    <footer className="mt-auto border-t border-slate-800 bg-slate-950 text-slate-300">
      <div className="mx-auto grid max-w-6xl gap-10 px-4 py-14 sm:grid-cols-2 lg:grid-cols-5">
        <div className="sm:col-span-2 lg:col-span-1">
          <p className="font-display text-xl font-semibold text-white">MerchantHub AI</p>
          <p className="mt-3 max-w-xs text-sm leading-relaxed text-slate-400">
            Local discovery with verified reviews and AI-suggested insights for customers and merchants.
          </p>
        </div>

        <div>
          <p className="font-display text-sm font-semibold uppercase tracking-wider text-white">Discover</p>
          <ul className="mt-4 space-y-2 text-sm">
            <li>
              <a href="/search" className="hover:text-brand-300">
                Search businesses
              </a>
            </li>
            <li>
              <a href="/" className="hover:text-brand-300">
                Home
              </a>
            </li>
            <li>
              <a href="/search" className="hover:text-brand-300">
                Browse by city or category
              </a>
            </li>
          </ul>
        </div>

        <div>
          <p className="font-display text-sm font-semibold uppercase tracking-wider text-white">
            For merchants
          </p>
          <ul className="mt-4 space-y-2 text-sm">
            <li>
              <a href="/register" className="hover:text-brand-300">
                List your business
              </a>
            </li>
            <li>
              <a href="/merchant/dashboard" className="hover:text-brand-300">
                Merchant dashboard
              </a>
            </li>
            <li>
              <a href="/login" className="hover:text-brand-300">
                Sign in
              </a>
            </li>
          </ul>
        </div>

        <div>
          <p className="font-display text-sm font-semibold uppercase tracking-wider text-white">Account</p>
          <ul className="mt-4 space-y-2 text-sm">
            <li>
              <a href="/login" className="hover:text-brand-300">
                Login
              </a>
            </li>
            <li>
              <a href="/register" className="hover:text-brand-300">
                Sign up
              </a>
            </li>
            <li>
              <a href="/profile" className="hover:text-brand-300">
                Profile & favorites
              </a>
            </li>
          </ul>
        </div>

        <div>
          <p className="font-display text-sm font-semibold uppercase tracking-wider text-white">Support</p>
          <ul className="mt-4 space-y-2 text-sm">
            <li>
              <a href="/support" className="hover:text-brand-300">
                Contact support
              </a>
            </li>
            <li>
              <a href="mailto:support@merchanthub.example" className="hover:text-brand-300">
                support@merchanthub.example
              </a>
            </li>
          </ul>
        </div>
      </div>

      <div className="border-t border-slate-800">
        <div className="mx-auto flex max-w-6xl flex-wrap items-center justify-between gap-3 px-4 py-5 text-xs text-slate-500">
          <p>© {year} MerchantHub AI. Portfolio MVP.</p>
          <p>AI output is suggestion-only — never a definitive judgment.</p>
        </div>
      </div>
    </footer>
  );
}
