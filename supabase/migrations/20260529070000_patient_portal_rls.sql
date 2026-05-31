-- =============================================================================
-- PATIENT PORTAL RLS — let a signed-in patient read ONLY their own entry
-- =============================================================================
-- Closes the Patient Hub's last code blocker (COMPLIANCE.md §10). The portal
-- (`portal/app.js`) runs `from('waitlist_entries').select(...)` under the patient's
-- own JWT and passes NO id — isolation MUST be enforced server-side by RLS. This
-- migration adds that policy: a patient sees a row only when its patient_user_id
-- equals their auth.uid().
--
-- DEPENDENCIES (apply order):
--   • 20260527000000_base_schema.sql defines waitlist_entries.patient_user_id (+ index).
--   • This file is dated after section-11 so the table + its other policies exist.
--
-- IDOR-safe by construction: the predicate is auth.uid() (from the verified JWT),
-- never a client-supplied value. Fail-closed: if patient_user_id IS NULL (not yet
-- identity-matched), the row is invisible.
--
-- STILL REQUIRED OUTSIDE THIS FILE (not closable in SQL alone):
--   (a) Real NHS Login OIDC wired into Supabase Auth (portal currently mocks it).
--   (b) An identity-matching step that sets waitlist_entries.patient_user_id from
--       the verified NHS Login subject. Until that runs, the portal stays empty.
-- Idempotent + safe to re-run.
-- =============================================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'public'
           AND table_name   = 'waitlist_entries'
           AND column_name  = 'patient_user_id'
    ) THEN
        RAISE EXCEPTION
            'waitlist_entries.patient_user_id is missing — apply 20260527000000_base_schema.sql first.';
    END IF;
END;
$$;

-- Patient self-read. RLS is already ENABLED+FORCED on waitlist_entries (base schema).
DROP POLICY IF EXISTS pol_entries_patient_select ON waitlist_entries;
CREATE POLICY pol_entries_patient_select
    ON waitlist_entries FOR SELECT TO authenticated
    USING (patient_user_id = auth.uid());

COMMENT ON POLICY pol_entries_patient_select ON waitlist_entries IS
    'Patient portal: a signed-in patient may read ONLY rows whose patient_user_id = auth.uid(). IDOR-safe, fail-closed when NULL.';

-- NOTE on the two SELECT policies now on waitlist_entries:
--   • pol_entries_admin_select   — staff: hospital_id = auth.current_hospital_id()
--   • pol_entries_patient_select — patient: patient_user_id = auth.uid()
-- Postgres RLS combines multiple permissive policies with OR. That is correct
-- here: a staff JWT carries the hospital claim (and no matching patient_user_id),
-- a patient JWT carries neither a hospital claim nor admin rights — so each role
-- only ever sees its intended rows. (If staff accounts could also be patients,
-- revisit; today the claim sets are disjoint.)
