"use client";

export type AuthMethod = "authenticator" | "otp";

/** Equal-weight Authenticator vs Mobile OTP chooser for login and register (S-092). */
export function AuthMethodToggle({
  value,
  onChange,
  legend = "Sign in with",
}: {
  value: AuthMethod;
  onChange: (next: AuthMethod) => void;
  legend?: string;
}) {
  return (
    <fieldset className="space-y-2">
      <legend className="text-sm font-medium text-ink">{legend}</legend>
      <div className="grid grid-cols-2 gap-2" role="radiogroup" aria-label={legend}>
        <button
          type="button"
          role="radio"
          aria-checked={value === "authenticator"}
          onClick={() => onChange("authenticator")}
          className={`rounded-lg border px-3 py-2 text-sm font-medium ${
            value === "authenticator"
              ? "border-brand-600 bg-brand-50 text-brand-800 dark:bg-brand-900/30 dark:text-brand-200"
              : "border-border bg-surface-raised text-muted hover:border-brand-300"
          }`}
        >
          Authenticator
        </button>
        <button
          type="button"
          role="radio"
          aria-checked={value === "otp"}
          onClick={() => onChange("otp")}
          className={`rounded-lg border px-3 py-2 text-sm font-medium ${
            value === "otp"
              ? "border-brand-600 bg-brand-50 text-brand-800 dark:bg-brand-900/30 dark:text-brand-200"
              : "border-border bg-surface-raised text-muted hover:border-brand-300"
          }`}
        >
          Mobile OTP
        </button>
      </div>
    </fieldset>
  );
}
