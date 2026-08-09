"use client";

import { useEffect, useRef } from "react";

declare global {
  interface Window {
    google?: {
      accounts: {
        id: {
          initialize: (config: {
            client_id: string;
            callback: (response: { credential: string }) => void;
          }) => void;
          renderButton: (parent: HTMLElement, options: Record<string, unknown>) => void;
        };
      };
    };
  }
}

const GSI_SRC = "https://accounts.google.com/gsi/client";

/** Renders Google's own "Continue with Google" button via Identity Services
 * and hands the resulting ID token (credential) back to the caller -- no
 * redirect, no popup managed by us. Renders nothing if
 * NEXT_PUBLIC_GOOGLE_CLIENT_ID isn't configured. */
export function GoogleSignInButton({ onCredential }: { onCredential: (credential: string) => void }) {
  const containerRef = useRef<HTMLDivElement>(null);
  // Ref so the mount-only effect below always calls the latest callback
  // without needing onCredential as a dependency -- LoginForm/RegisterForm
  // re-render on every keystroke, and re-running this effect each time would
  // reload/reinitialize the Google button and flicker it.
  const onCredentialRef = useRef(onCredential);
  onCredentialRef.current = onCredential;

  const clientId = process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID;

  useEffect(() => {
    if (!clientId || !containerRef.current) return;

    function render() {
      if (!window.google || !containerRef.current) return;
      window.google.accounts.id.initialize({
        client_id: clientId as string,
        callback: (response) => onCredentialRef.current(response.credential),
      });
      window.google.accounts.id.renderButton(containerRef.current, {
        theme: "outline",
        size: "large",
        width: 320,
      });
    }

    if (window.google) {
      render();
      return;
    }

    const existing = document.querySelector<HTMLScriptElement>(`script[src="${GSI_SRC}"]`);
    if (existing) {
      existing.addEventListener("load", render, { once: true });
      return;
    }

    const script = document.createElement("script");
    script.src = GSI_SRC;
    script.async = true;
    script.defer = true;
    script.addEventListener("load", render, { once: true });
    document.head.appendChild(script);
    // Intentionally no cleanup that removes the script tag -- Google's script
    // is meant to persist for the page lifetime, and other mounts of this
    // component (e.g. navigating login -> register) should reuse it.
  }, [clientId]);

  if (!clientId) return null;

  return <div ref={containerRef} className="flex justify-center" />;
}
