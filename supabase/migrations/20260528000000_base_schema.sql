-- =============================================================================
-- BASE SCHEMA — the upstream/core tables the rest of the app assumes
-- =============================================================================
-- Every other migration (and the sms-dispatch-worker edge function) references
-- objects that were previously "assumed upstream" and not present in this repo:
--   • public.hospitals
--   • public.waitlist_entries   (id, hospital_id, status, + minimal PII)
--   • public.hospital_staff     (auth user -> hospital mapping)
--   • public.sms_dispatch_jobs  (outbound SMS queue, drained by the worker)
--   • auth.current_hospital_id()  (need-to-know scope used by every RLS policy)
--   • public.get_next_sms_batch(batch_size)  (atomic batch claim for the worker)
-- This migration scaffolds them so an empty Supabase project can run the full
-- chain end-to-end. It is dated FIRST (20260528000000) so it applies before the
-- status-domain prerequisite (20260528120000) and section 11 (20260529000000).
--
-- CLINICAL-SAFETY (DCB0129/0160): waitlist_status is intentionally created WITHOUT
-- 'PENDING_CANCELLATION'. Migration 20260528120000 adds that reversible soft-state
-- afterwards (its whole reason to exist), and section 11 then builds the policy whose
-- WITH CHECK references it. Do not add it here or you defeat that migration's purpose.
--
-- ASSUMES Supabase (auth schema, auth.uid(), anon/authenticated/service_role roles).
-- Idempotent + safe to re-run (IF NOT EXISTS / CREATE OR REPLACE / DROP POLICY IF EXISTS).
-- Target: PostgreSQL 15 (per supabase/config.toml).
-- =============================================================================

-- gen_random_uuid() lives in pgcrypto on older PGs; ensure it is present.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ── 1. ENUMS ──────────────────────────────────────────────────────────────────

-- Waitlist lifecycle as a managed PAS/e-RS system would expose it. NOTE the
-- deliberate ABSENCE of 'PENDING_CANCELLATION' (added by migration 20260528120000).
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'waitlist_status') THEN
        CREATE TYPE waitlist_status AS ENUM ('WAITING', 'SCHEDULED', 'ATTENDED', 'CANCELLED');
    END IF;
END;
$$;

-- Outbound SMS job lifecycle. Lowercase to match the worker's writes
-- ('completed' / 'pending' / 'failed') and get_next_sms_batch ('processing').
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'sms_job_status') THEN
        CREATE TYPE sms_job_status AS ENUM ('pending', 'processing', 'completed', 'failed');
    END IF;
END;
$$;

-- ── 2. TABLES ───────────────────────────────────────────────────────────────--

-- Hospitals (tenants). hospital_id is the need-to-know boundary throughout.
CREATE TABLE IF NOT EXISTS hospitals (
    id          UUID         NOT NULL DEFAULT gen_random_uuid(),
    name        TEXT         NOT NULL,
    ods_code    TEXT,                       -- NHS Organisation Data Service code (optional)
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_hospitals PRIMARY KEY (id)
);
COMMENT ON TABLE hospitals IS 'Tenant boundary. hospital_id scopes all need-to-know access (Caldicott §3).';

-- Maps an authenticated Supabase user to their hospital. Drives auth.current_hospital_id().
CREATE TABLE IF NOT EXISTS hospital_staff (
    user_id     UUID         NOT NULL,                       -- references auth.users(id)
    hospital_id UUID         NOT NULL,
    role        TEXT         NOT NULL DEFAULT 'clinician',
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_hospital_staff PRIMARY KEY (user_id),
    CONSTRAINT fk_staff_hospital FOREIGN KEY (hospital_id) REFERENCES hospitals(id) ON DELETE CASCADE
);
COMMENT ON TABLE hospital_staff IS 'auth user -> hospital membership. Source of truth for auth.current_hospital_id() when no JWT claim is present.';

