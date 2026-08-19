import { randomBytes, randomUUID } from "node:crypto";
import { createClient } from "@supabase/supabase-js";
import {
  allRemainingMissionPackages,
  buildLearnerPayload,
  buildRubricCriteria,
  validateAllMissionPackages,
} from "./all-mission-assessment-packages.mjs";

const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
const publishableKey =
  process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ??
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!url || !publishableKey || !serviceRoleKey) {
  throw new Error("Trusted Supabase publishing environment is unavailable.");
}

const packageValidation = validateAllMissionPackages();
const requestedCoc = process.env.BYTEQUEST_COC?.trim().toLowerCase();
if (requestedCoc && !Object.hasOwn({ coc1: true, coc2: true, coc3: true, coc4: true }, requestedCoc)) {
  throw new Error(`Unsupported BYTEQUEST_COC value: ${requestedCoc}.`);
}
const selectedPackages = requestedCoc
  ? allRemainingMissionPackages.filter((item) => item.cocCode === requestedCoc)
  : allRemainingMissionPackages;
const service = createClient(url, serviceRoleKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});

const sourceByCoc = {
  coc1: {
    unitCode: "ELC724331",
    unitTitle: "Install and Configure Computer Systems",
    pages: "38-41",
  },
  coc2: {
    unitCode: "ELC724332",
    unitTitle: "Set-up Computer Networks",
    pages: "42-45",
  },
  coc3: {
    unitCode: "ELC724333",
    unitTitle: "Set-up Computer Servers",
    pages: "46-48",
  },
  coc4: {
    unitCode: "ELC724334",
    unitTitle: "Maintain and Repair Computer Systems and Networks",
    pages: "49-53",
  },
};

async function createGovernancePrincipal() {
  const suffix = `${new Date().toISOString().replace(/\D/g, "").slice(0, 14)}-${randomUUID().slice(0, 8)}`;
  const email = `bytequest-all-mission-release-${suffix}@bytequest.invalid`;
  const password = process.env.BYTEQUEST_E2E_PASSWORD;
  if (!password) {
    throw new Error("BYTEQUEST_E2E_PASSWORD is required for authenticated lifecycle scripts.");
  }
  const { data, error } = await service.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: {
      full_name: "ByteQuest Mission Release Governance",
      bytequest_technical_principal: true,
      purpose: "publish-19-authoritative-mission-packages",
    },
  });
  if (error || !data.user) {
    throw new Error(error?.message ?? "Technical release principal was not created.");
  }

  const { error: profileError } = await service
    .from("profiles")
    .update({
      full_name: "ByteQuest Mission Release Governance",
      role: "admin",
      status: "active",
    })
    .eq("user_id", data.user.id);
  if (profileError) throw profileError;

  const client = createClient(url, publishableKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { error: signInError } = await client.auth.signInWithPassword({
    email,
    password,
  });
  if (signInError) throw signInError;
  return { id: data.user.id, client };
}

async function retireGovernancePrincipal(principal) {
  if (!principal) return;
  await principal.client.auth.signOut();
  const now = new Date().toISOString();
  const { error: profileError } = await service
    .from("profiles")
    .update({
      status: "deactivated",
      deactivated_at: now,
      deactivation_reason:
        "Technical release principal retired after publishing the remaining authoritative mission packages.",
    })
    .eq("user_id", principal.id);
  if (profileError) throw profileError;
  const { error: banError } = await service.auth.admin.updateUserById(
    principal.id,
    { ban_duration: "876000h" },
  );
  if (banError) throw banError;
}

async function getActiveSource() {
  const { data, error } = await service
    .from("tesda_sources")
    .select("id,qualification_code,title,edition,status,source_reference")
    .eq("qualification_code", "ELCCSS213")
    .eq("status", "active")
    .single();
  if (error) throw error;
  if (data.edition !== "Amended December 2013") {
    throw new Error(`Unexpected active TESDA source edition: ${data.edition}.`);
  }
  return data;
}

async function getCatalog() {
  const [{ data: modules, error: modulesError }, { data: missions, error: missionsError }] =
    await Promise.all([
      service.from("coc_modules").select("id,coc_code,competency_id"),
      service.from("missions").select("id,mission_code"),
    ]);
  if (modulesError) throw modulesError;
  if (missionsError) throw missionsError;
  return {
    modules: new Map(modules.map((item) => [item.coc_code, item])),
    missions: new Map(missions.map((item) => [item.mission_code, item])),
  };
}

