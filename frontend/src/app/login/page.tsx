import { Suspense } from "react";
import { AlreadySignedIn } from "@/components/AlreadySignedIn";
import { LoginForm } from "@/components/LoginForm";
import { AuthMarketingPanel } from "@/components/auth/AuthMarketingPanel";
import { businesses, type PublicPlatformStats } from "@/lib/api";

export default async function LoginPage() {
  const stats = await businesses.stats().catch(() => null);
  const validStats: PublicPlatformStats | null =
    stats &&
    typeof stats.total_businesses === "number" &&
    typeof stats.total_reviews === "number" &&
    typeof stats.total_cities === "number"
      ? stats
      : null;

  return (
    <div className="mx-auto grid max-w-5xl gap-12 px-4 py-12 lg:grid-cols-2 lg:items-center lg:py-20">
      <AuthMarketingPanel stats={validStats} />
      <AlreadySignedIn>
        <Suspense fallback={<p className="text-center text-muted">Loading…</p>}>
          <LoginForm />
        </Suspense>
      </AlreadySignedIn>
    </div>
  );
}
