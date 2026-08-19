import { NextResponse } from "next/server";
import { z } from "zod";
import { getQuizAiConfiguration, QuizAiConfigurationError } from "@/lib/ai/config";
import { loadApprovedQuizGrounding, QuizGroundingError } from "@/lib/ai/quiz-grounding";
import { generateQuizDraftWithOpenRouter, QuizAiProviderError } from "@/lib/ai/providers/openrouter";
import { quizItemTypeSchema } from "@/lib/ai/quiz-draft";
import { getServerProfile } from "@/lib/auth/server";
import { createAdminSupabaseClient } from "@/lib/supabase/admin";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export const runtime = "nodejs";

const requestSchema = z.object({
  quizVersionId: z.string().uuid(),
  activityVersionId: z.string().uuid(),
  topic: z.string().trim().min(2).max(240),
  instructorContext: z.string().trim().max(2000).optional(),
  difficulty: z.enum(["foundation", "intermediate", "advanced"]),
  itemCount: z.number().int().min(1).max(10),
  itemTypes: z.array(quizItemTypeSchema).min(1).max(4),
});

function jsonError(error: string, status: number, retryAfter?: string) {
  const response = NextResponse.json({ error }, { status });
  if (retryAfter) response.headers.set("Retry-After", retryAfter);
  return response;
}

export async function POST(request: Request) {
  const actor = await getServerProfile();
  if (!actor || actor.role !== "instructor" || actor.status !== "active") {
    return jsonError("Active Instructor access is required.", 403);
  }

  const parsed = requestSchema.safeParse(await request.json().catch(() => null));
  if (!parsed.success) {
    return jsonError(
      "Choose an approved activity, topic, difficulty, item count, and at least one supported question type.",
      400,
    );
  }

  let configuration;
  try {
    configuration = getQuizAiConfiguration();
  } catch (error) {
    if (error instanceof QuizAiConfigurationError) {
      return jsonError(
        "AI drafting is not configured on this server. Manual quiz creation remains available.",
        503,
      );
    }
    throw error;
  }

  const supabase = await createServerSupabaseClient();
  const { data: version } = await supabase
    .from("quiz_versions")
    .select("id,quiz_id,status")
    .eq("id", parsed.data.quizVersionId)
    .maybeSingle();
  if (!version || version.status !== "draft") {
    return jsonError("An owned draft quiz version is required.", 403);
  }

  const { data: quiz } = await supabase
    .from("quizzes")
    .select("id,instructor_id,title,topic,coc_module_id,archived_at")
    .eq("id", version.quiz_id)
    .maybeSingle();
  if (!quiz || quiz.instructor_id !== actor.userId || quiz.archived_at) {
    return jsonError("You can generate drafts only for your own active quiz.", 403);
  }
  if (!quiz.coc_module_id) {
    return jsonError("Select and save a TESDA-aligned COC before generating an AI draft.", 422);
  }

  // The caller is already authenticated and the owned draft quiz is scoped
  // above. Approved source/rubric content is system-governed reference data,
  // so load it through the trusted server client rather than broadening the
  // Instructor RLS policy for every browser query.
  const admin = createAdminSupabaseClient();
  let grounding;
  try {
    grounding = await loadApprovedQuizGrounding(
      admin,
      quiz.coc_module_id,
      parsed.data.activityVersionId,
    );
  } catch (error) {
    if (error instanceof QuizGroundingError) {
      return jsonError(
        "The selected activity does not have complete, active TESDA-grounded content. Choose another approved activity or author manually.",
        422,
      );
    }
    throw error;
  }

  const itemTypes = [...new Set(parsed.data.itemTypes)];
  const inputContext = {
    topic: parsed.data.topic,
    difficulty: parsed.data.difficulty,
    item_types: itemTypes,
    draft_only: true,
    instructor_context_supplied: Boolean(parsed.data.instructorContext),
    tesda_source_id: grounding.source.id,
    tesda_source_title: grounding.source.title,
    tesda_source_edition: grounding.source.edition,
    coc_module_id: grounding.coc.id,
    coc_code: grounding.coc.code,
    competency_id: grounding.competency.id,
    competency_code: grounding.competency.code,
    module_version_id: grounding.module.id,
    activity_version_id: grounding.activity.id,
    mission_id: grounding.mission.id,
    rubric_version_id: grounding.rubric.id,
  };

  const { data: generation, error: beginError } = await supabase.rpc("begin_ai_quiz_generation", {
    p_quiz_version_id: version.id,
    p_provider: configuration.provider,
    p_model: configuration.model,
    p_input_context: inputContext,
    p_requested_count: parsed.data.itemCount,
  });
  if (beginError || !generation) {
    return jsonError("The AI draft request could not be authorized.", 403);
  }

  try {
    const items = await generateQuizDraftWithOpenRouter(
      {
        quizTitle: quiz.title,
        topic: parsed.data.topic,
        instructorContext: parsed.data.instructorContext?.trim() || null,
        difficulty: parsed.data.difficulty,
        itemCount: parsed.data.itemCount,
        itemTypes,
        grounding,
      },
      configuration,
    );

    const { data: count, error: completionError } = await admin.rpc("complete_ai_quiz_generation", {
      p_generation_id: generation.id,
      p_actor_id: actor.userId,
      p_provider: configuration.provider,
      p_model: configuration.model,
      p_items: items,
    });
    if (completionError || count === null) throw new Error("AI_DRAFT_COMMIT_FAILED");

    return NextResponse.json(
      {
        generationId: generation.id,
        generatedCount: count,
        provider: configuration.provider,
        status: "draft_review_required",
      },
      { status: 201 },
    );
  } catch (error) {
    const failureCode = error instanceof QuizAiProviderError ? error.code : "AI_DRAFT_COMMIT_FAILED";
    await admin.rpc("fail_ai_quiz_generation", {
      p_generation_id: generation.id,
      p_actor_id: actor.userId,
      p_failure_code: failureCode,
    });

    if (error instanceof QuizAiProviderError) {
      return jsonError(error.publicMessage, error.status, error.retryAfter);
    }
    return jsonError(
      "The generated draft could not be saved safely. No question was published; try again or author items manually.",
      502,
    );
  }
}
