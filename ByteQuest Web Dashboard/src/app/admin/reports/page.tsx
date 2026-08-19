import Link from "next/link";
import { BarChart3, CalendarRange, FileText, ShieldCheck } from "lucide-react";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { MetricStrip } from "@/components/dashboard/MetricStrip";
import { PageHeader } from "@/components/dashboard/PageHeader";
import { SectionHeading } from "@/components/dashboard/SectionHeading";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { requireStaffProfile } from "@/lib/auth/server";
import { getAdminAnalytics, parseAnalyticsFilters } from "@/lib/analytics/server";

export const dynamic = "force-dynamic";

export default async function AdminReportsPage({ searchParams }: { searchParams: Promise<Record<string, string | string[] | undefined>> }) {
  await requireStaffProfile(["admin"]);
  const filters = parseAnalyticsFilters(await searchParams);
  const data = await getAdminAnalytics(filters);
  const period = `${new Intl.DateTimeFormat("en-PH", { dateStyle: "medium", timeZone: "Asia/Manila" }).format(new Date(data.period.from))} – ${new Intl.DateTimeFormat("en-PH", { dateStyle: "medium", timeZone: "Asia/Manila" }).format(new Date(data.period.to))}`;

  return <DashboardLayout><div className="mx-auto max-w-7xl space-y-7 print:space-y-4">
    <PageHeader title="System reports" description="A period-scoped operational summary for platform activity, accounts, resources, and audit volume. Assessment decisions remain in the Instructor review workflow." actions={<><Button asChild variant="outline"><Link href="/admin/analytics"><BarChart3 className="mr-2 h-4 w-4" aria-hidden="true" />Open analytics</Link></Button><Button asChild variant="outline"><Link href="/admin/reports?range=90"><CalendarRange className="mr-2 h-4 w-4" aria-hidden="true" />90-day view</Link></Button></>} />
    <div className="flex items-center gap-2 rounded-xl border border-border bg-card px-4 py-3 text-xs text-muted-foreground"><FileText className="h-4 w-4 text-primary" aria-hidden="true" /><span>Reporting period: <strong className="font-semibold text-foreground">{period}</strong></span><span className="ml-auto hidden sm:inline">Values are live PostgreSQL aggregates.</span></div>
    <MetricStrip ariaLabel="System report summary" metrics={[
      { label: "Active learners", value: data.summary.activeLearners, helper: "Active profiles in the period", icon: ShieldCheck, featured: true },
      { label: "Assessment volume", value: data.summary.assessmentVolume, helper: "Recorded attempts", icon: BarChart3 },
      { label: "Released results", value: data.summary.releasedResults, helper: "Results released by workflow", icon: FileText, tone: "positive" },
      { label: "Audit events", value: data.summary.auditEvents, helper: "Trusted system events", icon: ShieldCheck, tone: "neutral" },
    ]} />
    <div className="grid gap-6 lg:grid-cols-[minmax(0,1.3fr)_minmax(320px,0.7fr)]">
      <section className="overflow-hidden rounded-2xl border border-border bg-card shadow-xs"><SectionHeading title="Activity by day" description="Assessment, release, resource, and audit activity in the selected period." />{data.trend.length ? <div className="divide-y divide-border">{data.trend.slice(-14).map((row) => <div key={row.date} className="grid grid-cols-[1fr_repeat(4,auto)] items-center gap-4 px-5 py-3 text-sm"><span className="text-muted-foreground">{new Intl.DateTimeFormat("en-PH", { month: "short", day: "numeric", timeZone: "Asia/Manila" }).format(new Date(row.date))}</span><span className="tabular-nums">{row.assessments} attempts</span><span className="tabular-nums">{row.released} released</span><span className="tabular-nums">{row.resources} resources</span><span className="tabular-nums">{row.auditEvents} audit</span></div>)}</div> : <p className="px-5 py-12 text-center text-sm text-muted-foreground">No activity is recorded for this period.</p>}</section>
      <section className="overflow-hidden rounded-2xl border border-border bg-card shadow-xs"><SectionHeading title="COC usage" description="Assessment volume by official ByteQuest COC context." />{data.cocUsage.length ? <div className="divide-y divide-border">{data.cocUsage.map((row) => <div key={row.id} className="flex items-center justify-between gap-3 px-5 py-3.5"><div><p className="font-semibold">{row.code}</p><p className="mt-0.5 text-xs text-muted-foreground">{row.learners} learners · {row.released} released</p></div><Badge variant="outline">{row.attempts} attempts</Badge></div>)}</div> : <p className="px-5 py-12 text-center text-sm text-muted-foreground">No COC activity is recorded.</p>}</section>
    </div>
    <section className="overflow-hidden rounded-2xl border border-border bg-card shadow-xs"><SectionHeading title="Report scope and controls" description="Use Analytics for interactive drilldown. Use this page for a stable system-level summary that can be printed or reviewed with advisers." /><div className="grid gap-4 p-5 sm:grid-cols-3"><div><p className="text-xs text-muted-foreground">Active Instructors</p><p className="mt-1 text-xl font-bold tabular-nums">{data.summary.activeInstructors}</p></div><div><p className="text-xs text-muted-foreground">Resource uploads</p><p className="mt-1 text-xl font-bold tabular-nums">{data.summary.resourceUploads}</p></div><div><p className="text-xs text-muted-foreground">Storage in use</p><p className="mt-1 text-xl font-bold tabular-nums">{Math.round(data.summary.storageBytes / 1024)} KiB</p></div></div></section>
  </div></DashboardLayout>;
}
