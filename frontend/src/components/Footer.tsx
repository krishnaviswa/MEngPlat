/** Footer — site-wide links and branding. No props or state. */
export function Footer() {
  return (
    <footer className="mt-auto border-t bg-gray-50">
      <div className="mx-auto max-w-6xl px-4 py-8 text-sm text-gray-500">
        <p className="font-semibold text-gray-700">MerchantHub AI</p>
        <p className="mt-1">Supporting local businesses with verified reviews and AI insights.</p>
        <div className="mt-4 flex gap-4">
          <a href="/search">Discover</a>
          <a href="/register">List your business</a>
        </div>
        <p className="mt-4 text-xs">© {new Date().getFullYear()} MerchantHub AI. Portfolio MVP.</p>
      </div>
    </footer>
  );
}
