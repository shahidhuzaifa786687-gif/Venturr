import { createClient, type SupabaseClient } from "@supabase/supabase-js";

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL as string | undefined;
const supabasePublishableKey = import.meta.env
  .VITE_SUPABASE_PUBLISHABLE_KEY as string | undefined;

/**
 * Browser access is intentionally limited to Supabase's publishable key.
 * Never add a service-role/secret key to a VITE_ environment variable: Vite
 * exposes those variables to every browser. RLS remains the authorization
 * boundary for every request.
 */
export const supabase: SupabaseClient | null =
  supabaseUrl && supabasePublishableKey
    ? createClient(supabaseUrl, supabasePublishableKey, {
        auth: {
          flowType: "pkce",
          persistSession: true,
          autoRefreshToken: true,
          detectSessionInUrl: true,
        },
        global: {
          headers: {
            "X-Client-Info": "venturr-web/1.0",
          },
        },
      })
    : null;

export const isSupabaseConfigured = supabase !== null;
