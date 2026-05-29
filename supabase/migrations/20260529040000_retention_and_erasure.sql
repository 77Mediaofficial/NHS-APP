-- =============================================================================
-- DATA RETENTION & RIGHT TO ERASURE (UK GDPR / DPA 2018)
-- =============================================================================
-- Addresses COMPLIANCE.md §2:
--   • Retention schedule for tokens + responses, enforced by an auto-purge job.
--   • Right to erasure / rectification process for patient responses.
--
-- DESIGN / SAFETY NOTES:
--   • waitlist_tokens are single-use, PII-FREE (UUID + FK + timestamps). Spent or
--     long-expired tokens carry no clinical value, so purging them automatically
--     is low-risk and is scheduled below (if pg_cron is available).
--   • validation_responses record a patient's clinical decision. Their retention
--     period is an INFORMATION-GOVERNANCE / Caldicott decision, NOT a purely
--     technical one. We therefore provide a purge function but DO NOT schedule it
--     by default — the Trust must set the retention interval and own the schedule.
--   • All functions are SECURITY DEFINER with a pinned search_path. The erasure
--     function is scoped to the caller's hospital_id (need-to-know, Caldicott §3).
-- Idempotent + safe to re-run.
-- =============================================================================

-- ── 1. PURGE SPENT / EXPIRED TOKENS (safe to automate) ───────────────────────
-- Removes tokens that are used OR expired beyond a grace window. Returns the row
-- count so a scheduler / dashboard can record purge volumes.
CREATE OR REPLACE FUNCTION purge_expired_tokens(
    p_used_retention    INTERVAL DEFAULT INTERVAL '30 days',
    p_expired_grace     INTERVAL DEFAULT INTERVAL '7 days'
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_deleted INTEGER;
BEGIN
    DELETE FROM waitlist_tokens
     WHERE (used_at IS NOT NULL AND used_at < NOW() - p_used_retention)
        OR (expires_at < NOW() - p_expired_grace);
    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    RETURN v_deleted;
END;
$$;

COMMENT ON FUNCTION purge_expired_tokens(INTERVAL, INTERVAL) IS
    'Deletes spent/expired single-use tokens (PII-free). Safe to schedule. '
    'Returns number of rows purged.';

REVOKE EXECUTE ON FUNCTION purge_expired_tokens(INTERVAL, INTERVAL) FROM PUBLIC;
-- service_role runs the scheduled job; anon is never granted execute.
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
        EXECUTE 'GRANT EXECUTE ON FUNCTION purge_expired_tokens(INTERVAL, INTERVAL) TO service_role';
    END IF;
END;
$$;


-- ── 2. PURGE AGED VALIDATION RESPONSES (IG-gated — NOT auto-scheduled) ────────
-- Retention period MUST be set by the Trust's IG / Caldicott Guardian. Provided
-- as a callable function only; deliberately left unscheduled. No default that
-- silently destroys clinical records.
CREATE OR REPLACE FUNCTION purge_aged_validation_responses(
    p_retention INTERVAL
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_deleted INTEGER;
BEGIN
    IF p_retention IS NULL THEN
        RAISE EXCEPTION 'retention interval is required (set by IG/Caldicott policy)';
    END IF;
    DELETE FROM validation_responses
     WHERE created_at < NOW() - p_retention;
    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    RETURN v_deleted;
END;
$$;

COMMENT ON FUNCTION purge_aged_validation_responses(INTERVAL) IS
    'Deletes validation_responses older than the IG-defined retention interval. '
    'NOT scheduled by default — retention period requires Caldicott/IG sign-off.';

REVOKE EXECUTE ON FUNCTION purge_aged_validation_responses(INTERVAL) FROM PUBLIC;
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
        EXECUTE 'GRANT EXECUTE ON FUNCTION purge_aged_validation_responses(INTERVAL) TO service_role';
    END IF;
END;
$$;


-- ── 3. RIGHT TO ERASURE / RECTIFICATION (admin, need-to-know scoped) ──────────
-- Erases all patient-response artefacts for a single waitlist entry. Callable by
-- an authenticated admin, but ONLY for entries within their own hospital_id
-- (Caldicott need-to-know). SECURITY DEFINER bypasses RLS, so the hospital check
-- is enforced explicitly in-function. Returns a JSONB summary for the audit log.
CREATE OR REPLACE FUNCTION erase_patient_validation_data(
    p_waitlist_entry_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_hospital_id   UUID;
    v_caller_hosp   UUID;
    v_tokens_del    INTEGER := 0;
    v_resp_del      INTEGER := 0;
BEGIN
    -- Need-to-know: confirm the entry belongs to the caller's hospital.
    SELECT hospital_id INTO v_hospital_id
      FROM waitlist_entries WHERE id = p_waitlist_entry_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'WAITLIST_ENTRY_NOT_FOUND' USING ERRCODE = 'P0002';
    END IF;

    v_caller_hosp := auth.current_hospital_id();
    IF v_caller_hosp IS NULL OR v_caller_hosp <> v_hospital_id THEN
        RAISE EXCEPTION 'NOT_AUTHORISED_FOR_THIS_HOSPITAL' USING ERRCODE = 'P0001';
    END IF;

    DELETE FROM validation_responses WHERE waitlist_entry_id = p_waitlist_entry_id;
    GET DIAGNOSTICS v_resp_del = ROW_COUNT;

    DELETE FROM waitlist_tokens WHERE waitlist_entry_id = p_waitlist_entry_id;
    GET DIAGNOSTICS v_tokens_del = ROW_COUNT;

    RETURN jsonb_build_object(
        'status', 'erased',
        'waitlist_entry_id', p_waitlist_entry_id,
        'responses_deleted', v_resp_del,
        'tokens_deleted', v_tokens_del
    );
END;
$$;

COMMENT ON FUNCTION erase_patient_validation_data(UUID) IS
    'UK GDPR right-to-erasure: removes tokens + responses for one waitlist entry, '
    'scoped to the caller''s hospital_id. Returns an audit summary.';

REVOKE EXECUTE ON FUNCTION erase_patient_validation_data(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION erase_patient_validation_data(UUID) TO authenticated;


-- ── 4. SCHEDULE THE SAFE TOKEN PURGE (only if pg_cron is present) ─────────────
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
        -- Re-register idempotently: unschedule any prior job of the same name.
        PERFORM cron.unschedule('purge-expired-waitlist-tokens')
          WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'purge-expired-waitlist-tokens');
        PERFORM cron.schedule(
            'purge-expired-waitlist-tokens',
            '17 3 * * *',                          -- daily 03:17
            $cron$ SELECT public.purge_expired_tokens(); $cron$
        );
        RAISE NOTICE '[retention] scheduled daily token purge via pg_cron.';
    ELSE
        RAISE NOTICE '[retention] pg_cron not installed — token purge NOT scheduled. '
            'Enable pg_cron (or call purge_expired_tokens() from an external scheduler).';
    END IF;
END;
$$;
