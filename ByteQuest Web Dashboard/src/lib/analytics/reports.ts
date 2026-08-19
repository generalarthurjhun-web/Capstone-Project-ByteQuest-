import type { InstructorAnalytics, ReportType } from "@/lib/analytics/types";

export type ReportColumn = { key: string; label: string; align?: "left" | "right" };
export type ReportRow = Record<string, string | number | null>;

export type PreparedReport = {
  type: ReportType;
  title: string;
  description: string;
  columns: ReportColumn[];
  rows: ReportRow[];
};

export const REPORT_OPTIONS: Array<{ value: ReportType; label: string; description: string }> = [
  { value: "class_performance", label: "Class Performance", description: "Attempt, learner, release, and final outcome activity by class." },
  { value: "learner_performance", label: "Learner Performance", description: "Scoped attempt and released-result history for each learner." },
  { value: "coc_competency", label: "COC Competency", description: "Criterion satisfaction and assessment activity by COC." },
  { value: "mission_assessment", label: "Mission Assessment", description: "Mission workload, finalization, release, and review signals." },
  { value: "criterion_analysis", label: "Criterion Analysis", description: "Versioned criterion outcomes, provenance, and affected learners." },
  { value: "assessment_history", label: "Assessment History", description: "Chronological, authoritative attempt-state history." },
  { value: "intervention", label: "Intervention", description: "Objective evidence signals that may require Instructor support." },
  { value: "released_results", label: "Released Results", description: "Current Instructor-final results that have been released." },
];

function formatDate(value: string | null): string {
  if (!value) return "—";
  return new Intl.DateTimeFormat("en-PH", {
    dateStyle: "medium",
    timeStyle: "short",
    timeZone: "Asia/Manila",
  }).format(new Date(value));
}

function outcomeLabel(value: string): string {
  return value.replaceAll("_", " ").replace(/\b\w/g, (letter) => letter.toUpperCase());
}