-- The clinical waitlist. This is the ONE PII-bearing table; the patient-facing
-- layer never touches it directly (it only ever sees a PII-free UUID token).
CREATE TABLE IF NOT EXISTS waitlist_entries (
    id            UUID            NOT NULL DEFAULT gen_random_uuid(),
    hospital_id   UUID            NOT NULL,
    patient_name  TEXT,                                       -- PII (special category by context)
    patient_phone TEXT,                                       -- PII — used only to populate the SMS queue
    nhs_number    TEXT,                                       -- PII — validate via is_valid_nhs_number() at ingest (migration 20260529050000)
    procedure     TEXT,
    status        waitlist_status NOT NULL DEFAULT 'WAITING',
    created_at    TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_waitlist_entries PRIMARY KEY (id),
    CONSTRAINT fk_entry_hospital   FOREIGN KEY (hospital_id) REFERENCES hospitals(id) ON DELETE CASCADE
);
COMMENT ON TABLE waitlist_entries IS 'Clinical waitlist (PII-bearing, upstream). Patient-facing layer reaches it only via a single-use UUID token + SECURITY DEFINER RPC.';

-- Outbound SMS queue. Drained by the sms-dispatch-worker edge function via
-- get_next_sms_batch(). payload_link holds the PII-free ?t= validation link.
CREATE TABLE IF NOT EXISTS sms_dispatch_jobs (
    id                UUID           NOT NULL DEFAULT gen_random_uuid(),
    waitlist_entry_id UUID           NOT NULL,
    patient_phone     TEXT           NOT NULL,
    payload_link      TEXT           NOT NULL,
    status            sms_job_status NOT NULL DEFAULT 'pending',
    retry_count       INTEGER        NOT NULL DEFAULT 0,
    locked_at         TIMESTAMPTZ,                            -- NULL = not currently claimed
    last_error        TEXT,
    created_at        TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_sms_dispatch_jobs PRIMARY KEY (id),
    CONSTRAINT fk_job_waitlist      FOREIGN KEY (waitlist_entry_id) REFERENCES waitlist_entries(id) ON DELETE CASCADE
);
COMMENT ON TABLE sms_dispatch_jobs IS 'Outbound SMS queue. job.id doubles as the GOV.UK Notify idempotency reference; payload_link is PII-free.';

-- ── 3. INDEXES ──────────────────────────────────────────────────────────────--

CREATE INDEX IF NOT EXISTS idx_waitlist_entries_hospital ON waitlist_entries(hospital_id);
CREATE INDEX IF NOT EXISTS idx_waitlist_entries_status   ON waitlist_entries(status);
CREATE INDEX IF NOT EXISTS idx_sms_jobs_hospital_link    ON sms_dispatch_jobs(waitlist_entry_id);
-- Hot path for the batch claim: find the oldest claimable 'pending' jobs fast.
CREATE INDEX IF NOT EXISTS idx_sms_jobs_claimable
    ON sms_dispatch_jobs(created_at)
    WHERE status = 'pending';

