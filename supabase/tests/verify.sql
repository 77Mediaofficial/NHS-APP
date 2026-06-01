-- =============================================================================
-- VERIFICATION HARNESS — runnable assertions for the safety-critical logic
-- =============================================================================
-- PURPOSE: turn "code-reviewed, not executed" into "executed + asserted". Run this
-- AFTER applying all 11 migrations (see DEPLOYMENT.md §3), in psql or the Supabase
-- SQL editor. Every check uses ASSERT — the script RAISES on the first failure, so
-- "completed with no exception, ROLLBACK done" == all assertions passed.
--
-- SAFETY: the whole thing runs inside one transaction and ROLLS BACK at the end, so
-- it leaves NO test data behind. It only writes to its own throwaway rows.
--
-- SCOPE — what this can and cannot prove in a plain SQL session:
--   ✓ CAN: table/constraint shape, the clinical-review state machine, the hash-chain
--     trigger + verify_audit_chain tamper detection, the NHS Number validator, the
--     proxy fail-closed predicate, function guard logic reachable as the table owner.
--   ✗ CANNOT here: the RLS POLICIES as experienced by the `authenticated`/`anon`
--     roles with a real JWT (auth.uid()/claims). Those need a live authenticated
--     session — they are covered by the post-deploy checks in DEPLOYMENT.md §6.
--     This file documents that boundary rather than pretending to cross it.
-- =============================================================================

BEGIN;
SET LOCAL client_min_messages = NOTICE;

DO $$
DECLARE
    v_hosp     UUID;
    v_other    UUID;
    v_entry    UUID;
    v_uid      UUID := gen_random_uuid();   -- a stand-in clinician/patient id
    v_res      JSONB;
    v_status   TEXT;
    v_chain    JSONB;
    v_count    INTEGER;
