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

const service = createClient(url, serviceRoleKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});
const runId = `bq-coc2-uat-${new Date().toISOString().replace(/\D/g, "").slice(0, 14)}-${randomUUID().slice(0, 8)}`;
const password = process.env.BYTEQUEST_E2E_PASSWORD;
if (!password) {
  throw new Error("BYTEQUEST_E2E_PASSWORD is required for authenticated lifecycle scripts.");
}
const domain = "bytequest-uat.invalid";
const accounts = [
  { key: "admin", role: "admin", name: "ByteQuest COC2 UAT Admin" },
  { key: "instructor1", role: "instructor", name: "ByteQuest COC2 UAT Instructor One" },
  { key: "instructor2", role: "instructor", name: "ByteQuest COC2 UAT Instructor Two" },
  { key: "learnerA", role: "learner", name: "ByteQuest COC2 UAT Learner A" },
  { key: "learnerB", role: "learner", name: "ByteQuest COC2 UAT Learner B" },
].map((account) => ({
  ...account,
  email: `${runId}-${account.key.toLowerCase()}@${domain}`,
}));

const users = new Map();
const clients = new Map();
const results = [];
let classId;
let resourceId;
let storagePath;

function record(name, status, detail = "") {
  results.push({ name, status, detail });
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function errorDetail(error) {
  if (error instanceof Error) return error.message;
  try {
    return JSON.stringify(error);
  } catch {
    return String(error);
  }
}

async function retireIncompleteUatRuns() {
  const { data, error } = await service
    .from("profiles")
    .select("user_id,email")
    .like("email", "bq-coc2-uat-%@bytequest-uat.invalid");
  if (error) throw error;
  const staleByRun = new Map();
  for (const profile of data) {
    const match = profile.email?.match(
      /^(bq-coc2-uat-\d+-[0-9a-f]+)-(admin|instructor1|instructor2|learnera|learnerb)@bytequest-uat\.invalid$/,
    );
    if (!match) continue;
    const staleRun = match[1];
    const list = staleByRun.get(staleRun) ?? [];
    list.push({ id: profile.user_id, email: profile.email });
    staleByRun.set(staleRun, list);
  }

  for (const [staleRun, staleUsers] of staleByRun) {
    const staleIds = staleUsers.map((user) => user.id);
    const instructorIds = staleUsers
      .filter((user) => user.email?.includes("instructor"))
      .map((user) => user.id);
    if (instructorIds.length > 0) {
      const { data: staleClasses } = await service
        .from("classes")
        .select("id")
        .in("instructor_id", instructorIds);
      const classIds = (staleClasses ?? []).map((row) => row.id);
      if (classIds.length > 0) {
        const now = new Date().toISOString();
        const { data: resources } = await service
          .from("learning_resources")
          .select("id,storage_bucket,storage_path")
          .in("class_id", classIds);
        for (const resource of resources ?? []) {
          await service.storage.from(resource.storage_bucket).remove([resource.storage_path]);
        }
        const resourceUpdate = await service
          .from("learning_resources")
          .update({
            status: "deleted",
            deleted_at: now,
            deleted_by: instructorIds[0],
            deletion_reason: "Incomplete disposable UAT run retired.",
          })
          .in("class_id", classIds)
          .eq("status", "active");
        if (resourceUpdate.error) throw resourceUpdate.error;
        const assignmentUpdate = await service
          .from("assignments")
          .update({ status: "closed", closed_at: now, close_reason: "Incomplete disposable UAT run retired." })
          .in("class_id", classIds);
        if (assignmentUpdate.error) throw assignmentUpdate.error;
        const membershipUpdate = await service
          .from("class_memberships")
          .update({
            status: "deactivated",
            deactivated_by: instructorIds[0],
            deactivated_at: now,
            deactivation_reason: "Incomplete disposable UAT run retired.",
          })
          .in("class_id", classIds);
        if (membershipUpdate.error) throw membershipUpdate.error;
        const classUpdate = await service
          .from("classes")
          .update({
            status: "archived",
            archived_by: instructorIds[0],
            archived_at: now,
            archive_reason: "Incomplete disposable UAT run retired.",
          })
          .in("id", classIds);
        if (classUpdate.error) throw classUpdate.error;
      }
    }
    const now = new Date().toISOString();
    const { error: profileError } = await service
      .from("profiles")
      .update({
        status: "deactivated",
        deactivated_at: now,
        deactivation_reason: `Incomplete disposable UAT run ${staleRun} retired safely.`,
      })
      .in("user_id", staleIds);
    if (profileError) throw profileError;
    for (const user of staleUsers) {
      const { error: banError } = await service.auth.admin.updateUserById(user.id, {
        ban_duration: "876000h",
      });
      if (banError) throw banError;
    }
  }
}

async function expectDenied(name, operation) {
  const response = await operation();
  if (!response?.error) throw new Error(`${name}: operation unexpectedly succeeded`);
  record(name, "PASS", response.error.code ?? response.error.message);
}

async function createAccounts() {
  for (const account of accounts) {
    const { data, error } = await service.auth.admin.createUser({
      email: account.email,
      password,
      email_confirm: true,
      user_metadata: {
        full_name: account.name,
        bytequest_test_account: true,
        bytequest_test_run: runId,
        bytequest_test_kind: "coc2_acceptance",
      },
    });
    if (error || !data.user) throw new Error(error?.message ?? `Could not create ${account.key}`);
    users.set(account.key, data.user.id);
    const { error: profileError } = await service
      .from("profiles")
      .update({ full_name: account.name, role: account.role, status: "active" })
      .eq("user_id", data.user.id);
    if (profileError) throw profileError;
    const client = createClient(url, publishableKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
    const { data: session, error: signInError } = await client.auth.signInWithPassword({
      email: account.email,
      password,
    });
    if (signInError || session.user?.id !== data.user.id) {
      throw new Error(signInError?.message ?? `${account.key} UUID mismatch`);
    }
    clients.set(account.key, client);
  }
  record("five disposable authenticated identities share Auth/profile UUIDs", "PASS");
}

async function getPublishedPackage() {
  const { data, error } = await service
    .from("activity_versions")
    .select("id,module_version_id,module_versions(tesda_source_id),rubric_versions(id,status)")
    .contains("learner_payload", { assessment_package_id: "coc2-cable-termination-testing-v1" })
    .eq("status", "published")
    .single();
  if (error) throw error;
  const rubric = data.rubric_versions.find((row) => row.status === "approved");
  assert(rubric, "Approved COC2 rubric was not found");
  return {
    activityVersionId: data.id,
    rubricVersionId: rubric.id,
    tesdaSourceId: data.module_versions.tesda_source_id,
  };
}

async function setupClass(packageData) {
  const instructor1 = clients.get("instructor1");
  const instructor2 = clients.get("instructor2");
  const { data: classroom, error: classError } = await instructor1.rpc("create_class", {
    p_title: `COC2 acceptance class — ${runId}`,
    p_class_code: `COC2-${randomUUID().slice(0, 8)}`,
  });
  if (classError) throw classError;
  classId = classroom.id;

  for (const learner of ["learnerA", "learnerB"]) {
    const { error } = await instructor1.rpc("enroll_learner", {
      p_class_id: classId,
      p_learner_id: users.get(learner),
    });
    if (error) throw error;
  }

  const { data: assignment, error: assignmentError } = await instructor1.rpc("assign_activity", {
    p_class_id: classId,
    p_activity_version_id: packageData.activityVersionId,
    p_rubric_version_id: packageData.rubricVersionId,
    p_assignment_type: "assessment",
    p_title: "COC2 cable termination UAT",
    p_instructions: "UAT-only authoritative assessment. No TESDA numeric threshold applies.",
    p_available_at: null,
    p_due_at: null,
  });
  if (assignmentError) throw assignmentError;
  const assignments = [assignment, assignment];

  const { error: policyError } = await instructor1.rpc("configure_assignment_access", {
    p_assignment_id: assignments[0].id,
    p_attempts_allowed: null,
    p_retry_enabled: true,
    p_retry_after_seconds: null,
    p_prerequisite_assignment_id: null,
    p_reason: "UAT confirms null means no configured institutional attempt limit.",
  });
  if (policyError) throw policyError;

  const { data: hiddenClass, error: hiddenClassError } = await instructor2
    .from("classes")
    .select("id")
    .eq("id", classId);
  assert(!hiddenClassError && hiddenClass.length === 0, "Instructor 2 read Instructor 1 class");
  await expectDenied("Instructor 2 cannot configure Instructor 1 assignment", () =>
    instructor2.rpc("configure_assignment_access", {
      p_assignment_id: assignments[0].id,
      p_attempts_allowed: 1,
      p_retry_enabled: false,
      p_retry_after_seconds: null,
      p_prerequisite_assignment_id: null,
      p_reason: "Expected denial from out-of-scope Instructor.",
    }),
  );
  record("Instructor 1 creates scoped class, enrollments, COC2 assignments, and nullable retry policy", "PASS");
  return assignments;
}

async function setupResource() {
  const instructor1 = clients.get("instructor1");
  const instructor2 = clients.get("instructor2");
  const learnerA = clients.get("learnerA");
  const pdfBytes = new TextEncoder().encode("%PDF-1.4\n% ByteQuest COC2 UAT resource\n%%EOF\n");
  resourceId = randomUUID();
  storagePath = `classes/${classId}/resources/${resourceId}/coc2-cable-guide.pdf`;
  const upload = await service.storage.from("learning-resources").upload(storagePath, pdfBytes, {
    contentType: "application/pdf",
    upsert: false,
  });
  if (upload.error) throw upload.error;
  const { data, error } = await instructor1.rpc("create_learning_resource", {
    p_resource_id: resourceId,
    p_class_id: classId,
    p_title: "COC2 cable-termination reference guide",
    p_description: "UAT resource used to verify private assigned learner access.",
    p_storage_path: storagePath,
    p_mime_type: "application/pdf",
    p_size_bytes: pdfBytes.byteLength,
  });
  if (error) throw error;
  resourceId = data.id;

  const learnerSigned = await learnerA.storage
    .from("learning-resources")
    .createSignedUrl(storagePath, 120);
  assert(!learnerSigned.error && learnerSigned.data?.signedUrl, "Learner A could not access assigned private resource");
  await expectDenied("Instructor 2 cannot access Instructor 1 private resource", () =>
    instructor2.storage.from("learning-resources").createSignedUrl(storagePath, 120),
  );
  record("private PDF resource upload, metadata, learner access, and cross-Instructor denial", "PASS");
}

const correctActions = [
  ["ppe_selection_submitted", null, { selected_items: ["working_clothes", "gloves", "goggles"] }],
  ["tools_materials_selection_submitted", null, { selected_items: ["lan_cable_tester", "copper_cable", "wire_stripper", "rj45_connector", "crimping_tool"] }],
  ["cable_preparation_step", "measure_cable", {}],
  ["cable_preparation_step", "strip_jacket", {}],
  ["cable_preparation_step", "untwist_and_straighten", {}],
  ["conductor_placed", "white_orange", { pin: 1, standard_scenario: "T568B" }],
  ["conductor_placed", "orange", { pin: 2, standard_scenario: "T568B" }],
  ["conductor_placed", "white_green", { pin: 3, standard_scenario: "T568B" }],
  ["conductor_placed", "blue", { pin: 4, standard_scenario: "T568B" }],
  ["conductor_placed", "white_blue", { pin: 5, standard_scenario: "T568B" }],
  ["conductor_placed", "green", { pin: 6, standard_scenario: "T568B" }],
  ["conductor_placed", "white_brown", { pin: 7, standard_scenario: "T568B" }],
  ["conductor_placed", "brown", { pin: 8, standard_scenario: "T568B" }],
  ["termination_step", "insert_conductors", {}],
  ["termination_step", "verify_jacket_depth", {}],
  ["termination_step", "crimp_connector", {}],
  ["tester_step", "connect_both_ends", {}],
  ["tester_step", "power_on_tester", {}],
  ["tester_step", "observe_indicator_sequence", {}],
  ["tester_result_submitted", null, { result: "pass" }],
  ["inspection_selection_submitted", null, { selected_items: ["no_visible_damage", "pin_order_compliant", "connector_secure"] }],
  ["cleanup_selection_submitted", null, { selected_items: ["tools_returned", "work_area_cleared", "scraps_sorted"] }],
  ["simulation_completed", null, { completion_signal: true }],
];

async function createAttempt(client, assignmentId, actions, swapConductors = false) {
  const startKey = randomUUID();
  const submissionKey = randomUUID();
  const firstStart = await client.rpc("start_attempt", {
    p_assignment_id: assignmentId,
    p_client_start_key: startKey,
  });
  if (firstStart.error) throw firstStart.error;
  const secondStart = await client.rpc("start_attempt", {
    p_assignment_id: assignmentId,
    p_client_start_key: startKey,
  });
  assert(!secondStart.error && secondStart.data.id === firstStart.data.id, "Attempt start was not idempotent");

  const actionList = actions.map((action) => [action[0], action[1], { ...action[2] }]);
  if (swapConductors) {
    const first = actionList.findIndex((action) => action[0] === "conductor_placed");
    [actionList[first][1], actionList[first + 1][1]] = [actionList[first + 1][1], actionList[first][1]];
  }
  let sequence = 1;
  for (const [actionType, target, value] of actionList) {
    const occurredAt = new Date(Date.now() + sequence).toISOString();
    const response = await client.rpc("append_attempt_action", {
      p_attempt_id: firstStart.data.id,
      p_sequence_number: sequence,
      p_action_type: actionType,
      p_target: target,
      p_value: {
        ...value,
        assessment_package_id: "coc2-cable-termination-testing-v1",
      },
      p_client_occurred_at: occurredAt,
    });
    if (response.error) throw response.error;
    if (sequence === 1) {
      const retry = await client.rpc("append_attempt_action", {
        p_attempt_id: firstStart.data.id,
        p_sequence_number: sequence,
        p_action_type: actionType,
        p_target: target,
        p_value: {
          ...value,
          assessment_package_id: "coc2-cable-termination-testing-v1",
        },
        p_client_occurred_at: occurredAt,
      });
      assert(!retry.error && retry.data.id === response.data.id, "Action append was not idempotent");
    }
    sequence++;
  }

  const submission = await client.rpc("submit_attempt", {
    p_attempt_id: firstStart.data.id,
    p_submission_key: submissionKey,
    p_elapsed_time_seconds: 420,
  });
  if (submission.error) throw submission.error;
  const retrySubmission = await client.rpc("submit_attempt", {
    p_attempt_id: firstStart.data.id,
    p_submission_key: submissionKey,
    p_elapsed_time_seconds: 420,
  });
  assert(!retrySubmission.error && retrySubmission.data.id === submission.data.id, "Submission retry was not idempotent");
  return submission.data;
}

async function verifyAndFinalize(attemptA, attemptB) {
  const learnerA = clients.get("learnerA");
  const learnerB = clients.get("learnerB");
  const instructor1 = clients.get("instructor1");
  const instructor2 = clients.get("instructor2");
  const admin = clients.get("admin");

  const { data: criteriaA, error: criteriaAError } = await instructor1
    .from("criterion_results")
    .select("id,observation,score_value,rubric_criteria(criterion_code,title)")
    .eq("attempt_id", attemptA.id);
  if (criteriaAError) throw criteriaAError;
  assert(criteriaA.length === 9 && criteriaA.every((row) => row.observation === "satisfied"), "Correct evidence did not satisfy all nine criteria");

  const { data: criteriaB, error: criteriaBError } = await instructor1
    .from("criterion_results")
    .select("id,observation,rubric_criteria(criterion_code)")
    .eq("attempt_id", attemptB.id);
  if (criteriaBError) throw criteriaBError;
  const failedB = criteriaB.filter((row) => row.observation !== "satisfied");
  assert(failedB.length === 1 && failedB[0].rubric_criteria.criterion_code === "COC2-CABLE-04-T568B-ORDER", "Wrong chronological conductor order was not isolated correctly");

  const learnerProvisional = await learnerA.from("score_revisions").select("id").eq("attempt_id", attemptA.id);
  assert(!learnerProvisional.error && learnerProvisional.data.length === 0, "Learner saw unreleased provisional revision");
  const crossLearner = await learnerB.from("attempts").select("id").eq("id", attemptA.id);
  assert(!crossLearner.error && crossLearner.data.length === 0, "Learner B read Learner A attempt");
  const crossInstructor = await instructor2.from("attempts").select("id").eq("id", attemptA.id);
  assert(!crossInstructor.error && crossInstructor.data.length === 0, "Instructor 2 read Instructor 1 attempt");
  await expectDenied("Learner cannot finalize COC2 result", () =>
    learnerA.rpc("finalize_attempt", {
      p_attempt_id: attemptA.id,
      p_total_value: 9,
      p_max_value: 9,
      p_percentage: 100,
      p_outcome: "competent",
      p_criterion_values: [],
      p_reason: null,
      p_remarks: "forbidden learner finalization",
    }),
  );
  await expectDenied("Admin cannot perform routine Instructor finalization", () =>
    admin.rpc("finalize_attempt", {
      p_attempt_id: attemptA.id,
      p_total_value: 9,
      p_max_value: 9,
      p_percentage: 100,
      p_outcome: "competent",
      p_criterion_values: [],
      p_reason: null,
      p_remarks: "forbidden admin routine finalization",
    }),
  );

  const revisions = {};
  for (const [key, attempt] of [["A", attemptA], ["B", attemptB]]) {
    const { data, error } = await instructor1
      .from("score_revisions")
      .select("*")
      .eq("attempt_id", attempt.id)
      .order("revision_number", { ascending: true });
    if (error) throw error;
    revisions[key] = data[0];
  }
  assert(revisions.A.outcome === "competent" && revisions.A.total_value === 9, "Attempt A provisional outcome is wrong");
  assert(revisions.B.outcome === "not_yet_competent" && revisions.B.total_value === 8, "Attempt B provisional outcome is wrong");

  const finalA = await instructor1.rpc("finalize_attempt", {
    p_attempt_id: attemptA.id,
    p_total_value: revisions.A.total_value,
    p_max_value: revisions.A.max_value,
    p_percentage: revisions.A.percentage,
    p_outcome: revisions.A.outcome,
    p_criterion_values: revisions.A.criterion_values,
    p_reason: null,
    p_remarks: "Instructor confirmed the automated evidence review.",
  });
  if (finalA.error) throw finalA.error;

  await expectDenied("Instructor adjustment requires a reason", () =>
    instructor1.rpc("finalize_attempt", {
      p_attempt_id: attemptB.id,
      p_total_value: 9,
      p_max_value: 9,
      p_percentage: 100,
      p_outcome: "competent",
      p_criterion_values: revisions.B.criterion_values,
      p_reason: null,
      p_remarks: "Expected denial for missing reason.",
    }),
  );
  const finalB = await instructor1.rpc("finalize_attempt", {
    p_attempt_id: attemptB.id,
    p_total_value: 9,
    p_max_value: 9,
    p_percentage: 100,
    p_outcome: "competent",
    p_criterion_values: revisions.B.criterion_values,
    p_reason: "UAT-only Instructor adjustment to prove append-only revision and mandatory-reason behavior.",
    p_remarks: "Disposable acceptance attempt; automated sequence evidence remains preserved.",
  });
  if (finalB.error) throw finalB.error;

  for (const attempt of [attemptA, attemptB]) {
    const first = await instructor1.rpc("release_attempt", {
      p_attempt_id: attempt.id,
      p_release_reason: "Release disposable COC2 UAT result to the learner.",
    });
    if (first.error) throw first.error;
    const second = await instructor1.rpc("release_attempt", {
      p_attempt_id: attempt.id,
      p_release_reason: "Idempotent repeated release.",
    });
    assert(!second.error && second.data.id === first.data.id, "Release was not idempotent");
  }

  const releasedA = await learnerA
    .from("result_releases")
    .select("attempt_id,score_revisions(revision_type,outcome,percentage)")
    .eq("attempt_id", attemptA.id)
    .eq("is_current", true);
  assert(!releasedA.error && releasedA.data.length === 1 && releasedA.data[0].score_revisions.revision_type === "instructor_final", "Learner A did not receive the released final revision");

  const { count: resultCount } = await service
    .from("criterion_results")
    .select("id", { count: "exact", head: true })
    .in("attempt_id", [attemptA.id, attemptB.id]);
  const { count: rewardCount } = await service
    .from("gamification_events")
    .select("id", { count: "exact", head: true })
    .in("source_id", [attemptA.id, attemptB.id]);
  assert(resultCount === 18, `Expected 18 exact-once criterion results; got ${resultCount}`);
  assert(rewardCount === 2, `Expected one gamification event per release; got ${rewardCount}`);

  const { data: historyB } = await instructor1
    .from("score_revisions")
    .select("revision_number,revision_type,reason")
    .eq("attempt_id", attemptB.id)
    .order("revision_number");
  assert(
    historyB.length === 3 &&
      historyB[0].revision_type === "automated_provisional" &&
      historyB[1].revision_type === "instructor_adjustment" &&
      historyB[2].revision_type === "instructor_final",
    "Adjustment/final revision history was not preserved",
  );
  record("ordered PostgreSQL evaluation, withholding, review, adjustment reason, finalization, release, progress, and exact-once gamification", "PASS");
}

async function verifyAnalyticsAndAudit(attemptIds) {
  const instructor1 = clients.get("instructor1");
  const admin = clients.get("admin");
  const { data: attempts, error: attemptsError } = await instructor1
    .from("attempts")
    .select("id,status,learner_id,assignment_id")
    .in("id", attemptIds);
  if (attemptsError) throw attemptsError;
  assert(attempts.length === 2 && attempts.every((attempt) => attempt.status === "released"), "Instructor analytics source attempts are incomplete");
  const { data: progress, error: progressError } = await instructor1
    .from("learner_progress")
    .select("user_id,status,attempts_count,latest_score")
    .in("user_id", [users.get("learnerA"), users.get("learnerB")]);
  if (progressError) throw progressError;
  assert(progress.length >= 2, "Real learner progress projections were not queryable");
  const { data: audits, error: auditError } = await admin
    .from("audit_events")
    .select("action,actor_id,actor_role,target_id,outcome")
    .in("target_id", attemptIds)
    .in("action", ["attempt.started", "attempt.provisional_evaluation_recorded", "score.adjusted", "score.finalized", "result.released"]);
  if (auditError) throw auditError;
  const actions = new Set(audits.map((row) => row.action));
  for (const action of ["attempt.started", "attempt.provisional_evaluation_recorded", "score.adjusted", "score.finalized", "result.released"]) {
    assert(actions.has(action), `Audit action ${action} is missing`);
  }
  record("Instructor analytics projections and Admin audit use the real authoritative UAT attempts", "PASS");
}

async function archiveAndRetireTestIdentities(attemptIds) {
  const instructor1 = clients.get("instructor1");
  const admin = clients.get("admin");
  if (resourceId) {
    const archive = await instructor1.rpc("delete_learning_resource", {
      p_resource_id: resourceId,
      p_reason: "Archive the disposable COC2 UAT resource after verification.",
    });
    if (archive.error) throw archive.error;
    const hidden = await clients
      .get("learnerA")
      .storage.from("learning-resources")
      .createSignedUrl(storagePath, 60);
    assert(hidden.error, "Archived resource remained downloadable by learner");
    const removeObject = await service.storage.from("learning-resources").remove([storagePath]);
    if (removeObject.error && !removeObject.error.message.toLowerCase().includes("not found")) {
      throw removeObject.error;
    }
  }
  for (const learner of ["learnerA", "learnerB"]) {
    const response = await instructor1.rpc("instructor_deactivate_learner_account", {
      p_learner_id: users.get(learner),
      p_reason: "Deactivate disposable COC2 UAT learner after acceptance verification.",
    });
    if (response.error) throw response.error;
  }
  const readiness = await admin.rpc("admin_account_removal_readiness", {
    p_user_id: users.get("learnerA"),
  });
  if (readiness.error) throw readiness.error;
  assert(readiness.data?.safe_to_remove === false, "Admin removal readiness ignored retained assessment history");
  record("Admin permanent removal readiness blocks a deactivated learner with retained history", "PASS");

  const { data: activeAssignments, error: activeAssignmentsError } = await instructor1
    .from("assignments")
    .select("id")
    .eq("class_id", classId)
    .eq("status", "active");
  if (activeAssignmentsError) throw activeAssignmentsError;
  for (const assignment of activeAssignments ?? []) {
    const closeAssignment = await instructor1.rpc("close_assignment", {
      p_assignment_id: assignment.id,
      p_reason: "Close the disposable COC2 UAT assignment after verification.",
    });
    if (closeAssignment.error) throw closeAssignment.error;
  }

  const archiveClass = await instructor1.rpc("archive_class", {
    p_class_id: classId,
    p_reason: "Archive the completed disposable COC2 acceptance class.",
  });
  if (archiveClass.error) throw archiveClass.error;

  for (const staff of ["instructor1", "instructor2"]) {
    const response = await admin.rpc("admin_set_account_status", {
      p_user_id: users.get(staff),
      p_status: "deactivated",
      p_reason: "Retire disposable COC2 UAT staff identity.",
    });
    if (response.error) throw response.error;
  }
  for (const client of clients.values()) await client.auth.signOut();
  const now = new Date().toISOString();
  const { error: retireProfilesError } = await service
    .from("profiles")
    .update({
      status: "deactivated",
      deactivated_at: now,
      deactivation_reason: `Retained disabled UAT identity for immutable run ${runId}.`,
    })
    .in("user_id", Array.from(users.values()));
  if (retireProfilesError) throw retireProfilesError;
  for (const userId of users.values()) {
    const { error } = await service.auth.admin.updateUserById(userId, { ban_duration: "876000h" });
    if (error) throw error;
  }
  const { count: retainedAttempts } = await service
    .from("attempts")
    .select("id", { count: "exact", head: true })
    .in("id", attemptIds);
  assert(retainedAttempts === 2, "Retiring test identities removed immutable attempts");
  record("UAT class/resource archived and all test identities disabled while evidence history remains preserved", "PASS");
}

let failed = false;
let attemptIds = [];
try {
  await retireIncompleteUatRuns();
  if (process.env.BYTEQUEST_RETIRE_ONLY === "1") {
    record("previous disposable COC2 UAT artifacts retired without creating a new run", "PASS");
  } else {
    await createAccounts();
    const packageData = await getPublishedPackage();
    record("active TESDA source, published activity, and approved all-required rubric resolved", "PASS");
    const assignments = await setupClass(packageData);
    await setupResource();
    const attemptA = await createAttempt(clients.get("learnerA"), assignments[0].id, correctActions, false);
    const attemptB = await createAttempt(clients.get("learnerB"), assignments[1].id, correctActions, true);
    attemptIds = [attemptA.id, attemptB.id];
    record("Learner evidence writes, start retry, action retry, and submission retry are idempotent", "PASS");
    await verifyAndFinalize(attemptA, attemptB);
    await verifyAnalyticsAndAudit(attemptIds);
    await archiveAndRetireTestIdentities(attemptIds);
  }
} catch (error) {
  failed = true;
  record("authenticated COC2 lifecycle suite", "FAIL", errorDetail(error));
}

console.log(JSON.stringify({ runId, attemptIds, results }, null, 2));
if (failed) process.exitCode = 1;
