// Follow this guide to add this function to your project:
// https://supabase.com/docs/guides/functions/new-function

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { createHmac } from "https://deno.land/std@0.177.0/node/crypto.ts";

// The main function that will be executed when the edge function is invoked.
serve(async (req: Request) => {
  try {
    // --- 1. Get secrets and create Supabase client ---
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const lemonSqueezyWebhookSecret = Deno.env.get("LEMONSQUEEZY_WEBHOOK_SECRET")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // --- 2. Verify the webhook signature for security ---
    const signature = req.headers.get("X-Signature");
    const body = await req.text();

    if (!signature) {
      throw new Error("Missing X-Signature header");
    }

    const hmac = createHmac("sha256", lemonSqueezyWebhookSecret);
    const digest = hmac.update(body).digest("hex");

    if (digest !== signature) {
      throw new Error("Invalid signature");
    }

    // --- 3. Parse the webhook payload ---
    const payload = JSON.parse(body);
    const eventName = payload.meta.event_name;
    const customerEmail = payload.data.attributes.user_email;

    // We only care about new subscriptions or successful renewals
    if (eventName !== "subscription_created" && eventName !== "subscription_payment_success") {
      return new Response(
        JSON.stringify({ message: `Ignoring event: ${eventName}` }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    // --- 4. Find the user in Supabase Auth ---
    // Note: This requires the user to have already signed up in your app with the same email.
    const { data: userData, error: userError } = await supabase.auth.admin.listUsers({ email: customerEmail });

    if (userError) throw userError;
    if (!userData || userData.users.length === 0) {
      throw new Error(`User not found for email: ${customerEmail}`);
    }
    
    const user = userData.users[0];

    // --- 5. Update the user's metadata to grant "Pro" access ---
    // We'll add a 'pro' flag and the subscription details to the user's app_metadata.
    const { data: updatedUser, error: updateUserError } = await supabase.auth.admin.updateUserById(
      user.id,
      {
        app_metadata: {
          ...user.app_metadata,
          pro: true,
          subscription_status: payload.data.attributes.status,
          variant_name: payload.data.attributes.variant_name,
        },
      }
    );

    if (updateUserError) throw updateUserError;

    // --- 6. Return a success response ---
    return new Response(
      JSON.stringify({ message: `Successfully granted Pro access to ${customerEmail}` }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );

  } catch (error) {
    console.error("Error handling Lemon Squeezy webhook:", error);
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      { status: 400, headers: { "Content-Type": "application/json" } }
    );
  }
});
