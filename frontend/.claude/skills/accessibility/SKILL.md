---
name: accessibility
description: Use when working in frontend/ building or reviewing UI — semantic HTML, ARIA, keyboard navigation, focus management, color contrast, forms, and reduced motion. Enforces WCAG 2.2 AA, semantics-before-ARIA, full keyboard operability, and the eslint-jsx-a11y + axe tooling. Accessibility is built in, not bolted on.
---

# Accessibility (WCAG 2.2 AA)

Every user can perceive, operate, and understand the UI. Build it in; automated tools catch only ~30–40%.

## Semantics first (ARIA is a last resort)
- Use real elements: `button` for actions, `a[href]` for navigation, `nav`/`main`/`header`/`footer` landmarks, `label` for inputs, headings in order (one `h1`/page, no skipped levels).
- Add ARIA **only** to fill a genuine gap, and only correctly — a wrong ARIA role is worse than none. "No ARIA is better than bad ARIA."

## Keyboard & focus
- Everything interactive is reachable and operable by keyboard; **visible focus** indicator (never `outline: none` without a replacement).
- Logical tab order; no keyboard traps. On route change / modal open, **move focus** to the new context; on close, **restore** it. Modals trap focus while open and close on `Esc`.
- Don't add `tabindex > 0`; don't make non-interactive elements focusable.

## Forms
- Every control has a programmatic label (`<label htmlFor>` or `aria-label`). Group related controls with `fieldset`/`legend`.
- Errors are announced: associate with `aria-describedby`, and surface a summary in `role="alert"`/`aria-live`. Don't rely on color alone for error state.

## Visual
- Text contrast ≥ 4.5:1 (3:1 for large text / UI components). Don't convey meaning by color alone (add icon/text).
- Respect `prefers-reduced-motion` — gate non-essential animation. Content reflows to 320px without horizontal scroll; supports 200% zoom.

## Tooling (gate in CI)
- **Static**: `eslint-plugin-jsx-a11y` (recommended ruleset) on all JSX.
- **Runtime**: `@axe-core/react` in dev; `axe`/`jest-axe` assertions in component tests.
- **Manual**: tab through it; test with a screen reader (VoiceOver/NVDA) for critical flows — automation can't verify meaningful labels or focus order.

## Definition of done
No Critical/High axe violations; keyboard-operable end to end; labels and focus correct; AA contrast. Call out what still needs manual assistive-tech verification.
