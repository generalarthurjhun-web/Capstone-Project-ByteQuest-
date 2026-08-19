"use client";

import Link from "next/link";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Line,
  LineChart,
  XAxis,
  YAxis,
} from "recharts";
import {
  ArrowRight,
  CheckCircle2,
  CircleDashed,
  Clock3,
  Eye,
  ListChecks,
  Users,
} from "lucide-react";
import { AnalyticsFilters } from "@/components/analytics/AnalyticsFilters";
import { MetricStrip } from "@/components/dashboard/MetricStrip";
import { PageHeader } from "@/components/dashboard/PageHeader";
import { SectionHeading } from "@/components/dashboard/SectionHeading";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { ChartContainer, ChartTooltip, ChartTooltipContent, type ChartConfig } from "@/components/ui/chart";
import type { AnalyticsFilters as Filters, InstructorAnalytics } from "@/lib/analytics/types";
import { cn } from "@/lib/utils";
import { useReducedMotion } from "@/hooks/use-reduced-motion";

const trendConfig = {
  submitted: { label: "Submitted", color: "hsl(var(--chart-1))" },
  released: { label: "Released", color: "hsl(var(--chart-3))" },
  criteriaSatisfied: { label: "Criteria satisfied", color: "hsl(var(--chart-2))" },
} satisfies ChartConfig;

const cocConfig = {
  satisfactionRate: { label: "Criterion satisfaction", color: "hsl(var(--chart-1))" },
} satisfies ChartConfig;

const workflowConfig = {
  count: { label: "Attempts", color: "hsl(var(--chart-2))" },
} satisfies ChartConfig;

const STATUS_LABELS: Record<string, string> = {
  in_progress: "In progress",
  submitted: "Submitted",
  evaluated: "Evaluated",
  under_review: "Under review",
  finalized: "Finalized",
  released: "Released",
};

const WORKFLOW_COLORS = [
  "hsl(var(--chart-2))",
  "hsl(var(--chart-4))",
  "hsl(var(--chart-5))",
  "hsl(32 90% 52%)",
  "hsl(173 70% 38%)",
  "hsl(var(--chart-3))",
];

function formatDate(value: string) {
  return new Intl.DateTimeFormat("en-PH", { month: "short", day: "numeric", timeZone: "Asia/Manila" }).format(new Date(value));
}

function formatDateTime(value: string) {
  return new Intl.DateTimeFormat("en-PH", { dateStyle: "medium", timeStyle: "short", timeZone: "Asia/Manila" }).format(new Date(value));
}

