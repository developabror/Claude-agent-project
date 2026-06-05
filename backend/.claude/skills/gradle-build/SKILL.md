---
name: gradle-build
description: Use when working on the backend build/release lifecycle — Gradle multi-module config, buildSrc/convention plugins, version catalogs, dependency bumps, multi-stage non-root layered Dockerfiles, docker-compose for local dev, and CI/CD (GitHub Actions / CircleCI). Enforces Java 21 toolchain declared once, immutable digest-pinned images, layered-jar caching, and same-artifact promotion across environments.
---

# Gradle Build & Packaging (Java 21 · Spring Boot 3.4)

Reproducible, cached, reversible. The build declares versions once and ships an immutable artifact.

## Multi-module layout
```
settings.gradle           # include 'common','domain','infra','service','api'
build.gradle              # allprojects group/version; subprojects: java 21, BOM, test
buildSrc/ or build-logic/ # convention plugin: toolchain(21), repos, common deps, spotless
api/  service/  domain/  infra/  common/
```
- Declare the **Java 21 toolchain and shared deps once** in a convention plugin — never repeat per module.
- Use `api` vs `implementation` scoping to hide transitive deps and keep rebuilds incremental.
- A `libs.versions.toml` **version catalog** is the single source of dependency versions.
- Semantic versioning; bump PATCH on each generated version (project convention); module artifact name = directory name.

## Multi-stage, non-root, layered Dockerfile
```dockerfile
# syntax=docker/dockerfile:1
FROM eclipse-temurin:21-jdk-jammy AS build
WORKDIR /app
COPY . .
RUN ./gradlew :api:bootJar --no-daemon
RUN java -Djarmode=tools -jar api/build/libs/*.jar extract --layers --destination extracted

FROM eclipse-temurin:21-jre-jammy AS runtime
RUN useradd -r -u 1001 app
WORKDIR /app
# COPY least-changing layers first so Docker caches them
COPY --from=build /app/extracted/dependencies/ ./
COPY --from=build /app/extracted/spring-boot-loader/ ./
COPY --from=build /app/extracted/snapshot-dependencies/ ./
COPY --from=build /app/extracted/application/ ./
USER 1001
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:9090/actuator/health/readiness || exit 1
ENTRYPOINT ["java","-XX:MaxRAMPercentage=75","org.springframework.boot.loader.launch.JarLauncher"]
```
Buildpacks (`./gradlew bootBuildImage`) are an acceptable zero-Dockerfile alternative producing
layered, non-root images.

## compose.yaml (local parity)
Postgres (+ Redis/Kafka if used) and optionally the Grafana LGTM stack; Spring Boot's
`spring-boot-docker-compose` auto-discovers them at dev runtime — one-command local parity with prod.

## CI/CD pipeline (GitHub Actions shape)
1. `setup-java` Temurin 21 + `gradle/actions/setup-gradle` (build cache).
2. `./gradlew build` → unit + Testcontainers integration tests (Docker is available on hosted runners).
3. Trivy/SBOM scan.
4. `docker/build-push-action` with registry layer cache → push **immutable digest-pinned** tags (git-sha + semver).
5. Deploy the **same artifact** across dev→staging→prod behind gates. **Never deploy `latest`** to staging/prod.

## Config & secrets (12-factor)
- `application.yml` base + `application-<profile>.yml` overrides with `${ENV_VAR}` placeholders, activated by `SPRING_PROFILES_ACTIVE`.
- Bind config to constructor-injected `@ConfigurationProperties` records. Secrets via env / Vault / platform secret store — **never committed, never in images**.

## Definition of done
- `./gradlew build` and `docker build` succeed; the image runs and `/actuator/health/readiness` is UP.
- Image tag is digest-pinned (sha+semver); README/CHANGELOG updated when the project requires it.
