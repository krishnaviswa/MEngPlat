import MerchantDashboardPage from "@/components/MerchantDashboard";
import { RequireAuth } from "@/components/RequireAuth";

export default function Page() {
  return (
    <RequireAuth role="merchant">
      <MerchantDashboardPage />
    </RequireAuth>
  );
}
