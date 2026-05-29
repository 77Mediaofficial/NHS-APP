-- =============================================================================
-- PREREQUISITE: waitlist_entries.status must permit 'PENDING_CANCELLATION'
-- =============================================================================
-- CLINICAL-SAFETY (DCB0129/0160): the patient-facing RPC moves a declined entry
-- into the REVERSIBLE soft-state 'PENDING_CANCELLATION' instead of a hard cancel.
-- The section-11 migration (20260529000000) defines a policy whose
-- `WITH CHECK (status = 'PENDING_CANCELLATION')` expression must resolve against
-- the column's domain — so this value MUST exist BEFORE that migration runs.
-- This file is intentionally dated earlier so it applies first.
--
-- `waitlist_entries` is an UPSTREAM/managed table not created in this repo, and we
-- do not know whether `status` is a Postgres ENUM or a TEXT column with a CHECK
-- constraint. This migration introspects the live schema and does the right thing,
-- and NEVER hard-fails: if it cannot safely widen the domain it raises an explicit
-- NOTICE telling the operator exactly what to change. Idempotent + safe to re-run.
-- Target: PostgreSQL 15 (per supabase/config.toml) — ALTER TYPE ... ADD VALUE is
-- permitted inside a transaction on PG12+ (the value is not USED in this same tx).
-- =============================================================================

DO $$
DECLARE
    v_type_oid   oid;
    v_typname    text;
    v_typnsp     text;
    v_typtype    "char";
    v_has_value  boolean;
    v_check_rec  record;
    v_found      boolean := false;
BEGIN
    -- Resolve the data type backing public.waitlist_entries.status
    SELECT t.oid, t.typname, n.nspname, t.typtype
      INTO v_type_oid, v_typname, v_typnsp, v_typtype
      FROM pg_attribute a
      JOIN pg_class     c ON c.oid = a.attrelid
      JOIN pg_namespace cn ON cn.oid = c.relnamespace
      JOIN pg_type      t ON t.oid = a.atttypid
      JOIN pg_namespace n ON n.oid = t.typnamespace
     WHERE cn.nspname = 'public'
       AND c.relname  = 'waitlist_entries'
       AND a.attname  = 'status'
       AND a.attnum   > 0
       AND NOT a.attisdropped;

    IF NOT FOUND THEN
        RAISE NOTICE '[status-domain] public.waitlist_entries.status not found. '
            'If this table is managed elsewhere, ensure its status domain permits '
            '''PENDING_CANCELLATION'' before applying migration 20260529000000.';
        RETURN;
    END IF;

    -- CASE 1: status is an ENUM ------------------------------------------------
    IF v_typtype = 'e' THEN
        SELECT EXISTS (
            SELECT 1 FROM pg_enum
             WHERE enumtypid = v_type_oid AND enumlabel = 'PENDING_CANCELLATION'
        ) INTO v_has_value;

        IF v_has_value THEN
            RAISE NOTICE '[status-domain] enum %.% already contains '
                '''PENDING_CANCELLATION'' — no change needed.', v_typnsp, v_typname;
        ELSE
            EXECUTE format(
                'ALTER TYPE %I.%I ADD VALUE IF NOT EXISTS %L',
                v_typnsp, v_typname, 'PENDING_CANCELLATION'
            );
            RAISE NOTICE '[status-domain] added ''PENDING_CANCELLATION'' to enum %.%.',
                v_typnsp, v_typname;
        END IF;
        RETURN;
    END IF;

    -- CASE 2: status is TEXT/VARCHAR/etc. — look for CHECK constraints ----------
    FOR v_check_rec IN
        SELECT con.conname, pg_get_constraintdef(con.oid) AS def
          FROM pg_constraint con
          JOIN pg_class      c  ON c.oid = con.conrelid
          JOIN pg_namespace  cn ON cn.oid = c.relnamespace
         WHERE cn.nspname = 'public'
           AND c.relname  = 'waitlist_entries'
           AND con.contype = 'c'
           AND pg_get_constraintdef(con.oid) ILIKE '%status%'
    LOOP
        v_found := true;
        IF v_check_rec.def ILIKE '%PENDING_CANCELLATION%' THEN
            RAISE NOTICE '[status-domain] CHECK constraint % already permits '
                '''PENDING_CANCELLATION'' — no change needed. (%).',
                v_check_rec.conname, v_check_rec.def;
        ELSE
            RAISE NOTICE '[status-domain] ACTION REQUIRED: CHECK constraint % on '
                'public.waitlist_entries restricts status and does NOT permit '
                '''PENDING_CANCELLATION''. Current definition: %. Drop and recreate '
                'it to include ''PENDING_CANCELLATION'' (cannot be auto-rewritten '
                'safely without knowing the full intended value set).',
                v_check_rec.conname, v_check_rec.def;
        END IF;
    END LOOP;

    IF NOT v_found THEN
        RAISE NOTICE '[status-domain] public.waitlist_entries.status is type %.% '
            'with no CHECK constraint — free text accepts ''PENDING_CANCELLATION'' '
            'already. No change needed.', v_typnsp, v_typname;
    END IF;
END;
$$;

-- Verification (run manually after apply):
--   SELECT e.enumlabel FROM pg_enum e
--     JOIN pg_type t ON t.oid = e.enumtypid
--    WHERE t.typname = (SELECT udt_name FROM information_schema.columns
--                        WHERE table_name='waitlist_entries' AND column_name='status');
