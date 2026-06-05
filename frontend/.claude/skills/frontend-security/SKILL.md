---
name: frontend-security
description: Use when working in frontend/ writing or reviewing code that renders untrusted data, handles auth tokens/sessions, calls the API, or adds dependencies — XSS prevention, token storage, CORS/CSRF posture, CSP, and supply-chain hygiene. Enforces no-localStorage-tokens, sanitized HTML sinks, and the principle that the client is never a trust boundary.
---

# Frontend Security

The browser is an injection surface, the token is a target, the dependency tree is hostile. Client validation is UX, **never** a trust boundary — the backend re-validates everything.

## XSS — the top client risk
- **Never** `dangerouslySetInnerHTML` with untrusted input. If you must render HTML, sanitize with **DOMPurify** first.
- Don't build `href`/`src` from untrusted strings (block `javascript:` URLs). Validate/allow-list URLs.
- External links: `target="_blank"` always with `rel="noopener noreferrer"`.
- Prefer text nodes (`{value}`) over HTML; React escapes by default — don't defeat it.

## Tokens & sessions
- Access token in **memory** or **HttpOnly + Secure + SameSite cookie** — **never `localStorage`/`sessionStorage`** (any XSS exfiltrates it).
- Refresh via a single-flight interceptor (see `data-fetching`); on refresh failure, log out and clear state.
- Nothing sensitive in `localStorage`, the URL, or logs. Don't put secrets in `VITE_` vars — they ship in the bundle.

## Transport & headers
- API over HTTPS; `withCredentials` only against the trusted origin. CORS allow-list lives on the backend; CSRF posture must match the cookie model.
- Recommend a **Content-Security-Policy** (no inline scripts; allow-list origins) served by nginx; add `X-Content-Type-Options: nosniff`, `Referrer-Policy`, `frame-ancestors`.

## Supply chain
- `npm audit --omit=dev` in CI; pin via lockfile; review new dependencies; no unvetted `<script>` tags or CDN includes for app logic.

## Review checklist
- [ ] No unsanitized HTML sink; no untrusted-URL `href`/`src`
- [ ] Tokens not in `localStorage`; nothing sensitive persisted client-side
- [ ] No secrets in the bundle / `VITE_` vars
- [ ] `rel="noopener"` on `_blank`; CSP recommended
- [ ] `npm audit` clean or risk-accepted
- [ ] Every client-side check is mirrored by a server-side check
- [ ] No swallowed errors — every API failure renders a visible state

## Errors must be visible (no silent failures)
A swallowed error is a UX *and* safety hole: the user acts on false success, and a real auth/permission
failure goes unseen. Every API error path renders a visible state — no empty `catch {}`, no ignored
promise rejection, no toast suppressed for a 4xx. Enforced by the `vite-build` lint rules and a
`frontend-testing` assertion that the error is surfaced.
