---
name: contract-testing
description: Use to set up or run consumer-driven contract tests (Pact) between the React frontend (consumer) and the Spring Boot backend (provider) — complements the OpenAPI codegen by asserting what the frontend actually consumes and verifying the backend honors it. Read when adding an endpoint the frontend depends on, or wiring the contract CI gate.
---

# Contract Testing (Pact — consumer-driven)

OpenAPI codegen keeps *types* in sync; **Pact keeps *behavior* in sync**. The frontend declares the
exact requests/responses it relies on; the backend is verified against that declaration. This catches
the bug class codegen misses: the backend changes a status code, nullability, or error shape the
frontend silently depended on.

## The flow
```
Frontend (CONSUMER)  ──writes pact──►  pact file (broker or repo)  ──verified by──►  Backend (PROVIDER)
  expects: GET /api/v1/orders → 200 {content:[...]}                  replays each interaction,
  expects: POST blank → 400 ProblemDetail{errorCode,detail}          asserts the real response matches
```

## Consumer side (frontend — Vitest + `@pact-foundation/pact`)
- For each hook/request the UI depends on, write a consumer test: given a provider state, expect a
  request → assert the response shape your code reads (including the **error paths**: 400 `ProblemDetail`,
  401, 409-with-message).
- Generates a pact JSON. Publish to a **Pact Broker** (or commit under `contracts/` for a small team).
- Run in CI; a changed expectation = a new pact version.

## Provider side (backend — `pact-jvm` / `au.com.dius.pact.provider`)
- `@Provider("backend")` + `@PactBroker`/`@PactFolder`; `@State("orders exist")` sets up each provider
  state (seed via Testcontainers). Pact **replays every consumer interaction** against the running app
  and fails if the real response diverges.
- Wire into the Gradle test task so provider verification runs in CI.

## CI gate (the point)
- Backend PR: `can-i-deploy` (or provider verification) must pass against the frontend's latest pact →
  a breaking change to a consumed contract **fails the backend build**, before it ever reaches the FE.
- Pair with `/contract-sync` (OpenAPI codegen): **codegen = shape, Pact = behavior**. Use both.

## Rules
- Only assert what the consumer **actually uses** — over-specifying makes the contract brittle.
- Always include the **error interactions** (this is where drift hurt before: a suppressed/empty error).
- Provider states seed real data via Testcontainers — never mock the provider's DB.
- A broken pact is a **breaking change**: version the API (`/api/v2`) or fix the consumer, never weaken the test.
