import { randomUUID } from "node:crypto";
import { createClient } from "@supabase/supabase-js";

const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
const publishableKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ?? process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const instructorPassword = process.env.BYTEQUEST_DEMO_INSTRUCTOR_PASSWORD;
const instructorEmail = process.env.BYTEQUEST_DEMO_INSTRUCTOR_EMAIL ?? "instructor@dnsc.edu.ph";

if (!url || !publishableKey || !serviceRoleKey || !instructorPassword) {
  throw new Error("Supabase configuration and BYTEQUEST_DEMO_INSTRUCTOR_PASSWORD are required.");
}

const runId = `quiz-e2e-${new Date().toISOString().replace(/\D/g, "").slice(0, 14)}-${randomUUID().slice(0, 8)}`;
const results = [];
const service = createClient(url, serviceRoleKey, { auth: { autoRefreshToken: false, persistSession: false } });
const instructor = createClient(url, publishableKey, { auth: { autoRefreshToken: false, persistSession: false } });
const anonymous = createClient(url, publishableKey, { auth: { autoRefreshToken: false, persistSession: false } });

function record(name, status, detail = "") {
  results.push({ name, status, detail });
}

function assert(value, message) {
  if (!value) throw new Error(message);
}

async function expectDenied(name, operation) {
  const response = await operation();
  if (!response.error) throw new Error(`${name}: operation unexpectedly succeeded`);
  record(name, "PASS", response.error.code ?? response.error.message);
}

let quizId = null;
let failed = false;

