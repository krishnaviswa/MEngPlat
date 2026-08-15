import { AlreadySignedIn } from "@/components/AlreadySignedIn";
import { RegisterForm } from "@/components/RegisterForm";
import { AuthMarketingPanel } from "@/components/auth/AuthMarketingPanel";
import { businesses, type PublicPlatformStats } from "@/lib/api";

export default async function RegisterPage() {
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
        <RegisterForm />
      </AlreadySignedIn>
    </div>
  );
}
