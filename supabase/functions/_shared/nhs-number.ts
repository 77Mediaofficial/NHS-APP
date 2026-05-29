/**
 * NHS Number — modulus 11 check-digit validation (DTAC v2 · Interoperability).
 *
 * Mirror of the SQL `is_valid_nhs_number()` for use in edge/ingest workers
 * (e.g. an admin import or FHIR feed) where PII first enters the system. The
 * patient-facing app is PII-free and does NOT use this.
 *
 * Algorithm (NHS Data Dictionary): 10 digits; weight digits 1..9 by 10..2; sum;
 * remainder = sum % 11; check = 11 - remainder; 11 -> 0; 10 -> invalid; the
 * 10th digit must equal the computed check digit.
 */
export function isValidNhsNumber(input: string | null | undefined): boolean {
  if (input == null) return false;

  const digits = String(input).replace(/[\s-]/g, "");
  if (!/^\d{10}$/.test(digits)) return false;

  let sum = 0;
  for (let i = 0; i < 9; i++) {
    sum += Number(digits[i]) * (10 - i);
  }

  let check = 11 - (sum % 11);
  if (check === 11) check = 0;
  if (check === 10) return false;

  return check === Number(digits[9]);
}

/** Normalise to the canonical 10-digit form, or null if invalid. */
export function normaliseNhsNumber(input: string | null | undefined): string | null {
  if (input == null) return null;
  const digits = String(input).replace(/[\s-]/g, "");
  return isValidNhsNumber(digits) ? digits : null;
}
