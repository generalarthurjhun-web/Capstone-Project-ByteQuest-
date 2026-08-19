import { createClient } from "@supabase/supabase-js";

const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
const publicKey =
  process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ||
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const adminPassword = process.env.BYTEQUEST_DEMO_ADMIN_PASSWORD;
const instructorPassword = process.env.BYTEQUEST_DEMO_INSTRUCTOR_PASSWORD;

const ADMIN_EMAIL = "admin@dnsc.edu.ph";
const INSTRUCTOR_EMAIL = "instructor@dnsc.edu.ph";

if (!url || !publicKey || !serviceRoleKey) {
  throw new Error("Supabase server configuration is incomplete.");
}
if (!adminPassword || !instructorPassword) {
  throw new Error(
    "BYTEQUEST_DEMO_ADMIN_PASSWORD and BYTEQUEST_DEMO_INSTRUCTOR_PASSWORD are required.",
  );
}

const service = createClient(url, serviceRoleKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});

const createdUserIds = [];

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

async function createDemoUser(email, password, fullName, requestedRole) {
  const { data, error } = await service.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: {
      full_name: fullName,
      bytequest_account_kind: "dashboard_demo",
      requested_role: requestedRole,
    },
    app_metadata: {
      bytequest_account_kind: "dashboard_demo",
    },
  });
  if (error || !data.user) {
    throw error || new Error(`Supabase did not return the created ${requestedRole}.`);
  }
  createdUserIds.push(data.user.id);
  return data.user;
}

async function readProfile(userId) {
  const { data, error } = await service
    .from("profiles")
    .select("id,user_id,email,full_name,role,status")
    .eq("user_id", userId)
    .single();
  if (error) throw error;
  return data;
}

async function verifyLogin(email, password, expectedRole) {
  const client = createClient(url, publicKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data, error } = await client.auth.signInWithPassword({ email, password });
  if (error || !data.user) throw error || new Error(`Login failed for ${email}.`);

  const { data: profile, error: profileError } = await client
    .from("profiles")
    .select("email,role,status")
    .eq("user_id", data.user.id)
    .single();
  if (profileError) throw profileError;
  assert(profile.role === expectedRole, `${email} has role ${profile.role}, not ${expectedRole}.`);
  assert(profile.status === "active", `${email} is not active.`);
  return client;
}

async function rollbackCreatedUsers() {
  for (const userId of [...createdUserIds].reverse()) {
    await service.auth.admin.deleteUser(userId);
  }
}

try {
  const adminUser = await createDemoUser(
    ADMIN_EMAIL,
    adminPassword,
    "ByteQuest Demo Administrator",
    "admin",
  );

  const adminProfileBefore = await readProfile(adminUser.id);
  const { data: adminProfile, error: bootstrapError } = await service
    .from("profiles")
    .update({ role: "admin", status: "active" })
    .eq("user_id", adminUser.id)
    .select("id,user_id,email,full_name,role,status")
    .single();
  if (bootstrapError) throw bootstrapError;

  const { error: auditError } = await service.from("audit_events").insert({
    actor_id: null,
    actor_role: null,
    action: "account.demo_admin_bootstrapped",
    target_type: "profile",
    target_id: adminProfile.id,
    old_value: adminProfileBefore,
    new_value: adminProfile,
    reason: "Project-owner requested the ByteQuest dashboard demo Administrator.",
    metadata: {
      trusted_service_operation: true,
      account_kind: "dashboard_demo",
      target_user_id: adminUser.id,
    },
    outcome: "success",
  });
  if (auditError) throw auditError;

  const authenticatedAdmin = await verifyLogin(
    ADMIN_EMAIL,
    adminPassword,
    "admin",
  );

  const instructorUser = await createDemoUser(
    INSTRUCTOR_EMAIL,
    instructorPassword,
    "ByteQuest Demo Instructor",
    "instructor",
  );

  const { error: roleError } = await authenticatedAdmin.rpc(
    "admin_change_user_role",
    {
      p_user_id: instructorUser.id,
      p_new_role: "instructor",
      p_reason: "Provision the project-owner-requested dashboard demo Instructor.",
    },
  );
  if (roleError) throw roleError;

  const authenticatedInstructor = await verifyLogin(
    INSTRUCTOR_EMAIL,
    instructorPassword,
    "instructor",
  );

  await authenticatedAdmin.auth.signOut();
  await authenticatedInstructor.auth.signOut();

  const finalProfiles = await Promise.all([
    readProfile(adminUser.id),
    readProfile(instructorUser.id),
  ]);

  console.log(
    JSON.stringify(
      {
        status: "PASS",
        accounts: finalProfiles.map(({ email, full_name, role, status }) => ({
          email,
          fullName: full_name,
          role,
          accountStatus: status,
          loginVerified: true,
          emailConfirmed: true,
        })),
      },
      null,
      2,
    ),
  );
} catch (error) {
  await rollbackCreatedUsers();
  const message = error instanceof Error ? error.message : String(error);
  console.error(JSON.stringify({ status: "FAIL", error: message }, null, 2));
  process.exitCode = 1;
}
