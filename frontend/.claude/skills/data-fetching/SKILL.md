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
export const api = axios.create({ baseURL: import.meta.env.VITE_API_BASE_URL, withCredentials: true });

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
- `toApiError` unwraps the backend RFC 9457 `ProblemDetail` — the standard fields are `title`, `status`, `detail` (the human-readable text) plus custom properties `errorCode` and `violations`. Map `detail`/`violations` into a typed error the UI can render — never swallow it. (Note: the field is `detail`, not `message`.)

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
