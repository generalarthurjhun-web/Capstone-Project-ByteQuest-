import { randomUUID } from "node:crypto";
import { createServerClient } from "@supabase/ssr";
import { createClient } from "@supabase/supabase-js";

const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
const publishableKey =
  process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ?? process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const openRouterKeyConfigured = Boolean(process.env.OPENROUTER_API_KEY?.trim());
const expectedModel = process.env.OPENROUTER_MODEL?.trim() || "openrouter/free";
const instructorEmail = process.env.BYTEQUEST_DEMO_INSTRUCTOR_EMAIL ?? "instructor@dnsc.edu.ph";
const instructorPassword = process.env.BYTEQUEST_DEMO_INSTRUCTOR_PASSWORD;
const webBaseUrl = process.env.BYTEQUEST_WEB_BASE_URL ?? "http://127.0.0.1:3000";

const missingConfiguration = [
  ["NEXT_PUBLIC_SUPABASE_URL", url],
  ["NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY", publishableKey],
  ["SUPABASE_SERVICE_ROLE_KEY", serviceRoleKey],
  ["BYTEQUEST_DEMO_INSTRUCTOR_PASSWORD", instructorPassword],
  ["OPENROUTER_API_KEY", openRouterKeyConfigured],
]
  .filter(([, value]) => !value)
  .map(([name]) => name);

if (missingConfiguration.length > 0) {
  console.log(
    JSON.stringify(
      {
        status: "BLOCKED",
        reason: "Required server/test configuration is unavailable; no database mutation was attempted.",
        missing: missingConfiguration,
      },
      null,
      2,
    ),
  );
  process.exitCode = 2;
} else {
  await run();
}

