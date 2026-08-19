import { createClient } from "@supabase/supabase-js";

const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const execute = process.argv.includes("--execute");

if (!url || !serviceRoleKey) {
  throw new Error("Supabase server configuration is incomplete.");
}

const canonical = new Map([
  ["admin@dnsc.edu.ph", { role: "admin", userId: "ed0f391a-cf1c-418f-9003-2a6ba9541ec8" }],
  ["instructor@dnsc.edu.ph", { role: "instructor", userId: "2b3d9027-3eb8-4bb6-88c2-969c9f957a12" }],
]);
const client = createClient(url, serviceRoleKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});

async function retry(operation, attempts = 3) {
  let lastError;
  for (let attempt = 1; attempt <= attempts; attempt += 1) {
    try {
      return await operation();
    } catch (error) {
      lastError = error;
      if (attempt < attempts) await new Promise((resolve) => setTimeout(resolve, attempt * 350));
    }
  }
  throw lastError;
}

const { data: profiles, error: profilesError } = await client
  .from("profiles")
  .select("id,user_id,email,role,status")
  .order("created_at");
if (profilesError) throw profilesError;

for (const [email, expectation] of canonical) {
  const matches = profiles.filter((profile) => profile.email?.toLowerCase() === email);
  if (
    matches.length !== 1 ||
    matches[0].user_id !== expectation.userId ||
    matches[0].role !== expectation.role ||
    matches[0].status !== "active"
  ) {
    throw new Error(`Canonical account guard failed for ${email}.`);
  }
}

const obsoleteProfiles = profiles.filter(
  (profile) => !canonical.has(profile.email?.toLowerCase()),
);

if (!execute) {
  console.log(
    JSON.stringify({
      status: "DRY_RUN",
      profilesBefore: profiles.length,
      canonicalAccounts: [...canonical.keys()],
      obsoleteAuthUsersToDelete: obsoleteProfiles.length,
    }),
  );
} else {
  const deleted = [];
  const failures = [];
  for (const profile of obsoleteProfiles) {
    try {
      await retry(async () => {
        const { error } = await client.auth.admin.deleteUser(profile.user_id, false);
        if (error) throw error;
      });
      deleted.push({ userId: profile.user_id, email: profile.email, role: profile.role });
    } catch (error) {
      failures.push({
        userId: profile.user_id,
        email: profile.email,
        role: profile.role,
        error: error instanceof Error ? error.message : String(error),
      });
    }
  }

  const { data: remaining, error: remainingError } = await client
    .from("profiles")
    .select("user_id,email,role,status")
    .order("email");
  if (remainingError) throw remainingError;

  console.log(
    JSON.stringify({
      status: failures.length === 0 && remaining.length === 2 ? "PASS" : "PARTIAL",
      deletedCount: deleted.length,
      failureCount: failures.length,
      failures,
      remaining,
    }),
  );

  if (failures.length > 0 || remaining.length !== 2) process.exitCode = 1;
}
