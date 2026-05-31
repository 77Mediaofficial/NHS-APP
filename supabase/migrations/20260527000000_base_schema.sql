-- =============================================================================
-- BASE SCHEMA (foundation the rest of the repo assumes "upstream")
-- =============================================================================
-- Earlier migrations (section-11 tokens/RPC, status-domain prereq, token issuer,
-- retention/erasure, portal RLS) all REFERENCE these objects but never created
-- them — they were treated as managed upstream. On a fresh Supabase project there
-- is no upstream, so the stack can't apply. This migration provides a MINIMAL,
-- standards-aligned foundation. It is dated 2026-05-27 to run BEFORE every other
-- migration in this repo.
--
-- IMPORTANT — REPLACE-IN-PLACE EXPECTATION:
--   If your Trust already has a real waitlist system, DO NOT use this as-is — point
--   the app at the real tables instead and delete this file. This exists so the
--   project is self-contained and runnable for development / demonstration.
--
-- Contracts this must satisfy (verified against the other migrations + portal):
--   • hospitals(id)                                    — tenant anchor
--   • waitlist_entries(id, hospital_id, status, ...)   — status TEXT incl. PENDING_CANCELLATION
--   • waitlist_entries.patient_user_id                 — links a row to an NHS Login identity (portal RLS)
--   • auth.current_hospital_id()                       — admin's hospital from JWT
--   • sms_dispatch_jobs + get_next_sms_batch(int)      — used by the edge worker
-- Idempotent + safe to re-run. Target: PostgreSQL 15 (supabase/config.toml).
-- =============================================================================

-- ── 1. HOSPITALS (tenant anchor) ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS hospitals (
    id          UUID         NOT NULL DEFAULT gen_random_uuid(),
    name        TEXT         NOT NULL,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_hospitals PRIMARY KEY (id)
);
COMMENT ON TABLE hospitals IS 'Tenant anchor. Each waitlist entry belongs to exactly one hospital.';


-- ── 2. WAITLIST ENTRIES (the core clinical record) ───────────────────────────
-- status is TEXT + CHECK that ALREADY includes PENDING_CANCELLATION, so the
-- status-domain prereq migration (20260528120000) will simply NOTICE "already
-- permits" rather than needing to widen anything.
CREATE TABLE IF NOT EXISTS waitlist_entries (
    id              UUID         NOT NULL DEFAULT gen_random_uuid(),
    hospital_id     UUID         NOT NULL,
    -- patient_user_id links this entry to an authenticated NHS Login identity
    -- (auth.users.id). NULLable + NULL by default: a row is invisible in the
    -- patient portal until an identity-matching step populates it (fail-closed).
    patient_user_id UUID,
    procedure       TEXT         NOT NULL DEFAULT 'Procedure',
    status          TEXT         NOT NULL DEFAULT 'ACTIVE',
    referred_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_waitlist_entries PRIMARY KEY (id),
    CONSTRAINT fk_entries_hospital FOREIGN KEY (hospital_id)
        REFERENCES hospitals(id) ON DELETE CASCADE,
    CONSTRAINT chk_entries_status CHECK (status IN
        ('ACTIVE', 'PENDING_CANCELLATION', 'CANCELLED', 'COMPLETED'))
);
COMMENT ON TABLE waitlist_entries IS 'Core waitlist record. status: ACTIVE -> (PENDING_CANCELLATION -> CANCELLED) | COMPLETED.';
COMMENT ON COLUMN waitlist_entries.patient_user_id IS 'auth.users.id of the patient (NHS Login). NULL until identity-matched; gates portal visibility.';

CREATE INDEX IF NOT EXISTS idx_waitlist_entries_hospital_id
    ON waitlist_entries(hospital_id);
CREATE INDEX IF NOT EXISTS idx_waitlist_entries_patient_user_id
    ON waitlist_entries(patient_user_id);


-- ── 3. auth.current_hospital_id() — admin's hospital from the JWT ─────────────
-- Reads a custom claim 'hospital_id' from the request JWT. Set this claim when
-- provisioning admin/staff accounts (e.g. via a custom access-token hook). Returns
-- NULL when absent, so policies that compare against it fail closed.
CREATE OR REPLACE FUNCTION auth.current_hospital_id()
RETURNS UUID
LANGUAGE sql
STABLE
AS $$
    SELECT NULLIF(
        current_setting('request.jwt.claims', true)::jsonb ->> 'hospital_id',
        ''
    )::uuid;
$$;
COMMENT ON FUNCTION auth.current_hospital_id() IS 'Hospital UUID from the request JWT claim ''hospital_id''; NULL if absent (fail-closed).';


