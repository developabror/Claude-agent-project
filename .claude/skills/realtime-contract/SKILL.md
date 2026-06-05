---
name: realtime-contract
description: Use when designing or changing any real-time / async channel between frontend and backend — WebSocket, SSE, or message/event payloads. Defines the AsyncAPI-as-source-of-truth contract, versioned event envelopes, a documented handshake/auth, and idempotent ordered delivery. The async counterpart to the REST api-contract — REST OpenAPI does NOT cover sockets.
---

# Realtime / Event Contract (WebSocket · SSE · events)

REST OpenAPI covers request/response only. Sockets, SSE, and events are **a separate contract** —
and an undocumented one drifts exactly like REST did, but silently. Treat the async surface with the
same rigor.

## Source of truth: AsyncAPI
- Describe every channel in an **`asyncapi.yaml`** (committed, like `openapi.json`): the channel/topic,
  the **message envelope**, direction, and the auth/handshake. Generate FE + BE types from it; diff it
  in CI (`git diff --exit-code`) so async drift fails the build too.

## Event envelope (versioned, self-describing)
```json
{ "type": "order.status.changed", "version": 1, "id": "<uuid>",
  "occurredAt": "<iso8601>", "seq": 1234, "traceId": "<w3c>", "data": { ... } }
```
- **`type` + `version`** so consumers can evolve; never repurpose an existing `type`/shape (that's breaking — add a new version).
- **`id`** for idempotency (consumers dedupe — networks redeliver).
- **`seq`** (monotonic per stream) so out-of-order delivery is detectable and orderable — **ordering is part of the contract**, not an accident of timing.
- **`traceId`** to correlate the event with the REST request and logs (see `observability`).

## Handshake & auth (document it)
- Define how a socket authenticates **explicitly**: token in the connect header / first message, what
  closes the connection, reconnce/backoff, and resume-from-`seq`. A second `SecurityFilterChain` /
  channel interceptor validates it (see `spring-security`) — don't bolt socket auth onto the REST chain.
- Heartbeat/ping + idle timeout; the client reconnects with exponential backoff and replays from its last `seq`.

## Frontend
- One typed socket/SSE client; validate inbound envelopes against the generated types (a malformed/
  unknown `type` is logged + dropped, never crashes the UI). Surface connection state; reconcile with
  TanStack Query cache (an event invalidates or patches the relevant query key — see `data-fetching`).

## Backend
- Publish through one typed emitter that stamps `type/version/id/occurredAt/seq/traceId`. Persist
  `seq` so reconnecting clients can resume. Never send an entity — send the documented `data` shape.

## Rules
- Async drift is a real bug class: **commit `asyncapi.yaml`, generate both sides, gate it in CI**.
- Ordering and delivery are contract terms (`seq`, idempotency `id`) — design them in, don't assume the transport guarantees them.
- A changed event shape is breaking → bump `version`, support both during migration, then retire the old.
