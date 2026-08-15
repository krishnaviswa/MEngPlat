"use client";

import { useCallback, useEffect, useState } from "react";
import { Badge } from "@/components/ui/Badge";
import { admin, auth, type User } from "@/lib/api";

const PAGE_SIZE = 20;

/** Admin panel — list users, suspend/reactivate non-admin accounts (S-034). Suspend/reactivate hidden for admins and the caller's own row. */
export function AdminUserPanel() {
  const [items, setItems] = useState<User[]>([]);
  const [page, setPage] = useState(1);
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

  const load = useCallback(async (p: number) => {
    setLoading(true);
    setError("");
    try {
      setItems(await admin.users({ page: p, page_size: PAGE_SIZE }));
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to load users");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load(page);
  }, [load, page]);

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
      {error && <p className="text-sm text-red-600">{error}</p>}
      {loading ? (
        <p className="text-sm text-gray-500">Loading users…</p>
      ) : items.length === 0 ? (
        <p className="rounded-lg border border-dashed bg-gray-50 p-6 text-center text-sm text-gray-500">
          No users found
        </p>
      ) : (
        <div className="space-y-3">
          {items.map((u) => {
            const protectedAccount = u.role === "admin" || u.id === selfId;
            return (
              <div
                key={u.id}
                className="flex flex-wrap items-center justify-between gap-3 rounded-xl border bg-white p-4"
              >
                <div>
                  <p className="font-semibold">{u.full_name}</p>
                  <p className="text-sm text-gray-600">
                    {u.email || u.phone || "no email"} · {u.role}
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
                          ? "rounded-lg border border-red-300 px-3 py-1.5 text-sm text-red-700 hover:bg-red-50 disabled:opacity-50"
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
          className="rounded border border-gray-200 px-3 py-1.5 text-sm text-gray-700 hover:bg-gray-50 disabled:opacity-50"
        >
          Previous
        </button>
        <span className="text-sm text-gray-500">Page {page}</span>
        <button
          type="button"
          disabled={loading || items.length < PAGE_SIZE}
          onClick={() => setPage((p) => p + 1)}
          className="rounded border border-gray-200 px-3 py-1.5 text-sm text-gray-700 hover:bg-gray-50 disabled:opacity-50"
        >
          Next
        </button>
      </div>
    </div>
  );
}
