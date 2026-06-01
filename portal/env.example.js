/* =========================================================================
   Runtime configuration template for the NHS Patient Hub (portal).
   Copy to env.js and fill in, OR generate env.js at deploy time.

   SECURITY:
     • SUPABASE_URL + SUPABASE_ANON_KEY are PUBLIC by design. The anon key is
       used only to START an auth session; once signed in, every read runs
       under the user's JWT and Row Level Security isolates their data.
     • NEVER put the service-role key (or any secret) here — it would be
       exposed to every visitor. Secrets live only in server-side functions.
     • NHS_OIDC_PROVIDER is just the PROVIDER NAME configured in the Supabase
       dashboard (Authentication → Providers). The client id/secret, NHS Login
       issuer URLs and scopes (incl. nhs_number) are registered THERE, never here.
       Leave it empty/omitted to use the local mock credential form instead.
   ========================================================================= */
window.__ENV = {
  SUPABASE_URL: "https://YOUR-PROJECT-REF.supabase.co",
  SUPABASE_ANON_KEY: "YOUR-PUBLIC-ANON-KEY",

  // Optional: name of the NHS Login OIDC provider configured in Supabase Auth.
  // When set (and the backend is configured), the "Sign in with NHS Login" button
  // starts the real OIDC flow. Empty/omitted → local mock sign-in form.
  NHS_OIDC_PROVIDER: "",
};
