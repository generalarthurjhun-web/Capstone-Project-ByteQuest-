import assert from "node:assert/strict";
import test from "node:test";
import { REPORT_OPTIONS, prepareReport, reportToCsv } from "../src/lib/analytics/reports";
import { instructorAnalyticsSchema } from "../src/lib/analytics/types";

const ids = {
  classId: "11111111-1111-4111-8111-111111111111",
  cocId: "22222222-2222-4222-8222-222222222222",
  missionId: "33333333-3333-4333-8333-333333333333",
  criterionId: "44444444-4444-4444-8444-444444444444",
  learnerId: "55555555-5555-4555-8555-555555555555",
  attemptId: "66666666-6666-4666-8666-666666666666",
};

const payload = instructorAnalyticsSchema.parse({
  period: { from: "2026-08-01T00:00:00.000Z", to: "2026-08-11T00:00:00.000Z" },
  filters: {
    classes: [{ id: ids.classId, title: "CSS NC II – A", classCode: "CSS-A", status: "active" }],
    cocs: [{ id: ids.cocId, code: "COC2", title: "Set-up Computer Networks" }],
    missions: [{ id: ids.missionId, cocId: ids.cocId, code: "COC2-M2", number: 2, title: "Cable Termination" }],
  },
  summary: { activeLearners: 1, totalAttempts: 1, assessmentsSubmitted: 1, releasedResults: 1, pendingReview: 0, learnersNeedingAttention: 1 },
  trend: [{ date: "2026-08-10T00:00:00.000Z", submitted: 1, released: 1, criteriaSatisfied: 1 }],
  cocPerformance: [{ id: ids.cocId, code: "COC2", title: "Set-up Computer Networks", attempts: 1, submitted: 1, released: 1, criteriaEvaluated: 2, criteriaSatisfied: 1, criteriaNotSatisfied: 1, satisfactionRate: 50 }],
  missionPerformance: [{ id: ids.missionId, cocId: ids.cocId, cocCode: "COC2", code: "COC2-M2", number: 2, title: "Cable Termination", attempts: 1, submitted: 1, finalized: 1, released: 1, criteriaNotSatisfied: 1, learnersNeedingReview: 1 }],
  criteria: [{ id: ids.criterionId, code: "T568B_SEQUENCE", title: "Chronological T568B arrangement", sourceTrace: "TESDA_OFFICIAL_APPROVED · project operationalization", isRequired: true, cocId: ids.cocId, cocCode: "COC2", missionId: ids.missionId, missionTitle: "Cable Termination", evaluatedAttempts: 1, satisfied: 0, notSatisfied: 1, affectedLearners: 1, repeatFailures: 0, latestFailureAt: "2026-08-10T01:00:00.000Z" }],
  attention: [{ learnerId: ids.learnerId, learnerName: "Test Learner", classId: ids.classId, classTitle: "CSS NC II – A", cocId: ids.cocId, cocCode: "COC2", missionId: ids.missionId, missionTitle: "Cable Termination", criterionId: ids.criterionId, criterionCode: "T568B_SEQUENCE", criterionTitle: "Chronological T568B arrangement", failedAttempts: 1, repeatFailures: 0, lastActivity: "2026-08-10T01:00:00.000Z", latestAttemptId: ids.attemptId, reason: "Criterion evidence was not satisfied" }],
  workflow: [{ status: "released", count: 1 }],
  retries: [{ cocId: ids.cocId, cocCode: "COC2", missionId: ids.missionId, missionTitle: "Cable Termination", attempts: 1, learnerAssignments: 1, averageAttempts: 1, learnersRetrying: 0 }],
  progressMatrix: [{ learnerId: ids.learnerId, learnerName: "Test Learner", classId: ids.classId, classTitle: "CSS NC II – A", cocs: [{ id: ids.cocId, code: "COC2", title: "Set-up Computer Networks", state: "needs_support" }] }],
  assessmentHistory: [{ attemptId: ids.attemptId, learnerId: ids.learnerId, learnerName: "Test Learner", classId: ids.classId, classTitle: "CSS NC II – A", cocId: ids.cocId, cocCode: "COC2", missionId: ids.missionId, missionTitle: "Cable Termination", assignmentTitle: "Network Lab", status: "released", eventAt: "2026-08-10T01:00:00.000Z", submittedAt: "2026-08-10T00:30:00.000Z", releasedAt: "2026-08-10T01:00:00.000Z", attemptNumber: 1 }],
  releasedResults: [{ attemptId: ids.attemptId, learnerId: ids.learnerId, learnerName: "Test Learner", learnerEmail: "test@example.invalid", classId: ids.classId, classTitle: "CSS NC II – A", cocId: ids.cocId, cocCode: "COC2", missionId: ids.missionId, missionTitle: "Cable Termination", assignmentTitle: "Network Lab", outcome: "not_yet_competent", percentage: null, remarks: "Review sequence, then retry", releaseReason: "Instructor released", releasedAt: "2026-08-10T01:00:00.000Z" }],
});

test("all eight report types use the normalized analytics payload", () => {
  for (const option of REPORT_OPTIONS) {
    const report = prepareReport(option.value, payload);
    assert.equal(report.type, option.value);
    assert.ok(report.columns.length > 0);
    assert.ok(report.rows.length > 0, `${option.value} should expose the real fixture row`);
    assert.doesNotMatch(`${report.title} ${report.description}`, /TESDA Score/i);
  }
});

test("analytics and reports preserve the same released-result counts", () => {
  const classReport = prepareReport("class_performance", payload);
  assert.equal(classReport.rows[0]?.attempts, payload.summary.totalAttempts);
  assert.equal(classReport.rows[0]?.released, payload.summary.releasedResults);
  const releasedReport = prepareReport("released_results", payload);
  assert.equal(releasedReport.rows.length, payload.summary.releasedResults);
  assert.equal(releasedReport.rows[0]?.result, "Criterion-based");
});

test("CSV export is UTF-8 BOM prefixed and escapes quoted/comma content", () => {
  const report = prepareReport("released_results", {
    ...payload,
    releasedResults: [{ ...payload.releasedResults[0], remarks: "Review cable, then \"retry\"" }],
  });
  const csv = reportToCsv(report);
  assert.ok(csv.startsWith("\uFEFF"));
  assert.match(csv, /"Review cable, then ""retry"""/);
});

test("analytics validation rejects impossible negative counts", () => {
  assert.throws(() => instructorAnalyticsSchema.parse({
    ...payload,
    summary: { ...payload.summary, totalAttempts: -1 },
  }));
});
