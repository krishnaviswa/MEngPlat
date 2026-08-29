"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { Badge, type Tone } from "@/components/ui/Badge";
import { Input } from "@/components/ui/Input";
import { admin, auth, type User } from "@/lib/api";

const PAGE_SIZE = 20;
const SEARCH_DEBOUNCE_MS = 300;

// S-083: judgment-neutral tones (info/brand), not positive/negative, so the badge
// doesn't misread as "customer bad, admin good" -- mirrors AllBusinessesQueue's
// STATUS_TONE pattern, including the defensive fallback for an unmapped value.
const ROLE_TONE: Partial<Record<User["role"], Tone>> = {
  customer: "neutral",
  merchant: "info",
  admin: "brand",
};

function roleTone(role: string): Tone {
  return ROLE_TONE[role as User["role"]] ?? "neutral";
}

/** Admin panel — list/search users, suspend/reactivate non-admin accounts (S-034, S-080, S-083). Suspend/reactivate hidden for admins and the caller's own row. */
export function AdminUserPanel() {
  const [items, setItems] = useState<User[]>([]);
  const [page, setPage] = useState(1);
  const [q, setQ] = useState("");
  const [debouncedQ, setDebouncedQ] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [acting, setActing] = useState<string | null>(null);
  const [selfId, setSelfId] = useState<string | null>(null);

  useEffect(() => {
    auth
      .me()
      .then((u) => setSelfId(u.id))
      .catch(() => setSelfId(null));
  }, []);

  // AC5: reset to page 1 as soon as the search term changes, before the
  // debounced fetch fires -- no stale page number carried into a new query.
  // Skips the very first render so mount doesn't schedule a redundant no-op fetch.
  const isFirstRender = useRef(true);
  useEffect(() => {
    if (isFirstRender.current) {
      isFirstRender.current = false;
      return;
    }
    const timer = setTimeout(() => {
      setPage(1);
      setDebouncedQ(q.trim());
    }, SEARCH_DEBOUNCE_MS);
    return () => clearTimeout(timer);
  }, [q]);

  const load = useCallback(async (p: number, query: string) => {
    setLoading(true);
    setError("");
    try {
      setItems(await admin.users({ page: p, page_size: PAGE_SIZE, q: query || undefined }));
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to load users");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load(page, debouncedQ);
  }, [load, page, debouncedQ]);

  async function handleToggle(user: User) {
    setActing(user.id);
    setError("");
    try {
      const updated = user.is_active ? await admin.suspendUser(user.id) : await admin.reactivateUser(user.id);
      setItems((prev) => prev.map((u) => (u.id === updated.id ? updated : u)));
    } catch (e) {
      setError(e instanceof Error ? e.message : "Action failed");
    } finally {
      setActing(null);
    }
  }

  return (
    <div className="space-y-3">
      <Input
        type="search"
        value={q}
        onChange={(e) => setQ(e.target.value)}
        placeholder="Search by name or email"
        aria-label="Search users"
      />
      {error && <p className="text-sm text-red-600">{error}</p>}
      {loading ? (
        <p className="text-sm text-muted">Loading users…</p>
      ) : items.length === 0 ? (
        <p className="rounded-lg border border-border border-dashed bg-surface p-6 text-center text-sm text-muted">
          {debouncedQ ? "No users match your search" : "No users found"}
        </p>
      ) : (
        <div className="space-y-3">
          {items.map((u) => {
            const protectedAccount = u.role === "admin" || u.id === selfId;
            return (
              <div
                key={u.id}
                className="flex flex-wrap items-center justify-between gap-3 rounded-xl border border-border bg-surface-raised p-4"
              >
                <div>
                  <div className="flex items-center gap-2">
                    <p className="font-semibold">{u.full_name}</p>
                    <Badge tone={roleTone(u.role)}>{u.role}</Badge>
                  </div>
                  <p className="text-sm text-muted">
                    {u.email || u.phone || "no email"}
                    {u.national_id_type
                      ? ` · ID ${u.national_id_type} ${u.national_id_number || "—"}`
                      : " · no national ID"}
                  </p>
                </div>
                <div className="flex shrink-0 items-center gap-3">
                  <Badge tone={u.is_active ? "positive" : "negative"}>{u.is_active ? "Active" : "Suspended"}</Badge>
                  {!protectedAccount && (
                    <button
                      type="button"
                      disabled={acting === u.id}
                      onClick={() => handleToggle(u)}
                      className={
                        u.is_active
                          ? "rounded-lg border border-red-300 px-3 py-1.5 text-sm text-red-700 hover:bg-red-50 dark:border-red-800 dark:text-red-400 dark:hover:bg-red-900/30 disabled:opacity-50"
                          : "rounded-lg bg-green-600 px-3 py-1.5 text-sm text-white hover:bg-green-700 disabled:opacity-50"
                      }
                    >
                      {u.is_active ? "Suspend" : "Reactivate"}
                    </button>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}
      <div className="flex items-center justify-between pt-2">
        <button
          type="button"
          disabled={page === 1 || loading}
          onClick={() => setPage((p) => Math.max(1, p - 1))}
          className="rounded border border-border px-3 py-1.5 text-sm text-muted hover:bg-surface disabled:opacity-50"
        >
          Previous
        </button>
        <span className="text-sm text-muted">Page {page}</span>
        <button
          type="button"
          disabled={loading || items.length < PAGE_SIZE}
          onClick={() => setPage((p) => p + 1)}
          className="rounded border border-border px-3 py-1.5 text-sm text-muted hover:bg-surface disabled:opacity-50"
        >
          Next
        </button>
      </div>
    </div>
  );
}
