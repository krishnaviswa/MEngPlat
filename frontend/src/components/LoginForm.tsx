"use client";

import { useEffect, useState } from "react";
import { useSearchParams } from "next/navigation";
import { GoogleSignInButton } from "@/components/GoogleSignInButton";
import { auth, storeTokens, type TotpSetupResponse } from "@/lib/api";

type Step = "credentials" | "enroll" | "verify";

/**
 * LoginForm — email/password (mandatory authenticator) or Google sign-in.
 * Password path never stores session tokens until TOTP enroll/verify succeeds.
 */
export function LoginForm() {
  const searchParams = useSearchParams();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [code, setCode] = useState("");
  const [step, setStep] = useState<Step>("credentials");
  const [mfaToken, setMfaToken] = useState<string | null>(null);
  const [setup, setSetup] = useState<TotpSetupResponse | null>(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [registeredNote, setRegisteredNote] = useState(false);

  useEffect(() => {
    const prefill = searchParams.get("email");
    if (prefill) setEmail(prefill);
    if (searchParams.get("registered") === "1") setRegisteredNote(true);
  }, [searchParams]);

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

  function finishWithTokens(tokens: { access_token: string; refresh_token: string }) {
    storeTokens(tokens);
    // Hard reload so ClientLayout remounts with the new session.
    window.location.href = "/";
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      if (step === "credentials") {
        const result = await auth.login({ email, password });
        if (result.access_token && result.refresh_token) {
          finishWithTokens({
            access_token: result.access_token,
            refresh_token: result.refresh_token,
          });
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
        finishWithTokens(tokens);
        return;
      }

      const tokens = await auth.totpVerify(mfaToken, code);
      finishWithTokens(tokens);
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
      finishWithTokens(tokens);
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
    <form onSubmit={handleSubmit} className="mx-auto max-w-md space-y-4 rounded-xl border bg-white p-6 shadow-sm">
      <h1 className="text-xl font-bold">
        {step === "credentials" && "Login"}
        {step === "enroll" && "Set up authenticator"}
        {step === "verify" && "Authenticator code"}
      </h1>

      {registeredNote && step === "credentials" && (
        <p className="rounded bg-green-50 p-2 text-sm text-green-800">
          Account created. Sign in with your password to set up your authenticator app.
        </p>
      )}

      {error && <p className="rounded bg-red-50 p-2 text-sm text-red-700">{error}</p>}

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
          <p className="text-xs text-gray-500">
            Email and password sign-in requires an authenticator app (Google Authenticator, Authy, etc.).
            Or continue with Gmail below.
          </p>
          <button
            type="submit"
            disabled={loading}
            className="w-full rounded bg-brand-600 py-2 text-white hover:bg-brand-700 disabled:opacity-50"
          >
            {loading ? "Signing in..." : "Sign in"}
          </button>
          <div className="flex items-center gap-3 text-xs text-gray-400">
            <div className="h-px flex-1 bg-gray-200" />
            or
            <div className="h-px flex-1 bg-gray-200" />
          </div>
          <GoogleSignInButton onCredential={handleGoogleCredential} />
        </>
      )}

      {step === "enroll" && (
        <>
          <p className="text-sm text-gray-600">
            Scan this QR code with your authenticator app, or enter the secret manually. Then enter the
            6-digit code to finish — this protects your password account.
          </p>
          {setup ? (
            <>
              <div
                className="mx-auto flex max-w-[200px] justify-center [&_svg]:h-full [&_svg]:w-full"
                dangerouslySetInnerHTML={{ __html: setup.qr_svg }}
              />
              <p className="break-all rounded bg-gray-50 p-2 font-mono text-xs text-gray-700">
                {setup.secret}
              </p>
            </>
          ) : (
            <p className="text-sm text-gray-500">Preparing authenticator…</p>
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
          <button type="button" onClick={backToCredentials} className="w-full text-sm text-gray-500 underline">
            Back
          </button>
        </>
      )}

      {step === "verify" && (
        <>
          <p className="text-sm text-gray-600">Enter the 6-digit code from your authenticator app.</p>
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
          <button type="button" onClick={backToCredentials} className="w-full text-sm text-gray-500 underline">
            Back
          </button>
        </>
      )}
    </form>
  );
}
