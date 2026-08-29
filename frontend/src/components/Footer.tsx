/** Footer — multi-column site map: Discover, For merchants, Account, Support. */
export function Footer() {
  const year = new Date().getFullYear();

  // Hit area only — >= 44px tall tap target via padding on the link box.
  // Palette / typography / dark styling are unchanged from S-087.
  const linkClass = "inline-flex min-h-[44px] items-center hover:text-brand-300";

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
              <a href="/search" className={linkClass}>
                Search businesses
              </a>
            </li>
            <li>
              <a href="/" className={linkClass}>
                Home
              </a>
            </li>
            <li>
              <a href="/search" className={linkClass}>
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
              <a href="/register" className={linkClass}>
                List your business
              </a>
            </li>
            <li>
              <a href="/merchant/dashboard" className={linkClass}>
                Merchant dashboard
              </a>
            </li>
            <li>
              <a href="/login" className={linkClass}>
                Sign in
              </a>
            </li>
          </ul>
        </div>

        <div>
          <p className="font-display text-sm font-semibold uppercase tracking-wider text-white">Account</p>
          <ul className="mt-4 space-y-2 text-sm">
            <li>
              <a href="/login" className={linkClass}>
                Login
              </a>
            </li>
            <li>
              <a href="/register" className={linkClass}>
                Sign up
              </a>
            </li>
            <li>
              <a href="/profile" className={linkClass}>
                Profile & favorites
              </a>
            </li>
          </ul>
        </div>

        <div>
          <p className="font-display text-sm font-semibold uppercase tracking-wider text-white">Support</p>
          <ul className="mt-4 space-y-2 text-sm">
            <li>
              <a href="/support" className={linkClass}>
                Contact support
              </a>
            </li>
            <li>
              <a href="mailto:support@merchanthub.example" className={linkClass}>
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
