import { randomBytes, randomUUID } from "node:crypto";
import { createClient } from "@supabase/supabase-js";
import {
  allRemainingMissionPackages,
  buildRubricCriteria,
} from "./all-mission-assessment-packages.mjs";

const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
const publishableKey =
  process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ??
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !publishableKey || !serviceRoleKey) {
  throw new Error("Supabase Realtime E2E environment variables are unavailable.");
}

const service = createClient(url, serviceRoleKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});
const runId = `bq-realtime-${Date.now()}-${randomUUID().slice(0, 8)}`;
const password = process.env.BYTEQUEST_E2E_PASSWORD;
if (!password) {
  throw new Error("BYTEQUEST_E2E_PASSWORD is required for authenticated lifecycle scripts.");
}
const accountDefinitions = [
  { key: "instructor", role: "instructor", name: "Realtime E2E Instructor" },
  { key: "learnerA", role: "learner", name: "Realtime E2E Learner A" },
  { key: "learnerB", role: "learner", name: "Realtime E2E Learner B" },
];
const users = new Map();
const clients = new Map();
const channels = [];
const classIds = [];
const assignmentIds = [];
const attemptIds = [];
const resourceIds = [];
const storagePaths = [];
const results = [];

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function record(name, detail = "") {
  results.push({ name, status: "PASS", detail });
}

function delay(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

async function subscribe(client, table, event, filter, onPayload) {
  const channel = client
    .channel(`${runId}-${table}-${randomUUID()}`)
    .on(
      "postgres_changes",
      { event, schema: "public", table, ...(filter ? { filter } : {}) },
      onPayload,
    );
  channels.push({ client, channel });
  await new Promise((resolve, reject) => {
    const timeout = setTimeout(
      () => reject(new Error(`Realtime subscription timed out for ${table}.`)),
      12_000,
    );
    channel.subscribe((status, error) => {
      if (status === "SUBSCRIBED") {
        clearTimeout(timeout);
        resolve();
      } else if (status === "CHANNEL_ERROR" || status === "TIMED_OUT") {
        clearTimeout(timeout);
        reject(error ?? new Error(`${table} subscription failed: ${status}.`));
      }
    });
  });
}

async function waitFor(description, predicate, milliseconds = 8_000) {
  const started = Date.now();
  while (Date.now() - started < milliseconds) {
    if (predicate()) return;
    await delay(80);
  }
  throw new Error(`Timed out waiting for ${description}.`);
}

async function createIdentities() {
  for (const definition of accountDefinitions) {
    const email = `${runId}-${definition.key.toLowerCase()}@bytequest-e2e.invalid`;
    const created = await service.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: {
        full_name: definition.name,
        bytequest_test_account: true,
        bytequest_test_run: runId,
        bytequest_test_kind: "realtime_sync",
      },
    });
    if (created.error || !created.data.user) {
      throw new Error(created.error?.message ?? `Could not create ${definition.key}.`);
    }
    users.set(definition.key, created.data.user.id);
    const profile = await service
      .from("profiles")
      .update({ full_name: definition.name, role: definition.role, status: "active" })
      .eq("user_id", created.data.user.id);
    if (profile.error) throw profile.error;

    const client = createClient(url, publishableKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
    const signedIn = await client.auth.signInWithPassword({ email, password });
    if (signedIn.error || signedIn.data.user?.id !== created.data.user.id) {
      throw new Error(signedIn.error?.message ?? `${definition.key} login linkage failed.`);
    }
    // setAuth updates the Realtime transport asynchronously. Waiting here
    // prevents a newly subscribed channel from joining with the previous
    // anonymous token and missing the first scoped INSERT event.
    await client.realtime.setAuth(signedIn.data.session.access_token);
    clients.set(definition.key, client);
  }
  record("Disposable authenticated identities created", "One Instructor and two isolated Learners.");
}

