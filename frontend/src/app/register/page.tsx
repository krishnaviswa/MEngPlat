import { AlreadySignedIn } from "@/components/AlreadySignedIn";
import { RegisterForm } from "@/components/RegisterForm";

export default function RegisterPage() {
  return (
    <div className="py-12">
      <AlreadySignedIn>
        <RegisterForm />
      </AlreadySignedIn>
    </div>
  );
}
