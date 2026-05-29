-- =============================================================================
-- TOKEN-LINK GENERATOR — issue_validation_token()
-- =============================================================================
-- Issues a single-use validation token for a waitlist entry and returns the
-- canonical, data-minimised patient link (?t=<uuid>). Used by admin tooling /
-- the dispatch pipeline to populate sms_dispatch_jobs.payload_link.
--
-- SECURITY:
--   • SECURITY DEFINER (writes waitlist_tokens under the definer policy) with a
--     pinned search_path.
--   • Need-to-know scoped: an authenticated admin may only issue tokens for
--     entries within their own hospital_id (Caldicott §3). Enforced in-function
--     because SECURITY DEFINER bypasses RLS.
--   • The link contains ONLY a random UUID — zero PII (UK GDPR data minimisation).
--   • anon is NEVER granted execute; only `authenticated`.
-- Idempotent (CREATE OR REPLACE).
-- =============================================================================

CREATE OR REPLACE FUNCTION issue_validation_token(
    p_waitlist_entry_id UUID,
    p_base_url          TEXT,
    p_ttl               INTERVAL DEFAULT INTERVAL '7 days'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_hospital_id UUID;
    v_caller_hosp UUID;
    v_token       UUID;
    v_expires     TIMESTAMPTZ;
    v_base        TEXT;
    v_sep         TEXT;
BEGIN
    -- Validate the entry exists and resolve its hospital.
    SELECT hospital_id INTO v_hospital_id
      FROM waitlist_entries WHERE id = p_waitlist_entry_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'WAITLIST_ENTRY_NOT_FOUND' USING ERRCODE = 'P0002';
    END IF;

    -- Need-to-know: caller's hospital must match the entry's hospital.
    v_caller_hosp := auth.current_hospital_id();
    IF v_caller_hosp IS NULL OR v_caller_hosp <> v_hospital_id THEN
        RAISE EXCEPTION 'NOT_AUTHORISED_FOR_THIS_HOSPITAL' USING ERRCODE = 'P0001';
    END IF;

    -- Basic guard on the base URL (must be https, no query/fragment injection).
    IF p_base_url IS NULL OR p_base_url !~ '^https://[A-Za-z0-9.\-/]+$' THEN
        RAISE EXCEPTION 'INVALID_BASE_URL' USING ERRCODE = 'P0001';
    END IF;

    v_expires := NOW() + COALESCE(p_ttl, INTERVAL '7 days');

    INSERT INTO waitlist_tokens (waitlist_entry_id, expires_at)
    VALUES (p_waitlist_entry_id, v_expires)
    RETURNING token INTO v_token;

    -- Build "<base>?t=<token>" (or "&t=" if the base already has a query string).
    v_base := rtrim(p_base_url, '/');
    v_sep  := CASE WHEN position('?' IN v_base) > 0 THEN '&' ELSE '?' END;

    RETURN jsonb_build_object(
        'token',      v_token,
        'expires_at', v_expires,
        'link',       v_base || v_sep || 't=' || v_token::text
    );
END;
$$;

COMMENT ON FUNCTION issue_validation_token(UUID, TEXT, INTERVAL) IS
    'Issues a single-use, PII-free validation token and returns the ?t= link. '
    'Scoped to the caller''s hospital_id. authenticated-only; never anon.';

REVOKE EXECUTE ON FUNCTION issue_validation_token(UUID, TEXT, INTERVAL) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION issue_validation_token(UUID, TEXT, INTERVAL) TO authenticated;
