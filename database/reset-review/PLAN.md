# Application test-data reset — approved and completed

Status: the user subsequently approved this plan and the reset completed successfully. See `RESULTS.md` for the execution and verification results. The remainder of this document preserves the original reviewed scope and pre-reset inventory. Health Step 3 has not started.

## Exact target

- Database: `homesweethome`
- PostgreSQL endpoint: `localhost:5433` (observed loopback address `::1`)
- Server: PostgreSQL 18.6
- Target schema: `public`, 27 ordinary application tables
- The Docker configuration's PostgreSQL instance on port 5432 is a different target and is excluded.

The live database, not the initial SQL file, is the source of this inventory. `schema-inventory.txt` records exact counts, columns, constraints, sequences, and other schema metadata without personal record contents.

## Rows proposed for removal

The user has designated the existing application data as disposable test data. The proposal removes **all rows** in the following application tables, including records without enforced foreign keys. There is no reliable database-level test/production flag; this is a whole-application-data reset of the named database, not selective filtering.

| Table in `public` | Rows inspected |
| --- | ---: |
| families | 1 |
| family_activities | 0 |
| family_documents | 0 |
| family_members | 1 |
| family_memories | 0 |
| family_profiles | 6 |
| garden_plants | 0 |
| garden_routine_completions | 0 |
| garden_routines | 24 |
| garden_setup | 3 |
| global_tasks | 0 |
| health_appointments | 0 |
| health_documents | 0 |
| health_profiles | 2 |
| health_records | 0 |
| maintenance_items | 0 |
| maintenance_records | 0 |
| medicine_logs | 0 |
| medicine_schedules | 0 |
| medicines | 0 |
| menstrual_cycles | 0 |
| menstrual_entries | 0 |
| service_providers | 0 |
| shopping_items | 6 |
| shopping_section_categories | 0 |
| shopping_sections | 0 |
| users | 1 |
| **Total** | **44** |

`family_documents` is an existing application/legacy table identified from its household/document columns, even though the current Java entity list does not map it. It is empty. No unrelated user tables, foreign tables, partitioned tables, views, or materialized views were found.

## Relationships and structures retained

There are nine actual foreign-key constraints:

- `family_members.family_id` → `families.id`
- `family_members.user_id` → `users.id`
- `family_profiles.family_id` → `families.id`
- `family_profiles.user_id` → `users.id` (an existing legacy column/constraint retained unchanged)
- `global_tasks.family_id` → `families.id`
- `global_tasks.assigned_to`, `created_by`, and `completed_by` → `family_members.id`
- `shopping_section_categories.section_id` → `shopping_sections.id`

Health, medicine, garden, maintenance, document, and some other references are stored as scalar IDs without database foreign keys. All their application tables are explicitly included so orphaned rows are not left behind.

The reset preserves the database, schema, tables, columns, UUID behavior, primary keys, unique/check/not-null constraints, all nine foreign keys, indexes, defaults, grants, ownership, and the `plpgsql` extension. All **20 sequences and their counters** remain unchanged (`CONTINUE IDENTITY`). Fresh records can therefore have numeric IDs above 1; resetting counters is unnecessary and avoids reusing old IDs.

No user-defined triggers or row-level security policies were found. No PostgreSQL large objects were present. Other databases, roles, server configuration, the Docker volume, uploaded files, application source, and the saved `JWT_SECRET` are excluded. Uploaded media under `backend/uploads` will remain on disk; removing those files would require a separate request.

## Backup already completed

Protected, Git-ignored directory:

```text
G:\Projects\home_sweet_home\.local-backups\homesweethome-pre-reset-20261030T132517Z
```

- `homesweethome.dump`: complete database-level logical backup, PostgreSQL custom format, with database creation metadata, schema, data, constraints, indexes, ownership/grants, and sequence states; 54,710 bytes.
- `schema.sql`: separate schema-only export, 30,168 bytes.
- `archive-list.txt`: archive contents recorded by `pg_restore --list`.
- SHA-256 of the database archive: `37A80351E54273B9795D290F916B77FD4F3D2EF40AB9FAA1D24343A2AC285B6D`.

`pg_dump` exited successfully. `pg_restore --list` and a complete offline SQL extraction to the Windows null device both succeeded. Neither verification connected to a database or executed restore SQL. A restoration into a separate disposable server/database has not been tested. This is a database-level logical backup, not a physical cluster backup or an export of cluster-wide roles/passwords. External uploaded files are outside PostgreSQL and outside this backup.

Access to the backup directory is restricted to the current Windows user, SYSTEM, and Administrators. `.gitignore` now excludes `.local-backups/`; its previous UTF-16 encoding was converted to UTF-8 so Git can correctly interpret the exclusion. No application source was changed for this review.

## Exact proposed execution procedure — only after approval

1. Stop backend/Flutter activity and other writers to this database. No other database's sessions will be terminated. No other sessions were observed during this inspection; that will be checked again.
2. Recheck the target, table inventory, constraints, schema, and row counts. If data/schema changed, stop and show the updated scope. Create and verify a fresh uniquely named backup before resetting; retain the backup above too.
3. Use the guarded script `reset-after-approval.sql`, connecting explicitly to `localhost:5433/homesweethome`. The script refuses to run without the exact approval variable and checks the database name, port, loopback address, table allowlist, unexpected user triggers, and every approved row count.
4. Inside one transaction, acquire exclusive locks on the 27 listed tables with a five-second lock timeout. Stop on any error. Execute **one `TRUNCATE TABLE` listing those 27 schema-qualified tables**, with **`CONTINUE IDENTITY RESTRICT`**. The complete exact SQL is in `reset-after-approval.sql`. No `CASCADE`, `DELETE`, `DROP`, identity restart, or dynamic table deletion will be used.
5. Verify all listed tables are empty before committing. Any failure aborts the transaction. If the connection fails before commit, do not assume success: reconnect and inspect before attempting any further action.
6. After commit, repeat the read-only inventory. Confirm 27 tables remain, all row counts are zero, all nine foreign keys and other schema structures remain unchanged, and sequence states are preserved. Run backend schema validation without applying schema updates.
7. Clear the old browser session through the application's logout/login flow because its account will no longer exist. Keep the same JWT signing key. Verify readiness for registration and family creation without silently inserting replacement data; end-to-end creation of new test accounts/families can then be done explicitly.
8. Report reset results and backups. Only then proceed with Health Step 3 work.

The database is currently reachable and structurally inventoried. It is **not yet reset or verified empty**. New-account/family readiness after a reset cannot be claimed until the approved reset and post-reset checks are completed.

## Recovery

Retain the archive unchanged. If recovery is needed, stop application writes and first restore into a separately approved isolated database/server to verify the archive and inspect the data. Do not run `pg_restore --create` or any overwrite/clean option against the current server without a separate recovery approval. Any required role/ownership mapping must be reviewed rather than changing unrelated cluster roles automatically.

## Approval requested

Approve only if you want all **44 currently inventoried rows across the 27 listed tables** removed from **`homesweethome` on `localhost:5433`**, while retaining all database structures and sequence counters and leaving uploaded files untouched. The approval is for the data reset only; Health implementation remains a subsequent step.
