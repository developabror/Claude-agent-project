---
description: Add a JPA entity + repository + Flyway migration, wired through the layered architecture.
argument-hint: <EntityName + key fields>
---

Add this entity end-to-end: $ARGUMENTS

1. **Model** (`backend-architect` if it introduces a new aggregate/bounded context, else `jpa-persistence-engineer`): the domain type + where it lives (`domain` pure model + port; `infra` JPA adapter).
2. **Entity + repository** (`jpa-persistence-engineer`, read `jpa-patterns`): `@Entity` with LAZY associations, repository, fetch strategy. No `ddl-auto` — schema comes from Flyway.
3. **Migration** (`db-migration-engineer`, read `flyway-migrations`): `V<n>__add_<table>.sql` with columns, FKs, indexes, constraints matching the mapping exactly. Dry-run against a throwaway Postgres.
4. **Verify**: `@DataJpaTest` against Testcontainers Postgres; `ddl-auto=validate` boots clean (mapping ↔ migration agree).

Done when the migration validates and a data-slice test passes. If the entity is exposed over HTTP, follow with `/new-endpoint`.