async function ensurePublishedModule({ definition, source, principal, baseModule }) {
  const { data: versions, error: versionsError } = await service
    .from("module_versions")
    .select("*")
    .eq("module_id", baseModule.id)
    .eq("tesda_source_id", source.id)
    .order("version_number", { ascending: false });
  if (versionsError) throw versionsError;

  const published = versions.find((item) => item.status === "published");
  if (published) return published;

  const sourceInfo = sourceByCoc[definition.cocCode];
  const versionNumber = (versions[0]?.version_number ?? 0) + 1;
  const { data: inserted, error: insertError } = await service
    .from("module_versions")
    .insert({
      module_id: baseModule.id,
      tesda_source_id: source.id,
      version_number: versionNumber,
      title: `${definition.cocCode.toUpperCase()} - ${sourceInfo.unitTitle}`,
      description:
        "Versioned supplementary ByteQuest module with published evidence-based mission assessments. It does not issue official TESDA certification.",
      source_trace: {
        source_classification: "TESDA_OFFICIAL_APPROVED",
        unit_code: sourceInfo.unitCode,
        unit_title: sourceInfo.unitTitle,
        tr_pages_printed: sourceInfo.pages,
        operational_rules: "PROJECT_APPROVED_OPERATIONAL_RULE",
      },
      content_metadata: {
        supplementary_platform: true,
        issues_official_tesda_certification: false,
        assessment_engine: "database_rule_v1",
      },
      created_by: principal.id,
    })
    .select("*")
    .single();
  if (insertError) throw insertError;

  const { data: publishedVersion, error: publishError } =
    await principal.client.rpc("publish_module_version", {
      p_module_version_id: inserted.id,
      p_reason: `Publish the versioned ${sourceInfo.unitCode} ByteQuest module for its approved operational assessment packages.`,
    });
  if (publishError) throw publishError;
  return publishedVersion;
}

async function ensureActivity({ definition, moduleVersion, mission, principal }) {
  const { data: packageMatches, error: packageError } = await service
    .from("activity_versions")
    .select("*")
    .contains("learner_payload", { assessment_package_id: definition.packageId });
  if (packageError) throw packageError;
  if (packageMatches.length > 1) {
    throw new Error(`Duplicate package identity ${definition.packageId}.`);
  }
  let activity = packageMatches[0];
  if (activity && activity.mission_id !== mission.id) {
    throw new Error(`${definition.packageId} is linked to the wrong mission.`);
  }

  if (!activity) {
    const { data: versions, error: versionsError } = await service
      .from("activity_versions")
      .select("version_number")
      .eq("mission_id", mission.id)
      .order("version_number", { ascending: false });
    if (versionsError) throw versionsError;
    const versionNumber = (versions[0]?.version_number ?? 0) + 1;
    const { data, error } = await service
      .from("activity_versions")
      .insert({
        mission_id: mission.id,
        module_version_id: moduleVersion.id,
        version_number: versionNumber,
        title: definition.title,
        instructions: definition.description,
        delivery_mode: "assessment",
        learner_payload: buildLearnerPayload(definition),
        evaluator_config: {
          engine: "database_rule_v1",
          scoring_method: "binary_sum",
          competency_method: "all_required",
          criterion_display: "SATISFIED_NOT_SATISFIED_INCOMPLETE",
          client_score_authoritative: false,
          official_numeric_threshold: null,
          package_classification: "PROJECT_APPROVED_OPERATIONAL_RULE",
        },
        created_by: principal.id,
      })
      .select("*")
      .single();
    if (error) throw error;
    activity = data;
  }

  if (activity.status === "draft") {
    const { data, error } = await principal.client.rpc("publish_activity_version", {
      p_activity_version_id: activity.id,
      p_reason: `Publish ${definition.localMissionCode} as a versioned evidence-based ByteQuest assessment.`,
    });
    if (error) throw error;
    activity = data;
  }
  if (activity.status !== "published") {
    throw new Error(`${definition.packageId} is ${activity.status}, not published.`);
  }
  return activity;
}

