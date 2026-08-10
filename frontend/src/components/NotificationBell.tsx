"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import type { Notification } from "@/lib/api";
import { notifications } from "@/lib/api";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";

const POLL_MS = 30_000;

/**
 * NotificationBell — navbar dropdown for the authenticated user's notifications.
 * Polls unread every 30s; loads full list when opened; mark-one / mark-all-read.
 */
export function NotificationBell() {
  const [open, setOpen] = useState(false);
  const [items, setItems] = useState<Notification[]>([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const rootRef = useRef<HTMLDivElement>(null);

  const refreshUnread = useCallback(() => {
    notifications
      .list({ unreadOnly: true })
      .then((list) => setUnreadCount(list.length))
      .catch(() => {});
  }, []);

  useEffect(() => {
    refreshUnread();
    const id = window.setInterval(refreshUnread, POLL_MS);
    return () => window.clearInterval(id);
  }, [refreshUnread]);

  useEffect(() => {
    if (!open) return;
    notifications
      .list()
      .then(setItems)
      .catch(() => setItems([]));
  }, [open]);

  useEffect(() => {
    if (!open) return;
    function onDocClick(e: MouseEvent) {
      if (rootRef.current && !rootRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    }
    function onKey(e: KeyboardEvent) {
      if (e.key === "Escape") setOpen(false);
    }
    document.addEventListener("mousedown", onDocClick);
    document.addEventListener("keydown", onKey);
    return () => {
      document.removeEventListener("mousedown", onDocClick);
      document.removeEventListener("keydown", onKey);
    };
  }, [open]);

  async function markOne(id: string) {
    try {
      await notifications.markRead(id);
      setItems((prev) => prev.map((n) => (n.id === id ? { ...n, is_read: true } : n)));
      refreshUnread();
    } catch {
      /* ignore */
    }
  }

  async function markAll() {
    try {
      await notifications.markAllRead();
      setItems((prev) => prev.map((n) => ({ ...n, is_read: true })));
      setUnreadCount(0);
    } catch {
      /* ignore */
    }
  }

  return (
    <div className="relative" ref={rootRef}>
      <button
        type="button"
        className="relative rounded p-1 text-gray-600 hover:bg-gray-100 hover:text-brand-600"
        aria-label="Notifications"
        aria-expanded={open}
        onClick={() => setOpen((v) => !v)}
      >
        <span aria-hidden className="block h-5 w-5">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="h-5 w-5">
            <path d="M15 17h5l-1.4-1.4A2 2 0 0 1 18 14.2V11a6 6 0 1 0-12 0v3.2c0 .5-.2 1-.6 1.4L4 17h5" />
            <path d="M9 17a3 3 0 0 0 6 0" />
          </svg>
        </span>
        {unreadCount > 0 && (
          <span className="absolute -right-1 -top-1">
            <Badge tone="negative">{unreadCount > 9 ? "9+" : unreadCount}</Badge>
          </span>
        )}
      </button>
      {open && (
        <Card className="absolute right-0 z-50 mt-2 w-80 max-w-[90vw] p-0 shadow-lg">
          <div className="flex items-center justify-between border-b px-3 py-2">
            <p className="text-sm font-semibold">Notifications</p>
            {unreadCount > 0 && (
              <Button type="button" variant="secondary" size="sm" onClick={markAll}>
                Mark all read
              </Button>
            )}
          </div>
          <ul className="max-h-80 overflow-y-auto">
            {items.length === 0 ? (
              <li className="px-3 py-6 text-center text-sm text-gray-500">No notifications yet</li>
            ) : (
              items.map((n) => (
                <li key={n.id}>
                  <button
                    type="button"
                    className={`w-full px-3 py-2 text-left hover:bg-gray-50 ${n.is_read ? "opacity-70" : ""}`}
                    onClick={() => {
                      if (!n.is_read) void markOne(n.id);
                    }}
                  >
                    <p className="text-sm font-medium text-gray-900">{n.title}</p>
                    <p className="text-xs text-gray-600">{n.message}</p>
                  </button>
                </li>
              ))
            )}
          </ul>
        </Card>
      )}
    </div>
  );
}
