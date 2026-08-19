"use client";

import { createBrowserClient } from "@supabase/ssr";
import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "@/types/database.generated";

let browserClient: SupabaseClient<Database> | undefined;

function publicSupabaseConfig() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key =
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ??
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

  if (!url || !key) {
    throw new Error("Supabase public configuration is missing.");
  }

  return { url, key };
}

export function createClient(): SupabaseClient<Database> {
  if (browserClient) return browserClient;

  const { url, key } = publicSupabaseConfig();
  browserClient = createBrowserClient<Database>(url, key);
  return browserClient;
}