-- ── 4. SMS DISPATCH QUEUE (used by the edge worker) ──────────────────────────
-- Columns match supabase/functions/sms-dispatch-worker/index.ts:
--   id, patient_phone, payload_link, status, retry_count, locked_at, last_error.
CREATE TABLE IF NOT EXISTS sms_dispatch_jobs (
    id                 UUID         NOT NULL DEFAULT gen_random_uuid(),
    waitlist_entry_id  UUID         NOT NULL,
    patient_phone      TEXT         NOT NULL,
    payload_link       TEXT         NOT NULL,
    status             TEXT         NOT NULL DEFAULT 'pending',
    retry_count        INTEGER      NOT NULL DEFAULT 0,
    locked_at          TIMESTAMPTZ,
    last_error         TEXT,
    created_at         TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_sms_dispatch_jobs PRIMARY KEY (id),
    CONSTRAINT fk_sms_waitlist FOREIGN KEY (waitlist_entry_id)
        REFERENCES waitlist_entries(id) ON DELETE CASCADE,
    CONSTRAINT chk_sms_status CHECK (status IN ('pending', 'completed', 'failed'))
);
COMMENT ON TABLE sms_dispatch_jobs IS 'Outbound SMS queue. patient_phone is PII — see RLS below; never exposed to anon/patients.';

CREATE INDEX IF NOT EXISTS idx_sms_jobs_claimable
    ON sms_dispatch_jobs(status, locked_at) WHERE status = 'pending';


-- ── 5. get_next_sms_batch(batch_size) — atomic claim for the worker ──────────
-- SECURITY DEFINER so the worker (service_role) can atomically claim a batch:
-- locks pending rows, marks them locked, returns them. SKIP LOCKED makes
-- concurrent workers safe. search_path pinned.
CREATE OR REPLACE FUNCTION get_next_sms_batch(batch_size INTEGER)
RETURNS TABLE (
    id                UUID,
    waitlist_entry_id UUID,
    patient_phone     TEXT,
    payload_link      TEXT,
    retry_count       INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    WITH claimed AS (
        SELECT j.id
          FROM sms_dispatch_jobs j
         WHERE j.status = 'pending'
           AND (j.locked_at IS NULL OR j.locked_at < NOW() - INTERVAL '5 minutes')
         ORDER BY j.created_at
         FOR UPDATE SKIP LOCKED
         LIMIT GREATEST(batch_size, 0)
    )
    UPDATE sms_dispatch_jobs j
       SET locked_at = NOW()
      FROM claimed
     WHERE j.id = claimed.id
    RETURNING j.id, j.waitlist_entry_id, j.patient_phone, j.payload_link, j.retry_count;
END;
$$;
COMMENT ON FUNCTION get_next_sms_batch(INTEGER) IS 'Atomically claims up to batch_size pending SMS jobs (FOR UPDATE SKIP LOCKED). service_role only.';

REVOKE EXECUTE ON FUNCTION get_next_sms_batch(INTEGER) FROM PUBLIC;
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
        EXECUTE 'GRANT EXECUTE ON FUNCTION get_next_sms_batch(INTEGER) TO service_role';
    END IF;
END;
$$;


-- ── 6. RLS ON BASE TABLES (forced; locked down by default) ───────────────────
-- waitlist_entries: admin read scoped to hospital; patient SELECT policy is added
-- by 20260529070000_patient_portal_rls.sql. The definer UPDATE policy for the
-- PENDING_CANCELLATION soft-state is added by section-11 (20260529000000).
ALTER TABLE hospitals          ENABLE ROW LEVEL SECURITY;
ALTER TABLE hospitals          FORCE  ROW LEVEL SECURITY;
ALTER TABLE waitlist_entries   ENABLE ROW LEVEL SECURITY;
ALTER TABLE waitlist_entries   FORCE  ROW LEVEL SECURITY;
ALTER TABLE sms_dispatch_jobs  ENABLE ROW LEVEL SECURITY;
ALTER TABLE sms_dispatch_jobs  FORCE  ROW LEVEL SECURITY;

-- Admin (authenticated staff) may read entries within their own hospital.
DROP POLICY IF EXISTS pol_entries_admin_select ON waitlist_entries;
CREATE POLICY pol_entries_admin_select
    ON waitlist_entries FOR SELECT TO authenticated
    USING (hospital_id = auth.current_hospital_id());

-- Admin may read hospitals (their own).
DROP POLICY IF EXISTS pol_hospitals_admin_select ON hospitals;
CREATE POLICY pol_hospitals_admin_select
    ON hospitals FOR SELECT TO authenticated
    USING (id = auth.current_hospital_id());

-- sms_dispatch_jobs holds PII (phone). No anon/patient access at all; the worker
-- uses service_role (bypasses RLS). Admin read scoped to their hospital.
DROP POLICY IF EXISTS pol_sms_admin_select ON sms_dispatch_jobs;
CREATE POLICY pol_sms_admin_select
    ON sms_dispatch_jobs FOR SELECT TO authenticated
    USING (waitlist_entry_id IN (
        SELECT id FROM waitlist_entries WHERE hospital_id = auth.current_hospital_id()
    ));
