-- =============================================================================
-- IDENTITY MATCHING — link a verified NHS Login patient to their waitlist row(s)
-- =============================================================================
-- Closes the §10 "identity-matching" dependency: `waitlist_entries.patient_user_id`
-- is NULL by default, so the portal (RLS: USING patient_user_id = auth.uid()) shows
-- a signed-in patient NOTHING until something links their auth identity to their
-- clinical record. This migration provides that link.
--
-- HOW THE MATCH WORKS (and why it is IDOR-safe by construction):
--   • NHS Login P9 (full identity verification) returns the patient's VERIFIED NHS
--     Number as a JWT claim. That number is the join key between "this authenticated
--     person" (auth.uid()) and "this clinical record" (waitlist_entries).
--   • `link_my_waitlist_record()` reads the caller's OWN verified NHS Number from the
--     request JWT (never a client-supplied parameter), validates it (modulus-11), and
--     sets patient_user_id = auth.uid() on matching rows that are NOT yet claimed.
--   • A caller can therefore only ever claim rows matching THEIR OWN verified number,
--     and only ever assign them to THEIR OWN uid. There is no parameter an attacker
--     could change to reach another patient's row. First-claim-wins (… IS NULL guard).
--   • Fail-closed: missing/invalid number, or identity not proven to P9 → 0 rows linked,
--     no error leaked.
--
-- DEPENDENCIES (apply order): runs AFTER
--   • 20260527000000_base_schema.sql        (waitlist_entries, patient_user_id, RLS)
--   • 20260529050000_nhs_number_modulus11.sql (is_valid_nhs_number)
--   • 20260529070000_patient_portal_rls.sql  (the patient SELECT policy this enables)
--
-- ⚠️ DATA PROTECTION (UK GDPR special-category / DPIA — see COMPLIANCE.md §2, §10):
--   This adds an NHS Number column to waitlist_entries. The NHS Number is PERSONAL,
--   special-category-adjacent data. It is:
--     • the clinical record's identifier (mirrors a real PAS waitlist row — expected),
--     • read-scoped to staff by the existing admin RLS (hospital_id), never anon,
--     • validated by a modulus-11 CHECK at the column,
--     • kept OUT of the patient-facing client query (portal/app.js selects explicit
--       non-PII columns only — data minimisation).
--   It MUST still be covered by the DPIA and the at-rest-encryption item (§2). Storing
--   it is a deliberate, documented increase in the data-protection surface.
--
-- 👤 INTEGRATION ASSUMPTIONS (confirm against the real NHS Login ↔ Supabase wiring;
--    cannot be verified in code alone):
--   • JWT claim name for the verified number is 'nhs_number'.
--   • JWT claim name for the identity-proofing level is 'identity_proofing_level',
--     and the value for full verification is 'P9'. Adjust REQUIRED_PROOFING / the
--     claim names below to match your OIDC mapping. Until they match, this fn fails
--     CLOSED (links nothing) — safe, but configure it correctly to enable matching.
--   • Best practice: run this linking server-side in a post-login / custom
--     access-token hook. Exposing it as an authenticated RPC (as here) is safe
--     because it only ever self-assigns the caller's own verified identity, but a
--     server-side hook removes the need for the client to call it at all.
-- Idempotent + safe to re-run. Target: PostgreSQL 15.
-- =============================================================================

-- ── 1. NHS Number on the clinical record (the match key) ─────────────────────
ALTER TABLE waitlist_entries
    ADD COLUMN IF NOT EXISTS nhs_number TEXT;

COMMENT ON COLUMN waitlist_entries.nhs_number IS
    'Patient NHS Number (PII). The Trust''s ingest/PAS populates this. Validated by '
    'modulus-11 CHECK; admin-RLS-scoped; never exposed to anon or to the patient client '
    'query. Used only to match a verified NHS Login identity to this row. DPIA scope.';

-- Modulus-11 CHECK at the column (no IF NOT EXISTS for ADD CONSTRAINT in PG → guard).
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_entries_nhs_number'
    ) THEN
        ALTER TABLE waitlist_entries
            ADD CONSTRAINT chk_entries_nhs_number
            CHECK (nhs_number IS NULL OR is_valid_nhs_number(nhs_number));
    END IF;
END;
$$;

-- Expression index on the normalised number (strip spaces/dashes) so the match
-- lookup below is sargable. Only index rows that actually carry a number.
CREATE INDEX IF NOT EXISTS idx_waitlist_entries_nhs_number_norm
    ON waitlist_entries ((regexp_replace(nhs_number, '[\s-]', '', 'g')))
    WHERE nhs_number IS NOT NULL;


-- ── 2. link_my_waitlist_record() — self-service identity match ───────────────
-- SECURITY DEFINER: bypasses RLS to set patient_user_id (there is intentionally no
-- patient UPDATE policy). Safe because it takes NO parameters and acts only on the
-- caller's own verified claim + own uid. authenticated-only.
CREATE OR REPLACE FUNCTION link_my_waitlist_record()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    -- 👤 Adjust to match the real NHS Login → Supabase claim mapping (see header).
    REQUIRED_PROOFING CONSTANT TEXT := 'P9';
    v_claims  JSONB;
    v_uid     UUID;
    v_nhs_raw TEXT;
    v_nhs     TEXT;
    v_proof   TEXT;
    v_linked  INTEGER := 0;
BEGIN
    v_uid := auth.uid();
    IF v_uid IS NULL THEN
        -- Not authenticated (defensive; GRANT already restricts to authenticated).
        RETURN jsonb_build_object('linked', 0, 'status', 'not_authenticated');
    END IF;

    v_claims  := NULLIF(current_setting('request.jwt.claims', true), '')::jsonb;
    v_nhs_raw := v_claims ->> 'nhs_number';
    v_proof   := v_claims ->> 'identity_proofing_level';

    -- Require full identity verification before trusting the number for matching.
    IF v_proof IS DISTINCT FROM REQUIRED_PROOFING THEN
        RETURN jsonb_build_object('linked', 0, 'status', 'identity_not_p9');
    END IF;

    -- Must have a syntactically valid (modulus-11) verified number.
    IF v_nhs_raw IS NULL OR NOT is_valid_nhs_number(v_nhs_raw) THEN
        RETURN jsonb_build_object('linked', 0, 'status', 'no_verified_nhs_number');
    END IF;

    v_nhs := regexp_replace(v_nhs_raw, '[\s-]', '', 'g');

    -- Claim ONLY this caller's own, not-yet-linked rows. First-claim-wins.
    -- `nhs_number IS NOT NULL` is logically implied (NULL never matches) but stated
    -- explicitly so the planner can use the partial expression index.
    UPDATE waitlist_entries
       SET patient_user_id = v_uid
     WHERE patient_user_id IS NULL
       AND nhs_number IS NOT NULL
       AND regexp_replace(nhs_number, '[\s-]', '', 'g') = v_nhs;

    GET DIAGNOSTICS v_linked = ROW_COUNT;

    RETURN jsonb_build_object('linked', v_linked, 'status', 'ok');
END;
$$;

COMMENT ON FUNCTION link_my_waitlist_record() IS
    'Links the caller''s VERIFIED NHS Login identity (auth.uid()) to their waitlist '
    'row(s) by matching the verified NHS Number JWT claim. Takes no parameters; only '
    'ever self-assigns the caller''s own unclaimed rows. IDOR-safe, fail-closed, '
    'first-claim-wins. authenticated-only.';

REVOKE EXECUTE ON FUNCTION link_my_waitlist_record() FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION link_my_waitlist_record() TO authenticated;
