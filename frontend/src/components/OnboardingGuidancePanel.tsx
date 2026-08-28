"use client";

import type { BusinessFormValues } from "@/components/BusinessForm";
import { MERCHANT_REQUIRED_FIELDS, NATIONAL_ID_DISCLAIMER } from "@/lib/onboarding-copy";

function hasBasicInfo(v: BusinessFormValues): boolean {
  return Boolean(v.name.trim() && v.address.trim() && v.city.trim());
}

function hasContactInfo(v: BusinessFormValues): boolean {
  return Boolean(v.phone.trim() && v.email.trim());
}

function StepBadge({ done }: { done: boolean }) {
  return (
    <span
      className={`inline-flex h-5 w-5 shrink-0 items-center justify-center rounded-full text-xs ${
        done ? "bg-green-600 text-white" : "border border-border text-muted"
      }`}
      aria-label={done ? "Complete" : "Pending"}
    >
      {done ? "✓" : ""}
    </span>
  );
}

/**
 * OnboardingGuidancePanel — merchant add-business screen's left-column guidance.
 * Purely presentational; progress is derived from BusinessForm's own state via
 * onFormStateChange, no backend call.
 */
export function OnboardingGuidancePanel({ formState }: { formState: BusinessFormValues | null }) {
  const basicInfoDone = formState ? hasBasicInfo(formState) : false;
  const contactInfoDone = formState ? hasContactInfo(formState) : false;

  return (
    <div className="space-y-4 rounded-xl border border-border bg-surface-raised p-4 text-sm">
      <div>
        <h3 className="font-semibold text-ink">Getting started</h3>
        <ol className="mt-2 space-y-2">
          <li className="flex items-center gap-2">
            <StepBadge done={basicInfoDone} />
            <span className="text-muted">1. Business info (name, address, city)</span>
          </li>
          <li className="flex items-center gap-2">
            <StepBadge done={contactInfoDone} />
            <span className="text-muted">2. Contact details (phone, email)</span>
          </li>
          <li className="flex items-center gap-2">
            <StepBadge done={false} />
            <span className="text-muted">3. Identity verification (dashboard profile)</span>
          </li>
          <li className="flex items-center gap-2">
            <StepBadge done={false} />
            <span className="text-muted">4. Submit for admin review</span>
          </li>
        </ol>
      </div>

      <div>
        <h3 className="font-semibold text-ink">What&apos;s required</h3>
        <ul className="mt-1 list-inside list-disc text-muted">
          {MERCHANT_REQUIRED_FIELDS.map((field) => (
            <li key={field}>{field}</li>
          ))}
        </ul>
      </div>

      <div>
        <h3 className="font-semibold text-ink">Identity verification</h3>
        <p className="mt-1 text-muted">{NATIONAL_ID_DISCLAIMER}</p>
      </div>
    </div>
  );
}
