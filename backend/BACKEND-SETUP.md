# BACKEND-SETUP.md — Spring Boot 3.4 / Java 21 · empty → production

The master, ordered playbook the `/scaffold-backend` command executes. Each phase names the owning
agent and the skill that holds the detail, and ends with a runnable check. Build the **smallest
layout that holds** — a thin CRUD service should not start as a 5-module sprawl.

> Stack: Java 21 · Spring Boot 3.4+ · **Gradle** · Postgres · Spring Data JPA · Flyway ·
> OAuth2 Resource Server (JWT) · Testcontainers · Actuator + Micrometer (OTLP) · springdoc OpenAPI.
> Base package: `com.example.app` (override per project). **No Lombok.**

---

## Phase 0 — Brief (`product-planner` / `backend-architect`)
Confirm: product name, base package, core domains/entities, auth model (external IdP vs local),
first endpoints, and the **API contract seam** with the frontend. Decide module layout:
- **Single-module** (`src/main/java/<pkg>/{controller,service,repository,model,dto,config,exception}`) for a small service.
- **Multi-module** (below) once boundaries justify it.

## Phase 1 — Build skeleton (`backend-build-engineer`, skill: `gradle-build`)
```
settings.gradle           include 'common','domain','infra','service','api'
build.gradle              allprojects group/version; subprojects java 21 + BOM + test
buildSrc/                 convention plugin: toolchain(21), repos, spotless, common deps
libs.versions.toml        version catalog (single source of dep versions)
```
Dependency direction: `api → service → domain ← infra`, `common` shared. `domain` is **framework-free**.
Base deps: `web, validation, data-jpa, postgresql, flyway-core, oauth2-resource-server, actuator,
micrometer-registry-otlp, micrometer-tracing-bridge-otel, springdoc-openapi-starter-webmvc-ui,
testcontainers (postgres, junit-jupiter)`. Add `@SpringBootApplication` in `api`.
✅ **Check:** `./gradlew build` compiles (empty app boots).

## Phase 2 — Domain + persistence (`jpa-persistence-engineer` + `db-migration-engineer`)
- `domain`: pure model + ports (interfaces), no Spring/JPA.
- `infra`: `@Entity` (LAZY associations) + repositories implementing the ports; `application` wires them.
- `src/main/resources/db/migration/V1__init.sql` (Flyway, plain Postgres SQL; indexes/constraints here).
- `spring.jpa.hibernate.ddl-auto=validate`, `spring.jpa.open-in-view=false`, explicit HikariCP sizing.
✅ **Check:** `@DataJpaTest` against a Testcontainers Postgres passes; `flywayValidate` green.

## Phase 3 — API layer (`api-designer` + `spring-boot-engineer`, skill: `rest-api-design`)
- DTO **records** + `@Valid`; thin `@RestController`s under `/api/v1`; map domain→DTO (MapStruct optional).
- One `@RestControllerAdvice extends ResponseEntityExceptionHandler` returning **RFC 9457 `ProblemDetail`**
  with `errorCode`, message, and `violations`.
- springdoc annotations on controllers/DTOs.
✅ **Check:** `@WebMvcTest` proves 201/400(`violations`)/404/409(with message); `/v3/api-docs` renders.

## Phase 4 — Security (`spring-security-engineer`, skill: `spring-security`)
- Explicit `SecurityFilterChain`: `STATELESS`, CSRF off (token API), **deny-by-default**, OAuth2 resource
  server (`issuer-uri`), `@EnableMethodSecurity`, CORS allow-list, `ProblemDetail` auth errors.
✅ **Check:** security slice: anonymous→401, wrong-role→403, valid→200 — all `ProblemDetail` bodies.

## Phase 5 — Config & profiles (`spring-boot-engineer`)
- `application.yml` base + `application-<profile>.yml`; `${ENV_VAR}` placeholders; activate via
  `SPRING_PROFILES_ACTIVE`. Bind config to constructor-injected `@ConfigurationProperties` records.
  Secrets via env/Vault — never committed.
✅ **Check:** app boots on the `dev` profile; missing required config fails fast.

## Phase 6 — Integration tests (`backend-test-engineer`, skill: `backend-testing`)
- `@SpringBootTest` + `@Testcontainers` + `@ServiceConnection` (real Postgres). Reusable
  `TestcontainersConfiguration` + `bootTestRun`. Cover happy + failure (validation, 409-with-message, auth).
✅ **Check:** `./gradlew test` (+ `integrationTest`) green.

## Phase 7 — Observability (`observability-engineer`, skill: `observability`)
- Actuator (`health,info,prometheus`) on a separate management port; liveness/readiness groups.
- Micrometer Observation + OTLP export; Boot 3.4 structured JSON logging with `traceId`/`spanId` in MDC.
✅ **Check:** `/actuator/health` UP; a request emits a trace + a correlated JSON log line.

## Phase 8 — Package & local stack (`backend-build-engineer`, skill: `gradle-build`)
- Multi-stage, **non-root, layered-jar** Dockerfile (or `bootBuildImage`) + `HEALTHCHECK`.
- `compose.yaml`: Postgres (+ Redis/Kafka if used) (+ Grafana LGTM optional); `spring-boot-docker-compose`.
✅ **Check:** `docker build` + container runs, `/actuator/health` UP.

## Phase 9 — CI/CD (`backend-build-engineer`)
- Temurin 21 + Gradle cache → unit + Testcontainers integration → Trivy/SBOM → buildx push
  **digest-pinned** (sha+semver) → promote the same artifact across envs. Never `latest` to staging/prod.
✅ **Check:** pipeline green on a PR.

## Phase 10 — Contract + review gate
- Emit + **commit `openapi.json`** (`./gradlew generateOpenApiDocs`); hand to `/contract-sync`.
- `backend-code-reviewer` + `backend-security-auditor` (read-only) — resolve every Critical.

---

### Definition of done (the "production" bar)
`./gradlew build` green · image runs with health UP · Flyway-managed schema · RFC 9457 errors ·
stateless JWT security · Testcontainers integration tests · Actuator + OTLP + structured logs ·
CI with scan + digest-pinned images · `openapi.json` committed and in sync with the frontend.
