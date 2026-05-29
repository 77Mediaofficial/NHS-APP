/* =========================================================================
   Runtime configuration template for the NHS Waitlist Validation frontend.

   Copy this file to `env.js` and fill in the values for your environment, OR
   generate `env.js` at deploy time (e.g. a Vercel build step that echoes the
   public env vars into this shape).

   SECURITY:
     • SUPABASE_URL and SUPABASE_ANON_KEY are PUBLIC by design — the anon key only
       grants EXECUTE on the validation RPC; every table is locked by forced RLS.
       It is safe to ship these to the browser.
     • NEVER place the service-role key (or any secret) in this file — it would be
       exposed to every visitor. The service-role key belongs only in server-side
       edge functions (see supabase/functions/*).
   ========================================================================= */
window.__ENV = {
  SUPABASE_URL: "https://YOUR-PROJECT-REF.supabase.co",
  SUPABASE_ANON_KEY: "YOUR-PUBLIC-ANON-KEY",
};
