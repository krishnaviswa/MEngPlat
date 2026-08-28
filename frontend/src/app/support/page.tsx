import { SupportTicketForm } from "@/components/SupportTicketForm";
import { PageHeading } from "@/components/ui/PageHeading";
import { API_URL } from "@/lib/api";

/** Public support / contact page (S-087, S-088). */
export default async function SupportPage() {
  let email = "support@merchanthub.example";
  try {
    const res = await fetch(`${API_URL}/api/v1/support/contact`, { cache: "no-store" });
    if (res.ok) {
      const data = (await res.json()) as { email?: string };
      if (data.email) email = data.email;
    }
  } catch {
    /* keep default */
  }

  return (
    <div className="mx-auto max-w-2xl px-4 py-10">
      <PageHeading>Contact support</PageHeading>
      <p className="mt-2 text-sm text-muted">
        Email{" "}
        <a className="text-brand-600 hover:underline" href={`mailto:${email}`}>
          {email}
        </a>{" "}
        or send a query below. If you are signed in, you will see ticket status here after you submit.
      </p>
      <div className="mt-6">
        <SupportTicketForm />
      </div>
    </div>
  );
}
