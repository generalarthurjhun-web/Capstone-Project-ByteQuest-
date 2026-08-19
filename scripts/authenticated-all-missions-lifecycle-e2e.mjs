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
  throw new Error("Supabase mission lifecycle E2E environment is unavailable.");
}

const requestedCoc = process.env.BYTEQUEST_COC?.trim().toLowerCase();
if (!requestedCoc || !["coc1", "coc2", "coc3", "coc4"].includes(requestedCoc)) {
  throw new Error("BYTEQUEST_COC must be one of coc1, coc2, coc3, or coc4.");
}
const packages = allRemainingMissionPackages.filter(
  (item) => item.cocCode === requestedCoc,
);
const service = createClient(url, serviceRoleKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});
const runId = `bq-${requestedCoc}-missions-${new Date().toISOString().replace(/\D/g, "").slice(0, 14)}-${randomUUID().slice(0, 8)}`;
const password = process.env.BYTEQUEST_E2E_PASSWORD;
if (!password) {
  throw new Error("BYTEQUEST_E2E_PASSWORD is required for authenticated lifecycle scripts.");
}
const accounts = [
  { key: "instructor1", role: "instructor", name: `${requestedCoc.toUpperCase()} Mission E2E Instructor One` },
  { key: "instructor2", role: "instructor", name: `${requestedCoc.toUpperCase()} Mission E2E Instructor Two` },
  { key: "learner", role: "learner", name: `${requestedCoc.toUpperCase()} Mission E2E Learner` },
].map((item) => ({
  ...item,
  email: `${runId}-${item.key}@bytequest-uat.invalid`,
}));

const users = new Map();
const clients = new Map();
const results = [];
const attemptIds = [];
const assignmentIds = [];
let classId;

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function record(name, status, detail = "") {
  results.push({ name, status, detail });
}

async function expectDenied(name, operation) {
  const response = await operation();
  if (!response?.error) throw new Error(`${name}: operation unexpectedly succeeded.`);
  record(name, "PASS", response.error.code ?? response.error.message);
}

