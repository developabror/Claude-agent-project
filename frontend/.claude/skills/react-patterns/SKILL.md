---
name: react-patterns
description: Use when working in frontend/ on React 18 + TypeScript structure and components — feature-slice folders, one-directional imports, function-component idioms, hooks discipline, React Router v7 data mode, code-splitting, and state boundaries (server vs client vs form). The architectural rulebook for the React SPA.
---

# React Patterns (React 18 · TS · Vite)

How this SPA is structured and written. Read before creating features, routes, or components.

## Folder structure — feature-based vertical slices
```
src/
  features/<domain>/
    components/    # UI for this feature
    hooks/         # feature hooks (incl. TanStack Query hooks)
    api/           # request fns + query-key factory for this feature
    types.ts       # feature types (prefer generated OpenAPI types)
    index.ts       # PUBLIC API — the only thing other code may import
  components/ui/   # shared shadcn primitives
  hooks/           # shared hooks
  lib/             # api-client, utils (cn), helpers
  config/          # env.ts (validated), constants
  routes/          # router definition (data mode)
```

- **One-directional imports**: `shared → features → pages`. Never feature→feature. Cross-feature needs go through `shared` or composition at the page level.
- The **barrel `index.ts`** is the only public surface of a feature. The **"delete test"**: a file not re-exported by `index.ts` must be deletable without breaking another feature.
- Files **kebab-case** (`order-form.tsx`), components **PascalCase** (`OrderForm`).

## Component idioms
- **Function components only.** No `React.FC` (it removed implicit children handling and adds noise) — type props explicitly:
  ```tsx
  type OrderCardProps = { order: Order; onSelect: (id: string) => void };
  export function OrderCard({ order, onSelect }: OrderCardProps) { … }
  ```
- Hooks at the **top level**, never conditional. Custom hooks encapsulate stateful logic; components stay declarative.
- Stable `key`s (never array index for dynamic lists). Lift state only as far as needed.
- **Concurrent features** for responsiveness: `useTransition` for non-urgent updates, `useDeferredValue` for expensive derived UI, `Suspense` boundaries around async/lazy.
- **Error boundaries** around data-driven and lazy subtrees so one failure doesn't blank the app.
- Derive, don't sync: compute from props/state during render instead of mirroring with `useEffect`. Reserve `useEffect` for true external side effects (subscriptions, imperative DOM).

## State boundaries (assign every piece of state)
| Kind | Tool | Rule |
|---|---|---|
| Server state | **TanStack Query v5** | the only owner of API data — see `data-fetching` skill |
| Client/UI/auth | **Zustand** | toggles, theme, session; zero-Provider; never mirror server data here |
| Form | **react-hook-form + zod** | `zodResolver`; types via `z.infer`; reuse schemas |

## Routing — React Router v7 Data Mode (non-SSR SPA)
- `createBrowserRouter` + `RouterProvider`; route `loader`/`action`/`useFetcher` for data wiring against the separate Spring Boot API.
- **Code-split per route**: `const OrdersPage = React.lazy(() => import('@/features/orders'))` wrapped in `Suspense`.
- Keep route objects in `src/routes`; guard protected routes with an auth loader that redirects on 401.

## MUST NOT
- No `any` / unjustified non-null `!`. No `React.FC`. No feature→feature imports. No server data in Zustand. No data fetching in components via raw `useEffect` (use Query hooks). No business logic in components that belongs in a hook/service.
