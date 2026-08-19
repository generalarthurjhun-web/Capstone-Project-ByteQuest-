import { randomBytes, randomUUID } from "node:crypto";
import { createClient } from "@supabase/supabase-js";

const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
const publishableKey =
  process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ??
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!url || !publishableKey || !serviceRoleKey) {
  throw new Error("Supabase E2E environment variables are unavailable.");
}

const runId = `bq-e2e-${new Date().toISOString().replace(/\D/g, "").slice(0, 14)}-${randomUUID().slice(0, 8)}`;
const domain = "bytequest-e2e.invalid";
const password = process.env.BYTEQUEST_E2E_PASSWORD;
if (!password) {
  throw new Error("BYTEQUEST_E2E_PASSWORD is required for authenticated lifecycle scripts.");
}
const admin = createClient(url, serviceRoleKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});

const accounts = [
  { key: "admin", role: "admin", name: "ByteQuest E2E Admin" },
  { key: "instructor1", role: "instructor", name: "ByteQuest E2E Instructor One" },
  { key: "instructor2", role: "instructor", name: "ByteQuest E2E Instructor Two" },
  { key: "learnerA", role: "learner", name: "ByteQuest E2E Learner A" },
  { key: "learnerB", role: "learner", name: "ByteQuest E2E Learner B" },
].map((account) => ({
  ...account,
  email: `${runId}-${account.key.toLowerCase()}@${domain}`,
}));

const users = new Map();
const clients = new Map();
const classIds = [];
const quizIds = [];
const resourceIds = [];
const storagePaths = [];
const results = [];

function record(name, status, detail = "") {
  results.push({ name, status, detail });
}

function requireValue(value, message) {
  if (value === null || value === undefined) throw new Error(message);
  return value;
}

async function expectDenied(name, operation) {
  try {
    const response = await operation();
    if (response?.error) {
      record(name, "PASS", response.error.code ?? response.error.message);
      return;
    }
    throw new Error("operation unexpectedly succeeded");
  } catch (error) {
    if (error instanceof Error && error.message === "operation unexpectedly succeeded") {
      throw error;
    }
    record(name, "PASS", error instanceof Error ? error.message : "denied");
  }
}

