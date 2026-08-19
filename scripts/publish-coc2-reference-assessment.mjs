import { randomBytes, randomUUID } from "node:crypto";
import { createClient } from "@supabase/supabase-js";

const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
const publishableKey =
  process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ??
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!url || !publishableKey || !serviceRoleKey) {
  throw new Error("Trusted Supabase deployment environment is unavailable.");
}

const service = createClient(url, serviceRoleKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});

const PACKAGE_ID = "coc2-cable-termination-testing-v1";
const SOURCE = {
  qualificationCode: "ELCCSS213",
  title: "Training Regulations: Computer Systems Servicing NC II",
  edition: "Amended December 2013",
  reference:
    "https://tesda.gov.ph/Downloadables/TRs/TR%20Computer%20Systems%20Servicing%20NC%20II%20.pdf",
  sha256: "42D85DAD87D0566B8B965AC0868E0F92E6CBB4C578028EFF648DB21BE421D147",
};

const binaryRule = {
  status: "APPROVED",
  method: "binary",
  satisfied_value: 1,
  not_satisfied_value: 0,
  classification: "TECHNICAL_BINARY_ENCODING",
  note: "1/0 encodes SATISFIED/NOT SATISFIED; it is not a TESDA percentage or criterion weight.",
};

const criteria = [
  {
    criterion_code: "COC2-CABLE-01-PPE-OHS",
    title: "PPE and OHS preparation",
    description: "Select the required PPE for the approved cable-termination scenario before beginning work.",
    source_trace:
      "TESDA_OFFICIAL_APPROVED — ELC724332 Element 1 PC1.4; Range of Variables 4-5; TR printed pp.42-44. Exact scenario checklist is PROJECT_APPROVED_OPERATIONAL_RULE.",
    evidence_rule: {
      operator: "final_action_value_set_equals",
      action_type: "ppe_selection_submitted",
      value_key: "selected_items",
      expected: ["gloves", "goggles", "working_clothes"],
    },
  },
  {
    criterion_code: "COC2-CABLE-02-TOOLS-MATERIALS",
    title: "Required tools and materials prepared",
    description: "Select the cable, connectors, termination tools, and LAN tester required by the scenario.",
    source_trace:
      "TESDA_OFFICIAL_APPROVED — ELC724332 Element 1 PCs1.2-1.3; Range of Variables 2-3; TR printed pp.42-44. Exact scenario inventory is PROJECT_APPROVED_OPERATIONAL_RULE.",
    evidence_rule: {
      operator: "final_action_value_set_equals",
      action_type: "tools_materials_selection_submitted",
      value_key: "selected_items",
      expected: [
        "copper_cable",
        "rj45_connector",
        "wire_stripper",
        "crimping_tool",
        "lan_cable_tester",
      ],
    },
  },
  {
    criterion_code: "COC2-CABLE-03-CABLE-PREPARATION",
    title: "Cable prepared in the required sequence",
    description: "Complete the approved preparation actions in chronological order.",
    source_trace:
      "TESDA_OFFICIAL_APPROVED basis — ELC724332 PC1.5 and Evidence Guide 2.2-2.3/3.1. The exact simulated preparation sequence is PROJECT_APPROVED_OPERATIONAL_RULE.",
    evidence_rule: {
      operator: "exact_target_sequence",
      action_type: "cable_preparation_step",
      expected_targets: ["measure_cable", "strip_jacket", "untwist_and_straighten"],
    },
  },
  {
    criterion_code: "COC2-CABLE-04-T568B-ORDER",
    title: "T568B conductor arrangement completed chronologically",
    description: "Arrange all eight conductors in the approved T568B scenario order.",
    source_trace:
      "TESDA_OFFICIAL_APPROVED basis — ELC724332 PC1.5 requires EIA/TIA-based copper splicing; official COC2 SAG explicitly names 568A and 568B. Exact T568B scenario/order is PROJECT_APPROVED_OPERATIONAL_RULE.",
    evidence_rule: {
      operator: "exact_target_sequence",
      action_type: "conductor_placed",
      expected_targets: [
        "white_orange",
        "orange",
        "white_green",
        "blue",
        "white_blue",
        "green",
        "white_brown",
        "brown",
      ],
    },
  },
  {
    criterion_code: "COC2-CABLE-05-TERMINATION",
    title: "Connector termination and crimping completed",
    description: "Complete insertion, jacket-depth verification, and crimping in order.",
    source_trace:
      "TESDA_OFFICIAL_APPROVED basis — ELC724332 PC1.5 and Evidence Guide 2.3/3.1. Exact simulated termination sequence is PROJECT_APPROVED_OPERATIONAL_RULE.",
    evidence_rule: {
      operator: "exact_target_sequence",
      action_type: "termination_step",
      expected_targets: ["insert_conductors", "verify_jacket_depth", "crimp_connector"],
    },
  },
  {
    criterion_code: "COC2-CABLE-06-TESTER-PROCEDURE",
    title: "LAN cable tester used in the required sequence",
    description: "Connect both ends, power the tester, and observe the indicator sequence.",
    source_trace:
      "TESDA_OFFICIAL_APPROVED basis — ELC724332 PCs1.3, 2.1 and 4.2; Evidence Guide 2.3 and 2.17. Exact simulated tester sequence is PROJECT_APPROVED_OPERATIONAL_RULE.",
    evidence_rule: {
      operator: "exact_target_sequence",
      action_type: "tester_step",
      expected_targets: ["connect_both_ends", "power_on_tester", "observe_indicator_sequence"],
    },
  },
  {
    criterion_code: "COC2-CABLE-07-TESTER-RESULT",
    title: "Tester result correctly observed",
    description: "Record the terminal-connectivity result shown by the approved scenario.",
    source_trace:
      "TESDA_OFFICIAL_APPROVED basis — ELC724332 PCs2.1 and 4.2; Evidence Guide 1.4/2.17. The presented passing wire-map scenario is PROJECT_APPROVED_OPERATIONAL_RULE.",
    evidence_rule: {
      operator: "final_action_value_equals",
      action_type: "tester_result_submitted",
      value_key: "result",
      expected: "pass",
    },
  },
  {
    criterion_code: "COC2-CABLE-08-INSPECTION",
    title: "Physical and visual inspection completed",
    description: "Inspect the finished cable for damage, conductor order, and connector security.",
    source_trace:
      "TESDA_OFFICIAL_APPROVED — ELC724332 PCs1.7, 4.1 and 4.2. Exact simulated inspection checklist is PROJECT_APPROVED_OPERATIONAL_RULE.",
    evidence_rule: {
      operator: "final_action_value_set_equals",
      action_type: "inspection_selection_submitted",
      value_key: "selected_items",
      expected: ["no_visible_damage", "pin_order_compliant", "connector_secure"],
    },
  },
  {
    criterion_code: "COC2-CABLE-09-CLEANUP",
    title: "Work area cleaned and completed safely",
    description: "Return tools, clear the work area, and sort cable scraps for approved disposal.",
    source_trace:
      "TESDA_OFFICIAL_APPROVED basis — ELC724332 PCs1.8-1.9; COC2 SAG requires 5S and 3Rs. Exact simulated completion checklist is PROJECT_APPROVED_OPERATIONAL_RULE.",
    evidence_rule: {
      operator: "final_action_value_set_equals",
      action_type: "cleanup_selection_submitted",
      value_key: "selected_items",
      expected: ["tools_returned", "work_area_cleared", "scraps_sorted"],
    },
  },
].map((criterion, index) => ({
  ...criterion,
  scoring_rule: binaryRule,
  max_value: 1,
  order_index: index + 1,
  is_required: true,
}));

