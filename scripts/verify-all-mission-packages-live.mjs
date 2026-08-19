import { createClient } from "@supabase/supabase-js";
import { allRemainingMissionPackages } from "./all-mission-assessment-packages.mjs";

const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !serviceRoleKey) {
  throw new Error("Trusted Supabase verification environment is unavailable.");
}
const service = createClient(url, serviceRoleKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function containsForbiddenKey(value) {
  if (Array.isArray(value)) return value.some(containsForbiddenKey);
  if (!value || typeof value !== "object") return false;
  for (const [key, child] of Object.entries(value)) {
    if (["expected", "expected_targets", "evidence_rule"].includes(key)) return true;
    if (containsForbiddenKey(child)) return true;
  }
  return false;
}

const expected = new Map(
  allRemainingMissionPackages.map((item) => [
    item.missionCode,
    { packageId: item.packageId, criteria: item.criteria.length },
  ]),
);
expected.set("coc2_m2", {
  packageId: "coc2-cable-termination-testing-v1",
  criteria: 9,
});

const { data: missions, error: missionError } = await service
  .from("missions")
  .select("id,mission_code,title")
  .in("mission_code", [...expected.keys()]);
if (missionError) throw missionError;
assert(missions.length === 20, `Expected 20 mission catalog rows; found ${missions.length}.`);

const missionById = new Map(missions.map((item) => [item.id, item]));
const { data: activities, error: activityError } = await service
  .from("activity_versions")
  .select("id,mission_id,status,learner_payload,evaluator_config,version_number")
  .in("mission_id", [...missionById.keys()])
  .eq("status", "published");
if (activityError) throw activityError;

const authoritativeActivities = activities.filter((activity) => {
  const packageId = activity.learner_payload?.assessment_package_id;
  return typeof packageId === "string" &&
    [...expected.values()].some((item) => item.packageId === packageId);
});
assert(authoritativeActivities.length === 20, `Expected 20 published authoritative activities; found ${authoritativeActivities.length}.`);
assert(
  new Set(authoritativeActivities.map((item) => item.learner_payload.assessment_package_id)).size === 20,
  "Published assessment package identities are not unique.",
);

const { data: rubrics, error: rubricError } = await service
  .from("rubric_versions")
  .select("id,activity_version_id,status,passing_rule,scoring_method")
  .in("activity_version_id", authoritativeActivities.map((item) => item.id))
  .eq("status", "approved");
if (rubricError) throw rubricError;
assert(rubrics.length === 20, `Expected 20 approved rubrics; found ${rubrics.length}.`);

const { data: criteria, error: criteriaError } = await service
  .from("rubric_criteria")
  .select("id,rubric_version_id,criterion_code,evidence_rule,is_required")
  .in("rubric_version_id", rubrics.map((item) => item.id));
if (criteriaError) throw criteriaError;

const rubricByActivity = new Map(rubrics.map((item) => [item.activity_version_id, item]));
const rows = [];
for (const activity of authoritativeActivities) {
  const mission = missionById.get(activity.mission_id);
  assert(mission, `Activity ${activity.id} has no mission.`);
  const expectation = expected.get(mission.mission_code);
  const packageId = activity.learner_payload.assessment_package_id;
  assert(packageId === expectation.packageId, `${mission.mission_code} has package ${packageId}.`);
  assert(activity.learner_payload.result_visibility === "released_only", `${mission.mission_code} does not withhold unreleased results.`);
  assert(!containsForbiddenKey(activity.learner_payload), `${mission.mission_code} learner payload exposes an answer.`);
  assert(activity.evaluator_config?.client_score_authoritative === false, `${mission.mission_code} trusts a client score.`);
  assert(activity.evaluator_config?.official_numeric_threshold === null, `${mission.mission_code} has an unsupported numeric threshold.`);
  const rubric = rubricByActivity.get(activity.id);
  assert(rubric?.passing_rule?.method === "all_required", `${mission.mission_code} does not use all-required evaluation.`);
  assert(rubric?.passing_rule?.official_numeric_threshold === null, `${mission.mission_code} rubric has a numeric threshold.`);
  const missionCriteria = criteria.filter((item) => item.rubric_version_id === rubric.id);
  assert(missionCriteria.length === expectation.criteria, `${mission.mission_code} has ${missionCriteria.length} criteria; expected ${expectation.criteria}.`);
  assert(missionCriteria.every((item) => item.is_required), `${mission.mission_code} contains a non-required criterion in the required package.`);
  rows.push({
    coc: mission.mission_code.slice(0, 4).toUpperCase(),
    mission: mission.mission_code,
    activityVersion: activity.version_number,
    criteria: missionCriteria.length,
    status: "AUTHORITATIVE",
  });
}

rows.sort((left, right) => left.mission.localeCompare(right.mission, undefined, { numeric: true }));
const criteriaTotal = rows.reduce((sum, item) => sum + item.criteria, 0);
assert(criteriaTotal === 98, `Expected 98 criteria across 20 missions; found ${criteriaTotal}.`);
console.log(JSON.stringify({
  status: "PASS",
  missions: rows.length,
  criteria: criteriaTotal,
  byCoc: Object.fromEntries(["COC1", "COC2", "COC3", "COC4"].map((coc) => [coc, rows.filter((item) => item.coc === coc).length])),
  rows,
}, null, 2));
