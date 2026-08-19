import { randomBytes, randomUUID } from "node:crypto";
import { execFileSync } from "node:child_process";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { createClient } from "@supabase/supabase-js";

const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
const publicKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ?? process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !publicKey || !serviceKey) throw new Error("Supabase E2E configuration is unavailable.");

const repositoryRoot = fileURLToPath(new URL("..", import.meta.url));

const runId = `quiz-learner-e2e-${new Date().toISOString().replace(/\D/g, "").slice(0, 14)}-${randomUUID().slice(0, 8)}`;
const password = process.env.BYTEQUEST_E2E_PASSWORD;
if (!password) {
  throw new Error("BYTEQUEST_E2E_PASSWORD is required for authenticated lifecycle scripts.");
}
const service = createClient(url, serviceKey, { auth: { autoRefreshToken: false, persistSession: false } });
const users = new Map();
const clients = new Map();
const classIds = [];
const quizIds = [];
const results = [];
const realtimeChannels = [];

function record(name, detail = "") { results.push({ name, status: "PASS", detail }); }
function assert(condition, message) { if (!condition) throw new Error(message); }
function delay(milliseconds) { return new Promise((resolve) => setTimeout(resolve, milliseconds)); }

async function subscribe(client, table, event, callback) {
  const channel = client
    .channel(`${runId}-${table}-${randomUUID()}`)
    .on("postgres_changes", { event, schema: "public", table }, callback);
  realtimeChannels.push({ client, channel });
  await new Promise((resolve, reject) => {
    const timeout = setTimeout(() => reject(new Error(`${table} Realtime subscription timed out`)), 12_000);
    channel.subscribe((status, error) => {
      if (status === "SUBSCRIBED") {
        clearTimeout(timeout);
        resolve();
      } else if (status === "CHANNEL_ERROR" || status === "TIMED_OUT") {
        clearTimeout(timeout);
        reject(error ?? new Error(`${table} Realtime subscription failed`));
      }
    });
  });
}

async function waitFor(description, predicate) {
  const started = Date.now();
  while (Date.now() - started < 8_000) {
    if (predicate()) return;
    await delay(80);
  }
  throw new Error(`Timed out waiting for ${description}`);
}

async function denied(name, operation) {
  const response = await operation();
  if (!response?.error) throw new Error(`${name}: operation unexpectedly succeeded`);
  record(name, response.error.code ?? response.error.message);
}

async function createAccount(key, role) {
  const email = `${runId}-${key.toLowerCase()}@bytequest-e2e.invalid`;
  const { data, error } = await service.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: { full_name: `ByteQuest Quiz ${key}`, bytequest_test_account: true, bytequest_test_run: runId },
  });
  if (error || !data.user) throw new Error(`Could not create ${key}: ${error?.message ?? "missing user"}`);
  users.set(key, data.user.id);
  const configured = await service.from("profiles").update({ role, status: "active" }).eq("user_id", data.user.id);
  if (configured.error) throw new Error(`Could not configure ${key}: ${configured.error.message}`);
  const client = createClient(url, publicKey, { auth: { autoRefreshToken: false, persistSession: false } });
  const session = await client.auth.signInWithPassword({ email, password });
  if (session.error || session.data.user?.id !== data.user.id) throw new Error(`Could not authenticate ${key}`);
  client.realtime.setAuth(session.data.session.access_token);
  clients.set(key, client);
}

async function createFixtures() {
  await createAccount("Instructor", "instructor");
  await createAccount("LearnerA", "learner");
  await createAccount("LearnerB", "learner");
  record("disposable Instructor and two Learner identities authenticate with matching UUIDs");

  const instructor = clients.get("Instructor");
  const classA = await instructor.rpc("create_class", {
    p_title: `Quiz lifecycle class A ${runId}`,
    p_class_code: `Q-A-${randomUUID().slice(0, 8)}`,
  });
  const classB = await instructor.rpc("create_class", {
    p_title: `Quiz lifecycle class B ${runId}`,
    p_class_code: `Q-B-${randomUUID().slice(0, 8)}`,
  });
  if (classA.error || classB.error) throw new Error(classA.error?.message ?? classB.error?.message);
  classIds.push(classA.data.id, classB.data.id);
  const enrollA = await instructor.rpc("enroll_learner", { p_class_id: classA.data.id, p_learner_id: users.get("LearnerA") });
  const enrollB = await instructor.rpc("enroll_learner", { p_class_id: classB.data.id, p_learner_id: users.get("LearnerB") });
  if (enrollA.error || enrollB.error) throw new Error(enrollA.error?.message ?? enrollB.error?.message);
  record("learners enrolled in separate disposable classes");
  return { instructor, classA: classA.data, classB: classB.data };
}

