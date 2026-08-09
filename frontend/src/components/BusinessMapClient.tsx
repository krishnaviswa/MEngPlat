"use client";

import dynamic from "next/dynamic";

/** Client-only wrapper — `ssr: false` dynamic imports must live in a Client Component, not a Server Component page. */
export const BusinessMap = dynamic(() => import("@/components/BusinessMap"), { ssr: false });
