---
name: data-fetching
description: Use when working in frontend/ on the server-state and networking layer — TanStack Query v5 (queryOptions, query-key factories, mutations, optimistic updates, invalidation), the typed axios client with auth/refresh interceptors, mapping the backend ProblemDetail envelope, and MSW handlers. The contract for how the SPA talks to the Spring Boot API.
---

# Data Fetching (TanStack Query v5 · axios)

TanStack Query owns **all** server state. Components consume hooks; they never call axios directly.

## The shared axios client (one instance, interceptors)
```ts
// src/lib/api-client.ts
import axios from "axios";
// baseURL comes from RUNTIME config (window.__ENV__, injected at container start), defaulting to the
// same-origin "/api" path that nginx proxies to the backend — NOT a baked VITE_ var (see vite-build).
export const api = axios.create({ baseURL: window.__ENV__?.API_BASE_URL ?? "/api", withCredentials: true });

api.interceptors.request.use((cfg) => {
  const token = getAccessToken();            // from memory, NOT localStorage
  if (token) cfg.headers.Authorization = `Bearer ${token}`;
  return cfg;
});

// single-flight 401 refresh: queue concurrent 401s onto one refresh call
let refreshing: Promise<void> | null = null;
api.interceptors.response.use(undefined, async (error) => {
  const { response, config } = error;
  if (response?.status === 401 && !config._retried) {
    config._retried = true;
    refreshing ??= refreshSession().finally(() => { refreshing = null; });
    try { await refreshing; return api(config); }
    catch { logout(); }
  }
  return Promise.reject(toApiError(error));   // map ProblemDetail → typed UI error
});
```

- **Tokens** live in memory or HttpOnly+Secure+SameSite cookies — **never `localStorage`** (XSS theft).
- `toApiError` unwraps the backend RFC 9457 `ProblemDetail` (fields `title`, `status`, `detail` = the human-readable text, plus custom `errorCode`/`violations`) into the **one** UI error type — the human-readable field is **`detail`**, never `message`:
  ```ts
  // src/lib/api-client.ts — the single source of truth for the UI error shape
  export type ApiError = { detail: string; errorCode?: string; status?: number;
                           violations?: { field: string; message: string }[] };
  ```
  Components read `error.detail` (see `typescript-strict`). Map it; never swallow it.

## QueryClient defaults
```ts
new QueryClient({ defaultOptions: { queries: {
  staleTime: 30_000, retry: 1, refetchOnWindowFocus: false,
}}});
```

## Query-key factory + queryOptions (per feature)
```ts
// features/orders/api/keys.ts
export const orderKeys = {
  all: ["orders"] as const,
  list: (f: OrderFilters) => [...orderKeys.all, "list", f] as const,
  detail: (id: string) => [...orderKeys.all, "detail", id] as const,
};

export const orderListOptions = (f: OrderFilters) => queryOptions({
  queryKey: orderKeys.list(f),
  queryFn: () => api.get<PagedResponse<Order>>("/api/v1/orders", { params: f }).then(r => r.data),
});
```
```ts
// features/orders/hooks/use-orders.ts
export const useOrders = (f: OrderFilters) => useQuery(orderListOptions(f));
```

## Mutations — optimistic + invalidation
```ts
export function useCreateOrder() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (body: CreateOrder) => api.post<Order>("/api/v1/orders", body).then(r => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: orderKeys.all }),
  });
}
```
For optimistic updates: `onMutate` snapshots + sets the cache, `onError` rolls back to the snapshot, `onSettled` invalidates.

## Hard rules
- **Never mirror server data into Zustand.** Query cache is the source of truth.
- Every feature has a **query-key factory**; mutations invalidate the right keys (no manual refetch sprawl).
- **Prefer generated types/hooks from the backend OpenAPI** (`/wire-api` → Orval/openapi-typescript) over hand-written request/response shapes — this is the anti-drift mechanism.
- Cover the **error and 401/refresh paths** in tests; never silently drop a `ProblemDetail` message.

## MSW (test + dev mocking)
Define handlers per feature (`features/<d>/api/handlers.ts`), share them between Vitest and the dev server. Generate handlers from the OpenAPI spec where possible so mocks track the real contract.

## Correlation header + never-swallow errors
- The request interceptor adds a **`traceparent`** (or `X-Request-Id`) to every call so the backend correlates UI → API → logs (see `observability`/`api-contract`). Show the returned `traceId` in error UI ("ref: …").
- **Never swallow an API error.** Every query/mutation surfaces error state to the user (toast, inline, error boundary). An empty `catch`, a dropped rejection, or a suppressed toast hiding a 4xx is a bug — it's exactly what hid real failures before. The `vite-build` lint rules (no empty catch, no floating promise) enforce it; a `frontend-testing` assertion proves the error is visible.

## Contract testing (Pact, consumer side)
Beyond generated types, write **consumer Pact tests** (see `contract-testing`) for the endpoints the UI depends on — assert the request and the response shape you read, **including error interactions**. Verified against the real backend so behavioral drift fails CI.