async function authorAndPublish(instructor) {
  const coc = await instructor.from("coc_modules").select("id").eq("coc_code", "coc2").single();
  if (coc.error) throw coc.error;
  const created = await instructor.rpc("create_instructor_quiz", {
    p_title: `TEST_ONLY learner quiz ${runId}`,
    p_topic: "Network device review",
    p_description: "Disposable learner lifecycle verification",
    p_coc_module_id: coc.data.id,
  });
  if (created.error || !created.data?.id) throw new Error(created.error?.message ?? "quiz missing");
  quizIds.push(created.data.id);
  const version = await instructor.from("quiz_versions").select("id,status").eq("quiz_id", created.data.id).single();
  if (version.error || version.data.status !== "draft") throw new Error("Draft version missing");

  const learnerA = clients.get("LearnerA");
  const draftRows = await learnerA.from("quiz_items").select("id").eq("quiz_version_id", version.data.id);
  assert(!draftRows.error && draftRows.data.length === 0, "Learner could see draft items");
  const beforePublish = await learnerA.rpc("get_available_learner_quizzes");
  assert(!beforePublish.error && beforePublish.data.length === 0, "Draft quiz appeared in learner list");
  record("draft and unpublished quiz content is hidden from learner");

  const item1 = await instructor.rpc("upsert_quiz_item", {
    p_quiz_version_id: version.data.id,
    p_item_type: "multiple_choice",
    p_prompt: "Which device forwards traffic between different networks?",
    p_options: ["Router", "Keyboard", "Monitor"],
    p_correct_answer: "Router",
    p_explanation: "A router connects and forwards traffic between networks.",
  });
  const item2 = await instructor.rpc("upsert_quiz_item", {
    p_quiz_version_id: version.data.id,
    p_item_type: "true_false",
    p_prompt: "A network switch can connect devices within a local network.",
    p_options: [],
    p_correct_answer: "true",
    p_explanation: "Switches connect devices on a local network.",
  });
  if (item1.error || item2.error) throw new Error(item1.error?.message ?? item2.error?.message);
  for (const item of [item1.data, item2.data]) {
    const reviewed = await instructor.rpc("review_quiz_item", {
      p_item_id: item.id,
      p_decision: "approved",
      p_notes: "Disposable authenticated lifecycle verification",
    });
    if (reviewed.error) throw reviewed.error;
  }
  const published = await instructor.rpc("publish_quiz_version", {
    p_quiz_version_id: version.data.id,
    p_reason: "Disposable authenticated learner lifecycle verification",
  });
  if (published.error) throw published.error;
  record("Instructor authors, approves, and publishes an immutable supplementary quiz");
  return { quizId: created.data.id, versionId: version.data.id, items: [item1.data, item2.data] };
}

