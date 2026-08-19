"use client";

import { Bar, BarChart, CartesianGrid, Line, LineChart, XAxis, YAxis } from "recharts";
import { Activity, Database, GraduationCap, HardDrive, ShieldCheck, Users } from "lucide-react";
import { MetricStrip } from "@/components/dashboard/MetricStrip";
import { PageHeader } from "@/components/dashboard/PageHeader";
import { SectionHeading } from "@/components/dashboard/SectionHeading";
import { PeriodFilter } from "@/components/analytics/PeriodFilter";
import { Badge } from "@/components/ui/badge";
import { ChartContainer, ChartTooltip, ChartTooltipContent, type ChartConfig } from "@/components/ui/chart";
import type { AdminAnalytics, AnalyticsFilters } from "@/lib/analytics/types";
import { useReducedMotion } from "@/hooks/use-reduced-motion";

const trendConfig = {
  assessments: { label: "Assessments", color: "hsl(var(--chart-1))" },
  released: { label: "Released results", color: "hsl(var(--chart-3))" },
  resources: { label: "Resources", color: "hsl(var(--chart-4))" },
} satisfies ChartConfig;

const usageConfig = { attempts: { label: "Attempts", color: "hsl(var(--chart-1))" } } satisfies ChartConfig;

function formatDay(value: string) {
  return new Intl.DateTimeFormat("en-PH", { month: "short", day: "numeric", timeZone: "Asia/Manila" }).format(new Date(value));
}

function formatBytes(value: number) {
  if (!value) return "0 B";
  const units = ["B", "KiB", "MiB", "GiB"];
  const index = Math.min(Math.floor(Math.log(value) / Math.log(1024)), units.length - 1);
  return `${(value / 1024 ** index).toFixed(index ? 1 : 0)} ${units[index]}`;
}

