-- =============================================================================
-- PROXY ACCESS SCAFFOLD — verified, consented, time-bounded (§10, Caldicott §3)
-- =============================================================================
-- The portal has a MOCK "Proxy view" toggle (caring for a dependent) that fetches
-- no one else's data. This migration builds the SERVER-SIDE foundation for REAL
-- proxy access — the data model + RLS — so that "proxy" can never be a client-
-- asserted claim. It deliberately does NOT enable any proxy relationship by data:
-- the table ships empty, and rows can only be created by an admin SECURITY DEFINER
-- function, never by a patient.
--
-- WHY proxy access is high-risk (and why this is conservative):
--   Letting account A read account B's health record is exactly the kind of
--   authorisation that, done loosely, becomes an IDOR / confidentiality breach.
--   So every read is gated on a relationship row that must be ALL of:
--     • active (not revoked), • consented, • within its valid-from/until window.
--   Anything missing → no access (fail-closed). The patient self-read policy is
--   untouched; this only ADDS a tightly-scoped third path.
--
-- 🚫👤 NOT closable in code (must precede any real use):
--   • Caldicott-approved CONSENT capture + identity verification of BOTH parties
--     (e.g. parental responsibility for a child, a registered carer). This table
--     RECORDS that a decision was made + by whom; it does not MAKE the decision.
--   • For under-16s / Gillick competence and for adults lacking capacity, the
--     lawful basis + safeguarding review are governance, not SQL.
--   • An admin UI to grant/revoke (the grant/revoke RPCs are here; the UI + real
--     staff auth are the follow-on, shared with the §1 staff-tooling gap).
--
-- DEPENDENCIES: runs AFTER 20260527000000_base_schema.sql and
-- 20260529070000_patient_portal_rls.sql. Idempotent. Target: PostgreSQL 15.
-- =============================================================================

-- ── 1. RELATIONSHIP TABLE ─────────────────────────────────────────────────────
-- One row = "proxy_user_id may act for subject_user_id" under recorded consent.
CREATE TABLE IF NOT EXISTS patient_proxies (
    id               UUID         NOT NULL DEFAULT gen_random_uuid(),
    subject_user_id  UUID         NOT NULL,   -- the patient whose data is viewed (auth.users.id)
    proxy_user_id    UUID         NOT NULL,   -- the person granted access      (auth.users.id)
    relationship     TEXT         NOT NULL,   -- e.g. 'parent', 'carer', 'lasting_power_of_attorney'
    consent_status   TEXT         NOT NULL DEFAULT 'PENDING',
    valid_from       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    valid_until      TIMESTAMPTZ,             -- NULL = open-ended (review still required)
    granted_by       UUID,                    -- staff auth.uid() who recorded the grant
    revoked_at       TIMESTAMPTZ,             -- non-NULL = revoked (kept for audit, not deleted)
    note             TEXT,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_patient_proxies PRIMARY KEY (id),
    CONSTRAINT chk_proxy_consent CHECK (consent_status IN ('PENDING', 'GRANTED', 'REVOKED')),
    CONSTRAINT chk_proxy_not_self CHECK (proxy_user_id <> subject_user_id),
    CONSTRAINT chk_proxy_window CHECK (valid_until IS NULL OR valid_until > valid_from),
    CONSTRAINT uq_proxy_pair UNIQUE (subject_user_id, proxy_user_id)
);
COMMENT ON TABLE patient_proxies IS
    'Verified proxy relationships (caring for a dependent). A row grants proxy_user_id read access to '
    'subject_user_id''s waitlist data ONLY while consent_status=GRANTED, not revoked, and within the '
    'validity window. Consent/identity verification is a Caldicott governance step recorded here, not made here.';

CREATE INDEX IF NOT EXISTS idx_patient_proxies_proxy   ON patient_proxies(proxy_user_id);
CREATE INDEX IF NOT EXISTS idx_patient_proxies_subject ON patient_proxies(subject_user_id);


