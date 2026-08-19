"use client";

import { useEffect, useState } from "react";
import clsx from "clsx";
import type { User } from "@/lib/api";

export interface AvatarProps {
  user: Pick<User, "full_name" | "avatar_url">;
  size?: "sm" | "lg";
  className?: string;
}

const sizeClasses: Record<NonNullable<AvatarProps["size"]>, string> = {
  sm: "h-8 w-8 text-xs",
  lg: "h-24 w-24 text-2xl",
};

function initialsFor(fullName: string): string {
  const words = fullName.trim().split(/\s+/).filter(Boolean);
  const letters = words.slice(0, 2).map((w) => w[0]?.toUpperCase() ?? "");
  return letters.join("") || "?";
}

/**
 * Avatar — image-or-initials presentational primitive (S-085). Renders
 * `user.avatar_url` when set, falling back to initials derived from
 * `full_name` (first letter of the first two words, uppercase) on a colored
 * circular background when `avatar_url` is unset OR the image fails to load
 * (`onError`, covering broken/unreachable URLs). Purely presentational — no
 * click handling, no upload logic; callers (Navbar, ProfilePage) wrap it
 * themselves for interactivity.
 */
export function Avatar({ user, size = "sm", className }: AvatarProps) {
  const [imgFailed, setImgFailed] = useState(false);

  // A new avatar_url (e.g. after a successful upload) deserves a fresh
  // attempt to load the image, even if a previous one had failed.
  useEffect(() => {
    setImgFailed(false);
  }, [user.avatar_url]);

  const showImage = Boolean(user.avatar_url) && !imgFailed;

  if (showImage) {
    return (
      <img
        src={user.avatar_url ?? undefined}
        alt={user.full_name}
        onError={() => setImgFailed(true)}
        className={clsx("rounded-full object-cover", sizeClasses[size], className)}
      />
    );
  }

  return (
    <span
      role="img"
      aria-label={user.full_name}
      className={clsx(
        "inline-flex select-none items-center justify-center rounded-full bg-brand-600 font-semibold text-white",
        sizeClasses[size],
        className,
      )}
    >
      {initialsFor(user.full_name)}
    </span>
  );
}
