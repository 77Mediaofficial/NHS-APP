-- =============================================================================
-- SECTION 11: SINGLE-USE TOKENS & SECURE RPC (FULLY HARDENED & IDEMPOTENT)
-- =============================================================================
-- Architecture Note: This file relies on explicit permissive RLS policies
-- targeted at the 'postgres' role. If this function's ownership is altered
-- (e.g., ALTER FUNCTION ... OWNER TO least_priv_role), these policies must
-- be updated in tandem to match the new definer security context.
--
-- CLINICAL-SAFETY UPSTREAM DEPENDENCY (DCB0129/0160): a patient response NEVER
-- hard-cancels a waitlist entry. The destructive path moves the entry into the
-- REVERSIBLE soft-state 'PENDING_CANCELLATION', which a clinician reviews and
-- confirms out-of-band. Before applying this migration, ensure the upstream
-- waitlist_entries.status domain (enum or CHECK constraint) permits the value
-- 'PENDING_CANCELLATION'. The hard 'CANCELLED' transition is now owned by the
-- clinical-review workflow, not by an unauthenticated single tap.
-- =============================================================================

-- ── 1. DATA LAYER: TOKENS & RESPONSES ────────────────────────────────────────

CREATE TABLE IF NOT EXISTS waitlist_tokens (
    token               UUID            NOT NULL DEFAULT gen_random_uuid(),
    waitlist_entry_id   UUID            NOT NULL,
    expires_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW() + INTERVAL '7 days',
    used_at             TIMESTAMPTZ,    -- NULL means active/unused
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_waitlist_tokens PRIMARY KEY (token),
    CONSTRAINT fk_token_waitlist  FOREIGN KEY (waitlist_entry_id) REFERENCES waitlist_entries(id) ON DELETE CASCADE
);

COMMENT ON TABLE waitlist_tokens IS 'Cryptographic, single-use URL tokens for unauthenticated patient access.';

CREATE TABLE IF NOT EXISTS validation_responses (
    id                  UUID            NOT NULL DEFAULT gen_random_uuid(),
    waitlist_entry_id   UUID            NOT NULL,
    response_type       TEXT            NOT NULL,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_validation_responses PRIMARY KEY (id),
    CONSTRAINT fk_validation_waitlist  FOREIGN KEY (waitlist_entry_id) REFERENCES waitlist_entries(id) ON DELETE CASCADE,
    CONSTRAINT chk_response_type       CHECK (response_type IN ('STILL_WAITING', 'SYMPTOMS_WORSENED', 'NO_LONGER_NEEDED'))
);

COMMENT ON TABLE validation_responses IS 'Immutable record of patient submissions via the secure RPC.';


-- ── 2. PERFORMANCE OPTIMIZATION INDEXES ──────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_waitlist_tokens_entry_id
    ON waitlist_tokens(waitlist_entry_id);

CREATE INDEX IF NOT EXISTS idx_validation_responses_entry_id
    ON validation_responses(waitlist_entry_id);


-- ── 3. ROW LEVEL SECURITY HARDENING & DEFINE POLICIES ────────────────────────

ALTER TABLE waitlist_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE waitlist_tokens FORCE ROW LEVEL SECURITY;

ALTER TABLE validation_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE validation_responses FORCE ROW LEVEL SECURITY;

-- Admin Read Policies
DROP POLICY IF EXISTS pol_tokens_select ON waitlist_tokens;
CREATE POLICY pol_tokens_select
    ON waitlist_tokens FOR SELECT TO authenticated
    USING (waitlist_entry_id IN (
        SELECT id FROM waitlist_entries WHERE hospital_id = auth.current_hospital_id()
    ));

DROP POLICY IF EXISTS pol_validation_select ON validation_responses;
CREATE POLICY pol_validation_select
    ON validation_responses FOR SELECT TO authenticated
    USING (waitlist_entry_id IN (
        SELECT id FROM waitlist_entries WHERE hospital_id = auth.current_hospital_id()
    ));

-- Definer Write Policies (Bypasses implicit reliance on administrative superuser attributes)
DROP POLICY IF EXISTS pol_tokens_update_definer ON waitlist_tokens;
CREATE POLICY pol_tokens_update_definer
    ON waitlist_tokens FOR UPDATE TO postgres
    USING (true);

DROP POLICY IF EXISTS pol_validation_insert_definer ON validation_responses;
CREATE POLICY pol_validation_insert_definer
    ON validation_responses FOR INSERT TO postgres
    WITH CHECK (true);

-- Explicit permission allowing the Security Definer to flag entries for clinical review.
-- CLINICAL-SAFETY (DCB0129/0160): a patient response may ONLY move an entry into the
-- reversible 'PENDING_CANCELLATION' soft-state. WITH CHECK strictly isolates the write
-- to that single value, so this code path can never hard-cancel a patient.
DROP POLICY IF EXISTS pol_entries_update_definer ON waitlist_entries;
CREATE POLICY pol_entries_update_definer
    ON waitlist_entries FOR UPDATE TO postgres
    USING (true)
    WITH CHECK (status = 'PENDING_CANCELLATION');


-- ── 4. SECURITY DEFINER EXECUTION LAYER ──────────────────────────────────────

CREATE OR REPLACE FUNCTION submit_validation_response(
    p_token UUID,
    p_response_type TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_waitlist_entry_id UUID;
    v_response_id UUID;
BEGIN
    -- [CONCURRENCY SAFE]: Atomic evaluation and invalidation state change
    UPDATE waitlist_tokens
    SET used_at = NOW()
    WHERE token = p_token
      AND used_at IS NULL
      AND expires_at > NOW()
    RETURNING waitlist_entry_id INTO v_waitlist_entry_id;

    -- [STABLE MACHINE CONTRACT]: Error string strictly maps to app.js error branch handling
    IF NOT FOUND THEN
        RAISE EXCEPTION 'INVALID_OR_EXPIRED_TOKEN' USING ERRCODE = 'P0001';
    END IF;

    -- Write directly to the validation ledger
    INSERT INTO validation_responses (waitlist_entry_id, response_type)
    VALUES (v_waitlist_entry_id, p_response_type)
    RETURNING id INTO v_response_id;

    -- CLINICAL-SAFETY (DCB0129/0160): a single patient tap must NEVER irreversibly remove
    -- them from a surgical waitlist. Instead of a hard 'CANCELLED', move the entry into the
    -- reversible 'PENDING_CANCELLATION' soft-state for MANDATORY clinical review. The
    -- frontend additionally gates this response behind an explicit confirmation step.
    -- Guard: only transition from an active state; never clobber an already-terminal status.
    IF p_response_type = 'NO_LONGER_NEEDED' THEN
        UPDATE waitlist_entries
        SET status = 'PENDING_CANCELLATION'
        WHERE id = v_waitlist_entry_id
          AND status NOT IN ('CANCELLED', 'PENDING_CANCELLATION');
    END IF;

    RETURN jsonb_build_object('status', 'success', 'response_id', v_response_id);
END;
$$;

-- ── 5. APPLICATION LAYER ENTITLEMENTS ────────────────────────────────────────

REVOKE EXECUTE ON FUNCTION submit_validation_response(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION submit_validation_response(UUID, TEXT) TO anon;
