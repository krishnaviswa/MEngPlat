import { Suspense } from "react";
import { AlreadySignedIn } from "@/components/AlreadySignedIn";
import { LoginForm } from "@/components/LoginForm";

export default function LoginPage() {
  return (
    <div className="py-12">
      <AlreadySignedIn>
        <Suspense fallback={<p className="text-center text-gray-500">Loading…</p>}>
          <LoginForm />
        </Suspense>
      </AlreadySignedIn>
    </div>
  );
}