async function ensureRubric({ definition, activity, source, principal }) {
  const { data: versions, error: versionsError } = await service
    .from("rubric_versions")
    .select("*")
    .eq("activity_version_id", activity.id)
    .order("version_number", { ascending: false });
  if (versionsError) throw versionsError;
  let rubric = versions.find((item) => item.status === "approved") ?? versions[0];
  const criteria = buildRubricCriteria(definition);

  if (!rubric) {
    const { data, error } = await service
      .from("rubric_versions")
      .insert({
        activity_version_id: activity.id,
        tesda_source_id: source.id,
        version_number: 1,
        title: `${definition.localMissionCode} Evidence Rubric`,
        status: "draft",
        scoring_method: "PENDING_TESDA_VALIDATION",
        passing_rule: { status: "PENDING_TESDA_VALIDATION" },
        created_by: principal.id,
      })
      .select("*")
      .single();
    if (error) throw error;
    rubric = data;
  }

  if (rubric.status === "approved") {
    const { count, error } = await service
      .from("rubric_criteria")
      .select("id", { count: "exact", head: true })
      .eq("rubric_version_id", rubric.id);
    if (error) throw error;
    if (count !== criteria.length) {
      throw new Error(
        `${definition.packageId} approved rubric has ${count} criteria; expected ${criteria.length}.`,
      );
    }
    return rubric;
  }

  const { error: criteriaError } = await service.from("rubric_criteria").upsert(
    criteria.map((criterion) => ({
      ...criterion,
      rubric_version_id: rubric.id,
    })),
    { onConflict: "rubric_version_id,criterion_code" },
  );
  if (criteriaError) throw criteriaError;

  const { data: approved, error: approveError } = await principal.client.rpc(
    "approve_rubric_version",
    {
      p_rubric_version_id: rubric.id,
      p_scoring_method: "binary_sum",
      p_passing_rule: {
        status: "APPROVED",
        method: "all_required",
        classification: "PROJECT_APPROVED_OPERATIONAL_RULE",
        official_numeric_threshold: null,
        note: "Every required evidence criterion must be SATISFIED. Technical 1/0 values are state encodings, not percentages or weights.",
      },
      p_reason:
        "Approve the project-authorized evidence-based mission rubric with explicit TESDA source provenance and no invented numeric threshold.",
    },
  );
  if (approveError) throw approveError;
  return approved;
}

async function publishAll() {
  const source = await getActiveSource();
  const catalog = await getCatalog();
  const principal = await createGovernancePrincipal();
  const moduleCache = new Map();
  const published = [];
  try {
    for (const definition of selectedPackages) {
      const baseModule = catalog.modules.get(definition.cocCode);
      const mission = catalog.missions.get(definition.missionCode);
      if (!baseModule || !mission) {
        throw new Error(`Catalog entry missing for ${definition.missionCode}.`);
      }

      const sourceInfo = sourceByCoc[definition.cocCode];
      const { error: traceError } = await service
        .from("competencies")
        .update({
          tesda_source_id: source.id,
          source_trace: `${sourceInfo.unitCode} - ${sourceInfo.unitTitle}; amended December 2013 CSS NC II Training Regulations, printed pp.${sourceInfo.pages}.`,
        })
        .eq("id", baseModule.competency_id);
      if (traceError) throw traceError;

      let moduleVersion = moduleCache.get(definition.cocCode);
      if (!moduleVersion) {
        moduleVersion = await ensurePublishedModule({
          definition,
          source,
          principal,
          baseModule,
        });
        moduleCache.set(definition.cocCode, moduleVersion);
      }

      const activity = await ensureActivity({
        definition,
        moduleVersion,
        mission,
        principal,
      });
      const rubric = await ensureRubric({
        definition,
        activity,
        source,
        principal,
      });

      const { error: auditError } = await service.from("audit_events").insert({
        actor_id: principal.id,
        actor_role: "admin",
        action: "assessment_package.published",
        target_type: "activity_version",
        target_id: activity.id,
        reason: `Publish ${definition.localMissionCode} as an approved ByteQuest operational assessment.`,
        metadata: {
          assessment_package_id: definition.packageId,
          mission_code: definition.missionCode,
          coc_code: definition.cocCode,
          unit_code: definition.unitCode,
          tesda_source_id: source.id,
          rubric_version_id: rubric.id,
          criteria_count: definition.criteria.length,
          competency_method: "all_required",
          official_numeric_threshold: null,
        },
        outcome: "success",
      });
      if (auditError) throw auditError;

      published.push({
        mission: definition.missionCode,
        package: definition.packageId,
        activityVersionId: activity.id,
        rubricVersionId: rubric.id,
        criteria: definition.criteria.length,
      });
    }
    return {
      status: "PUBLISHED",
      packageValidation,
      requestedCoc: requestedCoc ?? "all",
      sourceId: source.id,
      missions: published,
    };
  } finally {
    await retireGovernancePrincipal(principal);
  }
}

const result = await publishAll();
console.log(JSON.stringify(result, null, 2));
