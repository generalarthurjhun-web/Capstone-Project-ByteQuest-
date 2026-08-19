import { CheckCircle2, ClipboardCheck, FileText, Users, AlertTriangle } from "lucide-react";
import { AnalyticsFilters } from "@/components/analytics/AnalyticsFilters";
import { MetricStrip, type Metric } from "@/components/dashboard/MetricStrip";
import { PageHeader } from "@/components/dashboard/PageHeader";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { ReportActions } from "@/components/reports/ReportActions";
import { ReportTypeSelector } from "@/components/reports/ReportTypeSelector";
import { Badge } from "@/components/ui/badge";
import { getInstructorAnalytics, parseAnalyticsFilters } from "@/lib/analytics/server";
import { prepareReport } from "@/lib/analytics/reports";
import { reportTypeSchema } from "@/lib/analytics/types";
import { requireStaffProfile } from "@/lib/auth/server";
import { cn } from "@/lib/utils";

export const dynamic = "force-dynamic";

export default async function ReportsPage({
  searchParams,
}: {
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}) {
  await requireStaffProfile(["instructor"]);
  const params = await searchParams;
  const filters = parseAnalyticsFilters(params);
  const reportTypeValue = Array.isArray(params.type) ? params.type[0] : params.type;
  const reportType = reportTypeSchema.catch("class_performance").parse(reportTypeValue);
  const analytics = await getInstructorAnalytics(filters);
  const report = prepareReport(reportType, analytics);
  const reportMetrics: Metric[] = [
    { label: "Active learners", value: analytics.summary.activeLearners, helper: "Learners in the selected scope", icon: Users, href: "/progress", linkLabel: "Open learner monitoring", featured: true },
    { label: "Assessments submitted", value: analytics.summary.assessmentsSubmitted, helper: "Authoritative submissions in range", icon: ClipboardCheck, tone: "informational", href: "/attempts", linkLabel: "Open attempts" },
    { label: "Released results", value: analytics.summary.releasedResults, helper: "Instructor-final results in range", icon: CheckCircle2, tone: "positive", href: "/reports?type=released_results", linkLabel: "View released result report" },
    { label: "Needs attention", value: analytics.summary.learnersNeedingAttention, helper: analytics.summary.learnersNeedingAttention ? "Learners with objective support signals" : "No support signal in this scope", icon: AlertTriangle, tone: analytics.summary.learnersNeedingAttention ? "attention" : "neutral", href: "/analytics#interventions", linkLabel: "Open intervention analytics" },
  ];

  return (
    <DashboardLayout>
      <div className="mx-auto max-w-[1500px] space-y-6">
        <PageHeader
          title="Reports"
          description="Build scoped, exportable records from the same authoritative aggregates used by Analytics. Provisional results, gamification, and unrelated classes are excluded unless a report explicitly names them."
          actions={<ReportActions />}
        />

        <MetricStrip metrics={reportMetrics} ariaLabel="Report scope metrics" />

        <div className="grid gap-4 xl:grid-cols-[minmax(260px,0.6fr)_minmax(0,1.4fr)]">
          <ReportTypeSelector reportType={reportType} />
          <AnalyticsFilters filters={filters} options={analytics.filters} />
        </div>

        <section id="report-preview" className="report-sheet overflow-hidden rounded-xl border border-border/85 bg-card shadow-xs">
          <div className="flex flex-col gap-3 border-b border-border px-5 py-5 sm:flex-row sm:items-start sm:justify-between">
            <div>
              <div className="flex flex-wrap items-center gap-2">
                <h2 className="text-lg font-semibold tracking-tight">{report.title}</h2>
                <Badge variant="outline">{report.rows.length} row{report.rows.length === 1 ? "" : "s"}</Badge>
              </div>
              <p className="mt-1 max-w-3xl text-sm leading-6 text-muted-foreground">{report.description}</p>
            </div>
            <p className="text-xs text-muted-foreground">Generated {new Intl.DateTimeFormat("en-PH", { dateStyle: "medium", timeStyle: "short", timeZone: "Asia/Manila" }).format(new Date())}</p>
          </div>

          {report.rows.length ? (
            <div className="overflow-x-auto">
              <table className="w-full min-w-[760px] text-left text-sm">
                <thead className="bg-muted/45 text-xs text-muted-foreground">
                  <tr>{report.columns.map((column) => <th key={column.key} className={cn("px-4 py-3 font-medium first:pl-5 last:pr-5", column.align === "right" && "text-right")}>{column.label}</th>)}</tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {report.rows.map((row, rowIndex) => (
                    <tr key={rowIndex} className="align-top transition-colors duration-150 hover:bg-muted/30">
                      {report.columns.map((column) => <td key={column.key} className={cn("max-w-[380px] px-4 py-3.5 first:pl-5 last:pr-5", column.align === "right" && "text-right tabular-nums", typeof row[column.key] === "string" && String(row[column.key]).length > 100 && "text-xs leading-5 text-muted-foreground")}>{row[column.key] ?? "—"}</td>)}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <div className="px-5 py-16 text-center">
              <FileText className="mx-auto h-7 w-7 text-muted-foreground" aria-hidden="true" />
              <p className="mt-3 text-sm font-medium">No report rows match this scope.</p>
              <p className="mt-1 text-sm text-muted-foreground">Adjust the class, COC, mission, or date range. No placeholder values are shown.</p>
            </div>
          )}
        </section>

        <p className="text-xs leading-5 text-muted-foreground">Print / Save PDF uses the browser&apos;s secure print dialog and this report&apos;s print stylesheet. CSV contains the exact rows visible in the preview for the same URL filters.</p>
      </div>
    </DashboardLayout>
  );
}