-- ── 4. NEED-TO-KNOW SCOPE: auth.current_hospital_id() ─────────────────────────
-- Returns the caller's hospital. Resolution order:
--   1. JWT app_metadata.hospital_id claim   (set when minting staff tokens)
--   2. top-level hospital_id claim
--   3. hospital_staff mapping table (by auth.uid())
-- SECURITY DEFINER so it can read hospital_staff regardless of that table's RLS
-- (avoids policy recursion). STABLE: same result within a statement.
CREATE OR REPLACE FUNCTION auth.current_hospital_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
    SELECT COALESCE(
        NULLIF(current_setting('request.jwt.claims', true)::jsonb #>> '{app_metadata,hospital_id}', '')::uuid,
        NULLIF(current_setting('request.jwt.claims', true)::jsonb ->> 'hospital_id', '')::uuid,
        (SELECT hospital_id FROM public.hospital_staff WHERE user_id = auth.uid())
    );
$$;
COMMENT ON FUNCTION auth.current_hospital_id() IS
    'Resolves the caller''s hospital_id (JWT app_metadata claim, then top-level claim, then hospital_staff). Need-to-know boundary for all RLS.';

-- ── 5. ROW LEVEL SECURITY ─────────────────────────────────────────────────────
-- FORCE is set on waitlist_entries so that the postgres-role SECURITY DEFINER
-- functions (submit_validation_response, issue_validation_token, erase_patient_
-- validation_data) are subject to the explicit postgres-role policies that later
-- migrations create. Without FORCE, the postgres owner bypasses RLS entirely and
-- the clinical-safety WITH CHECK (status = 'PENDING_CANCELLATION') in migration
-- 20260529000000 would never be enforced. ENABLE-only is sufficient for the other
-- tables (sms_dispatch_jobs is drained by service_role which bypasses RLS anyway).

ALTER TABLE hospitals         ENABLE ROW LEVEL SECURITY;
ALTER TABLE hospital_staff    ENABLE ROW LEVEL SECURITY;
ALTER TABLE waitlist_entries  ENABLE ROW LEVEL SECURITY;
ALTER TABLE waitlist_entries  FORCE ROW LEVEL SECURITY;
ALTER TABLE sms_dispatch_jobs ENABLE ROW LEVEL SECURITY;

-- Staff may see their own membership row.
DROP POLICY IF EXISTS pol_staff_select_self ON hospital_staff;
CREATE POLICY pol_staff_select_self
    ON hospital_staff FOR SELECT TO authenticated
    USING (user_id = auth.uid());

-- Staff may see their own hospital.
DROP POLICY IF EXISTS pol_hospitals_select ON hospitals;
CREATE POLICY pol_hospitals_select
    ON hospitals FOR SELECT TO authenticated
    USING (id = auth.current_hospital_id());

-- Staff may read waitlist entries for their own hospital (need-to-know).
DROP POLICY IF EXISTS pol_entries_select ON waitlist_entries;
CREATE POLICY pol_entries_select
    ON waitlist_entries FOR SELECT TO authenticated
    USING (hospital_id = auth.current_hospital_id());

-- SECURITY DEFINER functions (issue_validation_token, erase_patient_validation_data)
-- SELECT from waitlist_entries to resolve hospital_id. With FORCE RLS they run as
-- postgres and need an explicit SELECT policy; the need-to-know check is enforced
-- inside each function, not here.
DROP POLICY IF EXISTS pol_entries_select_definer ON waitlist_entries;
CREATE POLICY pol_entries_select_definer
    ON waitlist_entries FOR SELECT TO postgres
    USING (true);

-- Staff may read SMS jobs for their own hospital (dispatch dashboard).
DROP POLICY IF EXISTS pol_sms_jobs_select ON sms_dispatch_jobs;
CREATE POLICY pol_sms_jobs_select
    ON sms_dispatch_jobs FOR SELECT TO authenticated
    USING (waitlist_entry_id IN (
        SELECT id FROM waitlist_entries WHERE hospital_id = auth.current_hospital_id()
    ));

-- ── 6. UPDATED_AT TRIGGER ─────────────────────────────────────────────────────
-- Keeps waitlist_entries.updated_at in sync automatically on every UPDATE.
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_waitlist_entries_updated_at ON waitlist_entries;
CREATE TRIGGER trg_waitlist_entries_updated_at
    BEFORE UPDATE ON waitlist_entries
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ── 7. BATCH CLAIM: get_next_sms_batch(batch_size) ────────────────────────────
-- Atomically claims up to batch_size pending jobs (FOR UPDATE SKIP LOCKED so
-- concurrent workers never grab the same row), marks them 'processing' + stamps
-- locked_at, and returns the fields the worker needs. Also reclaims jobs stuck in
-- 'processing' for >15 min (worker crash recovery). SECURITY DEFINER; the worker
-- calls it with the service_role key.
CREATE OR REPLACE FUNCTION get_next_sms_batch(batch_size INTEGER DEFAULT 100)
RETURNS TABLE (
    id            UUID,
    patient_phone TEXT,
    payload_link  TEXT,
    retry_count   INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    UPDATE sms_dispatch_jobs j
       SET status = 'processing',
           locked_at = NOW()
     WHERE j.id IN (
         SELECT s.id
           FROM sms_dispatch_jobs s
          WHERE s.status = 'pending'
             OR (s.status = 'processing' AND s.locked_at < NOW() - INTERVAL '15 minutes')
          ORDER BY s.created_at
          FOR UPDATE SKIP LOCKED
          LIMIT GREATEST(COALESCE(batch_size, 100), 0)
     )
    RETURNING j.id, j.patient_phone, j.payload_link, j.retry_count;
END;
$$;
COMMENT ON FUNCTION get_next_sms_batch(INTEGER) IS
    'Atomically claims a batch of pending (or stale-locked) SMS jobs, marks them processing, and returns them for dispatch. Run by the worker as service_role.';

-- ── 7. ENTITLEMENTS ───────────────────────────────────────────────────────────
-- Only the background worker (service_role) drains the queue; never anon/authenticated.
REVOKE EXECUTE ON FUNCTION get_next_sms_batch(INTEGER) FROM PUBLIC;
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
        EXECUTE 'GRANT EXECUTE ON FUNCTION get_next_sms_batch(INTEGER) TO service_role';
    END IF;
END;
$$;