export function InstructorAnalyticsDashboard({
  data,
  filters,
}: {
  data: InstructorAnalytics;
  filters: Filters;
}) {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const reducedMotion = useReducedMotion();
  const selectedCriterion = searchParams.get("criterion");
  const visibleAttention = selectedCriterion
    ? data.attention.filter((row) => row.criterionId === selectedCriterion)
    : data.attention;

  function setDrilldown(key: "coc" | "mission" | "criterion", value: string) {
    const next = new URLSearchParams(searchParams.toString());
    next.set(key, value);
    if (key === "coc") {
      next.delete("mission");
      next.delete("criterion");
    }
    if (key === "mission") next.delete("criterion");
    router.push(`${pathname}?${next.toString()}#criterion-analysis`);
  }

  function handleCocClick(entry: unknown) {
    if (typeof entry === "object" && entry !== null && "id" in entry && typeof entry.id === "string") {
      setDrilldown("coc", entry.id);
    }
  }

  const selectedCoc = data.filters.cocs.find((coc) => coc.id === filters.cocId);
  const selectedMission = data.filters.missions.find((mission) => mission.id === filters.missionId);
  const selectedCriterionRow = data.criteria.find((criterion) => criterion.id === selectedCriterion);
  const currentQuery = searchParams.toString();
  const interventionHref = `${pathname}${currentQuery ? `?${currentQuery}` : ""}#interventions`;
  const reportParams = new URLSearchParams(currentQuery);
  reportParams.set("type", "released_results");

  return (
    <div className="mx-auto max-w-[1500px] space-y-7">
      <PageHeader
        title="Analytics"
        description="Explore real assessment activity, criterion evidence, learner progress, and intervention signals from your owned classes. Percentages shown here are system aggregates—not TESDA scores."
        actions={<Button asChild variant="outline"><Link href="/reports">Build a report <ArrowRight className="ml-2 h-4 w-4" aria-hidden="true" /></Link></Button>}
      />

      <AnalyticsFilters filters={filters} options={data.filters} />

      {(selectedCoc || selectedMission || selectedCriterionRow) ? (
        <nav aria-label="Analytics drilldown" className="flex flex-wrap items-center gap-1.5 text-xs text-muted-foreground">
          <Link href={`/analytics?range=${filters.range}`} className="rounded-md px-2 py-1 font-medium text-foreground hover:bg-muted focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring">All analytics</Link>
          {selectedCoc ? <><span aria-hidden="true">/</span><span className="px-2 py-1">{selectedCoc.code}</span></> : null}
          {selectedMission ? <><span aria-hidden="true">/</span><span className="px-2 py-1">{selectedMission.title}</span></> : null}
          {selectedCriterionRow ? <><span aria-hidden="true">/</span><span className="px-2 py-1 text-foreground">{selectedCriterionRow.title}</span></> : null}
        </nav>
      ) : null}

      <MetricStrip
        ariaLabel="Filtered Instructor analytics metrics"
        metrics={[
          {
            label: "Active learners",
            value: data.summary.activeLearners,
            helper: "Current scoped enrollments",
            icon: Users,
            featured: true,
            href: "/progress",
            linkLabel: "Open learner monitoring",
          },
          {
            label: "Assessments submitted",
            value: data.summary.assessmentsSubmitted,
            helper: `${data.summary.totalAttempts} total attempts in this period`,
            icon: ListChecks,
            href: "/attempts",
            linkLabel: "Open assessment attempts",
          },
          {
            label: "Released results",
            value: data.summary.releasedResults,
            helper: "Instructor-final releases in scope",
            icon: CheckCircle2,
            tone: "positive",
            href: `/reports?${reportParams.toString()}`,
            linkLabel: "Open the filtered released results report",
          },
          {
            label: "Learners needing attention",
            value: data.summary.learnersNeedingAttention,
            helper: data.summary.pendingReview
              ? `${data.summary.pendingReview} attempts awaiting review`
              : "No attempt is awaiting review",
            icon: Eye,
            tone: data.summary.learnersNeedingAttention ? "attention" : "neutral",
            href: interventionHref,
            linkLabel: "Open learner intervention signals",
          },
        ]}
      />

      <div className="grid gap-5 xl:grid-cols-[minmax(0,2fr)_minmax(300px,1fr)]">
        <section className="overflow-hidden rounded-xl border border-border bg-card">
          <SectionHeading title="Class performance trend" description="Daily submitted assessments, released results, and satisfied criterion observations." />
          {data.summary.totalAttempts ? (
            <div className="p-4 sm:p-5">
              <p id="trend-summary" className="sr-only">Trend chart covering {data.trend.length} days. {data.summary.assessmentsSubmitted} assessments submitted and {data.summary.releasedResults} results released in the selected period.</p>
              <ChartContainer config={trendConfig} className="h-[310px] w-full aspect-auto" aria-describedby="trend-summary">
                <LineChart data={data.trend} margin={{ left: 4, right: 12, top: 8, bottom: 0 }} accessibilityLayer>
                  <CartesianGrid vertical={false} strokeDasharray="3 3" />
                  <XAxis dataKey="date" tickFormatter={formatDate} tickLine={false} axisLine={false} minTickGap={28} />
                  <YAxis allowDecimals={false} tickLine={false} axisLine={false} width={28} />
                  <ChartTooltip content={<ChartTooltipContent labelFormatter={(value) => formatDate(String(value))} />} />
                  <Line type="monotone" dataKey="submitted" stroke="var(--color-submitted)" strokeWidth={2.25} dot={false} activeDot={{ r: 5 }} isAnimationActive={!reducedMotion} />
                  <Line type="monotone" dataKey="released" stroke="var(--color-released)" strokeWidth={2.25} strokeDasharray="6 4" dot={false} activeDot={{ r: 5 }} isAnimationActive={!reducedMotion} />
                  <Line type="monotone" dataKey="criteriaSatisfied" stroke="var(--color-criteriaSatisfied)" strokeWidth={1.75} strokeDasharray="2 4" dot={false} activeDot={{ r: 5 }} isAnimationActive={!reducedMotion} />
                </LineChart>
              </ChartContainer>
              <details className="mt-3 text-xs text-muted-foreground">
                <summary className="cursor-pointer font-medium text-foreground">View accessible trend data</summary>
                <div className="mt-2 max-h-56 overflow-auto rounded-lg border border-border">
                  <table className="w-full text-left"><thead className="sticky top-0 bg-muted"><tr><th className="px-3 py-2">Date</th><th className="px-3 py-2">Submitted</th><th className="px-3 py-2">Released</th><th className="px-3 py-2">Criteria satisfied</th></tr></thead><tbody>{data.trend.map((row) => <tr key={row.date} className="border-t border-border"><td className="px-3 py-2">{formatDate(row.date)}</td><td className="px-3 py-2 tabular-nums">{row.submitted}</td><td className="px-3 py-2 tabular-nums">{row.released}</td><td className="px-3 py-2 tabular-nums">{row.criteriaSatisfied}</td></tr>)}</tbody></table>
                </div>
              </details>
            </div>
          ) : <EmptyAnalytics message="No assessment activity matches these filters." action="Assign an assessment or choose a broader period." />}
        </section>

        <section className="overflow-hidden rounded-xl border border-border bg-card">
          <SectionHeading title="Assessment workflow" description="Current state of every scoped attempt in the selected period." />
          {data.summary.totalAttempts ? (
            <div className="p-4 sm:p-5">
              <ChartContainer config={workflowConfig} className="h-[230px] w-full aspect-auto" aria-label="Assessment workflow state counts">
                <BarChart data={data.workflow.map((item) => ({ ...item, label: STATUS_LABELS[item.status] }))} layout="vertical" margin={{ left: 16, right: 12 }} accessibilityLayer>
                  <CartesianGrid horizontal={false} strokeDasharray="3 3" />
                  <XAxis type="number" allowDecimals={false} tickLine={false} axisLine={false} />
                  <YAxis type="category" dataKey="label" tickLine={false} axisLine={false} width={88} />
                  <ChartTooltip content={<ChartTooltipContent hideLabel />} />
                  <Bar dataKey="count" radius={[0, 5, 5, 0]} isAnimationActive={!reducedMotion}>
                    {data.workflow.map((item, index) => <Cell key={item.status} fill={WORKFLOW_COLORS[index]} />)}
                  </Bar>
                </BarChart>
              </ChartContainer>
              {data.summary.pendingReview ? (
                <Button asChild variant="outline" className="mt-3 w-full"><Link href="/attempts">Review {data.summary.pendingReview} pending attempt{data.summary.pendingReview === 1 ? "" : "s"}</Link></Button>
              ) : <p className="mt-3 flex items-center gap-2 text-xs text-muted-foreground"><CheckCircle2 className="h-4 w-4 text-emerald-700" aria-hidden="true" />No evaluated attempt is waiting for review.</p>}
            </div>
          ) : <EmptyAnalytics message="No workflow activity yet." action="Attempt states appear after learners start assigned assessments." />}
        </section>
      </div>

      <section className="overflow-hidden rounded-xl border border-border bg-card" id="coc-performance">
        <SectionHeading title="COC performance" description="Criterion satisfaction is satisfied required evidence divided by evaluated criterion evidence; it is not a TESDA score." />
        {data.cocPerformance.length ? (
          <div className="grid gap-4 p-4 sm:p-5 lg:grid-cols-[minmax(0,1.15fr)_minmax(360px,0.85fr)]">
            <ChartContainer config={cocConfig} className="h-[300px] w-full aspect-auto" aria-label="Criterion satisfaction by COC">
              <BarChart data={data.cocPerformance} margin={{ left: 4, right: 12, top: 10, bottom: 0 }} accessibilityLayer>
                <CartesianGrid vertical={false} strokeDasharray="3 3" />
                <XAxis dataKey="code" tickLine={false} axisLine={false} />
                <YAxis domain={[0, 100]} tickFormatter={(value) => `${value}%`} tickLine={false} axisLine={false} width={38} />
                <ChartTooltip content={<ChartTooltipContent formatter={(value) => <span className="font-mono tabular-nums">{value === null ? "No evidence" : `${value}%`}</span>} />} />
                <Bar dataKey="satisfactionRate" fill="var(--color-satisfactionRate)" radius={[6, 6, 0, 0]} maxBarSize={52} onClick={handleCocClick} className="cursor-pointer" isAnimationActive={!reducedMotion} />
              </BarChart>
            </ChartContainer>
            <div className="divide-y divide-border rounded-lg border border-border">
              {data.cocPerformance.map((coc) => (
                <button key={coc.id} type="button" onClick={() => setDrilldown("coc", coc.id)} className="flex min-h-14 w-full cursor-pointer items-center justify-between gap-4 px-4 py-3 text-left transition-colors hover:bg-muted/45 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-ring">
                  <div className="min-w-0"><p className="text-sm font-semibold">{coc.code}</p><p className="truncate text-xs text-muted-foreground">{coc.title}</p></div>
                  <div className="shrink-0 text-right"><p className="text-sm font-semibold tabular-nums">{coc.satisfactionRate === null ? "—" : `${coc.satisfactionRate}%`}</p><p className="text-[11px] text-muted-foreground">{coc.criteriaEvaluated} criteria</p></div>
                </button>
              ))}
            </div>
          </div>
        ) : <EmptyAnalytics message="No COC assessment data matches the current scope." action="Choose another class or date range." />}
      </section>

      <div className="grid gap-5 xl:grid-cols-[minmax(0,1.8fr)_minmax(300px,1fr)]">
        <section className="overflow-hidden rounded-xl border border-border bg-card" id="mission-performance">
          <SectionHeading title="Mission performance" description="Open a mission to narrow criterion and learner intervention analysis." />
          {data.missionPerformance.length ? (
            <div className="divide-y divide-border">
              {data.missionPerformance.map((mission) => (
                <button key={mission.id} type="button" onClick={() => setDrilldown("mission", mission.id)} className="grid min-h-16 w-full cursor-pointer gap-3 px-5 py-4 text-left transition-colors hover:bg-muted/40 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-ring sm:grid-cols-[minmax(0,1fr)_repeat(3,90px)_20px] sm:items-center">
                  <div className="min-w-0"><p className="text-sm font-semibold">{mission.cocCode} · {mission.code}</p><p className="mt-0.5 truncate text-xs text-muted-foreground">{mission.title}</p></div>
                  <MetricCell label="Attempts" value={mission.attempts} />
                  <MetricCell label="Released" value={mission.released} />
                  <MetricCell label="Needs review" value={mission.learnersNeedingReview} attention={mission.learnersNeedingReview > 0} />
                  <ArrowRight className="hidden h-4 w-4 text-muted-foreground sm:block" aria-hidden="true" />
                </button>
              ))}
            </div>
          ) : <EmptyAnalytics message="No mission is assigned in this scope." action="Assign published activities before expecting mission analytics." />}
        </section>

        <section className="overflow-hidden rounded-xl border border-border bg-card">
          <SectionHeading title="Retry signals" description="Repeated attempts are support signals, not automatic competency decisions." />
          {data.retries.length ? (
            <div className="divide-y divide-border">
              {data.retries.slice(0, 8).map((row) => (
                <div key={row.missionId} className="px-5 py-4">
                  <div className="flex items-start justify-between gap-4"><div className="min-w-0"><p className="truncate text-sm font-medium">{row.missionTitle}</p><p className="mt-1 text-xs text-muted-foreground">{row.cocCode} · {row.learnerAssignments} learner assignment{row.learnerAssignments === 1 ? "" : "s"}</p></div><span className="text-sm font-semibold tabular-nums">{row.averageAttempts}</span></div>
                  <div className="mt-2 flex items-center justify-between text-xs text-muted-foreground"><span>Average attempts</span><span>{row.learnersRetrying} learner{row.learnersRetrying === 1 ? "" : "s"} retried</span></div>
                </div>
              ))}
            </div>
          ) : <EmptyAnalytics message="No retry activity matches this period." action="This is a healthy empty state, not missing data." />}
        </section>
      </div>

      <section className="overflow-hidden rounded-xl border border-border bg-card" id="criterion-analysis">
        <SectionHeading title="Criterion analysis" description="Drill from versioned TESDA/project provenance into affected learners and real attempts." />
        {data.criteria.length ? (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[900px] text-left text-sm">
              <thead className="bg-muted/45 text-xs text-muted-foreground"><tr><th className="px-5 py-3 font-medium">Criterion</th><th className="px-4 py-3 font-medium">Provenance</th><th className="px-4 py-3 text-right font-medium">Evaluated</th><th className="px-4 py-3 text-right font-medium">Satisfied</th><th className="px-4 py-3 text-right font-medium">Not satisfied</th><th className="px-4 py-3 text-right font-medium">Affected</th><th className="px-5 py-3"><span className="sr-only">Action</span></th></tr></thead>
              <tbody className="divide-y divide-border">
                {data.criteria.map((criterion) => (
                  <tr key={`${criterion.id}-${criterion.missionId}`} className={cn("transition-colors hover:bg-muted/30", selectedCriterion === criterion.id && "bg-primary/[0.04]") }>
                    <td className="px-5 py-4"><p className="font-medium">{criterion.title}</p><p className="mt-1 text-xs text-muted-foreground">{criterion.cocCode} · {criterion.missionTitle} · {criterion.code}</p></td>
                    <td className="max-w-[280px] px-4 py-4"><Badge variant="outline">{criterion.sourceTrace.includes("TESDA_OFFICIAL_APPROVED") ? "TESDA basis" : "Project rule"}</Badge><p className="mt-1 line-clamp-2 text-xs leading-5 text-muted-foreground" title={criterion.sourceTrace}>{criterion.sourceTrace}</p></td>
                    <td className="px-4 py-4 text-right tabular-nums">{criterion.evaluatedAttempts}</td>
                    <td className="px-4 py-4 text-right tabular-nums">{criterion.satisfied}</td>
                    <td className="px-4 py-4 text-right font-semibold tabular-nums text-amber-800">{criterion.notSatisfied}</td>
                    <td className="px-4 py-4 text-right tabular-nums">{criterion.affectedLearners}</td>
                    <td className="px-5 py-4 text-right"><Button type="button" variant="ghost" size="sm" onClick={() => setDrilldown("criterion", criterion.id)} disabled={!criterion.affectedLearners}>Learners</Button></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : <EmptyAnalytics message="No criterion evaluation exists for this selection." action="Criterion analytics appear after PostgreSQL evaluates submitted evidence." />}
      </section>

      <section className="overflow-hidden rounded-xl border border-border bg-card" id="interventions">
        <SectionHeading title={selectedCriterionRow ? `Learners needing support · ${selectedCriterionRow.title}` : "Learners requiring attention"} description="Objective signals from not-satisfied or review-required evidence. These are support prompts, not labels about learner ability." action={selectedCriterion ? <Button variant="ghost" size="sm" onClick={() => { const next = new URLSearchParams(searchParams.toString()); next.delete("criterion"); router.push(`${pathname}?${next.toString()}#interventions`); }}>Clear criterion</Button> : null} />
        {visibleAttention.length ? (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[880px] text-left text-sm"><thead className="bg-muted/45 text-xs text-muted-foreground"><tr><th className="px-5 py-3 font-medium">Learner</th><th className="px-4 py-3 font-medium">Class / mission</th><th className="px-4 py-3 font-medium">Criterion</th><th className="px-4 py-3 text-right font-medium">Failed attempts</th><th className="px-4 py-3 font-medium">Last activity</th><th className="px-5 py-3"><span className="sr-only">Actions</span></th></tr></thead><tbody className="divide-y divide-border">{visibleAttention.slice(0, 30).map((row) => <tr key={`${row.learnerId}-${row.criterionId}-${row.missionId}`} className="hover:bg-muted/30"><td className="px-5 py-4"><p className="font-medium">{row.learnerName}</p><p className="mt-1 text-xs text-muted-foreground">{row.reason}</p></td><td className="px-4 py-4"><p>{row.classTitle}</p><p className="mt-1 text-xs text-muted-foreground">{row.cocCode} · {row.missionTitle}</p></td><td className="px-4 py-4"><p className="font-medium">{row.criterionTitle}</p><p className="mt-1 text-xs text-muted-foreground">{row.criterionCode}</p></td><td className="px-4 py-4 text-right font-semibold tabular-nums">{row.failedAttempts}{row.repeatFailures ? <span className="block text-[11px] font-normal text-amber-800">{row.repeatFailures} repeated</span> : null}</td><td className="px-4 py-4 text-xs text-muted-foreground">{formatDateTime(row.lastActivity)}</td><td className="px-5 py-4"><div className="flex justify-end gap-1"><Button asChild variant="ghost" size="sm"><Link href={`/progress/learners/${row.learnerId}`}>Learner</Link></Button><Button asChild variant="outline" size="sm"><Link href={`/attempts/${row.latestAttemptId}`}>Evidence</Link></Button></div></td></tr>)}</tbody></table>
          </div>
        ) : <EmptyAnalytics message="No learner currently matches this intervention signal." action="Broaden the filters or review the assessment queue." />}
      </section>

      <section className="overflow-hidden rounded-xl border border-border bg-card" id="learner-progress">
        <SectionHeading title="Learner progress matrix" description="Completed means an Instructor-final result was released as competent. In-progress and support states are shown separately." />
        {data.progressMatrix.length ? (
          <div className="overflow-x-auto"><table className="w-full min-w-[720px] text-left text-sm"><thead className="bg-muted/45 text-xs text-muted-foreground"><tr><th className="sticky left-0 z-[1] bg-muted px-5 py-3 font-medium">Learner</th>{data.filters.cocs.map((coc) => <th key={coc.id} className="px-4 py-3 text-center font-medium">{coc.code}</th>)}<th className="px-5 py-3"><span className="sr-only">Open learner</span></th></tr></thead><tbody className="divide-y divide-border">{data.progressMatrix.map((row) => <tr key={`${row.classId}-${row.learnerId}`}><td className="sticky left-0 bg-card px-5 py-4"><p className="font-medium">{row.learnerName}</p><p className="mt-1 text-xs text-muted-foreground">{row.classTitle}</p></td>{data.filters.cocs.map((coc) => { const state = row.cocs.find((item) => item.id === coc.id)?.state ?? "not_started"; return <td key={coc.id} className="px-4 py-4 text-center"><ProgressState state={state} /></td>; })}<td className="px-5 py-4 text-right"><Button asChild variant="ghost" size="sm"><Link href={`/progress/learners/${row.learnerId}`}>View</Link></Button></td></tr>)}</tbody></table></div>
        ) : <EmptyAnalytics message="No active learner progress is available in this scope." action="Enroll learners and assign published assessment content." />}
      </section>
    </div>
  );
}

function MetricCell({ label, value, attention = false }: { label: string; value: number; attention?: boolean }) {
  return <div className="flex items-center justify-between sm:block sm:text-right"><span className="text-xs text-muted-foreground sm:block">{label}</span><span className={cn("text-sm font-semibold tabular-nums", attention && "text-amber-800")}>{value}</span></div>;
}

function EmptyAnalytics({ message, action }: { message: string; action: string }) {
  return <div className="px-5 py-12 text-center"><CircleDashed className="mx-auto h-6 w-6 text-muted-foreground" aria-hidden="true" /><p className="mt-3 text-sm font-medium text-foreground">{message}</p><p className="mt-1 text-sm text-muted-foreground">{action}</p></div>;
}

function ProgressState({ state }: { state: "completed" | "needs_support" | "in_progress" | "not_started" }) {
  const config = {
    completed: { label: "Completed", icon: CheckCircle2, className: "border-emerald-200 bg-emerald-50 text-emerald-800" },
    needs_support: { label: "Needs support", icon: Eye, className: "border-amber-200 bg-amber-50 text-amber-900" },
    in_progress: { label: "In progress", icon: Clock3, className: "border-blue-200 bg-blue-50 text-blue-800" },
    not_started: { label: "Not started", icon: CircleDashed, className: "border-border bg-muted/30 text-muted-foreground" },
  }[state];
  const Icon = config.icon;
  return <span className={cn("inline-flex min-h-8 items-center gap-1.5 rounded-md border px-2.5 text-xs font-medium", config.className)} title={config.label}><Icon className="h-3.5 w-3.5" aria-hidden="true" /><span>{config.label}</span></span>;
}
