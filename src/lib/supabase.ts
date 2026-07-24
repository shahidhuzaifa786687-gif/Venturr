import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import { z } from "zod";

const browserSupabaseConfigSchema = z
  .object({
    url: z.string().url(),
    publishableKey: z.string().min(20),
  })
  .superRefine(({ url }, context) => {
    const parsed = new URL(url);
    const isLocal = parsed.hostname === "127.0.0.1" || parsed.hostname === "localhost";
    if (parsed.protocol !== "https:" && !isLocal) {
      context.addIssue({
        code: "custom",
        path: ["url"],
        message: "Hosted Supabase URLs must use HTTPS.",
      });
    }
  });

const rawConfig = {
  url: import.meta.env.VITE_SUPABASE_URL as string | undefined,
  publishableKey: import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY as string | undefined,
};

const parsedConfig =
  rawConfig.url && rawConfig.publishableKey
    ? browserSupabaseConfigSchema.safeParse(rawConfig)
    : null;

/**
 * Browser access is intentionally limited to Supabase's publishable key.
 * Never add a service-role/secret key to a VITE_ environment variable: Vite
 * exposes those variables to every browser. RLS remains the authorization
 * boundary for every request.
 */
export const supabase: SupabaseClient | null =
  parsedConfig?.success
    ? createClient(parsedConfig.data.url, parsedConfig.data.publishableKey, {
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
export const supabaseConfigurationError =
  parsedConfig && !parsedConfig.success
    ? "The public Supabase configuration is invalid."
    : null;

export const googleAuthEnabled =
  import.meta.env.VITE_GOOGLE_AUTH_ENABLED === "true";