async function createIdentities() {
  for (const account of accounts) {
    const { data, error } = await service.auth.admin.createUser({
      email: account.email,
      password,
      email_confirm: true,
      user_metadata: {
        full_name: account.name,
        bytequest_test_account: true,
        bytequest_test_run: runId,
        bytequest_test_kind: "all_missions_lifecycle",
      },
    });
    if (error || !data.user) throw new Error(error?.message ?? `Could not create ${account.key}.`);
    users.set(account.key, data.user.id);
    const { error: profileError } = await service
      .from("profiles")
      .update({ full_name: account.name, role: account.role, status: "active" })
      .eq("user_id", data.user.id);
    if (profileError) throw profileError;
    const client = createClient(url, publishableKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
    const { data: session, error: signInError } =
      await client.auth.signInWithPassword({ email: account.email, password });
    if (signInError || session.user?.id !== data.user.id) {
      throw new Error(signInError?.message ?? `${account.key} Auth/profile UUID mismatch.`);
    }
    clients.set(account.key, client);
  }
  record("disposable authenticated identities", "PASS", "Two Instructors and one Learner share Auth/profile UUIDs.");
}

async function resolvePublishedPackage(definition) {
  const { data, error } = await service
    .from("activity_versions")
    .select("id,status,learner_payload,rubric_versions(id,status,passing_rule)")
    .contains("learner_payload", { assessment_package_id: definition.packageId })
    .single();
  if (error) throw error;
  const rubric = data.rubric_versions.find((item) => item.status === "approved");
  assert(data.status === "published", `${definition.missionCode} activity is not published.`);
  assert(rubric, `${definition.missionCode} has no approved rubric.`);
  assert(
    rubric.passing_rule?.method === "all_required" &&
      rubric.passing_rule?.official_numeric_threshold === null,
    `${definition.missionCode} rubric does not use the approved all-required/no-threshold contract.`,
  );
  assert(
    data.learner_payload?.simulation_template === "authoritative_mission_v1",
    `${definition.missionCode} is not connected to the generalized Mobile assessment engine.`,
  );
  return { activityVersionId: data.id, rubricVersionId: rubric.id };
}

async function setupClass() {
  const instructor1 = clients.get("instructor1");
  const { data: classroom, error: classError } = await instructor1.rpc("create_class", {
    p_title: `${requestedCoc.toUpperCase()} mission lifecycle ${runId}`,
    p_class_code: `${requestedCoc.toUpperCase()}-${randomUUID().slice(0, 8)}`,
  });
  if (classError) throw classError;
  classId = classroom.id;
  const { error: enrollError } = await instructor1.rpc("enroll_learner", {
    p_class_id: classId,
    p_learner_id: users.get("learner"),
  });
  if (enrollError) throw enrollError;

  const { data: crossClass, error: crossClassError } = await clients
    .get("instructor2")
    .from("classes")
    .select("id")
    .eq("id", classId);
  assert(!crossClassError && crossClass.length === 0, "Instructor 2 read Instructor 1 class.");
  record("cross-Instructor class isolation", "PASS");
}

function actionsFor(definition, mode) {
  const criteria = buildRubricCriteria(definition);
  const actions = [];
  for (let criterionIndex = 0; criterionIndex < criteria.length; criterionIndex++) {
    const rule = criteria[criterionIndex].evidence_rule;
    if (mode === "incorrect_missing" && criterionIndex === criteria.length - 1) continue;
    const tamper = mode === "incorrect_missing" && criterionIndex === 0;
    if (rule.operator === "exact_target_sequence") {
      const targets = tamper ? [...rule.expected_targets].reverse() : rule.expected_targets;
      for (const target of targets) {
        actions.push([rule.action_type, target, {}]);
      }
    } else if (rule.operator === "final_action_value_set_equals") {
      const selected = tamper ? rule.expected.slice(0, -1) : rule.expected;
      actions.push([rule.action_type, null, { [rule.value_key]: selected }]);
    } else if (rule.operator === "final_action_value_equals") {
      actions.push([
        rule.action_type,
        null,
        { [rule.value_key]: tamper ? "__incorrect__" : rule.expected },
      ]);
    } else {
      throw new Error(`Unsupported E2E evidence operator ${rule.operator}.`);
    }
  }
  return actions;
}

async function startAndSubmit(assignmentId, definition, mode) {
  const learner = clients.get("learner");
  const startKey = randomUUID();
  const firstStart = await learner.rpc("start_attempt", {
    p_assignment_id: assignmentId,
    p_client_start_key: startKey,
  });
  if (firstStart.error) throw firstStart.error;
  const repeatedStart = await learner.rpc("start_attempt", {
    p_assignment_id: assignmentId,
    p_client_start_key: startKey,
  });
  assert(
    !repeatedStart.error && repeatedStart.data.id === firstStart.data.id,
    `${definition.missionCode} start_attempt is not idempotent.`,
  );

  let sequenceNumber = 1;
  for (const [actionType, target, value] of actionsFor(definition, mode)) {
    const occurredAt = new Date(Date.now() + sequenceNumber).toISOString();
    const response = await learner.rpc("append_attempt_action", {
      p_attempt_id: firstStart.data.id,
      p_sequence_number: sequenceNumber,
      p_action_type: actionType,
      p_target: target,
      p_value: {
        ...value,
        assessment_package_id: definition.packageId,
        local_mission_code: definition.localMissionCode,
      },
      p_client_occurred_at: occurredAt,
    });
    if (response.error) throw response.error;
    if (sequenceNumber === 1) {
      const retry = await learner.rpc("append_attempt_action", {
        p_attempt_id: firstStart.data.id,
        p_sequence_number: sequenceNumber,
        p_action_type: actionType,
        p_target: target,
        p_value: {
          ...value,
          assessment_package_id: definition.packageId,
          local_mission_code: definition.localMissionCode,
        },
        p_client_occurred_at: occurredAt,
      });
      assert(
        !retry.error && retry.data.id === response.data.id,
        `${definition.missionCode} action append is not idempotent.`,
      );
    }
    sequenceNumber += 1;
  }

  const submissionKey = randomUUID();
  const firstSubmit = await learner.rpc("submit_attempt", {
    p_attempt_id: firstStart.data.id,
    p_submission_key: submissionKey,
    p_elapsed_time_seconds: 300,
  });
  if (firstSubmit.error) throw firstSubmit.error;
  const repeatedSubmit = await learner.rpc("submit_attempt", {
    p_attempt_id: firstStart.data.id,
    p_submission_key: submissionKey,
    p_elapsed_time_seconds: 300,
  });
  assert(
    !repeatedSubmit.error && repeatedSubmit.data.id === firstSubmit.data.id,
    `${definition.missionCode} submission is not idempotent.`,
  );
  attemptIds.push(firstSubmit.data.id);
  return firstSubmit.data;
}

async function verifyCorrectAttempt(definition, attempt) {
  const instructor1 = clients.get("instructor1");
  const instructor2 = clients.get("instructor2");
  const learner = clients.get("learner");
  const criterionCount = definition.criteria.length;
  const { data: criterionResults, error: resultError } = await instructor1
    .from("criterion_results")
    .select("id,observation,rubric_criteria(criterion_code)")
    .eq("attempt_id", attempt.id);
  if (resultError) throw resultError;
  assert(
    criterionResults.length === criterionCount &&
      criterionResults.every((item) => item.observation === "satisfied"),
    `${definition.missionCode} correct evidence did not satisfy all ${criterionCount} criteria.`,
  );

  const { data: learnerRevision, error: learnerRevisionError } = await learner
    .from("score_revisions")
    .select("id")
    .eq("attempt_id", attempt.id);
  assert(!learnerRevisionError && learnerRevision.length === 0, `${definition.missionCode} exposed an unreleased revision.`);
  const { data: crossAttempt, error: crossAttemptError } = await instructor2
    .from("attempts")
    .select("id")
    .eq("id", attempt.id);
  assert(!crossAttemptError && crossAttempt.length === 0, `${definition.missionCode} leaked across Instructor scope.`);

  await expectDenied(`Learner cannot finalize ${definition.missionCode}`, () =>
    learner.rpc("finalize_attempt", {
      p_attempt_id: attempt.id,
      p_total_value: criterionCount,
      p_max_value: criterionCount,
      p_percentage: 100,
      p_outcome: "competent",
      p_criterion_values: [],
      p_reason: null,
      p_remarks: "Expected authorization denial.",
    }),
  );

  const { data: revisions, error: revisionError } = await instructor1
    .from("score_revisions")
    .select("*")
    .eq("attempt_id", attempt.id)
    .order("revision_number");
  if (revisionError) throw revisionError;
  const provisional = revisions[0];
  assert(
    revisions.length === 1 &&
      provisional.revision_type === "automated_provisional" &&
      provisional.outcome === "competent",
    `${definition.missionCode} provisional revision is incorrect.`,
  );

  const finalization = await instructor1.rpc("finalize_attempt", {
    p_attempt_id: attempt.id,
    p_total_value: provisional.total_value,
    p_max_value: provisional.max_value,
    p_percentage: provisional.percentage,
    p_outcome: provisional.outcome,
    p_criterion_values: provisional.criterion_values,
    p_reason: null,
    p_remarks: `Instructor confirmed ${definition.localMissionCode} automated evidence.`,
  });
  if (finalization.error) throw finalization.error;
  const release = await instructor1.rpc("release_attempt", {
    p_attempt_id: attempt.id,
    p_release_reason: `Release disposable ${definition.localMissionCode} lifecycle result.`,
  });
  if (release.error) throw release.error;
  const repeatedRelease = await instructor1.rpc("release_attempt", {
    p_attempt_id: attempt.id,
    p_release_reason: "Idempotent repeated release.",
  });
  assert(
    !repeatedRelease.error && repeatedRelease.data.id === release.data.id,
    `${definition.missionCode} release is not idempotent.`,
  );

  const { data: released, error: releasedError } = await learner
    .from("result_releases")
    .select("attempt_id,score_revisions(revision_type,outcome)")
    .eq("attempt_id", attempt.id)
    .eq("is_current", true);
  assert(
    !releasedError &&
      released.length === 1 &&
      released[0].score_revisions.revision_type === "instructor_final",
    `${definition.missionCode} released final result was not visible to the learner.`,
  );
  const { count: rewardCount, error: rewardError } = await service
    .from("gamification_events")
    .select("id", { count: "exact", head: true })
    .eq("source_id", attempt.id);
  if (rewardError) throw rewardError;
  assert(rewardCount === 1, `${definition.missionCode} did not award gamification exactly once.`);
}

async function verifyIncorrectAndMissing(definition, attempt) {
  const { data, error } = await clients
    .get("instructor1")
    .from("criterion_results")
    .select("observation,rubric_criteria(criterion_code)")
    .eq("attempt_id", attempt.id);
  if (error) throw error;
  assert(data.length === definition.criteria.length, `${definition.missionCode} did not create exact-once results for missing evidence.`);
  const failed = data.filter((item) => item.observation !== "satisfied");
  assert(failed.length >= 2, `${definition.missionCode} did not reject both incorrect and missing evidence.`);
}

async function runMission(definition) {
  const packageData = await resolvePublishedPackage(definition);
  const { data: assignment, error: assignmentError } = await clients
    .get("instructor1")
    .rpc("assign_activity", {
      p_class_id: classId,
      p_activity_version_id: packageData.activityVersionId,
      p_rubric_version_id: packageData.rubricVersionId,
      p_assignment_type: "assessment",
      p_title: `${definition.localMissionCode} lifecycle`,
      p_instructions: "Disposable evidence-based lifecycle test; no TESDA numeric threshold applies.",
      p_available_at: null,
      p_due_at: null,
    });
  if (assignmentError) throw assignmentError;
  assignmentIds.push(assignment.id);
  const policy = await clients.get("instructor1").rpc("configure_assignment_access", {
    p_assignment_id: assignment.id,
    p_attempts_allowed: null,
    p_retry_enabled: true,
    p_retry_after_seconds: null,
    p_prerequisite_assignment_id: null,
    p_reason: "Lifecycle suite requires one correct and one incorrect preserved attempt.",
  });
  if (policy.error) throw policy.error;

  const correct = await startAndSubmit(assignment.id, definition, "correct");
  await verifyCorrectAttempt(definition, correct);
  const incorrect = await startAndSubmit(assignment.id, definition, "incorrect_missing");
  await verifyIncorrectAndMissing(definition, incorrect);
  record(
    `${definition.missionCode} authoritative lifecycle`,
    "PASS",
    `${definition.criteria.length} correct criteria; incorrect and missing evidence rejected.`,
  );
}

async function verifyAnalytics() {
  const { data: attempts, error: attemptError } = await clients
    .get("instructor1")
    .from("attempts")
    .select("id,status,assignment_id")
    .in("id", attemptIds);
  if (attemptError) throw attemptError;
  assert(attempts.length === packages.length * 2, "Instructor analytics source is missing mission attempts.");
  const { data: progress, error: progressError } = await clients
    .get("instructor1")
    .from("learner_progress")
    .select("user_id,attempts_count,status")
    .eq("user_id", users.get("learner"));
  if (progressError) throw progressError;
  assert(progress.length >= packages.length, "Learner progress projections did not receive every mission.");
  record("real mission analytics/progress sources", "PASS", `${attempts.length} authoritative attempts queryable by the owning Instructor.`);
}

async function retireFixtures() {
  const instructor1 = clients.get("instructor1");
  for (const assignmentId of assignmentIds) {
    const response = await instructor1.rpc("close_assignment", {
      p_assignment_id: assignmentId,
      p_reason: "Close completed disposable mission lifecycle assignment.",
    });
    if (response.error) throw response.error;
  }
  const archive = await instructor1.rpc("archive_class", {
    p_class_id: classId,
    p_reason: "Archive completed disposable mission lifecycle class.",
  });
  if (archive.error) throw archive.error;
  for (const client of clients.values()) await client.auth.signOut();
  const now = new Date().toISOString();
  const ids = [...users.values()];
  const { error: profileError } = await service
    .from("profiles")
    .update({
      status: "deactivated",
      deactivated_at: now,
      deactivation_reason: `Retained disabled lifecycle identity for immutable test run ${runId}.`,
    })
    .in("user_id", ids);
  if (profileError) throw profileError;
  for (const id of ids) {
    const { error } = await service.auth.admin.updateUserById(id, {
      ban_duration: "876000h",
    });
    if (error) throw error;
  }
  const { count, error } = await service
    .from("attempts")
    .select("id", { count: "exact", head: true })
    .in("id", attemptIds);
  if (error) throw error;
  assert(count === attemptIds.length, "Fixture retirement removed immutable attempt history.");
  record("fixture retirement with history preservation", "PASS");
}

let failed = false;
try {
  await createIdentities();
  await setupClass();
  for (const definition of packages) await runMission(definition);
  await verifyAnalytics();
  await retireFixtures();
} catch (error) {
  failed = true;
  record(
    `${requestedCoc} authoritative mission lifecycle suite`,
    "FAIL",
    error instanceof Error ? error.message : String(error),
  );
}

console.log(JSON.stringify({ runId, requestedCoc, attemptIds, results }, null, 2));
if (failed) process.exitCode = 1;
