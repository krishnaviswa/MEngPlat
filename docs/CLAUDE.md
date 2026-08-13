# Documentation sync

> Mirrors `.cursor/rules/docs-and-api.mdc` (Cursor `globs: README.md,docs/**/*`). Keep
> both in sync — see the parity table in the root [`CLAUDE.md`](../CLAUDE.md).

This project keeps **one** prose document: `README.md`. Never create a new `.md` file for
documentation — update the relevant section instead.

| Change | Update |
|--------|--------|
| New endpoint | `README.md` §7 API reference |
| New flow | `README.md` §6 Feature flows |
| Architecture change | `README.md` §3 Architecture |
| New technology or dependency | `README.md` §4 Why this stack (state the rationale) |
| New component pattern | `README.md` §8 Frontend guide |
| Schema change | `README.md` §5 Domain model |
| Auth / RBAC / security change | `README.md` §9 Security |
| Deploy/env change | `README.md` §10 Deployment, §15 Environment variables |
| Feature completed or gap closed | `README.md` §14 Known gaps |
| New or changed **user-facing web** capability (route, nav, major interaction) | `README.md` §12 Web ↔ mobile feature parity tracker — add or adjust the mobile line item (`unimplemented` / `partial` / `future` as appropriate). Every web feature must have a mobile status row. |
| Mobile closes a parity gap | Same §12 tracker → `implemented` or `partial`; also §14 if a known gap closes |

Keep docs beginner-friendly. Use mermaid for non-trivial flows.

Exception: `docs/agents/` holds live workflow artifacts (slices, ADRs, test plans/reports)
created from their `_TEMPLATE.md` files — those are artifacts, not documentation. This
`CLAUDE.md` and other `.claude`/`.cursor` config files are tooling config, not
documentation either — they're exempt from the "one prose document" rule.
