import { Suspense } from "react";
import { ResetPasswordForm } from "@/components/ResetPasswordForm";

export default function ResetPasswordPage() {
  return (
    <div className="py-12">
      <Suspense fallback={<p className="text-center text-gray-500">Loading…</p>}>
        <ResetPasswordForm />
      </Suspense>
    </div>
  );
}