BEGIN
    RAISE NOTICE '--- 1. NHS Number modulus-11 validator ---';
    -- Known-valid test number (passes modulus-11). 9434765919 is a standard example.
    ASSERT is_valid_nhs_number('9434765919'),            'valid NHS number rejected';
    ASSERT is_valid_nhs_number('943 476 5919'),          'spaces should be stripped';
    ASSERT NOT is_valid_nhs_number('9434765918'),        'bad check digit accepted';
    ASSERT NOT is_valid_nhs_number('123'),               'too-short accepted';
    ASSERT NOT is_valid_nhs_number(NULL),                'NULL accepted';
    ASSERT NOT is_valid_nhs_number('abcdefghij'),        'non-numeric accepted';

    RAISE NOTICE '--- 2. Seed a hospital + entry (as table owner) ---';
    INSERT INTO hospitals (name) VALUES ('Test Trust Hospital') RETURNING id INTO v_hosp;
    INSERT INTO hospitals (name) VALUES ('Other Hospital')      RETURNING id INTO v_other;
    INSERT INTO waitlist_entries (hospital_id, procedure, status, nhs_number)
        VALUES (v_hosp, 'Test Procedure', 'ACTIVE', '9434765919')
        RETURNING id INTO v_entry;

    RAISE NOTICE '--- 3. NHS Number CHECK constraint on waitlist_entries ---';
    BEGIN
        INSERT INTO waitlist_entries (hospital_id, procedure, nhs_number)
            VALUES (v_hosp, 'Bad', '9434765918');         -- invalid check digit
        ASSERT false, 'CHECK should have rejected an invalid NHS number';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE '    ok: invalid NHS number rejected by CHECK';
    END;

    RAISE NOTICE '--- 4. status CHECK forbids arbitrary values ---';
    BEGIN
        UPDATE waitlist_entries SET status = 'BOGUS' WHERE id = v_entry;
        ASSERT false, 'status CHECK should forbid BOGUS';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE '    ok: bogus status rejected';
    END;

    RAISE NOTICE '--- 5. Clinical-review state machine (resolve_cancellation) ---';
    -- Move to PENDING_CANCELLATION (the only state resolve_cancellation acts on).
    UPDATE waitlist_entries SET status = 'PENDING_CANCELLATION' WHERE id = v_entry;
    -- resolve_cancellation reads auth.uid()/current_hospital_id(); in a plain session
    -- those are NULL, so it should fail CLOSED (NOT_AUTHENTICATED). That itself proves
    -- the guard ordering — it does not transition without an identity.
    BEGIN
        v_res := resolve_cancellation(v_entry, 'REINSTATE', 'test');
        ASSERT false, 'resolve_cancellation should fail closed without auth.uid()';
    EXCEPTION WHEN others THEN
        RAISE NOTICE '    ok: resolve_cancellation fails closed without identity (%).', SQLERRM;
    END;
    -- Entry must still be PENDING_CANCELLATION (no transition happened).
    SELECT status INTO v_status FROM waitlist_entries WHERE id = v_entry;
    ASSERT v_status = 'PENDING_CANCELLATION', 'entry changed despite failed resolve';

    RAISE NOTICE '--- 6. Audit hash chain (direct ledger insert + verify) ---';
    -- Insert two ledger rows directly (as owner) to exercise the BEFORE INSERT chain
    -- trigger, then verify the chain is intact, then tamper and confirm detection.
    INSERT INTO cancellation_reviews
        (waitlist_entry_id, hospital_id, decision, previous_status, new_status, reviewed_by, note)
    VALUES
        (v_entry, v_hosp, 'REINSTATE', 'PENDING_CANCELLATION', 'ACTIVE', v_uid, 'row 1'),
        (v_entry, v_hosp, 'CONFIRM_CANCELLATION', 'PENDING_CANCELLATION', 'CANCELLED', v_uid, 'row 2');

    SELECT count(*) INTO v_count FROM cancellation_reviews;
    ASSERT v_count = 2, 'expected 2 ledger rows';

    v_chain := verify_audit_chain('cancellation_reviews');
    RAISE NOTICE '    chain after inserts: %', v_chain;
    ASSERT (v_chain->>'intact')::boolean,        'fresh chain should be intact';
    ASSERT (v_chain->>'rows')::int = 2,          'verify_audit_chain row count wrong';

    -- Tamper: mutate a business column WITHOUT recomputing the hash. (Possible here
    -- only because we are the table owner — exactly the bypass-RLS threat the chain
    -- exists to DETECT.) The chain must now report broken.
    UPDATE cancellation_reviews SET note = 'TAMPERED' WHERE note = 'row 1';
    v_chain := verify_audit_chain('cancellation_reviews');
    RAISE NOTICE '    chain after tamper: %', v_chain;
    ASSERT NOT (v_chain->>'intact')::boolean,    'tamper not detected by hash chain!';
    ASSERT (v_chain->>'first_broken_seq') IS NOT NULL, 'no broken seq reported';

    RAISE NOTICE '--- 7. Proxy fail-closed predicate (auth.has_proxy_access) ---';
    -- With no patient_proxies rows and no auth.uid(), access must be FALSE.
    ASSERT NOT auth.has_proxy_access(v_uid), 'has_proxy_access should be false with no grant';
    -- A revoked / out-of-window grant must also read as no-access.
    INSERT INTO patient_proxies (subject_user_id, proxy_user_id, relationship, consent_status, valid_from, valid_until)
        VALUES (gen_random_uuid(), v_uid, 'carer', 'GRANTED', NOW() - INTERVAL '2 days', NOW() - INTERVAL '1 day');
    ASSERT NOT auth.has_proxy_access(v_uid), 'expired grant should not confer access';

    RAISE NOTICE '--- 8. Proxy self-grant structurally blocked ---';
    BEGIN
        INSERT INTO patient_proxies (subject_user_id, proxy_user_id, relationship, consent_status)
            VALUES (v_uid, v_uid, 'self', 'GRANTED');     -- proxy = subject
        ASSERT false, 'self-proxy should be rejected by CHECK';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE '    ok: proxy = subject rejected';
    END;

    RAISE NOTICE '====================================================';
    RAISE NOTICE 'ALL ASSERTIONS PASSED. (Transaction will ROLL BACK.)';
    RAISE NOTICE 'Note: RLS-as-a-role checks (authenticated/anon + JWT) are NOT';
    RAISE NOTICE 'covered here — see DEPLOYMENT.md §6 live post-deploy checks.';
    RAISE NOTICE '====================================================';
END;
$$;

ROLLBACK;