async function createAccounts() {
  for (const account of accounts) {
    const { data, error } = await admin.auth.admin.createUser({
      email: account.email,
      password,
      email_confirm: true,
      user_metadata: {
        full_name: account.name,
        bytequest_test_account: true,
        bytequest_test_run: runId,
      },
    });
    if (error || !data.user) {
      throw new Error(`Could not create ${account.key}: ${error?.message ?? "missing user"}`);
    }
    users.set(account.key, data.user.id);

    const { error: profileError } = await admin
      .from("profiles")
      .update({
        full_name: account.name,
        role: account.role,
        status: "active",
      })
      .eq("user_id", data.user.id);
    if (profileError) {
      throw new Error(`Could not configure ${account.key}: ${profileError.message}`);
    }

    const client = createClient(url, publishableKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
    const { data: session, error: signInError } =
      await client.auth.signInWithPassword({ email: account.email, password });
    if (signInError || session.user?.id !== data.user.id) {
      throw new Error(`Could not authenticate ${account.key}: ${signInError?.message ?? "UUID mismatch"}`);
    }
    clients.set(account.key, client);
  }
  record("five disposable Auth identities and matching profile UUIDs", "PASS");
}

async function exerciseBoundaries() {
  const testAdmin = clients.get("admin");
  const instructor1 = clients.get("instructor1");
  const instructor2 = clients.get("instructor2");
  const learnerA = clients.get("learnerA");
  const learnerB = clients.get("learnerB");
  for (const client of [testAdmin, instructor1, instructor2, learnerA, learnerB]) {
    requireValue(client, "Authenticated client is missing");
  }

  const { data: ownProfiles, error: ownProfileError } = await learnerA
    .from("profiles")
    .select("user_id,role,status")
    .eq("user_id", users.get("learnerA"));
  if (ownProfileError || ownProfiles?.length !== 1 || ownProfiles[0].role !== "learner") {
    throw new Error(`Learner profile linkage failed: ${ownProfileError?.message ?? "unexpected row"}`);
  }
  record("Learner A reads its linked active learner profile", "PASS");

  await expectDenied("Learner cannot change its role", () =>
    learnerA.rpc("admin_change_user_role", {
      p_user_id: users.get("learnerA"),
      p_new_role: "admin",
      p_reason: "E2E denial check",
    }),
  );
  await expectDenied("Learner cannot create a class", () =>
    learnerA.rpc("create_class", {
      p_title: "Forbidden learner class",
      p_class_code: `DENY-${randomUUID().slice(0, 8)}`,
    }),
  );
  await expectDenied("Instructor cannot perform Admin account governance", () =>
    instructor1.rpc("admin_set_account_status", {
      p_user_id: users.get("learnerB"),
      p_status: "inactive",
      p_reason: "E2E denial check",
    }),
  );

  const { data: classOne, error: classOneError } = await instructor1.rpc("create_class", {
    p_title: `ByteQuest authenticated E2E class ${runId}`,
    p_class_code: `E1-${randomUUID().slice(0, 8)}`,
  });
  if (classOneError || !classOne?.id) {
    throw new Error(`Instructor 1 class creation failed: ${classOneError?.message ?? "missing class"}`);
  }
  classIds.push(classOne.id);

  const { data: classTwo, error: classTwoError } = await instructor2.rpc("create_class", {
    p_title: `ByteQuest isolation E2E class ${runId}`,
    p_class_code: `E2-${randomUUID().slice(0, 8)}`,
  });
  if (classTwoError || !classTwo?.id) {
    throw new Error(`Instructor 2 class creation failed: ${classTwoError?.message ?? "missing class"}`);
  }
  classIds.push(classTwo.id);

  const { error: enrollAError } = await instructor1.rpc("enroll_learner", {
    p_class_id: classOne.id,
    p_learner_id: users.get("learnerA"),
  });
  const { error: enrollBError } = await instructor2.rpc("enroll_learner", {
    p_class_id: classTwo.id,
    p_learner_id: users.get("learnerB"),
  });
  if (enrollAError || enrollBError) {
    throw new Error(`Enrollment failed: ${enrollAError?.message ?? enrollBError?.message}`);
  }
  record("two Instructors create isolated classes and enroll separate Learners", "PASS");

  const analyticsStart = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();
  const analyticsEnd = new Date().toISOString();
  const instructorAnalytics = await instructor1.rpc("get_instructor_analytics", {
    p_class_id: classOne.id,
    p_coc_id: null,
    p_mission_id: null,
    p_from: analyticsStart,
    p_to: analyticsEnd,
  });
  if (
    instructorAnalytics.error ||
    instructorAnalytics.data?.filters?.classes?.length !== 1 ||
    instructorAnalytics.data.filters.classes[0]?.id !== classOne.id
  ) {
    throw new Error(`Instructor analytics failed: ${instructorAnalytics.error?.message ?? "wrong class scope"}`);
  }
  await expectDenied("Instructor 2 cannot retrieve Instructor 1 analytics", () =>
    instructor2.rpc("get_instructor_analytics", {
      p_class_id: classOne.id,
      p_coc_id: null,
      p_mission_id: null,
      p_from: analyticsStart,
      p_to: analyticsEnd,
    }),
  );
  await expectDenied("Learner cannot retrieve Instructor analytics", () =>
    learnerA.rpc("get_instructor_analytics", {
      p_class_id: null,
      p_coc_id: null,
      p_mission_id: null,
      p_from: analyticsStart,
      p_to: analyticsEnd,
    }),
  );
  await expectDenied("Instructor cannot retrieve Admin system analytics", () =>
    instructor1.rpc("get_admin_system_analytics", {
      p_from: analyticsStart,
      p_to: analyticsEnd,
    }),
  );
  const adminAnalytics = await testAdmin.rpc("get_admin_system_analytics", {
    p_from: analyticsStart,
    p_to: analyticsEnd,
  });
  if (adminAnalytics.error || typeof adminAnalytics.data?.summary?.activeLearners !== "number") {
    throw new Error(`Admin system analytics failed: ${adminAnalytics.error?.message ?? "invalid payload"}`);
  }
  record("analytics RPCs enforce Instructor class scope and Admin role boundaries", "PASS");

  const { data: hiddenClass, error: hiddenClassError } = await instructor2
    .from("classes")
    .select("id")
    .eq("id", classOne.id);
  if (hiddenClassError || hiddenClass?.length !== 0) {
    throw new Error(`Cross-Instructor class read was not isolated: ${hiddenClassError?.message ?? "row visible"}`);
  }
  await expectDenied("Instructor 2 cannot archive Instructor 1 class", () =>
    instructor2.rpc("archive_class", {
      p_class_id: classOne.id,
      p_reason: "E2E cross-scope denial check",
    }),
  );
  await expectDenied("Instructor 1 cannot deactivate out-of-scope Learner B", () =>
    instructor1.rpc("instructor_deactivate_learner_account", {
      p_learner_id: users.get("learnerB"),
      p_reason: "E2E cross-scope denial check",
    }),
  );

  const { data: learnerAClass } = await learnerA.from("classes").select("id").eq("id", classOne.id);
  const { data: learnerBClass } = await learnerB.from("classes").select("id").eq("id", classOne.id);
  if (learnerAClass?.length !== 1 || learnerBClass?.length !== 0) {
    throw new Error("Learner class isolation failed");
  }
  record("Learner class visibility follows active membership", "PASS");

  const { data: coc2, error: cocError } = await instructor1
    .from("coc_modules")
    .select("id")
    .eq("coc_code", "coc2")
    .single();
  if (cocError || !coc2) throw new Error(`Quiz COC lookup failed: ${cocError?.message}`);

  const { data: quiz, error: quizError } = await instructor1.rpc("create_instructor_quiz", {
    p_title: `TEST_ONLY boundary quiz ${runId}`,
    p_topic: `Boundary authorization ${runId}`,
    p_coc_module_id: coc2.id,
  });
  if (quizError || !quiz?.id) throw new Error(`Instructor quiz creation failed: ${quizError?.message}`);
  quizIds.push(quiz.id);

  const { data: instructorTwoQuizRows } = await instructor2.from("quizzes").select("id").eq("id", quiz.id);
  const { data: learnerQuizRows } = await learnerA.from("quizzes").select("id").eq("id", quiz.id);
  if (instructorTwoQuizRows?.length !== 0 || learnerQuizRows?.length !== 0) {
    throw new Error("Instructor quiz authoring records leaked outside the owner boundary");
  }
  await expectDenied("Instructor 2 cannot update Instructor 1 quiz", () =>
    instructor2.rpc("update_instructor_quiz", {
      p_quiz_id: quiz.id,
      p_title: "Forbidden cross-scope edit",
      p_topic: "Denied",
    }),
  );
  await expectDenied("Learner cannot create a quiz", () =>
    learnerA.rpc("create_instructor_quiz", {
      p_title: "Forbidden learner quiz",
      p_topic: "Denied",
    }),
  );
  await expectDenied("Admin cannot use ordinary Instructor quiz authoring", () =>
    testAdmin.rpc("create_instructor_quiz", {
      p_title: "Forbidden Admin-authored quiz",
      p_topic: "Denied",
    }),
  );
  record("quiz authoring enforces Instructor ownership and denies Learner/Admin mutation", "PASS");

  const resourceId = randomUUID();
  const storagePath = `classes/${classOne.id}/resources/${resourceId}/e2e-proof.pdf`;
  resourceIds.push(resourceId);
  storagePaths.push(storagePath);
  const pdfBytes = new TextEncoder().encode("%PDF-1.4\n% ByteQuest authenticated E2E proof\n");
  const { error: uploadError } = await admin.storage
    .from("learning-resources")
    .upload(storagePath, pdfBytes, { contentType: "application/pdf", upsert: false });
  if (uploadError) throw new Error(`Storage upload failed: ${uploadError.message}`);

  const { error: metadataError } = await instructor1.rpc("create_learning_resource", {
    p_resource_id: resourceId,
    p_class_id: classOne.id,
    p_title: "Authenticated E2E PDF proof",
    p_description: "Disposable Storage/RLS verification",
    p_storage_path: storagePath,
    p_mime_type: "application/pdf",
    p_size_bytes: pdfBytes.byteLength,
  });
  if (metadataError) throw new Error(`Resource metadata failed: ${metadataError.message}`);

  await expectDenied("Instructor rejects an executable learning resource", () =>
    instructor1.rpc("create_learning_resource", {
      p_resource_id: randomUUID(),
      p_class_id: classOne.id,
      p_title: "Rejected executable",
      p_description: "E2E denial check",
      p_storage_path: `classes/${classOne.id}/resources/${randomUUID()}/payload.exe`,
      p_mime_type: "application/x-msdownload",
      p_size_bytes: 10,
    }),
  );
  await expectDenied("Instructor rejects an oversized learning resource", () =>
    instructor1.rpc("create_learning_resource", {
      p_resource_id: randomUUID(),
      p_class_id: classOne.id,
      p_title: "Rejected oversized PDF",
      p_description: "E2E denial check",
      p_storage_path: `classes/${classOne.id}/resources/${randomUUID()}/large.pdf`,
      p_mime_type: "application/pdf",
      p_size_bytes: 52428801,
    }),
  );

  const learnerASigned = await learnerA.storage
    .from("learning-resources")
    .createSignedUrl(storagePath, 60);
  const learnerBSigned = await learnerB.storage
    .from("learning-resources")
    .createSignedUrl(storagePath, 60);
  const instructorTwoSigned = await instructor2.storage
    .from("learning-resources")
    .createSignedUrl(storagePath, 60);
  if (learnerASigned.error || !learnerASigned.data?.signedUrl) {
    throw new Error(`Authorized Learner Storage read failed: ${learnerASigned.error?.message}`);
  }
  if (!learnerBSigned.error || !instructorTwoSigned.error) {
    throw new Error("Out-of-scope Storage signed URL was issued");
  }
  record("private Storage signed URLs enforce class and Instructor scope", "PASS");

  await expectDenied("Learner cannot archive a learning resource", () =>
    learnerA.rpc("delete_learning_resource", {
      p_resource_id: resourceId,
      p_reason: "E2E denial check",
    }),
  );
  const { error: archiveResourceError } = await instructor1.rpc("delete_learning_resource", {
    p_resource_id: resourceId,
    p_reason: "Authenticated E2E archive verification",
  });
  if (archiveResourceError) throw new Error(`Resource archive failed: ${archiveResourceError.message}`);
  const afterArchive = await learnerA.storage
    .from("learning-resources")
    .createSignedUrl(storagePath, 60);
  if (!afterArchive.error) throw new Error("Archived resource remained readable");
  record("resource archive is audited and immediately removes learner read scope", "PASS");

  const { error: adminDeactivateError } = await testAdmin.rpc("admin_set_account_status", {
    p_user_id: users.get("instructor2"),
    p_status: "inactive",
    p_reason: "Authenticated E2E Admin state transition",
  });
  const { error: adminRestoreError } = await testAdmin.rpc("admin_set_account_status", {
    p_user_id: users.get("instructor2"),
    p_status: "active",
    p_reason: "Authenticated E2E Admin state restoration",
  });
  if (adminDeactivateError || adminRestoreError) {
    throw new Error(`Admin account-state workflow failed: ${adminDeactivateError?.message ?? adminRestoreError?.message}`);
  }
  record("Admin performs audited account deactivation and restoration", "PASS");

  const { error: instructorDeactivateError } = await instructor1.rpc(
    "instructor_deactivate_learner_account",
    {
      p_learner_id: users.get("learnerA"),
      p_reason: "Authenticated E2E in-scope instructional deactivation",
    },
  );
  if (instructorDeactivateError) {
    throw new Error(`Instructor account deactivation failed: ${instructorDeactivateError.message}`);
  }
  const { data: deactivatedProfile, error: deactivatedProfileError } = await admin
    .from("profiles")
    .select("status,deactivated_by,deactivation_reason")
    .eq("user_id", users.get("learnerA"))
    .single();
  if (
    deactivatedProfileError ||
    deactivatedProfile.status !== "deactivated" ||
    deactivatedProfile.deactivated_by !== users.get("instructor1")
  ) {
    throw new Error("Instructor deactivation did not preserve its authoritative actor/state");
  }
  const { data: deactivatedMemberships } = await admin
    .from("class_memberships")
    .select("status,deactivation_reason")
    .eq("learner_id", users.get("learnerA"));
  if (!deactivatedMemberships?.every((row) => row.status === "deactivated")) {
    throw new Error("Instructor account deactivation did not preserve/close memberships");
  }
  record("Instructor deactivates only an exclusively scoped Learner while preserving history", "PASS");

  const anonymous = createClient(url, publishableKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const anonymousAttempts = await anonymous.from("attempts").select("id").limit(1);
  if (!anonymousAttempts.error && (anonymousAttempts.data?.length ?? 0) > 0) {
    throw new Error("Anonymous caller read a protected attempt");
  }
  await expectDenied("Anonymous caller cannot invoke protected RPCs", () =>
    anonymous.rpc("create_class", {
      p_title: "Anonymous forbidden class",
      p_class_code: `ANON-${randomUUID().slice(0, 8)}`,
    }),
  );
  await expectDenied("Anonymous caller cannot retrieve Instructor analytics", () =>
    anonymous.rpc("get_instructor_analytics", {
      p_class_id: null,
      p_coc_id: null,
      p_mission_id: null,
      p_from: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(),
      p_to: new Date().toISOString(),
    }),
  );

  const expectedAuditActions = [
    "class.created",
    "class_membership.enrolled",
    "learning_resource.created",
    "learning_resource.deleted",
    "account.status_changed",
    "account.deactivated_by_instructor",
  ];
  const { data: auditRows, error: auditError } = await testAdmin
    .from("audit_events")
    .select("action,actor_id,actor_role,outcome")
    .in("actor_id", Array.from(users.values()))
    .in("action", expectedAuditActions);
  if (auditError) throw new Error(`Audit verification failed: ${auditError.message}`);
  const observedActions = new Set(auditRows.map((row) => row.action));
  const missingAudit = expectedAuditActions.filter((action) => !observedActions.has(action));
  if (missingAudit.length > 0) {
    throw new Error(`Missing E2E audit actions: ${missingAudit.join(", ")}`);
  }
  if (auditRows.some((row) => row.outcome !== "success" || !row.actor_id || !row.actor_role)) {
    throw new Error("E2E audit actor/role/outcome evidence is incomplete");
  }
  record("critical authenticated operations preserve actor, role, action, and outcome audit evidence", "PASS");
}

async function cleanup() {
  const cleanupErrors = [];
  if (quizIds.length > 0) {
    const { data: versions } = await admin.from("quiz_versions").select("id").in("quiz_id", quizIds);
    const versionIds = (versions ?? []).map((version) => version.id);
    if (versionIds.length > 0) {
      const { error: itemError } = await admin.from("quiz_items").delete().in("quiz_version_id", versionIds);
      if (itemError) cleanupErrors.push(itemError.message);
      const { error: generationError } = await admin.from("ai_quiz_generations").delete().in("quiz_version_id", versionIds);
      if (generationError) cleanupErrors.push(generationError.message);
      const { error: versionError } = await admin.from("quiz_versions").delete().in("id", versionIds);
      if (versionError) cleanupErrors.push(versionError.message);
    }
    const { error: quizError } = await admin.from("quizzes").delete().in("id", quizIds);
    if (quizError) cleanupErrors.push(quizError.message);
  }
  if (storagePaths.length > 0) {
    const { error } = await admin.storage.from("learning-resources").remove(storagePaths);
    if (error && !error.message.toLowerCase().includes("not found")) cleanupErrors.push(error.message);
  }
  if (resourceIds.length > 0) {
    const { error } = await admin.from("learning_resources").delete().in("id", resourceIds);
    if (error) cleanupErrors.push(error.message);
  }
  if (classIds.length > 0) {
    const { error: membershipError } = await admin
      .from("class_memberships")
      .delete()
      .in("class_id", classIds);
    if (membershipError) cleanupErrors.push(membershipError.message);
    const { error: classError } = await admin.from("classes").delete().in("id", classIds);
    if (classError) cleanupErrors.push(classError.message);
  }
  for (const client of clients.values()) await client.auth.signOut();
  for (const userId of Array.from(users.values()).reverse()) {
    const { error } = await admin.auth.admin.deleteUser(userId, false);
    if (error) cleanupErrors.push(`${userId}: ${error.message}`);
  }
  if (cleanupErrors.length > 0) throw new Error(cleanupErrors.join(" | "));
}

let failed = false;
try {
  await createAccounts();
  await exerciseBoundaries();
} catch (error) {
  failed = true;
  record("authenticated boundary smoke suite", "FAIL", error instanceof Error ? error.message : String(error));
} finally {
  try {
    await cleanup();
    record("disposable account/domain/storage cleanup", "PASS");
  } catch (error) {
    failed = true;
    record("disposable account/domain/storage cleanup", "FAIL", error instanceof Error ? error.message : String(error));
  }
}

console.log(JSON.stringify({ runId, results }, null, 2));
if (failed) process.exitCode = 1;