try {
  const { data: login, error: loginError } = await instructor.auth.signInWithPassword({ email: instructorEmail, password: instructorPassword });
  assert(!loginError && login.user, `Demo Instructor login failed: ${loginError?.message ?? "missing user"}`);
  const actorId = login.user.id;

  const { data: coc2, error: cocError } = await instructor.from("coc_modules").select("id,coc_code").eq("coc_code", "coc2").single();
  assert(!cocError && coc2, `COC2 lookup failed: ${cocError?.message ?? "missing row"}`);

  await expectDenied("Anonymous cannot create Instructor quiz", () =>
    anonymous.rpc("create_instructor_quiz", { p_title: "Forbidden quiz", p_topic: "Forbidden topic" }),
  );

  const { data: quiz, error: quizError } = await instructor.rpc("create_instructor_quiz", {
    p_title: `TEST_ONLY — Panel #8 lifecycle ${runId}`,
    p_topic: runId,
    p_description: "Archived test-only evidence for Instructor quiz draft/review/publish authorization.",
    p_coc_module_id: coc2.id,
    p_instructions: "Supplementary quiz; Instructor review is mandatory.",
  });
  assert(!quizError && quiz?.id, `Quiz creation failed: ${quizError?.message ?? "missing row"}`);
  quizId = quiz.id;

  const { data: version1, error: versionError } = await instructor.from("quiz_versions").select("id,status,version_number").eq("quiz_id", quiz.id).single();
  assert(!versionError && version1?.status === "draft" && version1.version_number === 1, "Version 1 draft was not created");
  record("Instructor creates owned quiz with version 1 draft", "PASS");

  const itemPayload = {
    p_quiz_version_id: version1.id,
    p_item_type: "multiple_choice",
    p_prompt: "Which tool verifies continuity and conductor mapping after an RJ45 cable is terminated?",
    p_options: ["Cable tester", "Crimping tool", "Wire stripper", "Punch-down tool"],
    p_correct_answer: "Cable tester",
    p_explanation: "A cable tester observes continuity and pin mapping after termination.",
  };
  const { data: item1, error: itemError } = await instructor.rpc("upsert_quiz_item", itemPayload);
  assert(!itemError && item1?.review_status === "draft", `Manual draft item failed: ${itemError?.message ?? "unexpected state"}`);

  await expectDenied("Unreviewed quiz cannot publish", () =>
    instructor.rpc("publish_quiz_version", { p_quiz_version_id: version1.id, p_reason: "Must fail before item review" }),
  );
  const { error: approvalError } = await instructor.rpc("review_quiz_item", {
    p_item_id: item1.id,
    p_decision: "approved",
    p_notes: "Instructor verified the answer and explanation.",
  });
  assert(!approvalError, `Manual item approval failed: ${approvalError?.message}`);
  const { error: publish1Error } = await instructor.rpc("publish_quiz_version", {
    p_quiz_version_id: version1.id,
    p_reason: "Authenticated lifecycle verification of reviewed manual content",
  });
  assert(!publish1Error, `Version 1 publication failed: ${publish1Error?.message}`);
  record("Manual item remains draft until reviewed, then publishes through audited transition", "PASS");

  await expectDenied("Published quiz item is immutable", () =>
    instructor.rpc("upsert_quiz_item", { ...itemPayload, p_item_id: item1.id, p_prompt: "A changed published prompt must be denied." }),
  );

  const { data: version2, error: version2Error } = await instructor.rpc("create_quiz_version", {
    p_quiz_id: quiz.id,
    p_change_summary: "AI draft transaction and review verification",
  });
  assert(!version2Error && version2?.version_number === 2 && version2.status === "draft", `Version 2 creation failed: ${version2Error?.message}`);

  const { data: generation, error: beginError } = await instructor.rpc("begin_ai_quiz_generation", {
    p_quiz_version_id: version2.id,
    p_provider: "openrouter",
    p_model: "contract-test-model",
    p_input_context: { test_only: true, topic: runId, draft_only: true },
    p_requested_count: 2,
  });
  assert(!beginError && generation?.status === "requested", `AI generation request failed: ${beginError?.message}`);

  const trustedContractItems = [
    {
      item_type: "true_false",
      prompt: "A learner should inspect cable termination before recording completion.",
      options: [],
      correct_answer: "true",
      explanation: "Visual inspection is part of the approved operational evidence package.",
    },
    {
      item_type: "scenario_based",
      prompt: "A cable tester reports an open conductor. What is the most appropriate next action?",
      options: ["Inspect and re-terminate the affected end", "Award competency immediately", "Ignore the tester", "Replace the switch"],
      correct_answer: "Inspect and re-terminate the affected end",
      explanation: "The observed termination fault should be inspected and corrected before retesting.",
    },
  ];
  const { data: generatedCount, error: completionError } = await service.rpc("complete_ai_quiz_generation", {
    p_generation_id: generation.id,
    p_actor_id: actorId,
    p_provider: "contract-test",
    p_model: "contract-test-model",
    p_items: trustedContractItems,
  });
  assert(!completionError && generatedCount === 2, `Trusted AI draft commit failed: ${completionError?.message}`);

  const { data: generatedItems, error: generatedItemsError } = await instructor
    .from("quiz_items")
    .select("id,origin,review_status")
    .eq("quiz_version_id", version2.id)
    .order("order_index");
  assert(!generatedItemsError && generatedItems?.length === 2, "Generated draft items were not stored");
  assert(generatedItems.every((item) => item.origin === "ai_generated_draft" && item.review_status === "draft"), "AI items gained authority before review");

  await expectDenied("AI drafts cannot auto-publish", () =>
    instructor.rpc("publish_quiz_version", { p_quiz_version_id: version2.id, p_reason: "Must fail before review" }),
  );
  await expectDenied("Rejected AI draft requires a reason", () =>
    instructor.rpc("review_quiz_item", { p_item_id: generatedItems[0].id, p_decision: "rejected" }),
  );

  for (const item of generatedItems) {
    const { error } = await instructor.rpc("review_quiz_item", {
      p_item_id: item.id,
      p_decision: "approved",
      p_notes: "Instructor reviewed this test-only draft for correctness.",
    });
    assert(!error, `AI draft approval failed: ${error?.message}`);
  }
  const { error: publish2Error } = await instructor.rpc("publish_quiz_version", {
    p_quiz_version_id: version2.id,
    p_reason: "Instructor approved every draft item in the test-only second version",
  });
  assert(!publish2Error, `Version 2 publication failed: ${publish2Error?.message}`);

  const { data: finalVersions } = await instructor.from("quiz_versions").select("version_number,status").eq("quiz_id", quiz.id).order("version_number");
  assert(finalVersions?.[0]?.status === "retired" && finalVersions?.[1]?.status === "published", "Version retirement/publication history is incorrect");
  record("Trusted AI payload creates draft-only items; Instructor approval is mandatory before publication", "PASS");

  const { data: anonymousRows } = await anonymous.from("quiz_items").select("id").in("quiz_version_id", [version1.id, version2.id]);
  assert(anonymousRows?.length === 0, "Anonymous caller read protected quiz answers");
  record("Anonymous users cannot read quiz answers or protected authoring records", "PASS");

  const { data: audits, error: auditError } = await service
    .from("audit_events")
    .select("action,actor_id,actor_role,outcome")
    .eq("actor_id", actorId)
    .in("action", ["quiz.created", "quiz_item.created", "quiz_item.reviewed", "quiz_version.published", "quiz.ai_draft.requested", "quiz.ai_draft.completed"]);
  assert(!auditError, `Audit query failed: ${auditError?.message}`);
  const observed = new Set((audits ?? []).map((event) => event.action));
  for (const action of ["quiz.created", "quiz_item.created", "quiz_item.reviewed", "quiz_version.published", "quiz.ai_draft.requested", "quiz.ai_draft.completed"]) {
    assert(observed.has(action), `Missing audit action: ${action}`);
  }
  assert(audits.every((event) => event.actor_id === actorId && event.actor_role === "instructor" && event.outcome === "success"), "Quiz audit identity or outcome is incomplete");
  record("Quiz create/review/publish/AI transitions preserve trusted Instructor audit evidence", "PASS");

  const { error: archiveError } = await instructor.rpc("archive_instructor_quiz", {
    p_quiz_id: quiz.id,
    p_reason: "Archive test-only lifecycle evidence after successful verification",
  });
  assert(!archiveError, `Quiz archive failed: ${archiveError?.message}`);
  record("Test-only quiz archived while immutable versions remain retained", "PASS", quiz.id);
} catch (error) {
  failed = true;
  record("authenticated quiz authoring lifecycle", "FAIL", error instanceof Error ? error.message : String(error));
} finally {
  await instructor.auth.signOut();
}

console.log(JSON.stringify({ runId, retainedArchivedQuizId: quizId, results }, null, 2));
if (failed) process.exitCode = 1;
