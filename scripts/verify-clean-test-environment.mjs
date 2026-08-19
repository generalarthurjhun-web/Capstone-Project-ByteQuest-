import { createClient } from "@supabase/supabase-js";

const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
const publicKey =
  process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ||
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!url || !publicKey || !serviceRoleKey) {
  throw new Error("Supabase environment configuration is incomplete.");
}

const canonical = [
  { email: "admin@dnsc.edu.ph", role: "admin" },
  { email: "instructor@dnsc.edu.ph", role: "instructor" },
];
const service = createClient(url, serviceRoleKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

async function authenticateWithoutPassword(email) {
  const { data: link, error: linkError } = await service.auth.admin.generateLink({
    type: "magiclink",
    email,
  });
  if (linkError || !link.properties?.hashed_token) {
    throw linkError || new Error(`No verification token returned for ${email}.`);
  }
  const client = createClient(url, publicKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data, error } = await client.auth.verifyOtp({
    token_hash: link.properties.hashed_token,
    type: "magiclink",
  });
  if (error || !data.session) throw error || new Error(`No session returned for ${email}.`);
  return { client, session: data.session };
}

async function verifyRealtime(client, accessToken, name) {
  await client.realtime.setAuth(accessToken);
  const channel = client.channel(`clean-baseline-${name}-${Date.now()}`).on(
    "postgres_changes",
    { event: "*", schema: "public", table: "profiles" },
    () => {},
  );
  const status = await new Promise((resolve, reject) => {
    const timeout = setTimeout(() => reject(new Error(`${name} Realtime subscription timed out.`)), 12_000);
    channel.subscribe((nextStatus) => {
      if (nextStatus === "SUBSCRIBED") {
        clearTimeout(timeout);
        resolve(nextStatus);
      } else if (nextStatus === "CHANNEL_ERROR" || nextStatus === "TIMED_OUT") {
        clearTimeout(timeout);
        reject(new Error(`${name} Realtime status: ${nextStatus}`));
      }
    });
  });
  await client.removeChannel(channel);
  return status;
}

const { data: authPage, error: authError } = await service.auth.admin.listUsers({
  page: 1,
  perPage: 100,
});
if (authError) throw authError;
assert(authPage.users.length === 2, `Expected 2 Auth users, found ${authPage.users.length}.`);

const { data: profiles, error: profileError } = await service
  .from("profiles")
  .select("user_id,email,role,status")
  .order("email");
if (profileError) throw profileError;
assert(profiles.length === 2, `Expected 2 profiles, found ${profiles.length}.`);

const results = [];
for (const expected of canonical) {
  const profile = profiles.find((entry) => entry.email === expected.email);
  assert(profile, `Missing canonical profile ${expected.email}.`);
  assert(profile.role === expected.role && profile.status === "active", `${expected.email} role/status mismatch.`);

  const { client, session } = await authenticateWithoutPassword(expected.email);
  const { data: ownProfile, error: ownProfileError } = await client
    .from("profiles")
    .select("email,role,status")
    .eq("user_id", session.user.id)
    .single();
  if (ownProfileError) throw ownProfileError;
  assert(ownProfile.role === expected.role, `${expected.email} authenticated role mismatch.`);

  const analyticsRpc = expected.role === "admin" ? "get_admin_system_analytics" : "get_instructor_analytics";
  const { data: analytics, error: analyticsError } = await client.rpc(analyticsRpc);
  if (analyticsError) throw analyticsError;
  assert(analytics && typeof analytics === "object", `${analyticsRpc} did not return an object.`);

  const deniedRpc = expected.role === "admin" ? "get_instructor_analytics" : "get_admin_system_analytics";
  const { error: deniedError } = await client.rpc(deniedRpc);
  assert(deniedError, `${expected.role} unexpectedly executed ${deniedRpc}.`);

  const realtime = await verifyRealtime(client, session.access_token, expected.role);
  await client.auth.signOut();
  results.push({ email: expected.email, role: expected.role, login: "PASS", analytics: "PASS", boundary: "PASS", realtime });
}

const anonymous = createClient(url, publicKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});
const { error: anonymousAdminError } = await anonymous.rpc("get_admin_system_analytics");
const { error: anonymousInstructorError } = await anonymous.rpc("get_instructor_analytics");
assert(anonymousAdminError && anonymousInstructorError, "Anonymous analytics denial failed.");

const counts = {};
for (const table of [
  "classes",
  "class_memberships",
  "assignments",
  "attempts",
  "attempt_actions",
  "criterion_results",
  "score_revisions",
  "result_releases",
  "quiz_attempts",
  "quiz_answers",
  "quiz_results",
  "learner_progress",
  "gamification_events",
  "notifications",
  "learning_resources",
]) {
  const { count, error } = await service.from(table).select("*", { count: "exact", head: true });
  if (error) throw error;
  counts[table] = count;
  assert(count === 0, `${table} is not empty (${count}).`);
}

for (const [table, expected] of Object.entries({
  coc_modules: 4,
  missions: 20,
  activity_versions: 20,
  rubric_criteria: 98,
})) {
  const { count, error } = await service.from(table).select("*", { count: "exact", head: true });
  if (error) throw error;
  counts[table] = count;
  assert(count === expected, `${table} expected ${expected}, found ${count}.`);
}

console.log(
  JSON.stringify({
    status: "PASS",
    authUsers: authPage.users.length,
    profiles: profiles.length,
    roleChecks: results,
    anonymousDenial: "PASS",
    counts,
  }),
);
