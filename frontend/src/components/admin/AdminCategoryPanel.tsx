"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { Input } from "@/components/ui/Input";
import { ApiError, businesses, type Category } from "@/lib/api";

const SEARCH_DEBOUNCE_MS = 300;

function slugify(name: string): string {
  return name
    .toLowerCase()
    .trim()
    .replace(/[^\w\s-]/g, "")
    .replace(/[\s_-]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

/** Admin panel — list/search categories and create new ones (S-034, S-081). Create + list APIs already existed; this ships the admin UI. */
export function AdminCategoryPanel() {
  const [items, setItems] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [name, setName] = useState("");
  const [creating, setCreating] = useState(false);
  const [q, setQ] = useState("");
  const [debouncedQ, setDebouncedQ] = useState("");

  const load = useCallback(async (query: string) => {
    setError("");
    try {
      setItems(await businesses.categoriesAll({ q: query || undefined }));
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to load categories");
    } finally {
      setLoading(false);
    }
  }, []);

  // Same debounce pattern as the Users search (S-080): skip the first render
  // so mount doesn't schedule a redundant no-op fetch.
  const isFirstRender = useRef(true);
  useEffect(() => {
    if (isFirstRender.current) {
      isFirstRender.current = false;
      return;
    }
    const timer = setTimeout(() => setDebouncedQ(q.trim()), SEARCH_DEBOUNCE_MS);
    return () => clearTimeout(timer);
  }, [q]);

  useEffect(() => {
    load(debouncedQ);
  }, [load, debouncedQ]);

  async function handleCreate(e: React.FormEvent) {
    e.preventDefault();
    const trimmed = name.trim();
    if (!trimmed) return;
    setCreating(true);
    setError("");
    try {
      await businesses.createCategory({ name: trimmed, slug: slugify(trimmed) });
      setName("");
      await load(debouncedQ);
    } catch (e) {
      if (e instanceof ApiError) {
        if (e.status === 409) setError(`A category named "${trimmed}" already exists`);
        else if (e.status === 401 || e.status === 403) {
          setError("Your session has expired or you don't have permission. Sign in again as an admin.");
        } else {
          setError("Something went wrong on our end. Please try again.");
        }
      } else {
        setError("Network problem — check your connection and try again.");
      }
    } finally {
      setCreating(false);
    }
  }

  if (loading) return <p className="text-sm text-muted">Loading categories…</p>;

  return (
    <div className="space-y-3">
      <form onSubmit={handleCreate} className="flex flex-wrap items-center gap-2">
        <Input
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="New category name"
          className="sm:max-w-xs"
        />
        <button
          type="submit"
          disabled={creating || !name.trim()}
          className="rounded bg-brand-600 px-4 py-2 text-sm text-white hover:bg-brand-700 disabled:opacity-50"
        >
          {creating ? "Adding..." : "Add category"}
        </button>
      </form>
      <Input
        type="search"
        value={q}
        onChange={(e) => setQ(e.target.value)}
        placeholder="Search categories"
        aria-label="Search categories"
        className="sm:max-w-xs"
      />
      {error && <p className="text-sm text-red-600">{error}</p>}
      {items.length === 0 ? (
        <p className="rounded-lg border border-dashed bg-surface p-6 text-center text-sm text-muted">
          {debouncedQ ? "No categories match your search" : "No categories yet"}
        </p>
      ) : (
        <ul className="flex flex-wrap gap-2">
          {items.map((c) => (
            <li key={c.id}>
              <a
                href={`/search?category=${encodeURIComponent(c.slug)}`}
                className="inline-block rounded-full bg-gray-100 px-3 py-1 text-sm text-gray-700 hover:bg-gray-200 hover:underline dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
              >
                {c.name}
              </a>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
