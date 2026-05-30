-- =============================================================================
-- NHS NUMBER — MODULUS 11 CHECK-DIGIT VALIDATION (DTAC v2 · Interoperability)
-- =============================================================================
-- Addresses COMPLIANCE.md §9. The patient-facing layer in this repo is PII-FREE
-- (UUID tokens only), so no NHS Number is handled here. This reusable, IMMUTABLE
-- validator is provided so that ANY future ingest boundary (admin import, FHIR
-- feed, PAS sync) can enforce the standard modulus-11 check at the point PII
-- first enters the system — e.g. as a CHECK constraint or a guard in an RPC.
--
-- Algorithm (NHS Data Dictionary): 10 digits. Multiply digits 1..9 by weights
-- 10..2, sum, take remainder mod 11, check digit = 11 - remainder. A result of
-- 11 maps to 0; a result of 10 means the number is INVALID. The 10th digit must
-- equal the computed check digit. Non-digits/spaces/dashes are stripped first.
-- Returns FALSE (never errors) for any malformed input. Idempotent.
-- =============================================================================

CREATE OR REPLACE FUNCTION is_valid_nhs_number(p_input TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
IMMUTABLE
PARALLEL SAFE
AS $$
DECLARE
    v_digits TEXT;
    v_sum    INTEGER := 0;
    v_i      INTEGER;
    v_check  INTEGER;
BEGIN
    IF p_input IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Strip spaces and dashes (common formatting), keep digits only.
    v_digits := regexp_replace(p_input, '[\s-]', '', 'g');

    -- Must be exactly 10 numeric digits.
    IF v_digits !~ '^[0-9]{10}$' THEN
        RETURN FALSE;
    END IF;

    -- Weighted sum of the first 9 digits (weights 10 down to 2).
    FOR v_i IN 1..9 LOOP
        v_sum := v_sum + (substr(v_digits, v_i, 1))::INTEGER * (11 - v_i);
    END LOOP;

    v_check := 11 - (v_sum % 11);
    IF v_check = 11 THEN
        v_check := 0;
    ELSIF v_check = 10 THEN
        RETURN FALSE;   -- 10 is not a valid check digit → number invalid
    END IF;

    RETURN v_check = (substr(v_digits, 10, 1))::INTEGER;
END;
$$;

COMMENT ON FUNCTION is_valid_nhs_number(TEXT) IS
    'TRUE if input is a valid 10-digit NHS Number per modulus-11 check digit. '
    'Strips spaces/dashes; returns FALSE for any malformed input. Use at ingest '
    'boundaries where PII enters (admin import, FHIR feed) — not in the PII-free '
    'patient-facing layer.';

-- Pure function, no data access — safe to expose broadly.
GRANT EXECUTE ON FUNCTION is_valid_nhs_number(TEXT) TO PUBLIC;

-- Apply the validator as a CHECK constraint on waitlist_entries.nhs_number.
-- NULL is allowed (not every entry may have an NHS Number at creation time).
-- This runs after the base schema (20260528000000) so is_valid_nhs_number() exists.
ALTER TABLE waitlist_entries
    DROP CONSTRAINT IF EXISTS chk_nhs_number_mod11;
ALTER TABLE waitlist_entries
    ADD CONSTRAINT chk_nhs_number_mod11
    CHECK (nhs_number IS NULL OR is_valid_nhs_number(nhs_number));
