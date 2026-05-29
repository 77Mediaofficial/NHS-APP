import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3"

// Initialize Supabase Client with the Service Role Key
// CRITICAL: Bypasses RLS to act as a trusted cross-tenant background worker
const supabaseUrl = Deno.env.get('SUPABASE_URL') as string
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') as string
const supabase = createClient(supabaseUrl, supabaseServiceKey)

const BATCH_SIZE = 100;
const MAX_RETRIES = 3;

// Mock GOV.UK Notify function (Replace with actual fetch to Notify API)
// `reference` is the idempotency key: Notify de-duplicates repeat references,
// so a re-send after a failed completion-write becomes a no-op at the provider.
async function sendGovUkNotify(phone: string, link: string, reference: string) {
  // Simulate network latency
  await new Promise((resolve) => setTimeout(resolve, Math.random() * 150 + 50));

  // Simulate a 1% random failure rate for testing the retry logic
  if (Math.random() < 0.01) throw new Error("GOV.UK Notify API Timeout");

  return true;

  // Real implementation:
  //   const res = await fetch("https://api.notifications.service.gov.uk/v2/notifications/sms", {
  //     method: "POST",
  //     headers: { Authorization: `ApiKey-v1 ${Deno.env.get("NOTIFY_API_KEY")}`,
  //                "Content-Type": "application/json" },
  //     body: JSON.stringify({
  //       phone_number: phone,
  //       template_id: Deno.env.get("NOTIFY_TEMPLATE_ID"),
  //       personalisation: { validation_link: link },
  //       reference, // idempotency key — Notify rejects/dedupes repeats
  //     }),
  //   });
  //   if (!res.ok) throw new Error(`Notify ${res.status}: ${await res.text()}`);
}

Deno.serve(async (req) => {
  // 1. Claim the next batch of jobs using the RPC function
  const { data: jobs, error: claimError } = await supabase.rpc('get_next_sms_batch', {
    batch_size: BATCH_SIZE
  });

  if (claimError) {
    console.error("Failed to claim jobs:", claimError);
    return new Response(JSON.stringify({ error: claimError.message }), { status: 500 });
  }

  if (!jobs || jobs.length === 0) {
    return new Response(JSON.stringify({ message: "Queue empty. No jobs processed." }), { status: 200 });
  }

  console.log(`Processing batch of ${jobs.length} jobs...`);

  // Execution counters
  let successes = 0;
  let retried = 0;
  let permanentlyFailed = 0;

  // 2. Process all jobs concurrently without failing the whole batch if one drops
  await Promise.allSettled(
    jobs.map(async (job: any) => {
      try {
        // Attempt to send the SMS (job.id doubles as the Notify idempotency reference)
        await sendGovUkNotify(job.patient_phone, job.payload_link, job.id);

        // On success, mark as completed (lowercase to match DB ENUM)
        const { error: updateError } = await supabase
          .from('sms_dispatch_jobs')
          .update({
            status: 'completed',
            locked_at: null,
            last_error: null
          })
          .eq('id', job.id);

        if (updateError) throw updateError; // Throw to the catch block to be retried

        successes++;

      } catch (err: any) {
        // Resolve error message
        const errorMessage = err instanceof Error ? err.message : String(err);

        // Assess retry threshold and new status (lowercase ENUMs)
        const newRetryCount = job.retry_count + 1;
        const isPermanentFailure = newRetryCount > MAX_RETRIES;
        const newStatus = isPermanentFailure ? 'failed' : 'pending';

        console.warn(`Job ${job.id} failed (Retry ${newRetryCount}):`, errorMessage);

        // Safely update the failure state and populate last_error
        const { error: fallbackUpdateError } = await supabase
          .from('sms_dispatch_jobs')
          .update({
            status: newStatus,
            retry_count: newRetryCount,
            locked_at: null, // Release lock so it can be reclaimed if pending
            last_error: errorMessage
          })
          .eq('id', job.id);

        // Unchecked failure-path defence: Log if the database rejects the failure update
        if (fallbackUpdateError) {
          console.error(`CRITICAL: Failed to write failure state for job ${job.id}:`, fallbackUpdateError);
        }

        // Increment the correct summary counter
        if (isPermanentFailure) {
            permanentlyFailed++;
        } else {
            retried++;
        }
      }
    })
  );

  // 3. Summarize execution cleanly for the dashboard metrics
  return new Response(
    JSON.stringify({
      message: "Batch complete",
      total_processed: jobs.length,
      successes: successes,
      retried_transient: retried,
      failed_dead_letter: permanentlyFailed
    }),
    { status: 200, headers: { "Content-Type": "application/json" } }
  );
});
