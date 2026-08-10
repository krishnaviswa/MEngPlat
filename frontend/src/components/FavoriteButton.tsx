"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { favorites } from "@/lib/api";
import { Button } from "@/components/ui/Button";

interface FavoriteButtonProps {
  businessId: string;
}

/**
 * FavoriteButton — toggles the current customer's favorite state for a business.
 * Unauthenticated clicks redirect to /login. Optimistic toggle with rollback on error.
 */
export function FavoriteButton({ businessId }: FavoriteButtonProps) {
  const router = useRouter();
  const [favorited, setFavorited] = useState(false);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!localStorage.getItem("access_token")) return;
    favorites
      .list()
      .then((list) => setFavorited(list.some((b) => b.id === businessId)))
      .catch(() => {});
  }, [businessId]);

  async function handleClick() {
    if (!localStorage.getItem("access_token")) {
      router.push("/login");
      return;
    }
    const next = !favorited;
    setFavorited(next);
    setLoading(true);
    try {
      if (next) {
        await favorites.add(businessId);
      } else {
        await favorites.remove(businessId);
      }
    } catch {
      setFavorited(!next);
    } finally {
      setLoading(false);
    }
  }

  return (
    <Button
      type="button"
      variant={favorited ? "primary" : "secondary"}
      size="sm"
      onClick={handleClick}
      disabled={loading}
      aria-pressed={favorited}
    >
      {favorited ? "★ Favorited" : "☆ Favorite"}
    </Button>
  );
}