async function findPublishedPackage() {
  const { data, error } = await service
    .from("activity_versions")
    .select("id,status,learner_payload,rubric_versions(id,status,passing_rule)")
    .contains("learner_payload", { assessment_package_id: PACKAGE_ID })
    .maybeSingle();
  if (error) throw error;
  return data;
}

async function createGovernancePrincipal() {
  const suffix = `${new Date().toISOString().replace(/\D/g, "").slice(0, 14)}-${randomUUID().slice(0, 8)}`;
  const email = `bytequest-release-governance-${suffix}@bytequest.invalid`;
  const password = process.env.BYTEQUEST_E2E_PASSWORD;
  if (!password) {
    throw new Error("BYTEQUEST_E2E_PASSWORD is required for authenticated lifecycle scripts.");
  }
  const { data, error } = await service.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: {
      full_name: "ByteQuest Release Governance",
      bytequest_technical_principal: true,
      purpose: PACKAGE_ID,
    },
  });
  if (error || !data.user) throw new Error(error?.message ?? "Technical principal was not created.");

  const { error: profileError } = await service
    .from("profiles")
    .update({
      full_name: "ByteQuest Release Governance",
      role: "admin",
      status: "active",
    })
    .eq("user_id", data.user.id);
  if (profileError) throw profileError;

  const client = createClient(url, publishableKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { error: signInError } = await client.auth.signInWithPassword({ email, password });
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
      deactivation_reason: `Technical release principal retired after publishing ${PACKAGE_ID}.`,
    })
    .eq("user_id", principal.id);
  if (profileError) throw profileError;
  const { error: banError } = await service.auth.admin.updateUserById(principal.id, {
    ban_duration: "876000h",
  });
  if (banError) throw banError;
}