async function resolvePublishedMission() {
  const definition = allRemainingMissionPackages.find((item) => item.cocCode === "coc1");
  assert(definition, "A published COC1 package is unavailable.");
  const response = await service
    .from("activity_versions")
    .select("id,status,learner_payload,rubric_versions(id,status)")
    .contains("learner_payload", { assessment_package_id: definition.packageId })
    .single();
  if (response.error) throw response.error;
  const rubric = response.data.rubric_versions.find((item) => item.status === "approved");
  assert(response.data.status === "published" && rubric, "Realtime mission package is not published.");
  return {
    definition,
    activityVersionId: response.data.id,
    rubricVersionId: rubric.id,
  };
}

function buildActions(definition) {
  const actions = [];
  for (const criterion of buildRubricCriteria(definition)) {
    const rule = criterion.evidence_rule;
    if (rule.operator === "exact_target_sequence") {
      for (const target of rule.expected_targets) {
        actions.push([rule.action_type, target, {}]);
      }
    } else if (rule.operator === "final_action_value_set_equals") {
      actions.push([rule.action_type, null, { [rule.value_key]: rule.expected }]);
    } else if (rule.operator === "final_action_value_equals") {
      actions.push([rule.action_type, null, { [rule.value_key]: rule.expected }]);
    } else {
      throw new Error(`Unsupported evidence operator ${rule.operator}.`);
    }
  }
  return actions;
}

