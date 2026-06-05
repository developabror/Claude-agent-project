---
name: design-system
description: Use when working in frontend/ building any UI — components, pages, dashboards, navs, forms, layouts, or anything visual. Enforces a token-driven design system (Tailwind v4 CSS-first @theme + shadcn/ui layered as ui/primitives/blocks), the cn() helper, and a pre-output validation checklist. Tokens are the single source of truth — never raw hex, magic spacing, or one-off colors.
---

# Design System

The **single source of visual truth**. Every component conforms to the tokens. Deviation needs explicit justification.
Read this in full before writing any HTML/JSX/CSS/Tailwind — tokens drift between memory and source.

## Tokens (Tailwind v4, CSS-first — no `tailwind.config.js`)
Define the theme once in CSS; everything references it. **This is a starter palette — replace the
values with the product's brand, but keep the token structure and the rules.**
```css
/* src/styles/theme.css */
@import "tailwindcss";
@theme {
  --color-bg:        #f8f9fc;   /* app canvas */
  --color-surface:   #ffffff;   /* cards */
  --color-fg:        #1b2540;   /* primary text — NEVER pure #000 */
  --color-muted:     #5b6478;
  --color-primary:   #0050f8;   /* brand / primary actions */
  --color-accent:    #16a34a;   /* reserved for CTA fills only — replace with brand accent */
  --color-danger:    #d92d20;
  --radius-card: 16px;  --radius-input: 8px;  --radius-pill: 9999px;
  --shadow-card: 0 1px 2px rgba(0,39,80,.06), 0 8px 24px rgba(0,39,80,.08);
  --space-1:4px; --space-2:8px; --space-3:12px; --space-4:16px; --space-6:24px; --space-8:32px;
  --font-sans: "Inter", system-ui, sans-serif;
}
```

## Component layering (shadcn/ui)
```
src/components/
  ui/          # raw shadcn primitives (Button, Input, Dialog) — generated, minimally touched
  primitives/  # project-tweaked wrappers (our Button with our variants via cva)
  blocks/      # compositions (PageHeader, DataTable, EmptyState)
```
- Compose UI from `blocks → primitives → ui`. Variants are defined with **`cva`**, consistent across siblings.
- **`cn()`** (clsx + tailwind-merge) for conditional/merged classes — never string-concatenate classes.

## Hard rules
- **Tokens only.** Color, spacing, radius, shadow, type come from the theme. **No raw hex in components, no magic px, no off-scale spacing.**
- **No pure `#000000`/`#ffffff` for text** — use `--color-fg` / `--color-surface`.
- One canonical component per concept — reuse `ui/primitives/blocks`, never re-implement an existing primitive.
- Dark/light parity where the system defines both modes; respect `prefers-reduced-motion`.
- Accessible by construction: real semantic elements, labels, visible focus, AA contrast (the `accessibility` skill verifies).

## Validation checklist (run before every UI output — reject the draft if any box is unchecked)
- [ ] Every color/spacing/radius/shadow value is a **token**, not a literal
- [ ] No raw hex and no pure `#000`/`#fff` for text
- [ ] Classes merged via `cn()`; variants via `cva`
- [ ] Composed from existing `ui/primitives/blocks` (no duplicate primitive)
- [ ] Interactive elements are real `button`/`a` with visible focus and labels
- [ ] Contrast meets WCAG AA; nothing conveyed by color alone
- [ ] Responsive at mobile/tablet/desktop; no layout shift (reserved space for media)
- [ ] `accent` color used only for CTA fills, never decorative

## When the brief conflicts with the system
The system wins. Build the conformant version, state the conflicting rule in one sentence, offer a conformant alternative. Never silently override a token.
