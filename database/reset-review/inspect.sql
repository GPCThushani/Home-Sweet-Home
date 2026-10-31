\set ON_ERROR_STOP on
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ READ ONLY;
SELECT current_database() AS database, inet_server_addr() AS server_address,
       inet_server_port() AS server_port, current_setting('server_version') AS server_version;
SELECT format('SELECT %L AS schema_name, %L AS table_name, count(*) AS exact_rows FROM %I.%I;',
              n.nspname, c.relname, n.nspname, c.relname)
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND n.nspname NOT LIKE 'pg_toast%' AND c.relkind IN ('r', 'p')
ORDER BY n.nspname, c.relname
\gexec
SELECT table_schema, table_name, ordinal_position, column_name, data_type,
       is_nullable, column_default, is_identity
FROM information_schema.columns
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY table_schema, table_name, ordinal_position;
SELECT ns.nspname AS schema_name, c.relname AS table_name, con.conname,
       con.contype, pg_get_constraintdef(con.oid) AS definition
FROM pg_constraint con JOIN pg_class c ON c.oid = con.conrelid
JOIN pg_namespace ns ON ns.oid = c.relnamespace
WHERE ns.nspname NOT IN ('pg_catalog', 'information_schema') ORDER BY 1,2,3;
SELECT schemaname, sequencename, data_type, start_value, min_value, max_value,
       increment_by, cycle, last_value
FROM pg_sequences WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY 1,2;
SELECT ns.nspname AS schema_name, c.relname AS table_name, t.tgname,
       pg_get_triggerdef(t.oid) AS definition
FROM pg_trigger t JOIN pg_class c ON c.oid = t.tgrelid
JOIN pg_namespace ns ON ns.oid = c.relnamespace
WHERE NOT t.tgisinternal ORDER BY 1,2,3;
SELECT schemaname, tablename, policyname, cmd FROM pg_policies ORDER BY 1,2,3;
SELECT n.nspname AS schema_name, c.relname AS object_name, c.relkind
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND n.nspname NOT LIKE 'pg_toast%' AND c.relkind IN ('v','m','f','p') ORDER BY 1,2;
SELECT extname, extversion FROM pg_extension ORDER BY 1;
SELECT count(*) AS large_object_count FROM pg_largeobject_metadata;
SELECT application_name, state, count(*) AS connections
FROM pg_stat_activity WHERE datname = current_database() AND pid <> pg_backend_pid()
GROUP BY application_name, state ORDER BY 1,2;
COMMIT;
