---
name: frontend-testing
description: Use when working in frontend/ writing or running tests — Vitest + React Testing Library unit/integration tests, MSW network mocks, and Playwright E2E. Enforces user-centric queries (getByRole/getByLabelText), behavior-not-implementation testing, network-layer mocking, positive+negative paths, and a coverage gate.
---

# Frontend Testing (Vitest · RTL · MSW · Playwright)

Test what the user experiences, not how it's implemented. Two layers: fast component/integration (Vitest), and critical-journey E2E (Playwright).

## Query like a user (RTL)
Priority order: `getByRole` → `getByLabelText` → `getByPlaceholderText` → `getByText` → (last resort) `getByTestId`.
Never `container.querySelector`. Drive interactions with `@testing-library/user-event`, not `fireEvent`.
```tsx
test("submitting a blank name shows a validation error", async () => {
  const user = userEvent.setup();
  render(<OrderForm />);
  await user.click(screen.getByRole("button", { name: /save/i }));
  expect(await screen.findByRole("alert")).toHaveTextContent(/name is required/i);
});
```

## Mock the network with MSW (not module mocks)
```ts
// test/handlers.ts
export const handlers = [
  http.get("/api/v1/orders", () => HttpResponse.json({ content: [], page: 0, totalElements: 0 })),
  http.post("/api/v1/orders", () =>
    HttpResponse.json({ errorCode: "VALIDATION_ERROR", detail: "Name is required" },
      { status: 400 })),   // exercise the ProblemDetail error path
];
```
Share handlers between tests and the dev server. Cover **loading, success, the `ProblemDetail` error path, and 401/refresh**.

## Rules
- **Behavior, not implementation** — assert on roles/labels/visible state and the response contract, never on hook internals or class names.
- **Both paths** — every feature gets a happy-path test and failure tests (validation, error envelope, empty, auth).
- **Deterministic** — no real network/clock; `findBy*` (awaited) instead of arbitrary timeouts; reset MSW + cleanup between tests.
- Co-locate tests with the feature (`order-form.test.tsx`). Report **only failures** + the summary.

## Playwright E2E (critical journeys only)
`@playwright/test` for flows needing cookies/router/real endpoints (auth, the core happy path). Run pre-release in CI; cache browsers. Keep E2E small and stable — it's a smoke net, not the bulk of coverage.

## Running & coverage
`npm run test` (Vitest) for the inner loop; `npx playwright test` for E2E. Gate coverage on changed code; reproduce reported bugs with a **failing test first**.