async function exerciseLifecycle({ instructor, classA }, quiz) {
  const learnerA = clients.get("LearnerA");
  const learnerB = clients.get("LearnerB");
  const activity = await instructor.from("activity_versions").select("id,mission_id").eq("status", "published").limit(1).single();
  if (activity.error) throw activity.error;
  const activityAssignment = await instructor.rpc("assign_activity", {
    p_class_id: classA.id,
    p_activity_version_id: activity.data.id,
    p_rubric_version_id: null,
    p_assignment_type: "practice",
    p_title: `TEST_ONLY learning path ${runId}`,
    p_instructions: "Disposable trusted projection verification",
  });
  if (activityAssignment.error) throw activityAssignment.error;
  const pathA = await learnerA.rpc("get_learner_learning_path");
  const pathB = await learnerB.rpc("get_learner_learning_path");
  if (pathA.error || pathB.error) throw new Error(pathA.error?.message ?? pathB.error?.message);
  assert(pathA.data.length === 20 && pathB.data.length === 20, "Learning path did not return the published 20-mission catalog");
  const assignedMissionA = pathA.data.find((row) => row.mission_id === activity.data.mission_id);
  const sameMissionB = pathB.data.find((row) => row.mission_id === activity.data.mission_id);
  assert(assignedMissionA?.assessment_assignment_id === activityAssignment.data.id && assignedMissionA?.assessment_access_state === "available", "Authorized assignment was not projected");
  assert(sameMissionB?.assessment_assignment_id == null && sameMissionB?.assessment_access_state === "practice_only", "Cross-class assignment leaked into learner projection");
  record("trusted learning path projects 20 missions and class-scoped assignment state");

  const savedSettings = await learnerA.from("user_settings").upsert({
    user_id: users.get("LearnerA"),
    notifications_enabled: false,
    sound_enabled: false,
  }, { onConflict: "user_id" }).select("notifications_enabled,sound_enabled").single();
  if (savedSettings.error) throw new Error(`settings persistence failed: ${JSON.stringify(savedSettings.error)}`);
  assert(savedSettings.data.notifications_enabled === false && savedSettings.data.sound_enabled === false, "Learner settings were not persisted");
  const otherSettings = await learnerB.from("user_settings").select("user_id").eq("user_id", users.get("LearnerA"));
  assert(!otherSettings.error && otherSettings.data.length === 0, "Cross-learner settings were visible");
  record("learner preferences persist under own-row RLS and cross-learner read is denied");

  const assignmentEventsA = [];
  const assignmentEventsB = [];
  await subscribe(learnerA, "quiz_assignments", "INSERT", (payload) => assignmentEventsA.push(payload));
  await subscribe(learnerB, "quiz_assignments", "INSERT", (payload) => assignmentEventsB.push(payload));
  const assignment = await instructor.rpc("assign_published_quiz", {
    p_class_id: classA.id,
    p_quiz_version_id: quiz.versionId,
    p_instructions: "Answer all questions, then review before submitting.",
  });
  if (assignment.error) throw assignment.error;
  await waitFor("authorized quiz-assignment event", () => assignmentEventsA.length === 1);
  await delay(800);
  assert(assignmentEventsB.length === 0, "Out-of-class learner received quiz-assignment Realtime payload");
  record("Instructor assigns the published quiz to the owned class", assignment.data.id);
  record("quiz assignment Realtime is class-scoped");

  const listA = await learnerA.rpc("get_available_learner_quizzes");
  const listB = await learnerB.rpc("get_available_learner_quizzes");
  assert(!listA.error && listA.data.length === 1 && listA.data[0].assignment_id === assignment.data.id, "Authorized learner list invalid");
  assert(!listB.error && listB.data.length === 0, "Out-of-class learner could list quiz");
  record("authorized learner lists assignment while cross-class learner sees none");

  await denied("cross-learner start is denied", () => learnerB.rpc("start_learner_quiz", {
    p_assignment_id: assignment.data.id,
    p_client_start_key: randomUUID(),
  }));
  const instructorAttemptEvents = [];
  await subscribe(instructor, "quiz_attempts", "*", (payload) => instructorAttemptEvents.push(payload));
  const started = await learnerA.rpc("start_learner_quiz", {
    p_assignment_id: assignment.data.id,
    p_client_start_key: randomUUID(),
  });
  if (started.error) throw started.error;
  const attemptId = started.data.attempt_id;
  await waitFor("Instructor quiz-attempt INSERT", () => instructorAttemptEvents.some((item) => item.eventType === "INSERT"));
  const serializedStart = JSON.stringify(started.data);
  assert(!serializedStart.includes("correct_answer") && !serializedStart.includes("review_notes"), "Learner payload exposed authoring authority");
  assert(started.data.questions.length === 2, "Published question contract invalid");
  record("learner starts one attempt without answer-key or review-data exposure", attemptId);

  const save1 = await learnerA.rpc("save_learner_quiz_answer", {
    p_attempt_id: attemptId,
    p_item_id: quiz.items[0].id,
    p_answer: "Router",
  });
  const save2 = await learnerA.rpc("save_learner_quiz_answer", {
    p_attempt_id: attemptId,
    p_item_id: quiz.items[1].id,
    p_answer: "True",
  });
  if (save1.error || save2.error) throw new Error(save1.error?.message ?? save2.error?.message);
  record("learner saves answers through trusted RPCs");

  const resumed = await learnerA.rpc("start_learner_quiz", {
    p_assignment_id: assignment.data.id,
    p_client_start_key: randomUUID(),
  });
  if (resumed.error) throw resumed.error;
  assert(resumed.data.attempt_id === attemptId, "Resume created a duplicate attempt");
  assert(resumed.data.questions.every((item) => typeof item.saved_answer === "string"), "Saved answers were not restored");
  record("leave/resume restores the same server attempt and saved answers");

  const submitted = await learnerA.rpc("submit_learner_quiz", {
    p_attempt_id: attemptId,
    p_submission_key: randomUUID(),
  });
  if (submitted.error) throw submitted.error;
  const duplicate = await learnerA.rpc("submit_learner_quiz", {
    p_attempt_id: attemptId,
    p_submission_key: randomUUID(),
  });
  if (duplicate.error || duplicate.data.status !== "completed") throw new Error(duplicate.error?.message ?? "duplicate submit not idempotent");
  await waitFor("Instructor quiz completion UPDATE", () => instructorAttemptEvents.some((item) => item.eventType === "UPDATE" && item.new?.status === "completed"));
  const resultRows = await service.from("quiz_results").select("id").eq("quiz_attempt_id", attemptId);
  assert(!resultRows.error && resultRows.data.length === 1, "Duplicate quiz result created");
  record("submission and network retry produce exactly one result");
  record("quiz submission Realtime reaches the owning Instructor");

  await denied("answers cannot change after submission", () => learnerA.rpc("save_learner_quiz_answer", {
    p_attempt_id: attemptId,
    p_item_id: quiz.items[0].id,
    p_answer: "Keyboard",
  }));
  await denied("cross-learner result retrieval is denied", () => learnerB.rpc("get_learner_quiz_result", { p_attempt_id: attemptId }));
  const result = await learnerA.rpc("get_learner_quiz_result", { p_attempt_id: attemptId });
  if (result.error) throw result.error;
  const serializedResult = JSON.stringify(result.data);
  assert(result.data.correct_count === 2 && result.data.question_count === 2, "Stored result count invalid");
  assert(!serializedResult.includes("correct_answer") && !serializedResult.includes("explanation"), "Result exposed hidden authoring data");
  record("own scoped result is correct and contains no answer keys");

  const anonymous = createClient(url, publicKey, { auth: { autoRefreshToken: false, persistSession: false } });
  await denied("anonymous learner quiz RPC is denied", () => anonymous.rpc("get_available_learner_quizzes"));
  await denied("anonymous learning path projection is denied", () => anonymous.rpc("get_learner_learning_path"));
  const anonRows = await anonymous.from("quiz_attempts").select("id").limit(1);
  assert(Boolean(anonRows.error) || anonRows.data.length === 0, "Anonymous caller read quiz attempts");
  const anonymousSettings = await anonymous.from("user_settings").select("id").limit(1);
  assert(Boolean(anonymousSettings.error) || anonymousSettings.data.length === 0, "Anonymous caller read learner settings");
  record("anonymous table and RPC access is denied");

  const audits = await service.from("audit_events").select("action,actor_id,outcome").eq("target_id", attemptId).in("action", ["quiz_attempt.started", "quiz_attempt.completed"]);
  assert(!audits.error && new Set(audits.data.map((row) => row.action)).size === 2, "Quiz attempt audit trail incomplete");
  record("quiz start and completion audit evidence is present");
}

