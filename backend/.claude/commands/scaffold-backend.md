---
description: Scaffold this backend from empty to a deployable Spring Boot 3.4 / Java 21 service following BACKEND-SETUP.md.
argument-hint: [base package + core domains] (optional; will ask if omitted)
disable-model-invocation: true
---

Scaffold the backend 0→production. Follow **`BACKEND-SETUP.md`** in full as the ordered playbook. Brief: $ARGUMENTS

Delegate each phase to the owning specialist; use plan mode before large steps; close each phase with a runnable check.

1. **Architect** (`backend-architect`): confirm base package + module layout (multi-module vs single) and the bounded contexts.
2. **Build skeleton** (`backend-build-engineer`): Gradle multi-module + `buildSrc` convention plugin (Java 21 toolchain, version catalog), base deps (web, validation, data-jpa, postgres, flyway, oauth2-resource-server, actuator, micrometer-otlp, springdoc, testcontainers), `@SpringBootApplication`.
3. **Domain + persistence** (`jpa-persistence-engineer` + `db-migration-engineer`): domain model + ports, JPA entities/repos in `infra`, Flyway `V1__init.sql`.
4. **API** (`api-designer` + `spring-boot-engineer`): DTO records, thin controllers under `/api/v1`, `ProblemDetail` `@RestControllerAdvice`, springdoc annotations → commit `openapi.json`.
5. **Security** (`spring-security-engineer`): stateless `SecurityFilterChain`, OAuth2 resource server, method security.
6. **Config** (`spring-boot-engineer`): `@ConfigurationProperties` records, `application.yml` + profiles + `${ENV}` placeholders.
7. **Tests** (`backend-test-engineer`): Testcontainers + `@ServiceConnection` integration tests (positive + negative).
8. **Observability** (`observability-engineer`): Actuator probes, Micrometer OTLP, structured JSON logging.
9. **Package + CI** (`backend-build-engineer`): layered non-root Dockerfile, `compose.yaml`, CI pipeline.
10. **Review gate** (`backend-code-reviewer` + `backend-security-auditor`): resolve every Critical.

Done when `./gradlew build` is green, the image runs with `/actuator/health` UP, and `openapi.json` is committed.
