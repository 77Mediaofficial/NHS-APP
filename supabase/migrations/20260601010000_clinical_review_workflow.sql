-- =============================================================================
-- CLINICAL-REVIEW WORKFLOW — resolve PENDING_CANCELLATION (DCB0129/0160)
-- =============================================================================
-- Closes the open §1 clinical hazard: a patient "I no longer need this" response
-- moves the entry into the REVERSIBLE soft-state 'PENDING_CANCELLATION' (see
-- 20260529000000_section_11_tokens_rpc.sql), but until now there was NO code path
-- for a clinician to RESOLVE that state. A slot could sit pending forever, or be
-- resolved only by ad-hoc manual SQL (no audit, no scoping). This migration adds
-- the safe, audited resolution mechanism.
--
-- THE STATE MACHINE (authoritative):
--     ACTIVE ──patient declines──▶ PENDING_CANCELLATION ──clinician──▶ CANCELLED   (CONFIRM_CANCELLATION)
--                                          │              └──────────▶ ACTIVE      (REINSTATE)
--                                          COMPLETED is terminal and untouched here.
--   Only a clinician (authenticated staff, scoped to the entry's hospital) may make
--   the PENDING_CANCELLATION ▶ CANCELLED|ACTIVE transition. The patient path can
--   STILL only ever write PENDING_CANCELLATION.
--
-- DEPENDENCIES (apply order): runs AFTER
--   • 20260527000000_base_schema.sql        (waitlist_entries, status CHECK, current_hospital_id)
--   • 20260529000000_section_11_tokens_rpc.sql (the PENDING_CANCELLATION soft-state + its definer policy)
--
-- 🚫👤 STILL REQUIRED OUTSIDE THIS FILE (cannot be closed in SQL alone):
--   • CSO sign-off + Hazard Log / Clinical Safety Case Report entry for this workflow.
--   • A staff-facing UI (or staff tooling) that lists PENDING_CANCELLATION entries and
--     calls resolve_cancellation(). That UI needs REAL staff authentication + the
--     'hospital_id' JWT claim (not built — the portal mocks even patient auth). This
--     migration deliberately ships the safety-critical MECHANISM; the human-facing
--     trigger is a documented follow-on. Until staff auth exists, resolution is
--     reachable only by authenticated staff tooling that carries the hospital claim.
-- Idempotent + safe to re-run. Target: PostgreSQL 15.
-- =============================================================================

-- ── 1. AUDIT LEDGER — who resolved what, when (append-only) ──────────────────
-- Tamper-evidence aim (§6): every resolution is recorded with the acting clinician
-- (auth.uid()), the before/after status, and an optional clinical note. There are
-- intentionally NO UPDATE/DELETE policies, so the app cannot rewrite history.
-- (True cryptographic tamper-evidence — e.g. hash chaining — is a later hardening;
-- this is an immutable-by-RLS ledger, documented honestly as such.)
CREATE TABLE IF NOT EXISTS cancellation_reviews (
    id                 UUID         NOT NULL DEFAULT gen_random_uuid(),
    waitlist_entry_id  UUID         NOT NULL,
    hospital_id        UUID         NOT NULL,
    decision           TEXT         NOT NULL,
    previous_status    TEXT         NOT NULL,
    new_status         TEXT         NOT NULL,
    reviewed_by        UUID         NOT NULL,
    note               TEXT,
    created_at         TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_cancellation_reviews PRIMARY KEY (id),
    CONSTRAINT fk_review_waitlist FOREIGN KEY (waitlist_entry_id)
        REFERENCES waitlist_entries(id) ON DELETE CASCADE,
    CONSTRAINT chk_review_decision CHECK (decision IN ('CONFIRM_CANCELLATION', 'REINSTATE')),
    CONSTRAINT chk_review_new_status CHECK (new_status IN ('CANCELLED', 'ACTIVE'))
);
COMMENT ON TABLE cancellation_reviews IS
    'Append-only audit of clinician resolutions of PENDING_CANCELLATION entries '
    '(DCB0129/0160). Health-adjacent: admin-RLS-scoped to hospital; never anon/patient.';

CREATE INDEX IF NOT EXISTS idx_cancellation_reviews_entry
    ON cancellation_reviews(waitlist_entry_id);
CREATE INDEX IF NOT EXISTS idx_cancellation_reviews_hospital
    ON cancellation_reviews(hospital_id);


-- ── 2. RLS on the ledger (forced; locked down) ───────────────────────────────
ALTER TABLE cancellation_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE cancellation_reviews FORCE  ROW LEVEL SECURITY;

-- Staff may read reviews for their own hospital (need-to-know, Caldicott §3).
DROP POLICY IF EXISTS pol_reviews_admin_select ON cancellation_reviews;
CREATE POLICY pol_reviews_admin_select
    ON cancellation_reviews FOR SELECT TO authenticated
    USING (hospital_id = auth.current_hospital_id());

-- Inserts happen ONLY via the SECURITY DEFINER RPC below (runs as postgres).
-- No UPDATE/DELETE policy at all → the ledger is immutable from the application.
DROP POLICY IF EXISTS pol_reviews_insert_definer ON cancellation_reviews;
CREATE POLICY pol_reviews_insert_definer
    ON cancellation_reviews FOR INSERT TO postgres
    WITH CHECK (true);


-- ── 3. Resolution UPDATE policy on waitlist_entries ──────────────────────────
-- The existing pol_entries_update_definer (section 11) is locked to
-- WITH CHECK (status = 'PENDING_CANCELLATION') — correct for the PATIENT path, but
-- it would BLOCK this clinician path from writing CANCELLED/ACTIVE. Postgres
-- combines multiple PERMISSIVE policies for the same role+command with OR, so this
-- ADDITIONAL policy widens what the definer role may write WITHOUT touching the
-- patient guarantee in code.
--
-- Combined effect for role `postgres` on UPDATE of waitlist_entries:
--   USING:      true OR (status = 'PENDING_CANCELLATION')           = any row (unchanged)
--   WITH CHECK: (status = 'PENDING_CANCELLATION')                   [patient path]
--               OR (status IN ('CANCELLED','ACTIVE'))               [this clinician path]
--             = the new status must be one of PENDING_CANCELLATION | CANCELLED | ACTIVE
--               (COMPLETED and arbitrary values remain forbidden at the RLS layer).
--
-- ⚠️ HONEST NOTE: this relaxes the RLS-layer guarantee from "definer can only write
-- PENDING_CANCELLATION" to the bounded set above. The patient path can STILL never
-- hard-cancel a patient, because (a) `anon` may EXECUTE only submit_validation_response
-- (never resolve_cancellation — see grants below), and (b) that function's code only
-- ever writes PENDING_CANCELLATION, guarded against clobbering terminal states. The
-- RLS WITH CHECK is defence-in-depth, not the sole control.
DROP POLICY IF EXISTS pol_entries_resolve_definer ON waitlist_entries;
CREATE POLICY pol_entries_resolve_definer
    ON waitlist_entries FOR UPDATE TO postgres
    USING (status = 'PENDING_CANCELLATION')
    WITH CHECK (status IN ('CANCELLED', 'ACTIVE'));


-- ── 4. resolve_cancellation() — the audited clinician transition ─────────────
-- SECURITY DEFINER (writes under the definer policies above) with a pinned
-- search_path. authenticated-only; need-to-know scoped to the caller's hospital.
CREATE OR REPLACE FUNCTION resolve_cancellation(
    p_entry_id  UUID,
    p_decision  TEXT,
    p_note      TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid         UUID;
    v_caller_hosp UUID;
    v_hospital_id UUID;
    v_status      TEXT;
    v_new_status  TEXT;
    v_review_id   UUID;
BEGIN
    v_uid := auth.uid();
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'NOT_AUTHENTICATED' USING ERRCODE = 'P0001';
    END IF;

    -- Validate the decision before any data access.
    IF p_decision NOT IN ('CONFIRM_CANCELLATION', 'REINSTATE') THEN
        RAISE EXCEPTION 'INVALID_DECISION' USING ERRCODE = 'P0001';
    END IF;

    -- Lock the entry and read its hospital + current status (race-safe: a second
    -- concurrent resolver or a late patient re-submit will serialise behind this).
    SELECT hospital_id, status
      INTO v_hospital_id, v_status
      FROM waitlist_entries
     WHERE id = p_entry_id
     FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'WAITLIST_ENTRY_NOT_FOUND' USING ERRCODE = 'P0002';
    END IF;

    -- Need-to-know: caller's hospital must match the entry's (Caldicott §3). Enforced
    -- in-function because SECURITY DEFINER bypasses the admin SELECT RLS.
    v_caller_hosp := auth.current_hospital_id();
    IF v_caller_hosp IS NULL OR v_caller_hosp <> v_hospital_id THEN
        RAISE EXCEPTION 'NOT_AUTHORISED_FOR_THIS_HOSPITAL' USING ERRCODE = 'P0001';
    END IF;

    -- Only entries awaiting review can be resolved. Idempotent-safe: a double-submit
    -- finds the status already changed and is rejected here rather than re-cancelling.
    IF v_status <> 'PENDING_CANCELLATION' THEN
        RAISE EXCEPTION 'ENTRY_NOT_PENDING_CANCELLATION (current: %)', v_status
            USING ERRCODE = 'P0001';
    END IF;

    v_new_status := CASE p_decision
        WHEN 'CONFIRM_CANCELLATION' THEN 'CANCELLED'
        WHEN 'REINSTATE'            THEN 'ACTIVE'
    END;

    UPDATE waitlist_entries
       SET status = v_new_status
     WHERE id = p_entry_id;

    -- Append the immutable audit row (who/what/when + before/after + optional note).
    INSERT INTO cancellation_reviews
        (waitlist_entry_id, hospital_id, decision, previous_status, new_status, reviewed_by, note)
    VALUES
        (p_entry_id, v_hospital_id, p_decision, 'PENDING_CANCELLATION', v_new_status, v_uid, p_note)
    RETURNING id INTO v_review_id;

    RETURN jsonb_build_object(
        'status',     'ok',
        'entry_id',   p_entry_id,
        'new_status', v_new_status,
        'review_id',  v_review_id
    );
END;
$$;

COMMENT ON FUNCTION resolve_cancellation(UUID, TEXT, TEXT) IS
    'Clinician resolution of a PENDING_CANCELLATION entry: CONFIRM_CANCELLATION→CANCELLED '
    'or REINSTATE→ACTIVE. Hospital-scoped, row-locked, audited in cancellation_reviews. '
    'authenticated-only; never anon. DCB0129/0160 reversible-soft-state resolution.';


-- ── 5. Entitlements ──────────────────────────────────────────────────────────
-- Staff only. anon (the patient path) is NEVER granted execute — it cannot reach
-- the hard-cancel transition.
REVOKE EXECUTE ON FUNCTION resolve_cancellation(UUID, TEXT, TEXT) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION resolve_cancellation(UUID, TEXT, TEXT) TO authenticated;
