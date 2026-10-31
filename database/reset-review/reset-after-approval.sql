-- DRAFT: NOT EXECUTED. Requires separate explicit user approval.
-- Stop application writers and take/verify a fresh backup before authorizing.
-- No CASCADE, DROP, DELETE, identity restart, or schema changes are used.
\set ON_ERROR_STOP on
\if :{?APPROVE_HOME_SWEET_HOME_RESET}
  SELECT :'APPROVE_HOME_SWEET_HOME_RESET' = 'homesweethome@localhost:5433' AS approved_target \gset
  \if :approved_target
  \else
    \echo 'Refusing reset: approval target does not match.'
    \quit 3
  \endif
\else
  \echo 'Refusing reset: separate explicit approval is required.'
  \quit 3
\endif

BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '30s';

DO $guard$
DECLARE
    expected text[] := ARRAY[
      'families','family_activities','family_documents','family_members','family_memories',
      'family_profiles','garden_plants','garden_routine_completions','garden_routines','garden_setup',
      'global_tasks','health_appointments','health_documents','health_profiles','health_records',
      'maintenance_items','maintenance_records','medicine_logs','medicine_schedules','medicines',
      'menstrual_cycles','menstrual_entries','service_providers','shopping_items',
      'shopping_section_categories','shopping_sections','users'];
    actual text[];
BEGIN
    IF current_database() <> 'homesweethome'
       OR inet_server_port() IS DISTINCT FROM 5433
       OR inet_server_addr() IS NULL
       OR NOT (inet_server_addr() <<= '127.0.0.0/8'::inet OR inet_server_addr() = '::1'::inet) THEN
        RAISE EXCEPTION 'Refusing reset: wrong database/server';
    END IF;
    SELECT array_agg(c.relname::text ORDER BY c.relname) INTO actual
    FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relkind IN ('r','p','f');
    IF actual IS DISTINCT FROM expected THEN
        RAISE EXCEPTION 'Refusing reset: table inventory changed; review is required';
    END IF;
    IF EXISTS (SELECT 1 FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid
               JOIN pg_namespace n ON n.oid=c.relnamespace
               WHERE n.nspname='public' AND NOT t.tgisinternal) THEN
        RAISE EXCEPTION 'Refusing reset: user-defined triggers require review';
    END IF;
END $guard$;

-- Lock every target before checking counts so application writes cannot race
-- the approval inventory. Timeout or any validation error aborts the transaction.
LOCK TABLE
    public.families, public.family_activities, public.family_documents,
    public.family_members, public.family_memories, public.family_profiles,
    public.garden_plants, public.garden_routine_completions, public.garden_routines,
    public.garden_setup, public.global_tasks, public.health_appointments,
    public.health_documents, public.health_profiles, public.health_records,
    public.maintenance_items, public.maintenance_records, public.medicine_logs,
    public.medicine_schedules, public.medicines, public.menstrual_cycles,
    public.menstrual_entries, public.service_providers, public.shopping_items,
    public.shopping_section_categories, public.shopping_sections, public.users
IN ACCESS EXCLUSIVE MODE;

DO $counts$
DECLARE
    item record;
    actual bigint;
BEGIN
    FOR item IN SELECT * FROM (VALUES
        ('families',1), ('family_activities',0), ('family_documents',0),
        ('family_members',1), ('family_memories',0), ('family_profiles',6),
        ('garden_plants',0), ('garden_routine_completions',0), ('garden_routines',24),
        ('garden_setup',3), ('global_tasks',0), ('health_appointments',0),
        ('health_documents',0), ('health_profiles',2), ('health_records',0),
        ('maintenance_items',0), ('maintenance_records',0), ('medicine_logs',0),
        ('medicine_schedules',0), ('medicines',0), ('menstrual_cycles',0),
        ('menstrual_entries',0), ('service_providers',0), ('shopping_items',6),
        ('shopping_section_categories',0), ('shopping_sections',0), ('users',1)
    ) AS approved(table_name, row_count)
    LOOP
        EXECUTE format('SELECT count(*) FROM public.%I', item.table_name) INTO actual;
        IF actual <> item.row_count THEN
            RAISE EXCEPTION 'Refusing reset: row count changed for %; review required', item.table_name;
        END IF;
    END LOOP;
END $counts$;

-- This is the sole proposed data-removal statement. It has NOT been executed.
TRUNCATE TABLE
    public.families, public.family_activities, public.family_documents,
    public.family_members, public.family_memories, public.family_profiles,
    public.garden_plants, public.garden_routine_completions, public.garden_routines,
    public.garden_setup, public.global_tasks, public.health_appointments,
    public.health_documents, public.health_profiles, public.health_records,
    public.maintenance_items, public.maintenance_records, public.medicine_logs,
    public.medicine_schedules, public.medicines, public.menstrual_cycles,
    public.menstrual_entries, public.service_providers, public.shopping_items,
    public.shopping_section_categories, public.shopping_sections, public.users
CONTINUE IDENTITY RESTRICT;

DO $verify$
DECLARE
    item record;
    actual bigint;
BEGIN
    FOR item IN SELECT c.relname FROM pg_class c
        JOIN pg_namespace n ON n.oid=c.relnamespace
        WHERE n.nspname='public' AND c.relkind='r'
    LOOP
        EXECUTE format('SELECT count(*) FROM public.%I', item.relname) INTO actual;
        IF actual <> 0 THEN RAISE EXCEPTION 'Reset verification failed for %', item.relname; END IF;
    END LOOP;
END $verify$;

COMMIT;