-- ── 2. The single source of truth: is (proxy, subject) currently authorised? ──
-- STABLE helper used by both the RLS policy and any app check. Fail-closed.
CREATE OR REPLACE FUNCTION auth.has_proxy_access(p_subject UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM patient_proxies pp
         WHERE pp.proxy_user_id   = auth.uid()
           AND pp.subject_user_id = p_subject
           AND pp.consent_status  = 'GRANTED'
           AND pp.revoked_at IS NULL
           AND pp.valid_from <= NOW()
           AND (pp.valid_until IS NULL OR pp.valid_until > NOW())
    );
$$;
COMMENT ON FUNCTION auth.has_proxy_access(UUID) IS
    'TRUE iff the current user is a currently-authorised proxy for p_subject (GRANTED, not revoked, in window). Fail-closed.';


-- ── 3. RLS ─────────────────────────────────────────────────────────────────--
ALTER TABLE patient_proxies ENABLE ROW LEVEL SECURITY;
ALTER TABLE patient_proxies FORCE  ROW LEVEL SECURITY;

-- A user may SEE relationships where they are the subject or the proxy (transparency:
-- a patient can see who has access to them). No INSERT/UPDATE/DELETE policy for
-- normal users → relationships are managed ONLY by the definer RPCs below.
DROP POLICY IF EXISTS pol_proxies_party_select ON patient_proxies;
CREATE POLICY pol_proxies_party_select
    ON patient_proxies FOR SELECT TO authenticated
    USING (subject_user_id = auth.uid() OR proxy_user_id = auth.uid());

-- Definer write policy (grant/revoke RPCs run as postgres).
DROP POLICY IF EXISTS pol_proxies_write_definer ON patient_proxies;
CREATE POLICY pol_proxies_write_definer
    ON patient_proxies FOR ALL TO postgres
    USING (true) WITH CHECK (true);

-- THE PROXY READ PATH on waitlist_entries: a third permissive SELECT policy.
-- OR-combines with pol_entries_patient_select (own data) and pol_entries_admin_select
-- (staff). A proxy sees the subject's rows ONLY while auth.has_proxy_access() holds.
DROP POLICY IF EXISTS pol_entries_proxy_select ON waitlist_entries;
CREATE POLICY pol_entries_proxy_select
    ON waitlist_entries FOR SELECT TO authenticated
    USING (patient_user_id IS NOT NULL AND auth.has_proxy_access(patient_user_id));
COMMENT ON POLICY pol_entries_proxy_select ON waitlist_entries IS
    'Verified proxy read: a row is visible to a currently-authorised proxy of its patient_user_id. Fail-closed via auth.has_proxy_access().';


-- ── 4. Admin grant / revoke RPCs (consent recorded out-of-band) ──────────────
-- 🚫👤 These are the MECHANISM. The CONSENT + identity verification that justifies a
-- grant is a Caldicott governance step performed BEFORE calling grant_proxy_access.
-- STAFF-ONLY: granting access to one person over another's record is a staff action,
-- so grant_proxy_access requires the caller to carry the 'hospital_id' JWT claim (the
-- same signal the admin RLS uses — patients do NOT carry it). Without that gate, any
-- authenticated user could grant THEMSELVES access to another person's record by
-- passing p_proxy = their own uid. The gate closes that. (When real staff roles exist
-- — the §1 staff-auth follow-on — tighten further to an explicit role check.)
-- proxy<>subject is also enforced, and every grant is attributed to granted_by.
CREATE OR REPLACE FUNCTION grant_proxy_access(
    p_subject       UUID,
    p_proxy         UUID,
    p_relationship  TEXT,
    p_valid_until   TIMESTAMPTZ DEFAULT NULL,
    p_note          TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_actor UUID;
    v_id    UUID;
BEGIN
    v_actor := auth.uid();
    IF v_actor IS NULL THEN
        RAISE EXCEPTION 'NOT_AUTHENTICATED' USING ERRCODE = 'P0001';
    END IF;
    -- STAFF-ONLY gate: caller must carry the 'hospital_id' JWT claim. This prevents a
    -- patient from self-granting access to another person's record. (Fail-closed: no
    -- claim → not authorised.) Tighten to an explicit staff-role check once roles exist.
    IF auth.current_hospital_id() IS NULL THEN
        RAISE EXCEPTION 'NOT_AUTHORISED_TO_GRANT_PROXY' USING ERRCODE = 'P0001';
    END IF;
    IF p_subject IS NULL OR p_proxy IS NULL OR p_subject = p_proxy THEN
        RAISE EXCEPTION 'INVALID_PROXY_PAIR' USING ERRCODE = 'P0001';
    END IF;
    IF COALESCE(btrim(p_relationship), '') = '' THEN
        RAISE EXCEPTION 'RELATIONSHIP_REQUIRED' USING ERRCODE = 'P0001';
    END IF;

    -- Upsert the pair to GRANTED (re-granting a revoked pair re-activates it + audits).
    INSERT INTO patient_proxies
        (subject_user_id, proxy_user_id, relationship, consent_status, valid_until, granted_by, revoked_at, note)
    VALUES
        (p_subject, p_proxy, p_relationship, 'GRANTED', p_valid_until, v_actor, NULL, p_note)
    ON CONFLICT (subject_user_id, proxy_user_id) DO UPDATE
        SET consent_status = 'GRANTED',
            relationship   = EXCLUDED.relationship,
            valid_until    = EXCLUDED.valid_until,
            granted_by     = v_actor,
            revoked_at     = NULL,
            note           = EXCLUDED.note
    RETURNING id INTO v_id;

    RETURN jsonb_build_object('status', 'ok', 'proxy_id', v_id, 'consent_status', 'GRANTED');