async function exerciseRealtime() {
  const instructor = clients.get("instructor");
  const learnerA = clients.get("learnerA");
  const learnerB = clients.get("learnerB");
  assert(instructor && learnerA && learnerB, "Authenticated clients are missing.");

  const classA = await instructor.rpc("create_class", {
    p_title: `Realtime class A ${runId}`,
    p_class_code: `RTA-${randomUUID().slice(0, 8)}`,
  });
  const classB = await instructor.rpc("create_class", {
    p_title: `Realtime class B ${runId}`,
    p_class_code: `RTB-${randomUUID().slice(0, 8)}`,
  });
  if (classA.error || classB.error) throw classA.error ?? classB.error;
  classIds.push(classA.data.id, classB.data.id);

  const membershipEventsA = [];
  const membershipEventsB = [];
  await subscribe(
    learnerA,
    "class_memberships",
    "INSERT",
    `learner_id=eq.${users.get("learnerA")}`,
    (payload) => membershipEventsA.push(payload),
  );
  await subscribe(
    learnerB,
    "class_memberships",
    "INSERT",
    `learner_id=eq.${users.get("learnerB")}`,
    (payload) => membershipEventsB.push(payload),
  );
  const enrollA = await instructor.rpc("enroll_learner", {
    p_class_id: classA.data.id,
    p_learner_id: users.get("learnerA"),
  });
  if (enrollA.error) throw enrollA.error;
  await waitFor("Learner A enrollment event", () => membershipEventsA.length === 1);
  await delay(800);
  assert(membershipEventsB.length === 0, "Learner B received Learner A enrollment payload.");
  const enrollB = await instructor.rpc("enroll_learner", {
    p_class_id: classB.data.id,
    p_learner_id: users.get("learnerB"),
  });
  if (enrollB.error) throw enrollB.error;
  await waitFor("Learner B enrollment event", () => membershipEventsB.length === 1);
  record("Enrollment Realtime is learner-scoped", "Each Learner received only its own membership INSERT.");

  const assignmentEventsA = [];
  const assignmentEventsB = [];
  await subscribe(learnerA, "assignments", "INSERT", null, (payload) => assignmentEventsA.push(payload));
  await subscribe(learnerB, "assignments", "INSERT", null, (payload) => assignmentEventsB.push(payload));
  const mission = await resolvePublishedMission();
  const assignment = await instructor.rpc("assign_activity", {
    p_class_id: classA.data.id,
    p_activity_version_id: mission.activityVersionId,
    p_rubric_version_id: mission.rubricVersionId,
    p_assignment_type: "assessment",
    p_title: `Realtime authoritative mission ${runId}`,
    p_instructions: "Disposable scoped Realtime acceptance mission.",
    p_available_at: null,
    p_due_at: null,
  });
  if (assignment.error) throw assignment.error;
  assignmentIds.push(assignment.data.id);
  await waitFor("Learner A assignment event", () => assignmentEventsA.length === 1);
  await delay(800);
  assert(assignmentEventsB.length === 0, "Out-of-class Learner received assignment payload.");
  record("Assignment Realtime is class-scoped", "Authorized Learner received the assignment; isolated Learner received nothing.");

  const instructorAttemptEvents = [];
  await subscribe(
    instructor,
    "attempts",
    "*",
    `class_id=eq.${classA.data.id}`,
    (payload) => instructorAttemptEvents.push(payload),
  );
  const started = await learnerA.rpc("start_attempt", {
    p_assignment_id: assignment.data.id,
    p_client_start_key: randomUUID(),
  });
  if (started.error) throw started.error;
  attemptIds.push(started.data.id);
  await waitFor("Instructor attempt INSERT", () =>
    instructorAttemptEvents.some((event) => event.eventType === "INSERT"),
  );
  let sequence = 1;
  for (const [actionType, target, value] of buildActions(mission.definition)) {
    const appended = await learnerA.rpc("append_attempt_action", {
      p_attempt_id: started.data.id,
      p_sequence_number: sequence,
      p_action_type: actionType,
      p_target: target,
      p_value: value,
      p_client_occurred_at: new Date(Date.now() + sequence).toISOString(),
    });
    if (appended.error) throw appended.error;
    sequence += 1;
  }
  const submitted = await learnerA.rpc("submit_attempt", {
    p_attempt_id: started.data.id,
    p_submission_key: randomUUID(),
    p_elapsed_time_seconds: 180,
  });
  if (submitted.error) throw submitted.error;
  await waitFor("Instructor submitted-attempt UPDATE", () =>
    instructorAttemptEvents.some(
      (event) => event.eventType === "UPDATE" && event.new?.status === "evaluated",
    ),
  );
  record("Mission submission Realtime reaches owning Instructor", "Attempt INSERT and evaluated UPDATE were delivered.");

  const releaseEventsA = [];
  const releaseEventsB = [];
  await subscribe(learnerA, "result_releases", "INSERT", null, (payload) => releaseEventsA.push(payload));
  await subscribe(learnerB, "result_releases", "INSERT", null, (payload) => releaseEventsB.push(payload));
  const revisions = await instructor
    .from("score_revisions")
    .select("*")
    .eq("attempt_id", started.data.id)
    .order("revision_number");
  if (revisions.error || revisions.data.length !== 1) {
    throw new Error(revisions.error?.message ?? "Provisional revision was unavailable.");
  }
  const provisional = revisions.data[0];
  const finalized = await instructor.rpc("finalize_attempt", {
    p_attempt_id: started.data.id,
    p_total_value: provisional.total_value,
    p_max_value: provisional.max_value,
    p_percentage: provisional.percentage,
    p_outcome: provisional.outcome,
    p_criterion_values: provisional.criterion_values,
    p_reason: null,
    p_remarks: "Realtime E2E confirmation.",
  });
  if (finalized.error) throw finalized.error;
  const released = await instructor.rpc("release_attempt", {
    p_attempt_id: started.data.id,
    p_release_reason: "Realtime E2E release.",
  });
  if (released.error) throw released.error;
  await waitFor("Learner A release event", () => releaseEventsA.length === 1);
  await delay(800);
  assert(releaseEventsB.length === 0, "Learner B received Learner A result-release payload.");
  record("Released-result Realtime is learner-scoped", "Owning Learner received the release; isolated Learner received nothing.");

  const resourceEventsA = [];
  const resourceEventsB = [];
  await subscribe(learnerA, "learning_resources", "INSERT", null, (payload) => resourceEventsA.push(payload));
  await subscribe(learnerB, "learning_resources", "INSERT", null, (payload) => resourceEventsB.push(payload));
  const resourceId = randomUUID();
  const storagePath = `classes/${classA.data.id}/resources/${resourceId}/realtime-proof.pdf`;
  resourceIds.push(resourceId);
  storagePaths.push(storagePath);
  const bytes = new TextEncoder().encode("%PDF-1.4\n% ByteQuest scoped Realtime resource proof.\n");
  const uploaded = await service.storage
    .from("learning-resources")
    .upload(storagePath, bytes, { contentType: "application/pdf", upsert: false });
  if (uploaded.error) throw uploaded.error;
  const createdResource = await instructor.rpc("create_learning_resource", {
    p_resource_id: resourceId,
    p_class_id: classA.data.id,
    p_title: "Realtime scoped resource",
    p_description: "Disposable Realtime acceptance resource.",
    p_storage_path: storagePath,
    p_mime_type: "application/pdf",
    p_size_bytes: bytes.byteLength,
  });
  if (createdResource.error) throw createdResource.error;
  await waitFor("Learner A resource event", () => resourceEventsA.length === 1);
  await delay(800);
  assert(resourceEventsB.length === 0, "Out-of-class Learner received resource payload.");
  record("Resource Realtime is class-scoped", "Authorized Learner received metadata; isolated Learner received nothing.");
}