export function AdminSystemAnalyticsDashboard({ data, range }: { data: AdminAnalytics; range: AnalyticsFilters["range"] }) {
  const reducedMotion = useReducedMotion();
  return <div className="mx-auto max-w-[1500px] space-y-7">
    <PageHeader title="System analytics" description="Monitor platform activity, account state, content usage, storage, and auditable system events. This workspace does not grant routine assessment-finalization authority." actions={<PeriodFilter range={range} />} />
    <MetricStrip
      ariaLabel="Filtered system analytics metrics"
      metrics={[
        {
          label: "Active learners",
          value: data.summary.activeLearners,
          helper: "Active learner accounts",
          icon: Users,
          featured: true,
          href: "/users",
          linkLabel: "Open learner accounts",
        },
        {
          label: "Active instructors",
          value: data.summary.activeInstructors,
          helper: `${data.summary.activeClasses} active classes platform-wide`,
          icon: ShieldCheck,
          href: "/users",
          linkLabel: "Open instructor accounts",
        },
        {
          label: "Assessment volume",
          value: data.summary.assessmentVolume,
          helper: `${data.summary.releasedResults} results released in this period`,
          icon: GraduationCap,
        },
        {
          label: "Storage in use",
          value: formatBytes(data.summary.storageBytes),
          helper: `${data.summary.resourceUploads} resource uploads in this period`,
          icon: HardDrive,
          tone: "neutral",
        },
      ]}
    />

    <div className="grid gap-5 xl:grid-cols-[minmax(0,2fr)_minmax(300px,1fr)]">
      <section className="overflow-hidden rounded-xl border border-border bg-card"><SectionHeading title="Platform activity trend" description="Real attempts, current releases, and learning-resource uploads by day." /><div className="p-4 sm:p-5"><p className="sr-only">Platform activity for {data.trend.length} days: {data.summary.assessmentVolume} assessment attempts, {data.summary.releasedResults} released results, and {data.summary.resourceUploads} resource uploads.</p><ChartContainer config={trendConfig} className="h-[320px] w-full aspect-auto" aria-label="Platform activity over time"><LineChart data={data.trend} margin={{ left: 4, right: 12, top: 8 }} accessibilityLayer><CartesianGrid vertical={false} strokeDasharray="3 3" /><XAxis dataKey="date" tickFormatter={formatDay} tickLine={false} axisLine={false} minTickGap={28} /><YAxis allowDecimals={false} tickLine={false} axisLine={false} width={30} /><ChartTooltip content={<ChartTooltipContent labelFormatter={(value) => formatDay(String(value))} />} /><Line dataKey="assessments" stroke="var(--color-assessments)" strokeWidth={2.25} dot={false} isAnimationActive={!reducedMotion} /><Line dataKey="released" stroke="var(--color-released)" strokeWidth={2.25} strokeDasharray="6 4" dot={false} isAnimationActive={!reducedMotion} /><Line dataKey="resources" stroke="var(--color-resources)" strokeWidth={1.75} strokeDasharray="2 4" dot={false} isAnimationActive={!reducedMotion} /></LineChart></ChartContainer></div></section>
      <section className="overflow-hidden rounded-xl border border-border bg-card"><SectionHeading title="Account states" description="Current account roles and lifecycle states." />{data.accountStates.length ? <div className="divide-y divide-border">{data.accountStates.map((row) => <div key={`${row.role}-${row.status}`} className="flex items-center justify-between gap-3 px-5 py-3.5"><div><p className="text-sm font-medium capitalize">{row.role}</p><p className="mt-0.5 text-xs text-muted-foreground capitalize">{row.status.replaceAll("_", " ")}</p></div><Badge variant={row.status === "active" ? "secondary" : "outline"}>{row.count}</Badge></div>)}</div> : <EmptyState text="No account state is available." />}</section>
    </div>

    <div className="grid gap-6 xl:grid-cols-[minmax(0,1fr)_minmax(0,1fr)]">
      <section className="overflow-hidden rounded-xl border border-border bg-card"><SectionHeading title="COC usage" description="Assessment attempts by COC for the selected period." />{data.cocUsage.length ? <div className="p-4 sm:p-5"><ChartContainer config={usageConfig} className="h-[300px] w-full aspect-auto" aria-label="Assessment usage by COC"><BarChart data={data.cocUsage} accessibilityLayer><CartesianGrid vertical={false} strokeDasharray="3 3" /><XAxis dataKey="code" tickLine={false} axisLine={false} /><YAxis allowDecimals={false} tickLine={false} axisLine={false} width={30} /><ChartTooltip content={<ChartTooltipContent />} /><Bar dataKey="attempts" fill="var(--color-attempts)" radius={[6, 6, 0, 0]} maxBarSize={54} isAnimationActive={!reducedMotion} /></BarChart></ChartContainer><div className="mt-3 grid gap-2 sm:grid-cols-2">{data.cocUsage.map((row) => <div key={row.id} className="rounded-lg border border-border px-3 py-2"><div className="flex items-center justify-between gap-2"><span className="text-xs font-semibold">{row.code}</span><span className="text-xs tabular-nums">{row.attempts} attempts</span></div><p className="mt-1 text-[11px] text-muted-foreground">{row.learners} learners · {row.released} released</p></div>)}</div></div> : <EmptyState text="No COC activity matches this period." />}</section>
      <section className="overflow-hidden rounded-xl border border-border bg-card"><SectionHeading title="Recent audited operations" description={`${data.summary.auditEvents} trusted audit events occurred in the selected period.`} />{data.recentAuditEvents.length ? <div className="divide-y divide-border">{data.recentAuditEvents.map((event) => <div key={event.id} className="flex items-start justify-between gap-4 px-5 py-3.5"><div className="min-w-0"><p className="truncate text-sm font-medium">{event.action}</p><p className="mt-1 text-xs text-muted-foreground">{event.targetType} · {event.actorRole ?? "system"}</p></div><div className="shrink-0 text-right"><Badge variant={event.outcome === "success" ? "secondary" : "destructive"}>{event.outcome}</Badge><p className="mt-1 text-[11px] text-muted-foreground">{formatDay(event.createdAt)}</p></div></div>)}</div> : <EmptyState text="No recent audit event is recorded." />}</section>
    </div>
    <div className="flex flex-wrap items-center gap-4 rounded-xl border border-border bg-card px-5 py-4 text-xs text-muted-foreground"><span className="flex items-center gap-2"><Activity className="h-4 w-4 text-primary" aria-hidden="true" />{data.summary.auditEvents} audited operations</span><span className="flex items-center gap-2"><Database className="h-4 w-4 text-primary" aria-hidden="true" />All values are live PostgreSQL aggregates</span></div>
  </div>;
}

function EmptyState({ text }: { text: string }) { return <div className="px-5 py-12 text-center text-sm text-muted-foreground">{text}</div>; }