END;
$$;
COMMENT ON FUNCTION grant_proxy_access(UUID, UUID, TEXT, TIMESTAMPTZ, TEXT) IS
    'Records a GRANTED proxy relationship (consent/identity verified out-of-band, Caldicott). STAFF-ONLY '
    '(requires the hospital_id JWT claim); proxy<>subject enforced; grant attributed to granted_by=auth.uid().';

CREATE OR REPLACE FUNCTION revoke_proxy_access(p_subject UUID, p_proxy UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_actor UUID;
    v_n     INTEGER;
BEGIN
    v_actor := auth.uid();
    IF v_actor IS NULL THEN
        RAISE EXCEPTION 'NOT_AUTHENTICATED' USING ERRCODE = 'P0001';
    END IF;

    -- Authorisation (revoking only REMOVES access — safety-positive — but still scoped):
    -- allowed if the caller is the SUBJECT (revoking access to their own record), the
    -- PROXY themselves (declining the access), or staff (carry the hospital_id claim).
    IF NOT (
        v_actor = p_subject
        OR v_actor = p_proxy
        OR auth.current_hospital_id() IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'NOT_AUTHORISED_TO_REVOKE_PROXY' USING ERRCODE = 'P0001';
    END IF;

    UPDATE patient_proxies
       SET consent_status = 'REVOKED', revoked_at = NOW()
     WHERE subject_user_id = p_subject
       AND proxy_user_id   = p_proxy
       AND revoked_at IS NULL;
    GET DIAGNOSTICS v_n = ROW_COUNT;

    RETURN jsonb_build_object('status', 'ok', 'revoked', v_n);
END;
$$;
COMMENT ON FUNCTION revoke_proxy_access(UUID, UUID) IS
    'Revokes a proxy relationship (sets REVOKED + revoked_at). Kept for audit, not deleted. authenticated-only.';


-- ── 5. Entitlements ──────────────────────────────────────────────────────────
REVOKE EXECUTE ON FUNCTION grant_proxy_access(UUID, UUID, TEXT, TIMESTAMPTZ, TEXT) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION grant_proxy_access(UUID, UUID, TEXT, TIMESTAMPTZ, TEXT) TO authenticated;
REVOKE EXECUTE ON FUNCTION revoke_proxy_access(UUID, UUID) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION revoke_proxy_access(UUID, UUID) TO authenticated;
-- has_proxy_access is used by RLS; expose to authenticated for app-side checks too.
REVOKE EXECUTE ON FUNCTION auth.has_proxy_access(UUID) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION auth.has_proxy_access(UUID) TO authenticated;
