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
        className="flex-1 rounded-lg border px-4 py-2 focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500"
      />
      <button
        type="submit"
        className="rounded-lg bg-brand-600 px-4 py-2 text-white hover:bg-brand-700"
      >
        Search
      </button>
    </form>
  );
}
