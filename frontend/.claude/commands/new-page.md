---
description: Add a routed page/feature slice — route (data mode), data hooks, components, and tests.
argument-hint: <page name + route + what it shows>
---

Add this page end-to-end: $ARGUMENTS

1. **Architect** (`frontend-architect`): create the `src/features/<domain>/` slice + its public `index.ts`; define the route (lazy-loaded) and what state each piece is.
2. **Route** (`react-engineer`): add to the React Router data-mode tree with a `loader` where it grounds initial data; `React.lazy` + `Suspense`; auth-guard if protected (redirect on 401).
3. **Data** (`data-state-engineer`): query-key factory + `queryOptions` + mutations for the page, using the generated API client; MSW handlers for tests.
4. **UI** (`react-engineer`): compose the page from on-system components; loading/empty/error states; responsive.
5. **Test** (`frontend-test-engineer`): integration test of the page (render → interact → assert) with MSW; a Playwright flow if it's a critical journey.
6. **Gates**: `design-system-enforcer`, `accessibility-auditor`, then `frontend-reviewer`. `npm run validate` green.

Done when the route renders, handles loading/error/empty, is accessible and tested.
