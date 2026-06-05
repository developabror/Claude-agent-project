---
name: flyway-migrations
description: Use when creating or reviewing database schema changes with Flyway — versioned SQL migrations, naming/ordering, indexes/constraints, backfills, and the ddl-auto=validate discipline on Postgres. Enforces immutable applied migrations, fix-forward, and migration-owned schema (not Hibernate ddl-auto).
---

# Flyway Migrations (Postgres)

Schema is code. Every change is a versioned, immutable, reviewed migration. Hibernate never owns the schema.

## Layout & naming
```
src/main/resources/db/migration/
  V1__initial_schema.sql
  V2__add_orders_table.sql
  V3__add_orders_status_index.sql
```
- `V<n>__<snake_case_summary>.sql`, monotonically increasing, one logical change per file.
- Repeatable (views/functions) use `R__<name>.sql` and run on checksum change.

## Iron rules
- **Never edit an applied migration.** It is immutable. Fix-forward with a new version. Flyway's checksum will fail the build if you mutate history.
- **`spring.jpa.hibernate.ddl-auto=validate`** in every real environment — Hibernate validates against the Flyway-built schema, never creates/updates it.
- Create **indexes and constraints in migrations**, not via entity annotations alone (annotations document intent; the migration is the truth).
- **Destructive changes are a two-step**: (1) add new + backfill + dual-write, deploy; (2) drop old in a later migration after the old code is gone. Never drop a column the running version still reads.
- Keep migrations **DB-portable only if you must** — otherwise use Postgres features freely (this is a single-Postgres app).

## Example
```sql
-- V2__add_orders_table.sql
CREATE TABLE orders (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        TEXT NOT NULL,
    customer_id UUID NOT NULL REFERENCES customers(id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_orders_customer ON orders(customer_id);
-- DOWN (manual rollback reference): DROP TABLE orders;
```

## Backfill pattern (safe column add with non-null)
```sql
-- V5__add_orders_status.sql
ALTER TABLE orders ADD COLUMN status TEXT;          -- 1. nullable
UPDATE orders SET status = 'ACTIVE' WHERE status IS NULL;  -- 2. backfill
ALTER TABLE orders ALTER COLUMN status SET NOT NULL;        -- 3. enforce
```

## Verify
- Dry-run against a **throwaway** Postgres (Testcontainers or local compose): `./gradlew flywayMigrate flywayValidate` must be green.
- Never run migrations against a shared/staging/prod DB from a dev session — that is the deploy pipeline's job.
- Confirm the migration matches the JPA entity exactly (types, nullability, FKs) — mismatch fails `ddl-auto=validate` at boot.
