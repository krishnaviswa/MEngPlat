"use client";

import { useEffect, useState } from "react";
import { AuthMethodToggle, type AuthMethod } from "@/components/AuthMethodToggle";
import { GoogleSignInButton } from "@/components/GoogleSignInButton";
import { PhoneOtpPanel } from "@/components/PhoneOtpPanel";
import { auth, storeTokens, type TokenResponse, type TotpSetupResponse } from "@/lib/api";

type PasswordStep = "credentials" | "enroll" | "verify";

/**
 * InlineAuthStep — sign-in surface hosted inline inside the QR review-collection
 * flow (S-121), rendered only when the customer taps Submit while unauthenticated.
 * Not a reuse of `LoginForm.tsx` (that component is page-shaped: it owns a role
 * selector, a "registered" banner, a forgot-password link, and its own `<form>`
 * card chrome — none of which apply here). Composes the same primitives
 * `LoginForm.tsx` does (`AuthMethodToggle`, `GoogleSignInButton`, `PhoneOtpPanel`)
 * plus a local password+TOTP mini state machine calling the identical `auth.*`
 * functions `LoginForm.tsx` calls.
 *
 * On any method's success, stores tokens directly and calls `onAuthenticated()` —
 * deliberately never `redirectAfterAuth` (ADR-018), so the caller can auto-submit
 * the already-composed review in place instead of navigating away.
 */
export function InlineAuthStep({ onAuthenticated }: { onAuthenticated: () => void }) {
  const [authMethod, setAuthMethod] = useState<AuthMethod>("otp");
  const [step, setStep] = useState<PasswordStep>("credentials");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [code, setCode] = useState("");
  const [mfaToken, setMfaToken] = useState<string | null>(null);
  const [setup, setSetup] = useState<TotpSetupResponse | null>(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (step !== "enroll" || !mfaToken || setup) return;
    let cancelled = false;
    setLoading(true);
    auth
      .totpSetup(mfaToken)
      .then((s) => {
        if (!cancelled) setSetup(s);
      })
      .catch((err) => {
        if (!cancelled) setError(err instanceof Error ? err.message : "Failed to start authenticator setup");
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [step, mfaToken, setup]);

  function completeAuth(tokens: TokenResponse) {
    storeTokens(tokens);
    onAuthenticated();
  }

  async function handlePasswordSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      if (step === "credentials") {
        const result = await auth.login({ email, password });
        if (result.access_token && result.refresh_token) {
          completeAuth({ access_token: result.access_token, refresh_token: result.refresh_token });
          return;
        }
        if (result.mfa_enrollment_required && result.mfa_token) {
          setMfaToken(result.mfa_token);
          setSetup(null);
          setStep("enroll");
          return;
        }
        if (result.mfa_required && result.mfa_token) {
          setMfaToken(result.mfa_token);
          setStep("verify");
          return;
        }
        setError("Unexpected login response");
        return;
      }

      if (!mfaToken) {
        setError("Session expired — sign in again");
        setStep("credentials");
        return;
      }

      if (step === "enroll") {
        const tokens = await auth.totpConfirm(mfaToken, code);
        completeAuth(tokens);
        return;
      }

      const tokens = await auth.totpVerify(mfaToken, code);
      completeAuth(tokens);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Login failed");
    } finally {
      setLoading(false);
    }
  }

  async function handleGoogleCredential(credential: string) {
    setError("");
    try {
      const tokens = await auth.google({ credential });
      completeAuth(tokens);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Google sign-in failed");
    }
  }

  function backToCredentials() {
    setStep("credentials");
    setMfaToken(null);
    setSetup(null);
    setCode("");
    setError("");
  }

  return (
    <div className="space-y-3 text-left">
      <p className="text-center text-sm font-medium text-muted">Sign in to post your review</p>
      {error && <p className="text-sm text-red-600">{error}</p>}

      <AuthMethodToggle value={authMethod} onChange={setAuthMethod} />

      <GoogleSignInButton onCredential={handleGoogleCredential} />

      {authMethod === "otp" && <PhoneOtpPanel role="customer" onError={setError} onTokens={completeAuth} />}

      {authMethod === "authenticator" && (
        <form onSubmit={handlePasswordSubmit} className="space-y-3">
          {step === "credentials" && (
            <>
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="Email"
                className="w-full rounded border px-3 py-2"
              />
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Password"
                className="w-full rounded border px-3 py-2"
              />
              <p className="text-xs text-muted">
                Email and password sign-in requires an authenticator app (Google Authenticator, Authy, etc.).
              </p>
              <button
                type="submit"
                disabled={loading}
                className="w-full rounded bg-brand-600 py-2 text-white hover:bg-brand-700 disabled:opacity-50"
              >
                {loading ? "Signing in..." : "Sign in"}
              </button>
            </>
          )}

          {step === "enroll" && (
            <>
              <p className="text-sm text-muted">
                Scan this QR code with your authenticator app, or enter the secret manually. Then
                enter the 6-digit code to finish.
              </p>
              {setup ? (
                <>
                  <div
                    className="mx-auto flex max-w-[200px] justify-center [&_svg]:h-full [&_svg]:w-full"
                    dangerouslySetInnerHTML={{ __html: setup.qr_svg }}
                  />
                  <p className="break-all rounded bg-surface p-2 font-mono text-xs text-muted">{setup.secret}</p>
                </>
              ) : (
                <p className="text-sm text-muted">Preparing authenticator…</p>
              )}
              <input
                type="text"
                inputMode="numeric"
                autoComplete="one-time-code"
                required
                minLength={6}
                maxLength={8}
                value={code}
                onChange={(e) => setCode(e.target.value)}
                placeholder="6-digit code"
                className="w-full rounded border px-3 py-2"
              />
              <button
                type="submit"
                disabled={loading || !setup}
                className="w-full rounded bg-brand-600 py-2 text-white hover:bg-brand-700 disabled:opacity-50"
              >
                {loading ? "Confirming..." : "Confirm and sign in"}
              </button>
              <button type="button" onClick={backToCredentials} className="w-full text-sm text-muted underline">
                Back
              </button>
            </>
          )}

          {step === "verify" && (
            <>
              <p className="text-sm text-muted">Enter the 6-digit code from your authenticator app.</p>
              <input
                type="text"
                inputMode="numeric"
                autoComplete="one-time-code"
                required
                minLength={6}
                maxLength={8}
                value={code}
                onChange={(e) => setCode(e.target.value)}
                placeholder="6-digit code"
                className="w-full rounded border px-3 py-2"
              />
              <button
                type="submit"
                disabled={loading}
                className="w-full rounded bg-brand-600 py-2 text-white hover:bg-brand-700 disabled:opacity-50"
              >
                {loading ? "Verifying..." : "Verify and sign in"}
              </button>
              <button type="button" onClick={backToCredentials} className="w-full text-sm text-muted underline">
                Back
              </button>
            </>
          )}
        </form>
      )}
    </div>
  );
}
