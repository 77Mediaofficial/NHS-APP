/* =========================================================================
   Runtime configuration template for the NHS Patient Hub (portal).
   Copy to env.js and fill in, OR generate env.js at deploy time.

   SECURITY:
     • SUPABASE_URL + SUPABASE_ANON_KEY are PUBLIC by design. The anon key is
       used only to START an auth session; once signed in, every read runs
       under the user's JWT and Row Level Security isolates their data.
     • NEVER put the service-role key (or any secret) here — it would be
       exposed to every visitor. Secrets live only in server-side functions.
   ========================================================================= */
window.__ENV = {
  SUPABASE_URL: "https://YOUR-PROJECT-REF.supabase.co",
  SUPABASE_ANON_KEY: "YOUR-PUBLIC-ANON-KEY",
};
