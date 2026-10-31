\set ON_ERROR_STOP on
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ READ ONLY;
SELECT jsonb_build_object(
  'kind','structure',
  'database',current_database(),
  'address',inet_server_addr()::text,
  'port',inet_server_port(),
  'version',current_setting('server_version'),
  'cluster',(SELECT system_identifier::text FROM pg_control_system()),
  'tables',(SELECT jsonb_agg(jsonb_build_object('schema',n.nspname,'table',c.relname,
      'oid',c.oid,'kind',c.relkind,'owner',pg_get_userbyid(c.relowner),'acl',c.relacl::text)
      ORDER BY n.nspname,c.relname)
    FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname NOT IN ('pg_catalog','information_schema')
      AND n.nspname NOT LIKE 'pg_toast%' AND c.relkind IN ('r','p','f')),
  'columns',(SELECT jsonb_agg(to_jsonb(cols) ORDER BY table_schema,table_name,ordinal_position)
    FROM information_schema.columns cols WHERE table_schema='public'),
  'constraints',(SELECT jsonb_agg(jsonb_build_object('table',c.relname,'name',con.conname,
       'oid',con.oid,'type',con.contype,'definition',pg_get_constraintdef(con.oid))
       ORDER BY c.relname,con.conname)
    FROM pg_constraint con JOIN pg_class c ON c.oid=con.conrelid
    JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public'),
  'indexes',(SELECT jsonb_agg(to_jsonb(idx) ORDER BY schemaname,tablename,indexname)
    FROM pg_indexes idx WHERE schemaname='public'),
  'extensions',(SELECT jsonb_agg(jsonb_build_object('name',extname,'version',extversion)
    ORDER BY extname) FROM pg_extension),
  'triggers',(SELECT jsonb_agg(pg_get_triggerdef(t.oid) ORDER BY c.relname,t.tgname)
    FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid
    JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND NOT t.tgisinternal)
);
SELECT format('SELECT jsonb_build_object(''kind'',''rows'',''schema'',%L,''table'',%L,''count'',count(*)) FROM %I.%I;',
  n.nspname,c.relname,n.nspname,c.relname)
FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname NOT IN ('pg_catalog','information_schema')
  AND n.nspname NOT LIKE 'pg_toast%' AND c.relkind IN ('r','p','f') ORDER BY n.nspname,c.relname
\gexec
SELECT format('SELECT jsonb_build_object(''kind'',''sequence'',''schema'',%L,''name'',%L,''last_value'',last_value,''is_called'',is_called) FROM %I.%I;',
  schemaname,sequencename,schemaname,sequencename)
FROM pg_sequences WHERE schemaname='public' ORDER BY schemaname,sequencename
\gexec
COMMIT;
