import {
  buildLearnerPayload,
  buildRubricCriteria,
  remainingMissionPackages,
  validateMissionPackages,
} from "./mission-assessment-packages.mjs";
import { additionalMissionPackages } from "./mission-assessment-packages-additional.mjs";

export const allRemainingMissionPackages = [
  ...remainingMissionPackages,
  ...additionalMissionPackages,
];

export { buildLearnerPayload, buildRubricCriteria, validateMissionPackages };

export function validateAllMissionPackages() {
  const result = validateMissionPackages(allRemainingMissionPackages);
  if (result.missions !== 19) {
    throw new Error(`Expected 19 remaining mission packages, found ${result.missions}.`);
  }
  const byCoc = Object.fromEntries(
    ["coc1", "coc2", "coc3", "coc4"].map((cocCode) => [
      cocCode,
      allRemainingMissionPackages.filter((item) => item.cocCode === cocCode).length,
    ]),
  );
  const expected = { coc1: 5, coc2: 4, coc3: 5, coc4: 5 };
  if (JSON.stringify(byCoc) !== JSON.stringify(expected)) {
    throw new Error(`Unexpected COC package distribution: ${JSON.stringify(byCoc)}.`);
  }
  for (const definition of allRemainingMissionPackages) {
    const payload = buildLearnerPayload(definition);
    const serialized = JSON.stringify(payload);
    if (serialized.includes('"expected"') || serialized.includes('"evidence_rule"')) {
      throw new Error(`${definition.missionCode} exposes an authoritative answer in learner payload.`);
    }
  }
  return { ...result, byCoc };
}
