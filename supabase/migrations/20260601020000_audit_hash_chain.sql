-- =============================================================================
-- TAMPER-EVIDENT AUDIT CHAINS — hash-chain the append-only ledgers (§6)
-- =============================================================================
-- Strengthens COMPLIANCE.md §6 "audit trail / tamper-evidence". The ledgers
-- (`cancellation_reviews`, `validation_responses`) are already immutable-by-RLS
-- (no UPDATE/DELETE policy). This adds CRYPTOGRAPHIC tamper-evidence on top: each
-- row carries a SHA-256 hash chaining it to the previous row, so ANY later edit or
-- deletion (e.g. by someone with direct DB/superuser access that bypasses RLS)
-- breaks the chain and is DETECTABLE by re-walking it (`verify_audit_chain`).
--
-- WHY THIS IS LOW-RISK SQL (no extension dependency):
--   PostgreSQL 15 (this project's target) ships sha256(bytea) in core — NO pgcrypto,
--   NO `extensions`-schema / search_path issues. Hashing is encode(sha256(convert_to(
--   <text>, 'UTF8')), 'hex').
--
-- CHAIN CONSTRUCTION (per table):
--   • seq BIGINT IDENTITY gives a strict append order.
--   • prev_hash = row_hash of the latest existing row (or 'GENESIS' for the first).
--   • row_hash  = sha256( prev_hash || '|' || <canonical business columns as jsonb text> ).
--   • A BEFORE INSERT trigger sets prev_hash + row_hash automatically, so the
--     clinical-safety RPCs need NO change. A per-table transaction advisory lock
--     serialises appends to prevent chain forks under concurrent inserts (audit
--     ledgers are low-write, so the serialisation cost is negligible).
--
-- DEPENDENCIES (apply order): runs AFTER
--   • 20260529000000_section_11_tokens_rpc.sql (validation_responses)
--   • 20260601010000_clinical_review_workflow.sql (cancellation_reviews)
--
-- HONEST LIMITS (so this is not over-claimed):
--   • Tamper-EVIDENT, not tamper-PROOF: it lets you DETECT alteration, it does not
--     prevent a DB admin from rewriting the whole chain consistently. For stronger
--     guarantees, periodically export the latest row_hash to external WORM storage
--     (notarisation) — a Trust operational step, not closable here.
--   • Rows that already existed BEFORE this migration (none on a fresh apply) are
--     not retro-hashed; verification starts from the first chained insert.
--   • Code-reviewed, NOT executed (no live Postgres this session).
-- Idempotent + safe to re-run. Target: PostgreSQL 15.
-- =============================================================================

-- ── 1. Chain columns on each ledger ──────────────────────────────────────────
ALTER TABLE cancellation_reviews ADD COLUMN IF NOT EXISTS seq       BIGINT GENERATED ALWAYS AS IDENTITY;
ALTER TABLE cancellation_reviews ADD COLUMN IF NOT EXISTS prev_hash TEXT;
ALTER TABLE cancellation_reviews ADD COLUMN IF NOT EXISTS row_hash  TEXT;

ALTER TABLE validation_responses ADD COLUMN IF NOT EXISTS seq       BIGINT GENERATED ALWAYS AS IDENTITY;
ALTER TABLE validation_responses ADD COLUMN IF NOT EXISTS prev_hash TEXT;
ALTER TABLE validation_responses ADD COLUMN IF NOT EXISTS row_hash  TEXT;

COMMENT ON COLUMN cancellation_reviews.row_hash IS 'SHA-256 tamper-evidence chain link: sha256(prev_hash||business cols). See verify_audit_chain().';
COMMENT ON COLUMN validation_responses.row_hash IS 'SHA-256 tamper-evidence chain link: sha256(prev_hash||business cols). See verify_audit_chain().';


-- ── 2. Generic chain-append trigger function ─────────────────────────────────
-- Reusable across any ledger that has (seq, prev_hash, row_hash). The hashed
-- payload is the row's jsonb MINUS the chain-metadata columns, so it covers only
-- the immutable business content. jsonb key order is deterministic, so the same
-- row always hashes identically (here and in verify_audit_chain).
CREATE OR REPLACE FUNCTION audit_chain_append()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_prev    TEXT;
    v_payload TEXT;
BEGIN
    -- Serialise appends to THIS table's chain (prevents forks under concurrency).
    PERFORM pg_advisory_xact_lock(hashtextextended(TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME, 0));

    -- Tail hash of the existing chain (NULL → 'GENESIS' for the first row).
    EXECUTE format('SELECT row_hash FROM %I.%I ORDER BY seq DESC LIMIT 1',
                   TG_TABLE_SCHEMA, TG_TABLE_NAME)
       INTO v_prev;
    v_prev := COALESCE(v_prev, 'GENESIS');

    -- Canonical business payload: drop chain metadata (and the hash cols, which are
    -- still NULL at BEFORE INSERT) so trigger + verifier hash exactly the same text.
    v_payload := ((to_jsonb(NEW) - 'row_hash') - 'prev_hash' - 'seq')::text;

    NEW.prev_hash := v_prev;
    NEW.row_hash  := encode(sha256(convert_to(v_prev || '|' || v_payload, 'UTF8')), 'hex');
    RETURN NEW;
END;
$$;
COMMENT ON FUNCTION audit_chain_append() IS
    'BEFORE INSERT trigger: sets prev_hash + SHA-256 row_hash to chain an append-only '
    'ledger row to the previous one. Advisory-lock serialised per table. PG15 core sha256.';

DROP TRIGGER IF EXISTS trg_chain_cancellation_reviews ON cancellation_reviews;
CREATE TRIGGER trg_chain_cancellation_reviews
    BEFORE INSERT ON cancellation_reviews
    FOR EACH ROW EXECUTE FUNCTION audit_chain_append();

DROP TRIGGER IF EXISTS trg_chain_validation_responses ON validation_responses;
CREATE TRIGGER trg_chain_validation_responses
    BEFORE INSERT ON validation_responses
    FOR EACH ROW EXECUTE FUNCTION audit_chain_append();


-- ── 3. verify_audit_chain(table) — detect tampering ──────────────────────────
-- Re-walks the chain and reports whether it is intact, the row count, and the first
-- broken seq (if any). Restricted to the known ledger tables (a whitelist, so it
-- cannot be pointed at arbitrary tables). authenticated-only; read-only.
CREATE OR REPLACE FUNCTION verify_audit_chain(p_table TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_total   BIGINT;
    v_first_bad BIGINT;
BEGIN
    IF p_table NOT IN ('cancellation_reviews', 'validation_responses') THEN
        RAISE EXCEPTION 'UNKNOWN_LEDGER (%).', p_table USING ERRCODE = 'P0001';
    END IF;

    -- For each row, recompute the expected prev_hash (lag of row_hash) and the
    -- expected row_hash, then flag any mismatch. Same canonical payload as the
    -- trigger: jsonb minus chain metadata.
    EXECUTE format($q$
        WITH walked AS (
            SELECT
                seq,
                row_hash,
                prev_hash,
                COALESCE(lag(row_hash) OVER (ORDER BY seq), 'GENESIS') AS expected_prev,
                encode(sha256(convert_to(
                    COALESCE(lag(row_hash) OVER (ORDER BY seq), 'GENESIS') || '|' ||
                    (((to_jsonb(t) - 'row_hash') - 'prev_hash' - 'seq')::text), 'UTF8')), 'hex')
                    AS expected_hash
            FROM %I.%I t
        )
        SELECT count(*),
               min(seq) FILTER (WHERE row_hash IS DISTINCT FROM expected_hash
                                   OR prev_hash IS DISTINCT FROM expected_prev)
          FROM walked
    $q$, 'public', p_table)
    INTO v_total, v_first_bad;

    RETURN jsonb_build_object(
        'table',        p_table,
        'rows',         v_total,
        'intact',       (v_first_bad IS NULL),
        'first_broken_seq', v_first_bad
    );
END;
$$;
COMMENT ON FUNCTION verify_audit_chain(TEXT) IS
    'Re-walks a ledger hash chain; returns {rows, intact, first_broken_seq}. Whitelisted '
    'to the audit ledgers. Run periodically / before relying on the audit trail.';

REVOKE EXECUTE ON FUNCTION verify_audit_chain(TEXT) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION verify_audit_chain(TEXT) TO authenticated;
