/** FilterPanel — sidebar filters for search page. Uses native form GET to /search. */
export function FilterPanel() {
  return (
    <aside className="rounded-xl border bg-white p-4">
      <h3 className="font-semibold text-gray-900">Filters</h3>
      <div className="mt-3 flex flex-wrap gap-2">
        <a href="/search?city=Chennai" className="rounded-full bg-brand-50 px-3 py-1 text-xs font-medium text-brand-800 hover:bg-brand-100">
          Chennai
        </a>
        <a href="/search?q=Chrompet" className="rounded-full bg-brand-50 px-3 py-1 text-xs font-medium text-brand-800 hover:bg-brand-100">
          Chrompet
        </a>
        <a href="/search?q=Radha+Nagar" className="rounded-full bg-brand-50 px-3 py-1 text-xs font-medium text-brand-800 hover:bg-brand-100">
          Radha Nagar
        </a>
      </div>
      <form action="/search" method="get" className="mt-4 space-y-4">
        <div>
          <label className="text-sm text-gray-600">City</label>
          <input name="city" className="mt-1 w-full rounded border px-3 py-2 text-sm" placeholder="Chennai" />
        </div>
        <div>
          <label className="text-sm text-gray-600">Category</label>
          <select name="category" className="mt-1 w-full rounded border px-3 py-2 text-sm">
            <option value="">All</option>
            <option value="restaurant">Restaurant</option>
            <option value="cafe">Café</option>
            <option value="salon">Salon</option>
            <option value="grocery">Grocery</option>
            <option value="pharmacy">Pharmacy</option>
          </select>
        </div>
        <div>
          <label className="text-sm text-gray-600">Min rating</label>
          <select name="min_rating" className="mt-1 w-full rounded border px-3 py-2 text-sm">
            <option value="">Any</option>
            <option value="3">3+ stars</option>
            <option value="4">4+ stars</option>
            <option value="4.5">4.5+ stars</option>
          </select>
        </div>
        <button type="submit" className="w-full rounded bg-brand-600 py-2 text-sm text-white hover:bg-brand-700">
          Apply filters
        </button>
      </form>
    </aside>
  );
}
