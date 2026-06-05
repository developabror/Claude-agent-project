---
name: typescript-strict
description: Use when working in frontend/ writing TypeScript — strict-mode discipline, typing patterns, discriminated unions, generics, zod inference, and avoiding any/non-null assertions. Enforces fully-typed boundaries and types derived from a single source (zod schemas / generated OpenAPI types).
---

# TypeScript (strict)

Types are a correctness tool, not decoration. The codebase runs `strict` + `noUnusedLocals/Parameters`,
`noImplicitReturns`, `noFallthroughCasesInSwitch`, `exactOptionalPropertyTypes`. Keep it green.

## Rules
- **No `any`.** Use `unknown` at untyped boundaries and narrow. No unjustified non-null `!` — handle the `undefined`.
- **Type the boundaries**: every exported function's params and return; component props; API request/response shapes.
- **Single source of types**: derive form types from zod (`z.infer<typeof schema>`); derive API types from the backend OpenAPI codegen (`/wire-api`). Don't hand-maintain a type the schema/spec already defines.
- **Discriminated unions** for state machines (`{ status: "loading" } | { status: "error"; error: ApiError } | { status: "ok"; data: T }`) — exhaustive `switch` with a `never` default makes missing cases a compile error.
- Prefer `type` aliases for unions/props; `interface` for extensible object contracts. `as const` for literal tuples/keys (query-key factories).
- Generics for reusable utilities; constrain them (`<T extends { id: string }>`) rather than leaving them open.

## Patterns
```ts
// exhaustiveness
function render(s: RequestState): ReactNode {
  switch (s.status) {
    case "loading": return <Spinner/>;
    case "error":   return <Error msg={s.error.detail}/>;   // ApiError.detail (defined in data-fetching) — not .message
    case "ok":      return <List items={s.data}/>;
    default: { const _x: never = s; return _x; }   // compile error if a case is added
  }
}

// zod as the single source of a form's type
const orderSchema = z.object({ name: z.string().min(1), customerId: z.string().uuid() });
type OrderForm = z.infer<typeof orderSchema>;
```

## MUST NOT
- `any`, unchecked `!`, `@ts-ignore` (use `@ts-expect-error` with a reason if truly unavoidable), or duplicating a type the schema/OpenAPI already owns.