async function publish() {
  const existing = await findPublishedPackage();
  if (existing?.status === "published") {
    const approved = existing.rubric_versions?.find((rubric) => rubric.status === "approved");
    if (approved?.passing_rule?.method === "all_required") {
      return { status: "ALREADY_PUBLISHED", activityVersionId: existing.id, rubricVersionId: approved.id };
    }
  }

  const principal = await createGovernancePrincipal();
  let source;
  try {
    const { data: existingSource, error: sourceLookupError } = await service
      .from("tesda_sources")
      .select("*")
      .eq("qualification_code", SOURCE.qualificationCode)
      .eq("title", SOURCE.title)
      .eq("edition", SOURCE.edition)
      .maybeSingle();
    if (sourceLookupError) throw sourceLookupError;
    source = existingSource;

    if (!source) {
      const { data, error } = await principal.client.rpc("register_tesda_source", {
        p_qualification_code: SOURCE.qualificationCode,
        p_title: SOURCE.title,
        p_edition: SOURCE.edition,
        p_effective_date: null,
        p_publication_date: null,
        p_source_reference: SOURCE.reference,
        p_document_storage_path: null,
        p_validation_notes: `Official TESDA primary source verified by SHA-256 ${SOURCE.sha256}.`,
      });
      if (error) throw error;
      source = data;
    }

    if (source.status === "pending_tesda_validation") {
      const { data, error } = await principal.client.rpc("approve_tesda_source", {
        p_source_id: source.id,
        p_validation_notes:
          `TESDA_OFFICIAL_APPROVED: official amended December 2013 CSS NC II Training Regulations; SHA-256 ${SOURCE.sha256}.`,
      });
      if (error) throw error;
      source = data;
    }
    if (source.status === "approved") {
      const { data, error } = await principal.client.rpc("activate_tesda_source", {
        p_source_id: source.id,
        p_reason:
          "Activate the verified official source for the project-owner-approved COC2 cable-termination reference assessment.",
      });
      if (error) throw error;
      source = data;
    }
    if (source.status !== "active") throw new Error(`TESDA source is ${source.status}, not active.`);

    const { data: baseModule, error: moduleLookupError } = await service
      .from("coc_modules")
      .select("id,competency_id")
      .eq("coc_code", "coc2")
      .single();
    if (moduleLookupError) throw moduleLookupError;
    const { data: mission, error: missionLookupError } = await service
      .from("missions")
      .select("id")
      .eq("mission_code", "coc2_m2")
      .single();
    if (missionLookupError) throw missionLookupError;

    const { error: competencyTraceError } = await service
      .from("competencies")
      .update({
        tesda_source_id: source.id,
        source_trace: "ELC724332 — Set-up Computer Networks; TR amended December 2013, printed pp.42-45.",
      })
      .eq("id", baseModule.competency_id);
    if (competencyTraceError) throw competencyTraceError;

    let { data: moduleVersion, error: moduleVersionError } = await service
      .from("module_versions")
      .select("*")
      .eq("module_id", baseModule.id)
      .eq("version_number", 1)
      .maybeSingle();
    if (moduleVersionError) throw moduleVersionError;
    if (!moduleVersion) {
      const insert = await service
        .from("module_versions")
        .insert({
          module_id: baseModule.id,
          tesda_source_id: source.id,
          version_number: 1,
          title: "COC2 — Set-up Computer Networks",
          description:
            "Versioned COC2 learning module anchored to ELC724332. The first assessment-capable activity is Cable Termination and Testing.",
          source_trace: {
            source_classification: "TESDA_OFFICIAL_APPROVED",
            unit_code: "ELC724332",
            unit_title: "Set-up Computer Networks",
            tr_pages_printed: "42-45",
            source_sha256: SOURCE.sha256,
          },
          content_metadata: {
            supplementary_platform: true,
            issues_official_tesda_certification: false,
            first_reference_assessment: PACKAGE_ID,
          },
          created_by: principal.id,
        })
        .select("*")
        .single();
      if (insert.error) throw insert.error;
      moduleVersion = insert.data;
    }
    if (moduleVersion.status === "draft") {
      const { data, error } = await principal.client.rpc("publish_module_version", {
        p_module_version_id: moduleVersion.id,
        p_reason: "Publish the versioned ELC724332 module for the approved COC2 reference assessment.",
      });
      if (error) throw error;
      moduleVersion = data;
    }

    let { data: activityVersion, error: activityVersionError } = await service
      .from("activity_versions")
      .select("*")
      .eq("mission_id", mission.id)
      .eq("version_number", 1)
      .maybeSingle();
    if (activityVersionError) throw activityVersionError;
    if (!activityVersion) {
      const insert = await service
        .from("activity_versions")
        .insert({
          mission_id: mission.id,
          module_version_id: moduleVersion.id,
          version_number: 1,
          title: "Cable Termination and Testing",
          instructions:
            "Prepare safely, select the required tools, prepare and terminate the cable, arrange the T568B conductors, test and inspect the result, then complete 5S cleanup. Actions are recorded in chronological order for Instructor review.",
          delivery_mode: "assessment",
          learner_payload: {
            assessment_package_id: PACKAGE_ID,
            local_mission_code: "COC2-M2",
            simulation_template: "coc2_cable_termination",
            standard_scenario: "T568B",
            result_visibility: "released_only",
            supplementary_disclaimer: true,
          },
          evaluator_config: {
            engine: "database_rule_v1",
            scoring_method: "binary_sum",
            competency_method: "all_required",
            criterion_display: "SATISFIED_NOT_SATISFIED",
            client_score_authoritative: false,
            official_numeric_threshold: null,
            package_classification: "PROJECT_APPROVED_OPERATIONAL_RULE",
          },
          created_by: principal.id,
        })
        .select("*")
        .single();
      if (insert.error) throw insert.error;
      activityVersion = insert.data;
    }
    if (activityVersion.status === "draft") {
      const { data, error } = await principal.client.rpc("publish_activity_version", {
        p_activity_version_id: activityVersion.id,
        p_reason: "Publish the approved COC2 cable-termination and testing operational assessment.",
      });
      if (error) throw error;
      activityVersion = data;
    }

    let { data: rubricVersion, error: rubricVersionError } = await service
      .from("rubric_versions")
      .select("*")
      .eq("activity_version_id", activityVersion.id)
      .eq("version_number", 1)
      .maybeSingle();
    if (rubricVersionError) throw rubricVersionError;
    if (!rubricVersion) {
      const insert = await service
        .from("rubric_versions")
        .insert({
          activity_version_id: activityVersion.id,
          tesda_source_id: source.id,
          version_number: 1,
          title: "COC2 Cable Termination Evidence Rubric",
          status: "draft",
          scoring_method: "PENDING_TESDA_VALIDATION",
          passing_rule: { status: "PENDING_TESDA_VALIDATION" },
          created_by: principal.id,
        })
        .select("*")
        .single();
      if (insert.error) throw insert.error;
      rubricVersion = insert.data;
    }

    if (rubricVersion.status !== "approved") {
      const { error: criteriaError } = await service.from("rubric_criteria").upsert(
        criteria.map((criterion) => ({ ...criterion, rubric_version_id: rubricVersion.id })),
        { onConflict: "rubric_version_id,criterion_code" },
      );
      if (criteriaError) throw criteriaError;

      const { data, error } = await principal.client.rpc("approve_rubric_version", {
        p_rubric_version_id: rubricVersion.id,
        p_scoring_method: "binary_sum",
        p_passing_rule: {
          status: "APPROVED",
          method: "all_required",
          classification: "PROJECT_APPROVED_OPERATIONAL_RULE",
          official_numeric_threshold: null,
          note: "Every required evidence criterion must be SATISFIED; no arbitrary percentage is used for the competency decision.",
        },
        p_reason:
          "Approve the project-owner-authorized evidence-based COC2 operational rubric; official TESDA provenance and project operational decisions remain explicitly separated.",
      });
      if (error) throw error;
      rubricVersion = data;
    }

    const { error: auditError } = await service.from("audit_events").insert({
      actor_id: principal.id,
      actor_role: "admin",
      action: "assessment_package.published",
      target_type: "activity_version",
      target_id: activityVersion.id,
      reason: "Project-owner approval of the first complete COC2 operational assessment package.",
      metadata: {
        assessment_package_id: PACKAGE_ID,
        tesda_source_id: source.id,
        rubric_version_id: rubricVersion.id,
        criteria_count: criteria.length,
        official_numeric_threshold: null,
        competency_method: "all_required",
      },
      outcome: "success",
    });
    if (auditError) throw auditError;

    return {
      status: "PUBLISHED",
      sourceId: source.id,
      moduleVersionId: moduleVersion.id,
      activityVersionId: activityVersion.id,
      rubricVersionId: rubricVersion.id,
      criteriaCount: criteria.length,
    };
  } finally {
    await retireGovernancePrincipal(principal);
  }
}

const result = await publish();
console.log(JSON.stringify(result, null, 2));
