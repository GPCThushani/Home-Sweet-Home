# Approved test-data reset — completed

The user explicitly approved the 44-row, 27-table reset of `homesweethome` on `localhost:5433`. The guarded procedure committed successfully. Health Step 3 has not started.

## Preflight and backup

- Database identity matched: `homesweethome`, loopback `::1`, port 5433, PostgreSQL 18.6.
- All 27 application tables and their individual counts matched the approved inventory: 44 total rows.
- Nine foreign keys, 20 sequences, and no user-defined triggers matched the reviewed state. No other database clients were connected.
- The fresh schema export matched the original reviewed backup, ignoring only pg_dump's generated restrict/unrestrict tokens.
- The final custom-format logical backup and its checksum were verified before deletion. Archive listing and full offline archive reading succeeded; no restoration into another database was performed.

Final backup:

```text
G:\Projects\home_sweet_home\.local-backups\homesweethome-final-reset-20261030T133637Z\homesweethome.dump
```

SHA-256: `B0F4479301A707645DE3FDCA1829E5ABC6C4227886DB94867DE026154777BBBD`

The original pre-approval backup also remains intact. Both are under the existing access-restricted, Git-ignored backup directory.

## Execution

The exact reviewed `reset-after-approval.sql` was executed with the explicit approval parameter. Its transaction performed target/allowlist checks, locked the target tables, checked every approved row count, ran one explicit-table `TRUNCATE ... CONTINUE IDENTITY RESTRICT`, verified emptiness, and committed.

No `CASCADE`, `DROP`, `DELETE`, identity restart, constraint disabling, schema update, uploaded-file deletion, or JWT change was performed. No connection was made to port 5432 or to another database.

## Verification

| Check | Result |
| --- | --- |
| Approved rows removed | 44 |
| Application tables verified empty | 27 of 27 |
| Rows remaining after Spring Boot validation | 0 |
| Database identity, table/constraint/index metadata and object identities | Unchanged |
| Foreign keys preserved | 9 |
| Indexes preserved | 32 |
| Sequences preserved | 20 |
| Sequence values and `is_called` flags | Unchanged |
| Uploaded files | Existing file count, size and SHA-256 unchanged |
| Windows user `JWT_SECRET` | Fingerprint unchanged; value not printed |
| Final backup checksum after reset | Unchanged |
| Spring Boot application-context test | 1 passed; 0 failures/errors |
| Hibernate schema compatibility | Passed using `spring.jpa.hibernate.ddl-auto=validate` |

Schema/sequence comparisons and empty-table checks were repeated after the Spring Boot test. The test used the configured PostgreSQL database; schema updates were disabled. No replacement account, family, or health record was inserted for verification.

The protected final-backup directory contains the approved SQL copy, before/after snapshots, backup manifest/checksums, execution log, Spring Boot test result, and `verification-results.json`.

The database is empty and compatible with the current backend schema. Browser end-to-end registration/family creation was not exercised so that it remains empty. Old accounts no longer exist; the next application session should sign up anew. Reuse the existing signing key.

Application source files were not changed during reset execution. Only the read-only verification script, this report, the plan status, and protected backup/audit/generated-test artifacts were added or updated. Step 3 remains untouched.
