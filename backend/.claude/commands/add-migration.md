---
description: Author and validate a new Flyway migration from an approved schema change (immutable, fix-forward).
argument-hint: <schema change summary>
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash(./gradlew:*), Bash(docker compose:*)
---

Author a Flyway migration for: $ARGUMENTS

Delegate to `db-migration-engineer` (read the `flyway-migrations` skill).

1. Find the latest version in `src/main/resources/db/migration`; create the next `V<n>__<snake_summary>.sql`.
2. One logical change; plain Postgres SQL; indexes/constraints in the migration. Provide the inverse as a commented `-- DOWN` reference.
3. **Destructive changes are two-step**: add+backfill+dual-write now, drop the old column in a later migration after the old code is gone. Never drop a column the running version still reads.
4. **Dry-run** against a throwaway Postgres: `./gradlew flywayMigrate flywayValidate` must be green — show the output.

Hard rule: **never edit an already-applied migration** — fix-forward with a new version. Never run against a shared/prod DB.