async function cleanup() {
  const errors = [];
  for (const { client, channel } of realtimeChannels) {
    const removed = await client.removeChannel(channel);
    if (removed === "error") errors.push(`could not remove ${channel.topic}`);
  }
  const uuidList = (values) => values.map((value) => {
    if (!/^[0-9a-f-]{36}$/i.test(value)) throw new Error("Refusing cleanup for an invalid UUID");
    return `'${value}'::uuid`;
  }).join(",");
  if (quizIds.length) {
    const versions = await service.from("quiz_versions").select("id").in("quiz_id", quizIds);
    const versionIds = (versions.data ?? []).map((row) => row.id);
    const assignments = versionIds.length
      ? await service.from("quiz_assignments").select("id").in("quiz_version_id", versionIds)
      : { data: [] };
    const assignmentIds = (assignments.data ?? []).map((row) => row.id);
    const attempts = assignmentIds.length
      ? await service.from("quiz_attempts").select("id").in("quiz_assignment_id", assignmentIds)
      : { data: [] };
    const attemptIds = (attempts.data ?? []).map((row) => row.id);
    const deleteWhere = (table, column, ids) => ids.length
      ? `delete from public.${table} where ${column} in (${uuidList(ids)});`
      : "";
    const maintenanceSql = [
      "begin;",
      "set local session_replication_role = replica;",
      deleteWhere("quiz_results", "quiz_attempt_id", attemptIds),
      deleteWhere("quiz_answers", "quiz_attempt_id", attemptIds),
      deleteWhere("quiz_attempts", "id", attemptIds),
      deleteWhere("quiz_assignments", "id", assignmentIds),
      deleteWhere("quiz_items", "quiz_version_id", versionIds),
      deleteWhere("ai_quiz_generations", "quiz_version_id", versionIds),
      deleteWhere("quiz_versions", "id", versionIds),
      deleteWhere("quizzes", "id", quizIds),
      deleteWhere("assignments", "class_id", classIds),
      deleteWhere("class_memberships", "class_id", classIds),
      deleteWhere("classes", "id", classIds),
      "commit;",
    ].filter(Boolean).join("\n");
    const cleanupDirectory = mkdtempSync(join(tmpdir(), "bytequest-quiz-cleanup-"));
    const cleanupFile = join(cleanupDirectory, "cleanup.sql");
    try {
      writeFileSync(cleanupFile, maintenanceSql, { encoding: "utf8", mode: 0o600 });
      const command = process.platform === "win32" ? "powershell.exe" : "supabase";
      const args = process.platform === "win32"
        ? ["-NoProfile", "-NonInteractive", "-Command", "& supabase db query --linked --file $args[0] --output json", cleanupFile]
        : ["db", "query", "--linked", "--file", cleanupFile, "--output", "json"];
      execFileSync(command, args, {
        cwd: repositoryRoot,
        encoding: "utf8",
        stdio: ["ignore", "pipe", "pipe"],
      });
    } catch (error) {
      errors.push(`scoped database cleanup failed: ${error instanceof Error ? error.message : String(error)}`);
    } finally {
      rmSync(cleanupDirectory, { recursive: true, force: true });
    }
  }
  for (const client of clients.values()) await client.auth.signOut();
  for (const id of [...users.values()].reverse()) {
    const deleted = await service.auth.admin.deleteUser(id, false);
    if (deleted.error) errors.push(deleted.error.message);
  }
  if (errors.length) throw new Error(errors.join(" | "));
}

let failed = false;
try {
  const fixtures = await createFixtures();
  const quiz = await authorAndPublish(fixtures.instructor);
  await exerciseLifecycle(fixtures, quiz);
} catch (error) {
  failed = true;
  results.push({ name: "authenticated learner quiz E2E", status: "FAIL", detail: error instanceof Error ? error.message : String(error) });
} finally {
  try {
    await cleanup();
    record("disposable quiz, class, account, and attempt cleanup");
  } catch (error) {
    failed = true;
    results.push({ name: "disposable cleanup", status: "FAIL", detail: error instanceof Error ? error.message : String(error) });
  }
}

console.log(JSON.stringify({ runId, results }, null, 2));
if (failed) process.exitCode = 1;