export function prepareReport(type: ReportType, data: InstructorAnalytics): PreparedReport {
  const option = REPORT_OPTIONS.find((item) => item.value === type) ?? REPORT_OPTIONS[0];

  if (type === "class_performance") {
    const classRows = new Map<string, { className: string; attempts: number; learners: Set<string>; released: number; competent: number; notYetCompetent: number }>();
    for (const attempt of data.assessmentHistory) {
      const row = classRows.get(attempt.classId) ?? { className: attempt.classTitle, attempts: 0, learners: new Set<string>(), released: 0, competent: 0, notYetCompetent: 0 };
      row.attempts += 1;
      row.learners.add(attempt.learnerId);
      classRows.set(attempt.classId, row);
    }
    for (const release of data.releasedResults) {
      const row = classRows.get(release.classId) ?? { className: release.classTitle, attempts: 0, learners: new Set<string>(), released: 0, competent: 0, notYetCompetent: 0 };
      row.released += 1;
      if (release.outcome === "competent") row.competent += 1;
      if (release.outcome === "not_yet_competent") row.notYetCompetent += 1;
      row.learners.add(release.learnerId);
      classRows.set(release.classId, row);
    }
    return {
      type,
      title: `${option.label} Report`,
      description: option.description,
      columns: [
        { key: "class", label: "Class" }, { key: "learners", label: "Learners", align: "right" },
        { key: "attempts", label: "Attempts", align: "right" }, { key: "released", label: "Released", align: "right" },
        { key: "competent", label: "Competent", align: "right" }, { key: "notYetCompetent", label: "Not Yet Competent", align: "right" },
      ],
      rows: [...classRows.values()].sort((a, b) => a.className.localeCompare(b.className)).map((row) => ({ class: row.className, learners: row.learners.size, attempts: row.attempts, released: row.released, competent: row.competent, notYetCompetent: row.notYetCompetent })),
    };
  }

  if (type === "learner_performance") {
    const learners = new Map<string, { learner: string; className: string; attempts: number; released: number; competent: number; support: number }>();
    for (const attempt of data.assessmentHistory) {
      const key = `${attempt.classId}:${attempt.learnerId}`;
      const row = learners.get(key) ?? { learner: attempt.learnerName, className: attempt.classTitle, attempts: 0, released: 0, competent: 0, support: 0 };
      row.attempts += 1;
      learners.set(key, row);
    }
    for (const release of data.releasedResults) {
      const key = `${release.classId}:${release.learnerId}`;
      const row = learners.get(key) ?? { learner: release.learnerName, className: release.classTitle, attempts: 0, released: 0, competent: 0, support: 0 };
      row.released += 1;
      if (release.outcome === "competent") row.competent += 1;
      else if (release.outcome === "not_yet_competent") row.support += 1;
      learners.set(key, row);
    }
    return {
      type,
      title: `${option.label} Report`, description: option.description,
      columns: [{ key: "learner", label: "Learner" }, { key: "class", label: "Class" }, { key: "attempts", label: "Attempts", align: "right" }, { key: "released", label: "Released", align: "right" }, { key: "competent", label: "Competent", align: "right" }, { key: "support", label: "Needs Support", align: "right" }],
      rows: [...learners.values()].sort((a, b) => a.learner.localeCompare(b.learner)).map((row) => ({ learner: row.learner, class: row.className, attempts: row.attempts, released: row.released, competent: row.competent, support: row.support })),
    };
  }

  if (type === "coc_competency") {
    return {
      type,
      title: `${option.label} Report`, description: option.description,
      columns: [{ key: "coc", label: "COC" }, { key: "attempts", label: "Attempts", align: "right" }, { key: "released", label: "Released", align: "right" }, { key: "evaluated", label: "Criteria Evaluated", align: "right" }, { key: "satisfied", label: "Satisfied", align: "right" }, { key: "notSatisfied", label: "Not Satisfied", align: "right" }, { key: "rate", label: "Criterion Satisfaction", align: "right" }],
      rows: data.cocPerformance.map((row) => ({ coc: `${row.code} · ${row.title}`, attempts: row.attempts, released: row.released, evaluated: row.criteriaEvaluated, satisfied: row.criteriaSatisfied, notSatisfied: row.criteriaNotSatisfied, rate: row.satisfactionRate === null ? "—" : `${row.satisfactionRate}%` })),
    };
  }

  if (type === "mission_assessment") {
    return {
      type,
      title: `${option.label} Report`, description: option.description,
      columns: [{ key: "mission", label: "Mission" }, { key: "attempts", label: "Attempts", align: "right" }, { key: "submitted", label: "Submitted", align: "right" }, { key: "finalized", label: "Finalized", align: "right" }, { key: "released", label: "Released", align: "right" }, { key: "notSatisfied", label: "Unsatisfied Criteria", align: "right" }, { key: "review", label: "Learners Needing Review", align: "right" }],
      rows: data.missionPerformance.map((row) => ({ mission: `${row.cocCode} · ${row.title}`, attempts: row.attempts, submitted: row.submitted, finalized: row.finalized, released: row.released, notSatisfied: row.criteriaNotSatisfied, review: row.learnersNeedingReview })),
    };
  }

  if (type === "criterion_analysis") {
    return {
      type,
      title: `${option.label} Report`, description: option.description,
      columns: [{ key: "criterion", label: "Criterion" }, { key: "mission", label: "COC / Mission" }, { key: "provenance", label: "Provenance" }, { key: "evaluated", label: "Evaluated", align: "right" }, { key: "satisfied", label: "Satisfied", align: "right" }, { key: "notSatisfied", label: "Not Satisfied", align: "right" }, { key: "affected", label: "Affected Learners", align: "right" }, { key: "repeats", label: "Repeat Failures", align: "right" }],
      rows: data.criteria.map((row) => ({ criterion: `${row.code} · ${row.title}`, mission: `${row.cocCode} · ${row.missionTitle}`, provenance: row.sourceTrace, evaluated: row.evaluatedAttempts, satisfied: row.satisfied, notSatisfied: row.notSatisfied, affected: row.affectedLearners, repeats: row.repeatFailures })),
    };
  }

  if (type === "assessment_history") {
    return {
      type,
      title: `${option.label} Report`, description: option.description,
      columns: [{ key: "date", label: "Activity Date" }, { key: "learner", label: "Learner" }, { key: "class", label: "Class" }, { key: "mission", label: "COC / Mission" }, { key: "attempt", label: "Attempt", align: "right" }, { key: "status", label: "State" }],
      rows: data.assessmentHistory.map((row) => ({ date: formatDate(row.eventAt), learner: row.learnerName, class: row.classTitle, mission: `${row.cocCode} · ${row.missionTitle}`, attempt: row.attemptNumber, status: outcomeLabel(row.status) })),
    };
  }

  if (type === "intervention") {
    return {
      type,
      title: `${option.label} Report`, description: option.description,
      columns: [{ key: "learner", label: "Learner" }, { key: "class", label: "Class" }, { key: "mission", label: "COC / Mission" }, { key: "criterion", label: "Criterion" }, { key: "failed", label: "Failed Attempts", align: "right" }, { key: "repeats", label: "Repeat Failures", align: "right" }, { key: "lastActivity", label: "Last Activity" }, { key: "reason", label: "Support Signal" }],
      rows: data.attention.map((row) => ({ learner: row.learnerName, class: row.classTitle, mission: `${row.cocCode} · ${row.missionTitle}`, criterion: `${row.criterionCode} · ${row.criterionTitle}`, failed: row.failedAttempts, repeats: row.repeatFailures, lastActivity: formatDate(row.lastActivity), reason: row.reason })),
    };
  }

  return {
    type: "released_results",
    title: `${REPORT_OPTIONS.at(-1)?.label ?? "Released Results"} Report`,
    description: REPORT_OPTIONS.at(-1)?.description ?? "Current released results.",
    columns: [{ key: "released", label: "Released" }, { key: "learner", label: "Learner" }, { key: "class", label: "Class" }, { key: "mission", label: "COC / Mission" }, { key: "outcome", label: "Final Outcome" }, { key: "result", label: "Recorded Value", align: "right" }, { key: "remarks", label: "Instructor Remarks" }],
    rows: data.releasedResults.map((row) => ({ released: formatDate(row.releasedAt), learner: row.learnerName, class: row.classTitle, mission: `${row.cocCode} · ${row.missionTitle}`, outcome: outcomeLabel(row.outcome), result: row.percentage === null ? "Criterion-based" : `${row.percentage}%`, remarks: row.remarks ?? "—" })),
  };
}

function escapeCsv(value: string | number | null): string {
  const text = value === null ? "" : String(value);
  return /[",\r\n]/.test(text) ? `"${text.replaceAll('"', '""')}"` : text;
}

export function reportToCsv(report: PreparedReport): string {
  const lines = [
    report.columns.map((column) => escapeCsv(column.label)).join(","),
    ...report.rows.map((row) => report.columns.map((column) => escapeCsv(row[column.key] ?? null)).join(",")),
  ];
  return `\uFEFF${lines.join("\r\n")}`;
}

