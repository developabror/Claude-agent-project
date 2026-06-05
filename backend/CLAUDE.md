# CLAUDE.md — backend (Spring Boot / Java 21)

Launching Claude here loads **only the backend team** (+ shared root skills). Apply these on every
backend task unless told otherwise.

## Stack (non-negotiable defaults)
- **Java 21**, **Spring Boot 3.4+**, **Gradle multi-module** (`api · service · domain · infra · common`).
  > This template uses **Gradle**, not Maven. Build/test with `./gradlew`.
- Postgres + Spring Data JPA + **Flyway** migrations. OAuth2 Resource Server (JWT). springdoc OpenAPI.
- Base package `com.example.app` (override per project). **No Lombok** — use records / explicit accessors.

## Agents (delegate proactively)
| Agent | Use for |
|---|---|
| `backend-architect` | module boundaries, contracts, layering — *before* coding (read-only) |
| `spring-boot-engineer` | primary implementer: controllers, services, config |
| `api-designer` | REST contract, DTO records, `ProblemDetail`, OpenAPI |
| `jpa-persistence-engineer` | entities, fetch strategy, N+1, transactions |
| `db-migration-engineer` | Flyway migrations (immutable, fix-forward) |
| `backend-test-engineer` | JUnit 5 + Testcontainers; positive **and** negative |
| `spring-security-engineer` | SecurityFilterChain, JWT, method security |
| `backend-security-auditor` | independent OWASP review gate (read-only) |
| `observability-engineer` | Actuator, Micrometer OTLP, structured logging |
| `backend-performance-engineer` | profiling, Hikari, GC (measure-first, read-mostly) |
| `backend-code-reviewer` | adversarial review gate before merge (read-only) |
| `backend-build-engineer` | Gradle, Dockerfile, compose, CI |

Use the built-in **Explore** agent for cheap read-only recon before building.

## Commands
`/scaffold-backend` (0→prod) · `/new-endpoint` · `/new-entity` · `/add-migration`.

## Skills (auto-load by description — read the matching one before coding that domain)
`spring-boot` · `rest-api-design` · `jpa-patterns` · `spring-security` · `backend-testing` ·
`flyway-migrations` · `observability` · `gradle-build` · `code-quality` · `design-patterns` · `logging-patterns`.

## Non-negotiables (surfaced so you don't need to load a skill to recall them)
- **Constructor injection** only; `@Valid` every request body; DTO **records** separate from entities (never serialize an entity).
- Errors → **RFC 9457 `ProblemDetail`** with a mandatory human-readable message + stable `errorCode`. A 4xx/409 **must** carry a message.
- `@Transactional` on multi-step writes; `readOnly=true` on reads; `open-in-view=false`; associations **LAZY**.
- Schema via **Flyway only**; `ddl-auto=validate`; never edit an applied migration.
- Security **deny-by-default**, stateless, CORS allow-list (never `*`+credentials); secrets via env/Vault, never in source/images/logs.
- Tests cover **positive and negative**; integration tests use **Testcontainers** (never H2 as a Postgres stand-in).
- Paths under `/api/v1`; pagination capped (default 20, max 100).
- **Invariants are DB constraints** (unique/check/`EXCLUDE`) + a rejecting/property test — never just a service `if`.
- **Continue the incoming `traceparent`** and echo `traceId` in `ProblemDetail`/logs (end-to-end correlation).
- A single **`ErrorCode`** enum is the catalog (exposed in OpenAPI). Ship risky work behind a **feature flag**.
- **Pact provider verification** runs in the suite; the async surface (sockets/events) has its own `asyncapi.yaml` contract.

## Working principles
Plan non-trivial work first. Close every task with `./gradlew test`/`build` evidence **and a
`/redeploy --backend` local smoke** (db + backend up, `/actuator/health/readiness` UP) — never "done"
on a red build or an unrun stack. Keep `backend/compose.yaml` and the root `compose.yaml` in sync.
**Commit & push policy:** finalize → local commit always; never push to a git remote or Docker Hub
without an exact instruction (then ask git/Docker/both) — see root `CLAUDE.md` / `git-workflow`. Run `backend-code-reviewer` (+ `backend-security-auditor` for sensitive changes)
before merge. Bump version per semver (PATCH each generated version) and update README/CHANGELOG when
the project requires it. Smallest correct diff; find root causes, not band-aids.

If you add an agent/skill, update the tables above.
