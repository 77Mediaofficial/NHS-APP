/* =========================================================================
   Runtime configuration template for the NHS Staff Console (staff/).
   Copy to env.js and fill in, OR generate env.js at deploy time.

   SECURITY:
     • SUPABASE_URL + SUPABASE_ANON_KEY are PUBLIC by design. Staff actions run
       under the signed-in staff member's JWT; the worklist read is scoped by
       admin RLS (hospital_id) and every mutation goes through a SECURITY DEFINER
       RPC that re-checks authorisation server-side.
     • NEVER put the service-role key (or any secret) here — it would be exposed
       to every visitor. Secrets live only in server-side functions.
     • PRODUCTION AUTH: this console ships with a MOCK sign-in for local demo.
       Real deployment must wire NHS staff authentication (Care Identity / hospital
       SSO) that issues the `hospital_id` JWT claim the RLS + RPCs depend on. That
       integration is a Trust step — see DEPLOYMENT.md.
   ========================================================================= */
window.__ENV = {
  SUPABASE_URL: "https://YOUR-PROJECT-REF.supabase.co",
  SUPABASE_ANON_KEY: "YOUR-PUBLIC-ANON-KEY",
};
