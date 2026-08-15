# Slice: S-039 — AI reply drafting in merchant UI

| Field | Value |
|-------|-------|
| **Slice ID** | S-039 |
| **Phase** | 2 Core |
| **Status** | Accepted |
| **Role(s)** | merchant |
| **Owner** | PM / 2026-08-15 |

---

## User story

**As a** merchant replying to a review  
**I want** a “Draft with AI” control that fills `AIAnalysis.suggested_response` into the reply box  
**So that** I can edit a suggestion instead of starting from a blank textarea

---

## Acceptance criteria

1. **Given** a review on the merchant dashboard has `ai_analysis.suggested_response`, **when** I click “Draft with AI”, **then** the reply textarea is filled with that text and visible copy says it is a **suggestion**, not a verdict, and is not auto-sent.
2. **Given** there is no suggested_response, **when** the reply UI shows, **then** the button is hidden or disabled with “No draft available”.
3. **Given** I submit the reply, **when** it saves, **then** the stored reply is whatever I edited — the API does not force the AI text.
4. **Given** a customer, **when** they view ReviewCard, **then** they do not see Draft with AI.

---

## UX notes

- `ReviewCard` when `canReply`. No new backend field.
- AI disclaimer required: yes.

---

## Out of scope

- Auto-send. New LLM call on click (use stored analysis). Email.

---

## Dependencies

- S-033 dashboard recent reviews already include `ai_analysis`.
- Parallel with S-040; avoid S-037 chart files.
- No S-036 dependency.

---

## Definition of done (PM)

- [x] Combined TR
- [x] README §8 ReviewCard note
- [x] §12 M-70
- [x] Accepted shot 2

---

## Technical specification (Architect)

### API contract

None new. `suggested_response` already on `AIAnalysisResponse` / review payload.

### RBAC

Unchanged reply POST.

### Data model

- [x] None

### Frontend

`ReviewCard`: button “Draft with AI” sets local `replyBody` from `review.ai_analysis.suggested_response`. Label: “AI suggestion — edit before sending.”

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-15 | PM + Architect | Specified; near-zero backend. |
