import { z } from "zod";

const uuid = z.string().uuid();
const count = z.coerce.number().int().nonnegative();
const numeric = z.coerce.number();

export const analyticsFiltersSchema = z.object({
  classId: uuid.nullable(),
  cocId: uuid.nullable(),
  missionId: uuid.nullable(),
  from: z.string().datetime(),
  to: z.string().datetime(),
  range: z.enum(["7", "30", "90", "custom"]),
});

export type AnalyticsFilters = z.infer<typeof analyticsFiltersSchema>;

const filterClassSchema = z.object({
  id: uuid,
  title: z.string(),
  classCode: z.string().nullable(),
  status: z.string(),
});

const filterCocSchema = z.object({
  id: uuid,
  code: z.string(),
  title: z.string(),
});

const filterMissionSchema = z.object({
  id: uuid,
  cocId: uuid,
  code: z.string(),
  number: count,
  title: z.string(),
});

const trendPointSchema = z.object({
  date: z.string(),
  submitted: count,
  released: count,
  criteriaSatisfied: count,
});

const cocPerformanceSchema = z.object({
  id: uuid,
  code: z.string(),
  title: z.string(),
  attempts: count,
  submitted: count,
  released: count,
  criteriaEvaluated: count,
  criteriaSatisfied: count,
  criteriaNotSatisfied: count,
  satisfactionRate: numeric.nullable(),
});

const missionPerformanceSchema = z.object({
  id: uuid,
  cocId: uuid,
  cocCode: z.string(),
  code: z.string(),
  number: count,
  title: z.string(),
  attempts: count,
  submitted: count,
  finalized: count,
  released: count,
  criteriaNotSatisfied: count,
  learnersNeedingReview: count,
});

const criterionAnalyticsSchema = z.object({
  id: uuid,
  code: z.string(),
  title: z.string(),
  sourceTrace: z.string(),
  isRequired: z.boolean(),
  cocId: uuid,
  cocCode: z.string(),
  missionId: uuid,
  missionTitle: z.string(),
  evaluatedAttempts: count,
  satisfied: count,
  notSatisfied: count,
  affectedLearners: count,
  repeatFailures: count,
  latestFailureAt: z.string().nullable(),
});

const attentionSchema = z.object({
  learnerId: uuid,
  learnerName: z.string(),
  classId: uuid,
  classTitle: z.string(),
  cocId: uuid,
  cocCode: z.string(),
  missionId: uuid,
  missionTitle: z.string(),
  criterionId: uuid,
  criterionCode: z.string(),
  criterionTitle: z.string(),
  failedAttempts: count,
  repeatFailures: count,
  lastActivity: z.string(),
  latestAttemptId: uuid,
  reason: z.string(),
});

const workflowSchema = z.object({
  status: z.enum([
    "in_progress",
    "submitted",
    "evaluated",
    "under_review",
    "finalized",
    "released",
  ]),
  count,
});

const retrySchema = z.object({
  cocId: uuid,
  cocCode: z.string(),
  missionId: uuid,
  missionTitle: z.string(),
  attempts: count,
  learnerAssignments: count,
  averageAttempts: numeric.nonnegative(),
  learnersRetrying: count,
});

const progressCocSchema = z.object({
  id: uuid,
  code: z.string(),
  title: z.string(),
  state: z.enum(["completed", "needs_support", "in_progress", "not_started"]),
});

const progressRowSchema = z.object({
  learnerId: uuid,
  learnerName: z.string(),
  classId: uuid,
  classTitle: z.string(),
  cocs: z.array(progressCocSchema),
});

const assessmentHistorySchema = z.object({
  attemptId: uuid,
  learnerId: uuid,
  learnerName: z.string(),
  classId: uuid,
  classTitle: z.string(),
  cocId: uuid,
  cocCode: z.string(),
  missionId: uuid,
  missionTitle: z.string(),
  assignmentTitle: z.string(),
  status: z.string(),
  eventAt: z.string(),
  submittedAt: z.string().nullable(),
  releasedAt: z.string().nullable(),
  attemptNumber: count,
});

const releasedResultSchema = z.object({
  attemptId: uuid,
  learnerId: uuid,
  learnerName: z.string(),
  learnerEmail: z.string().email(),
  classId: uuid,
  classTitle: z.string(),
  cocId: uuid,
  cocCode: z.string(),
  missionId: uuid,
  missionTitle: z.string(),
  assignmentTitle: z.string(),
  outcome: z.string(),
  percentage: numeric.nullable(),
  remarks: z.string().nullable(),
  releaseReason: z.string().nullable(),
  releasedAt: z.string(),
});

export const instructorAnalyticsSchema = z.object({
  period: z.object({ from: z.string(), to: z.string() }),
  filters: z.object({
    classes: z.array(filterClassSchema),
    cocs: z.array(filterCocSchema),
    missions: z.array(filterMissionSchema),
  }),
  summary: z.object({
    activeLearners: count,
    totalAttempts: count,
    assessmentsSubmitted: count,
    releasedResults: count,
    pendingReview: count,
    learnersNeedingAttention: count,
  }),
  trend: z.array(trendPointSchema),
  cocPerformance: z.array(cocPerformanceSchema),
  missionPerformance: z.array(missionPerformanceSchema),
  criteria: z.array(criterionAnalyticsSchema),
  attention: z.array(attentionSchema),
  workflow: z.array(workflowSchema),
  retries: z.array(retrySchema),
  progressMatrix: z.array(progressRowSchema),
  assessmentHistory: z.array(assessmentHistorySchema),
  releasedResults: z.array(releasedResultSchema),
});

export type InstructorAnalytics = z.infer<typeof instructorAnalyticsSchema>;
export type CocPerformance = InstructorAnalytics["cocPerformance"][number];
export type MissionPerformance = InstructorAnalytics["missionPerformance"][number];
export type CriterionAnalytics = InstructorAnalytics["criteria"][number];

export const adminAnalyticsSchema = z.object({
  period: z.object({ from: z.string(), to: z.string() }),
  summary: z.object({
    activeLearners: count,
    activeInstructors: count,
    activeClasses: count,
    assessmentVolume: count,
    releasedResults: count,
    resourceUploads: count,
    storageBytes: z.coerce.number().nonnegative(),
    auditEvents: count,
  }),
  trend: z.array(z.object({
    date: z.string(),
    assessments: count,
    released: count,
    resources: count,
    auditEvents: count,
  })),
  accountStates: z.array(z.object({ role: z.string(), status: z.string(), count })),
  cocUsage: z.array(z.object({
    id: uuid,
    code: z.string(),
    title: z.string(),
    attempts: count,
    learners: count,
    released: count,
  })),
  recentAuditEvents: z.array(z.object({
    id: uuid,
    action: z.string(),
    targetType: z.string(),
    outcome: z.string(),
    actorRole: z.string().nullable(),
    createdAt: z.string(),
  })),
});

export type AdminAnalytics = z.infer<typeof adminAnalyticsSchema>;

export const reportTypeSchema = z.enum([
  "class_performance",
  "learner_performance",
  "coc_competency",
  "mission_assessment",
  "criterion_analysis",
  "assessment_history",
  "intervention",
  "released_results",
]);

export type ReportType = z.infer<typeof reportTypeSchema>;

