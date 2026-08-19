import "server-only";

import type { SupabaseClient } from "@supabase/supabase-js";
import type { QuizGenerationGrounding } from "@/lib/ai/quiz-draft";
import type { Database } from "@/types/database.generated";

type ServerSupabaseClient = SupabaseClient<Database>;

export interface QuizGroundingCatalog {
  source: { title: string; edition: string };
  coc: { id: string; code: string; title: string };
  competency: { code: string; title: string };
  module: { title: string; version: number };
  activities: Array<{
    id: string;
    title: string;
    missionNumber: number;
    missionTitle: string;
    learningOutcome: string;
  }>;
}

export class QuizGroundingError extends Error {
  constructor(public readonly code: "CONTEXT_NOT_FOUND" | "CONTEXT_NOT_APPROVED" | "CONTEXT_INCOMPLETE") {
    super(code);
    this.name = "QuizGroundingError";
  }
}

function strings(value: unknown): string[] {
  return Array.isArray(value) ? value.filter((item): item is string => typeof item === "string") : [];
}

async function loadBaseContext(client: ServerSupabaseClient, cocModuleId: string) {
  const { data: coc } = await client
    .from("coc_modules")
    .select("id,coc_code,title,competency_id")
    .eq("id", cocModuleId)
    .maybeSingle();
  if (!coc?.competency_id) throw new QuizGroundingError("CONTEXT_NOT_FOUND");

  const { data: competency } = await client
    .from("competencies")
    .select("id,competency_code,name,source_trace,tesda_source_id")
    .eq("id", coc.competency_id)
    .maybeSingle();
  if (!competency?.tesda_source_id || !competency.source_trace) {
    throw new QuizGroundingError("CONTEXT_INCOMPLETE");
  }

  const { data: source } = await client
    .from("tesda_sources")
    .select("id,qualification_code,title,edition,source_reference,status,approved_at,activated_at")
    .eq("id", competency.tesda_source_id)
    .maybeSingle();
  if (!source) throw new QuizGroundingError("CONTEXT_NOT_FOUND");
  if (
    source.status !== "active" ||
    !source.approved_at ||
    !source.activated_at ||
    !source.qualification_code ||
    !source.edition ||
    !source.source_reference
  ) {
    throw new QuizGroundingError("CONTEXT_NOT_APPROVED");
  }

  const { data: moduleVersion } = await client
    .from("module_versions")
    .select("id,title,version_number,source_trace,tesda_source_id")
    .eq("module_id", coc.id)
    .eq("tesda_source_id", source.id)
    .eq("status", "published")
    .order("version_number", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (!moduleVersion) throw new QuizGroundingError("CONTEXT_NOT_APPROVED");

  return {
    coc,
    competency: { ...competency, source_trace: competency.source_trace },
    source: {
      ...source,
      qualification_code: source.qualification_code,
      edition: source.edition,
      source_reference: source.source_reference,
    },
    moduleVersion,
  };
}

export async function getQuizGroundingCatalog(
  client: ServerSupabaseClient,
  cocModuleId: string,
): Promise<QuizGroundingCatalog> {
  const base = await loadBaseContext(client, cocModuleId);
  const { data: activities } = await client
    .from("activity_versions")
    .select("id,title,mission_id")
    .eq("module_version_id", base.moduleVersion.id)
    .eq("status", "published")
    .order("title");
  if (!activities?.length) throw new QuizGroundingError("CONTEXT_INCOMPLETE");

  const { data: missions } = await client
    .from("missions")
    .select("id,mission_number,title,objective")
    .in("id", activities.map((activity) => activity.mission_id));
  const missionById = new Map((missions ?? []).map((mission) => [mission.id, mission]));

  const options = activities
    .map((activity) => {
      const mission = missionById.get(activity.mission_id);
      return mission?.objective
        ? {
            id: activity.id,
            title: activity.title,
            missionNumber: mission.mission_number,
            missionTitle: mission.title,
            learningOutcome: mission.objective,
          }
        : null;
    })
    .filter((option): option is NonNullable<typeof option> => option !== null)
    .sort((a, b) => a.missionNumber - b.missionNumber);
  if (!options.length) throw new QuizGroundingError("CONTEXT_INCOMPLETE");

  return {
    source: { title: base.source.title, edition: base.source.edition },
    coc: { id: base.coc.id, code: base.coc.coc_code, title: base.coc.title },
    competency: { code: base.competency.competency_code, title: base.competency.name },
    module: { title: base.moduleVersion.title, version: base.moduleVersion.version_number },
    activities: options,
  };
}

export async function loadApprovedQuizGrounding(
  client: ServerSupabaseClient,
  cocModuleId: string,
  activityVersionId: string,
): Promise<QuizGenerationGrounding> {
  const base = await loadBaseContext(client, cocModuleId);
  const { data: activity } = await client
    .from("activity_versions")
    .select("id,title,version_number,instructions,mission_id,module_version_id")
    .eq("id", activityVersionId)
    .eq("module_version_id", base.moduleVersion.id)
    .eq("status", "published")
    .maybeSingle();
  if (!activity) throw new QuizGroundingError("CONTEXT_NOT_APPROVED");

  const [{ data: mission }, { data: rubric }] = await Promise.all([
    client
      .from("missions")
      .select("id,coc_id,competency_id,mission_number,title,objective,scenario,skills_assessed")
      .eq("id", activity.mission_id)
      .eq("coc_id", base.coc.id)
      .eq("competency_id", base.competency.id)
      .maybeSingle(),
    client
      .from("rubric_versions")
      .select("id,title,version_number,tesda_source_id,approved_at")
      .eq("activity_version_id", activity.id)
      .eq("tesda_source_id", base.source.id)
      .eq("status", "approved")
      .order("version_number", { ascending: false })
      .limit(1)
      .maybeSingle(),
  ]);
  if (!mission || !mission.objective || !mission.scenario || !rubric?.approved_at) {
    throw new QuizGroundingError("CONTEXT_NOT_APPROVED");
  }

  const { data: criteria } = await client
    .from("rubric_criteria")
    .select("criterion_code,title,description,is_required,source_trace,order_index")
    .eq("rubric_version_id", rubric.id)
    .order("order_index");
  if (!criteria?.length || criteria.some((criterion) => !criterion.source_trace.trim())) {
    throw new QuizGroundingError("CONTEXT_INCOMPLETE");
  }

  return {
    qualification: { code: base.source.qualification_code, title: base.source.title },
    source: {
      id: base.source.id,
      title: base.source.title,
      edition: base.source.edition,
      reference: base.source.source_reference,
    },
    coc: { id: base.coc.id, code: base.coc.coc_code.toUpperCase(), title: base.coc.title },
    competency: {
      id: base.competency.id,
      code: base.competency.competency_code,
      title: base.competency.name,
      sourceTrace: base.competency.source_trace,
    },
    module: {
      id: base.moduleVersion.id,
      title: base.moduleVersion.title,
      version: base.moduleVersion.version_number,
      sourceTrace: base.moduleVersion.source_trace,
    },
    activity: {
      id: activity.id,
      title: activity.title,
      version: activity.version_number,
      instructions: activity.instructions,
    },
    mission: {
      id: mission.id,
      number: mission.mission_number,
      title: mission.title,
      objective: mission.objective,
      scenario: mission.scenario,
      skillsAssessed: strings(mission.skills_assessed),
    },
    rubric: { id: rubric.id, title: rubric.title, version: rubric.version_number },
    criteria: criteria.map((criterion) => ({
      code: criterion.criterion_code,
      title: criterion.title,
      description: criterion.description,
      required: criterion.is_required,
      sourceTrace: criterion.source_trace,
    })),
  };
}