async function cleanup() {
  const errors = [];
  for (const { client, channel } of channels) {
    const response = await client.removeChannel(channel);
    if (response === "error") errors.push(`Could not remove channel ${channel.topic}.`);
  }
  if (storagePaths.length) {
    const response = await service.storage.from("learning-resources").remove(storagePaths);
    if (response.error && !response.error.message.toLowerCase().includes("not found")) {
      errors.push(response.error.message);
    }
  }
  const instructor = clients.get("instructor");
  if (instructor) {
    for (const resourceId of resourceIds) {
      const archived = await instructor.rpc("delete_learning_resource", {
        p_resource_id: resourceId,
        p_reason: "Retire completed disposable Realtime acceptance resource.",
      });
      if (archived.error) errors.push(`learning_resources: ${archived.error.message}`);
    }
    for (const classId of classIds) {
      const archived = await instructor.rpc("archive_class", {
        p_class_id: classId,
        p_reason: "Retire completed disposable Realtime acceptance class.",
      });
      if (archived.error) errors.push(`classes: ${archived.error.message}`);
    }
  }
  for (const client of clients.values()) await client.auth.signOut();
  const now = new Date().toISOString();
  const userIds = Array.from(users.values());
  if (userIds.length) {
    const profiles = await service
      .from("profiles")
      .update({
        status: "deactivated",
        deactivated_at: now,
        deactivation_reason: `Retained disabled Realtime identity for immutable test run ${runId}.`,
      })
      .in("user_id", userIds);
    if (profiles.error) errors.push(`profiles: ${profiles.error.message}`);
  }
  for (const userId of userIds) {
    const response = await service.auth.admin.updateUserById(userId, { ban_duration: "876000h" });
    if (response.error) errors.push(`Auth retirement: ${response.error.message}`);
  }
  if (errors.length) throw new Error(errors.join(" | "));
}

let failed = false;
try {
  await createIdentities();
  await exerciseRealtime();
} catch (error) {
  failed = true;
  results.push({
    name: "Authenticated scoped Realtime synchronization",
    status: "FAIL",
    detail: error instanceof Error ? error.message : String(error),
  });
} finally {
  try {
    await cleanup();
    record("Disposable Realtime test data cleanup");
  } catch (error) {
    failed = true;
    results.push({
      name: "Disposable Realtime test data cleanup",
      status: "FAIL",
      detail: error instanceof Error ? error.message : String(error),
    });
  }
}

console.log(JSON.stringify({ runId, results }, null, 2));
if (failed) process.exitCode = 1;
