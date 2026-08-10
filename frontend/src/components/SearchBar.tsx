interface SearchBarProps {
  defaultValue?: string;
  placeholder?: string;
  className?: string;
}

/** SearchBar — GET form to /search. Props: defaultValue, placeholder, className. */
export function SearchBar({
  defaultValue = "",
  placeholder = "Search restaurants, salons, shops...",
  className = "",
}: SearchBarProps) {
  return (
    <form action="/search" method="get" className={`flex gap-2 ${className}`}>
      <input
        type="search"
        name="q"
        defaultValue={defaultValue}
        placeholder={placeholder}
        className="min-w-0 flex-1 rounded-lg border border-slate-200 bg-white px-4 py-3 text-slate-900 shadow-sm placeholder:text-slate-500 focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/30"
      />
      <button
        type="submit"
        className="shrink-0 rounded-lg bg-brand-600 px-5 py-3 font-medium text-white transition hover:bg-brand-700"
      >
        Search
      </button>
    </form>
  );
}
