import { AlreadySignedIn } from "@/components/AlreadySignedIn";
import { LoginForm } from "@/components/LoginForm";

export default function LoginPage() {
  return (
    <div className="py-12">
      <AlreadySignedIn>
        <LoginForm />
      </AlreadySignedIn>
    </div>
  );
}
