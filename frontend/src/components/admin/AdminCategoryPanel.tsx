"use client";

import { useCallback, useEffect, useState } from "react";
import { Input } from "@/components/ui/Input";
import { businesses, type Category } from "@/lib/api";

function slugify(name: string): string {
  return name
    .toLowerCase()
    .trim()
    .replace(/[^\w\s-]/g, "")
    .replace(/[\s_-]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

/** Admin panel — list categories and create new ones (S-034). Create + list APIs already existed; this ships the admin UI. */
export function AdminCategoryPanel() {
  const [items, setItems] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [name, setName] = useState("");
  const [creating, setCreating] = useState(false);

  const load = useCallback(async () => {
    setError("");
    try {
      setItems(await businesses.categoriesAll());
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to load categories");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  async function handleCreate(e: React.FormEvent) {
    e.preventDefault();
    const trimmed = name.trim();
    if (!trimmed) return;
    setCreating(true);
    setError("");
    try {
      await businesses.createCategory({ name: trimmed, slug: slugify(trimmed) });
      setName("");
      await load();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Create failed");
    } finally {
      setCreating(false);
    }
  }

  if (loading) return <p className="text-sm text-gray-500">Loading categories…</p>;

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
      {error && <p className="text-sm text-red-600">{error}</p>}
      {items.length === 0 ? (
        <p className="rounded-lg border border-dashed bg-gray-50 p-6 text-center text-sm text-gray-500">
          No categories yet
        </p>
      ) : (
        <ul className="flex flex-wrap gap-2">
          {items.map((c) => (
            <li key={c.id} className="rounded-full bg-gray-100 px-3 py-1 text-sm text-gray-700">
              {c.name}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