async function run() {
  const runId = `openrouter-live-${new Date().toISOString().replace(/\D/g, "").slice(0, 14)}-${randomUUID().slice(0, 8)}`;
  const service = createClient(url, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const session = createCookieSessionClient();
  const results = [];
  let quizId = null;

  function record(name, status, detail = "") {
    results.push({ name, status, detail });
  }

  function assert(value, message) {
    if (!value) throw new Error(message);
  }

  try {
    const { data: login, error: loginError } = await session.client.auth.signInWithPassword({
      email: instructorEmail,
      password: instructorPassword,
    });
    assert(!loginError && login.user, `Demo Instructor login failed: ${loginError?.message ?? "missing user"}`);
    const actorId = login.user.id;
    record("real Instructor Supabase session established", "PASS");

    const { data: coc2, error: cocError } = await session.client
      .from("coc_modules")
      .select("id,coc_code,title")
      .eq("coc_code", "coc2")
      .single();
    assert(!cocError && coc2, `COC2 lookup failed: ${cocError?.message ?? "missing row"}`);

    const { data: moduleVersion, error: moduleError } = await session.client
      .from("module_versions")
      .select("id,version_number,status")
      .eq("module_id", coc2.id)
      .eq("status", "published")
      .order("version_number", { ascending: false })
      .limit(1)
      .single();
    assert(!moduleError && moduleVersion, `Published COC2 module version lookup failed: ${moduleError?.message ?? "missing row"}`);

    const { data: mission, error: missionError } = await session.client
      .from("missions")
      .select("id,title,objective")
      .eq("coc_id", coc2.id)
      .eq("mission_number", 2)
      .single();
    assert(!missionError && mission, `COC2 Mission 2 lookup failed: ${missionError?.message ?? "missing row"}`);

    const { data: activity, error: activityError } = await session.client
      .from("activity_versions")
      .select("id,title,status")
      .eq("module_version_id", moduleVersion.id)
      .eq("mission_id", mission.id)
      .eq("status", "published")
      .order("version_number", { ascending: false })
      .limit(1)
      .single();
    assert(!activityError && activity, `Published COC2 Mission 2 activity lookup failed: ${activityError?.message ?? "missing row"}`);

    const { data: quiz, error: quizError } = await session.client.rpc("create_instructor_quiz", {
      p_title: `TEST_ONLY — OpenRouter live acceptance ${runId}`,
      p_topic: "Cable termination and tester-result interpretation",
      p_description: "Disposable live-provider acceptance evidence; archived automatically after the run.",
      p_coc_module_id: coc2.id,
      p_instructions: "Review every AI-generated draft. Publish only verified questions.",
    });
    assert(!quizError && quiz?.id, `Quiz creation failed: ${quizError?.message ?? "missing row"}`);
    quizId = quiz.id;

    const { data: version, error: versionError } = await session.client
      .from("quiz_versions")
      .select("id,status,version_number")
      .eq("quiz_id", quizId)
      .single();
    assert(!versionError && version?.status === "draft", "Owned draft quiz version was not created");
    record("disposable Instructor-owned COC2 quiz draft created", "PASS");

    const response = await request("/api/instructor/quizzes/ai-draft", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        quizVersionId: version.id,
        activityVersionId: activity.id,
        topic: "Safe cable termination and cable tester result interpretation",
        instructorContext:
          "Draft supplementary questions that help learners explain the approved procedure. Do not add numeric TESDA grading rules.",
        difficulty: "foundation",
        itemCount: 2,
        itemTypes: ["multiple_choice", "scenario_based"],
      }),
    });
    const responseBody = await response.json().catch(() => null);
    assert(
      response.status === 201 && responseBody?.status === "draft_review_required",
      `Live OpenRouter route failed (${response.status}): ${responseBody?.error ?? "invalid response"}`,
    );
    assert(responseBody.generatedCount === 2 && responseBody.provider === "openrouter", "Provider response provenance/count is incorrect");
    record("real OpenRouter structured generation returned draft-review-required", "PASS");

    const [{ data: generation, error: generationError }, { data: items, error: itemsError }] =
      await Promise.all([
        session.client
          .from("ai_quiz_generations")
          .select("id,provider,model,status,requested_count,generated_count,failure_code,input_context")
          .eq("id", responseBody.generationId)
          .single(),
        session.client
          .from("quiz_items")
          .select("id,item_type,prompt,options,correct_answer,explanation,origin,review_status,order_index,removed_at")
          .eq("quiz_version_id", version.id)
          .order("order_index"),
      ]);
    assert(!generationError && generation, `Generation provenance lookup failed: ${generationError?.message ?? "missing row"}`);
    assert(!itemsError && items?.length === 2, `Generated draft lookup failed: ${itemsError?.message ?? "wrong count"}`);
    assert(
      generation.provider === "openrouter" &&
        generation.model === expectedModel &&
        generation.status === "completed" &&
        generation.requested_count === 2 &&
        generation.generated_count === 2 &&
        !generation.failure_code,
      "Stored OpenRouter generation provenance/state is incorrect",
    );
    assert(
      generation.input_context?.tesda_source_id &&
        generation.input_context?.rubric_version_id &&
        generation.input_context?.activity_version_id === activity.id,
      "Stored generation context is not tied to the approved source/rubric/activity",
    );
    assert(
      items.every((item) => item.origin === "ai_generated_draft" && item.review_status === "draft" && !item.removed_at),
      "AI output gained authority before Instructor review",
    );
    record("TESDA-grounded provider provenance and draft-only items persisted", "PASS");

    const { error: prematurePublishError } = await session.client.rpc("publish_quiz_version", {
      p_quiz_version_id: version.id,
      p_reason: "This must be denied before Instructor review",
    });
    assert(prematurePublishError, "Unreviewed AI content published unexpectedly");
    record("AI-generated drafts cannot auto-publish", "PASS");

    const first = items[0];
    const { data: edited, error: editError } = await session.client.rpc("upsert_quiz_item", {
      p_quiz_version_id: version.id,
      p_item_type: first.item_type,
      p_prompt: `${first.prompt} (Instructor-reviewed wording)`,
      p_options: first.options,
      p_correct_answer: first.correct_answer,
      p_explanation: first.explanation,
      p_order_index: first.order_index,
      p_item_id: first.id,
    });
    assert(!editError && edited?.review_status === "draft", `Instructor edit failed: ${editError?.message ?? "invalid state"}`);

    const { error: approvalError } = await session.client.rpc("review_quiz_item", {
      p_item_id: first.id,
      p_decision: "approved",
      p_notes: "Instructor verified the source, answer, distractors, and explanation.",
    });
    assert(!approvalError, `Instructor approval failed: ${approvalError?.message}`);

    const second = items[1];
    const { error: missingReasonError } = await session.client.rpc("review_quiz_item", {
      p_item_id: second.id,
      p_decision: "rejected",
    });
    assert(missingReasonError, "Rejected AI draft did not require a reason");
    const { error: rejectionError } = await session.client.rpc("review_quiz_item", {
      p_item_id: second.id,
      p_decision: "rejected",
      p_notes: "Rejected during acceptance testing to prove Instructor control.",
    });
    assert(!rejectionError, `Instructor rejection failed: ${rejectionError?.message}`);
    const { error: removeError } = await session.client.rpc("remove_quiz_item", {
      p_item_id: second.id,
      p_reason: "Remove the rejected live-provider draft before publication.",
    });
    assert(!removeError, `Rejected item removal failed: ${removeError?.message}`);
    record("Instructor can edit, approve, reject with reason, and remove draft content", "PASS");

    const { data: published, error: publishError } = await session.client.rpc("publish_quiz_version", {
      p_quiz_version_id: version.id,
      p_reason: "Publish only the Instructor-reviewed live OpenRouter draft item",
    });
    assert(!publishError && published?.status === "published", `Reviewed quiz publication failed: ${publishError?.message ?? "invalid state"}`);

    const { data: activeItems, error: activeItemsError } = await session.client
      .from("quiz_items")
      .select("id,review_status,removed_at")
      .eq("quiz_version_id", version.id)
      .is("removed_at", null);
    assert(
      !activeItemsError && activeItems?.length === 1 && activeItems[0].review_status === "approved",
      "Published version contains unapproved active content",
    );
    record("approved-items-only publication succeeds after explicit Instructor review", "PASS");

    const { data: audits, error: auditError } = await service
      .from("audit_events")
      .select("action,actor_id,actor_role,outcome")
      .eq("actor_id", actorId)
      .in("action", [
        "quiz.ai_draft.requested",
        "quiz.ai_draft.completed",
        "quiz_item.updated",
        "quiz_item.reviewed",
        "quiz_item.removed",
        "quiz_version.published",
      ]);
    assert(!auditError, `Audit verification failed: ${auditError?.message}`);
    const actions = new Set((audits ?? []).map((event) => event.action));
    for (const action of [
      "quiz.ai_draft.requested",
      "quiz.ai_draft.completed",
      "quiz_item.updated",
      "quiz_item.reviewed",
      "quiz_item.removed",
      "quiz_version.published",
    ]) {
      assert(actions.has(action), `Missing audit action: ${action}`);
    }
    assert(
      audits.every((event) => event.actor_id === actorId && event.actor_role === "instructor"),
      "AI authoring audit identity is incomplete",
    );
    record("AI request, completion, review, removal, and publication are audited", "PASS");
  } catch (error) {
    record("live OpenRouter Instructor quiz lifecycle", "FAIL", error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  } finally {
    if (quizId) {
      const { error: archiveError } = await session.client.rpc("archive_instructor_quiz", {
        p_quiz_id: quizId,
        p_reason: "Archive disposable live OpenRouter acceptance quiz after verification",
      });
      record(
        "disposable live-provider quiz archived",
        archiveError ? "FAIL" : "PASS",
        archiveError?.message ?? quizId,
      );
      if (archiveError) process.exitCode = 1;
    }
    await session.client.auth.signOut();
    console.log(JSON.stringify({ runId, provider: "openrouter", model: expectedModel, results }, null, 2));
  }

  function createCookieSessionClient() {
    const jar = new Map();
    const client = createServerClient(url, publishableKey, {
      cookies: {
        getAll: () => Array.from(jar, ([name, value]) => ({ name, value })),
        setAll: (cookies) => {
          for (const cookie of cookies) {
            if (cookie.options?.maxAge === 0 || cookie.value === "") jar.delete(cookie.name);
            else jar.set(cookie.name, cookie.value);
          }
        },
      },
    });
    return {
      client,
      cookieHeader: () => Array.from(jar, ([name, value]) => `${name}=${value}`).join("; "),
    };
  }

  async function request(path, init = {}) {
    const headers = new Headers(init.headers);
    headers.set("cookie", session.cookieHeader());
    return fetch(`${webBaseUrl}${path}`, { ...init, headers, redirect: "manual" });
  }
}
