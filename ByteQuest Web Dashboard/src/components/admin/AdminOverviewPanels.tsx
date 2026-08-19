"use client";

import Link from "next/link";
import {
  Activity,
  ArrowUpRight,
  CheckCircle2,
  CircleAlert,
  Database,
  FileStack,
  ShieldCheck,
  TriangleAlert,
} from "lucide-react";
import {
  CartesianGrid,
  Cell,
  Line,
  LineChart,
  Pie,
  PieChart,
  XAxis,
  YAxis,
} from "recharts";
import { ChartContainer, ChartTooltip, ChartTooltipContent, type ChartConfig } from "@/components/ui/chart";
import { SectionHeading } from "@/components/dashboard/SectionHeading";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { useReducedMotion } from "@/hooks/use-reduced-motion";
import type { AdminAnalytics } from "@/lib/analytics/types";

type SourceRow = {
  id: string;
  title: string;
  edition: string | null;
  status: string;
  updated_at: string;
};

type AuditRow = {
  id: string;
  action: string;
  target_type: string;
  outcome: string;
  created_at: string;
};

type ResourceRow = {
  mime_type: string | null;
  size_bytes: number | null;
};

type AdminOverviewPanelsProps = {
  analytics: AdminAnalytics | null;
  sources: SourceRow[];
  resources: ResourceRow[];
  audits: AuditRow[];
};

const trendConfig = {
  assessments: { label: "Assessments", color: "hsl(var(--chart-1))" },
  released: { label: "Released results", color: "hsl(var(--chart-3))" },
  resources: { label: "Resources", color: "hsl(var(--chart-4))" },
} satisfies ChartConfig;

const accountColors = [
  "hsl(var(--chart-1))",
  "hsl(var(--chart-4))",
  "hsl(var(--destructive))",
  "hsl(var(--muted-foreground))",
];

function formatDay(value: string) {
  return new Intl.DateTimeFormat("en-PH", {
    month: "short",
    day: "numeric",
    timeZone: "Asia/Manila",
  }).format(new Date(value));
}

function formatDate(value: string) {
  return new Intl.DateTimeFormat("en-PH", {
    dateStyle: "medium",
    timeZone: "Asia/Manila",
  }).format(new Date(value));
}

function formatBytes(value: number) {
  if (!value) return "0 B";
  const units = ["B", "KiB", "MiB", "GiB"];
  const index = Math.min(Math.floor(Math.log(value) / Math.log(1024)), units.length - 1);
  return `${(value / 1024 ** index).toFixed(index ? 1 : 0)} ${units[index]}`;
}

function readableStatus(value: string) {
  return value.replaceAll("_", " ");
}

function sourceVariant(status: string): "default" | "secondary" | "outline" {
  if (status === "active") return "default";
  if (status === "approved") return "secondary";
  return "outline";
}

export function AdminOverviewPanels({ analytics, sources, resources, audits }: AdminOverviewPanelsProps) {
  const reducedMotion = useReducedMotion();
  const accountStates = (analytics?.accountStates ?? []).map((row) => ({
    ...row,
    label: `${row.role} · ${readableStatus(row.status)}`,
  }));
  const resourceGroups = resources.reduce<Map<string, { label: string; count: number; bytes: number }>>((groups, row) => {
    const label = row.mime_type?.split("/")[0] || "Unspecified";
    const current = groups.get(label) ?? { label, count: 0, bytes: 0 };
    current.count += 1;
    current.bytes += Number(row.size_bytes ?? 0);
    groups.set(label, current);
    return groups;
  }, new Map());
  const resourceSummary = [...resourceGroups.values()].sort((a, b) => b.bytes - a.bytes).slice(0, 4);
  const pendingSources = sources.filter((source) => source.status === "pending_tesda_validation").length;
  const failedAudits = audits.filter((event) => event.outcome !== "success").length;
  const alerts = [
    ...(pendingSources
      ? [{
        title: `${pendingSources} TESDA source${pendingSources === 1 ? "" : "s"} awaiting validation`,
        description: "Review provenance before activating a source for authoritative workflows.",
        tone: "warning" as const,
        href: "/tesda-sources",
      }]
      : []),
    ...(failedAudits
      ? [{
        title: `${failedAudits} recent audited operation${failedAudits === 1 ? "" : "s"} need review`,
        description: "Inspect the recorded outcome and actor scope in Audit Logs.",
        tone: "danger" as const,
        href: "/logs",
      }]
      : []),
  ];

  return (
    <div className="space-y-6">
      <div className="grid gap-5 xl:grid-cols-[minmax(0,1.7fr)_minmax(320px,0.9fr)]">
        <section className="overflow-hidden rounded-2xl border border-border/75 bg-card shadow-card">
          <SectionHeading
            title="Platform activity"
            description="A seven-day view of trusted assessment, release, and resource events."
            action={<Button asChild variant="ghost" size="sm"><Link href="/admin/analytics">Open analytics <ArrowUpRight className="ml-1 h-3.5 w-3.5" aria-hidden="true" /></Link></Button>}
          />
          {analytics?.trend.length ? (
            <div className="p-4 sm:p-5">
              <p className="sr-only">
                Activity trend for {analytics.trend.length} days with {analytics.summary.assessmentVolume} assessment attempts, {analytics.summary.releasedResults} released results, and {analytics.summary.resourceUploads} resource uploads.
              </p>
              <ChartContainer config={trendConfig} className="h-[270px] w-full aspect-auto" aria-label="Platform activity trend">
                <LineChart data={analytics.trend} margin={{ left: 0, right: 10, top: 10, bottom: 0 }} accessibilityLayer>
                  <CartesianGrid vertical={false} strokeDasharray="3 3" />
                  <XAxis dataKey="date" tickFormatter={formatDay} tickLine={false} axisLine={false} minTickGap={28} />
                  <YAxis allowDecimals={false} tickLine={false} axisLine={false} width={30} />
                  <ChartTooltip content={<ChartTooltipContent labelFormatter={(value) => formatDay(String(value))} />} />
                  <Line dataKey="assessments" stroke="var(--color-assessments)" strokeWidth={2.25} dot={false} isAnimationActive={!reducedMotion} />
                  <Line dataKey="released" stroke="var(--color-released)" strokeWidth={2.25} dot={false} strokeDasharray="6 4" isAnimationActive={!reducedMotion} />
                  <Line dataKey="resources" stroke="var(--color-resources)" strokeWidth={1.75} dot={false} strokeDasharray="2 4" isAnimationActive={!reducedMotion} />
                </LineChart>
              </ChartContainer>
              <div className="mt-3 flex flex-wrap gap-x-5 gap-y-2 text-[11px] text-muted-foreground" aria-label="Chart legend">
                {Object.entries(trendConfig).map(([key, config]) => <span key={key} className="inline-flex items-center gap-2"><span className="h-2 w-2 rounded-full" style={{ backgroundColor: config.color }} aria-hidden="true" />{config.label}</span>)}
              </div>
            </div>
          ) : (
            <EmptyState icon={Activity} title="No activity trend is available" text="Live analytics will appear here once authoritative system events are recorded." />
          )}
        </section>

        <section className="overflow-hidden rounded-2xl border border-border/75 bg-card shadow-card">
          <SectionHeading title="Account status" description="Current profiles grouped by role and lifecycle state." />
          {accountStates.length ? (
            <div className="grid gap-4 p-5 sm:grid-cols-[156px_minmax(0,1fr)] sm:items-center">
              <div className="relative mx-auto h-36 w-36">
                <ChartContainer config={{ count: { label: "Profiles", color: "hsl(var(--chart-1))" } }} className="h-36 w-36 aspect-square" aria-label="Account status distribution">
                  <PieChart accessibilityLayer>
                    <Pie data={accountStates} dataKey="count" nameKey="label" innerRadius={45} outerRadius={62} paddingAngle={2} strokeWidth={0} isAnimationActive={!reducedMotion}>
                      {accountStates.map((row, index) => <Cell key={`${row.role}-${row.status}`} fill={accountColors[index % accountColors.length]} />)}
                    </Pie>
                    <ChartTooltip content={<ChartTooltipContent />} />
                  </PieChart>
                </ChartContainer>
                <div className="pointer-events-none absolute inset-0 flex flex-col items-center justify-center"><span className="text-xl font-bold tabular-nums tracking-tight">{accountStates.reduce((sum, row) => sum + row.count, 0).toLocaleString()}</span><span className="text-[10px] text-muted-foreground">profiles</span></div>
              </div>
              <div className="space-y-2.5">
                {accountStates.slice(0, 6).map((row, index) => <div key={`${row.role}-${row.status}`} className="flex items-center justify-between gap-3 text-xs"><span className="flex min-w-0 items-center gap-2 text-muted-foreground"><span className="h-2 w-2 shrink-0 rounded-full" style={{ backgroundColor: accountColors[index % accountColors.length] }} aria-hidden="true" /><span className="truncate capitalize">{row.label}</span></span><span className="font-semibold tabular-nums text-foreground">{row.count.toLocaleString()}</span></div>)}
              </div>
            </div>
          ) : (
            <EmptyState icon={ShieldCheck} title="No account states to summarize" text="The current project has not returned account lifecycle aggregates." />
          )}
          <div className="border-t border-border/70 px-5 py-3"><Link href="/users" className="inline-flex items-center text-xs font-semibold text-primary hover:underline">Review accounts <ArrowUpRight className="ml-1 h-3.5 w-3.5" aria-hidden="true" /></Link></div>
        </section>
      </div>

      <div className="grid gap-5 xl:grid-cols-[minmax(0,1.15fr)_minmax(0,0.85fr)]">
        <section className="overflow-hidden rounded-2xl border border-border/75 bg-card shadow-card">
          <SectionHeading title="TESDA source readiness" description="Source versions remain separate from operational approval until their provenance is reviewed." action={<Button asChild variant="ghost" size="sm"><Link href="/tesda-sources">View registry <ArrowUpRight className="ml-1 h-3.5 w-3.5" aria-hidden="true" /></Link></Button>} />
          {sources.length ? <div className="divide-y divide-border/70">{sources.slice(0, 6).map((source) => <div key={source.id} className="flex items-center justify-between gap-4 px-5 py-3.5"><div className="min-w-0"><p className="truncate text-sm font-semibold text-foreground">{source.title}</p><p className="mt-0.5 truncate text-[11px] text-muted-foreground">{source.edition || "Edition not recorded"} · updated {formatDate(source.updated_at)}</p></div><Badge variant={sourceVariant(source.status)} className="shrink-0 capitalize">{readableStatus(source.status)}</Badge></div>)}</div> : <EmptyState icon={Database} title="No TESDA sources registered" text="Register a candidate source to begin the controlled provenance workflow." />}
          {pendingSources ? <div className="flex items-center gap-2 border-t border-amber-200 bg-amber-50 px-5 py-3 text-xs font-semibold text-amber-900"><TriangleAlert className="h-4 w-4" aria-hidden="true" />{pendingSources} source version{pendingSources === 1 ? "" : "s"} need validation before activation.</div> : null}
        </section>

        <section className="overflow-hidden rounded-2xl border border-border/75 bg-card shadow-card">
          <SectionHeading title="Private resource storage" description="Active private learning resources grouped by their recorded MIME family." action={<Button asChild variant="ghost" size="sm"><Link href="/admin/resources">Manage resources <ArrowUpRight className="ml-1 h-3.5 w-3.5" aria-hidden="true" /></Link></Button>} />
          {resourceSummary.length ? <div className="space-y-4 p-5">{resourceSummary.map((group) => { const totalBytes = resources.reduce((sum, row) => sum + Number(row.size_bytes ?? 0), 0); const share = totalBytes ? Math.round((group.bytes / totalBytes) * 100) : 0; return <div key={group.label}><div className="flex items-center justify-between gap-3 text-xs"><span className="font-semibold capitalize">{group.label}</span><span className="text-muted-foreground">{group.count} resource{group.count === 1 ? "" : "s"} · {formatBytes(group.bytes)}</span></div><div className="mt-2 h-2 overflow-hidden rounded-full bg-muted"><div className="h-full rounded-full bg-primary transition-[width] duration-300 motion-reduce:transition-none" style={{ width: `${share}%` }} aria-label={`${group.label} uses ${share}% of recorded active resource storage`} /></div></div>})}<div className="flex items-center justify-between border-t border-border/70 pt-4 text-xs"><span className="text-muted-foreground">Recorded active resources</span><span className="font-bold tabular-nums">{resources.length} · {formatBytes(resources.reduce((sum, row) => sum + Number(row.size_bytes ?? 0), 0))}</span></div></div> : <EmptyState icon={FileStack} title="No active resources recorded" text="Private storage usage will appear after an authorized resource is uploaded." />}
        </section>
      </div>

      <div className="grid gap-5 xl:grid-cols-[minmax(0,1.15fr)_minmax(0,0.85fr)]">
        <section className="overflow-hidden rounded-2xl border border-border/75 bg-card shadow-card">
          <SectionHeading title="Recent audit activity" description="Trusted events from the most recent Admin summary window." action={<Button asChild variant="ghost" size="sm"><Link href="/logs">View audit logs <ArrowUpRight className="ml-1 h-3.5 w-3.5" aria-hidden="true" /></Link></Button>} />
          {audits.length ? <div className="divide-y divide-border/70">{audits.slice(0, 6).map((event) => <div key={event.id} className="grid gap-2 px-5 py-3.5 sm:grid-cols-[minmax(0,1fr)_auto_auto] sm:items-center sm:gap-4"><div className="min-w-0"><p className="truncate text-sm font-semibold">{event.action}</p><p className="mt-0.5 truncate text-[11px] text-muted-foreground">{event.target_type}</p></div><Badge variant={event.outcome === "success" ? "secondary" : "destructive"}>{event.outcome}</Badge><time dateTime={event.created_at} className="text-[11px] text-muted-foreground sm:text-right">{formatDay(event.created_at)}</time></div>)}</div> : <EmptyState icon={Activity} title="No audit activity recorded" text="High-impact operations will appear here after they are recorded by the trusted workflow." />}
        </section>

        <section className="overflow-hidden rounded-2xl border border-border/75 bg-card shadow-card">
          <SectionHeading title="Governance attention" description="Actionable signals derived from the current source and audit records." />
          {alerts.length ? <div className="divide-y divide-border/70">{alerts.map((alert) => <Link href={alert.href} key={alert.title} className="group flex items-start gap-3 px-5 py-4 transition-colors hover:bg-muted/25 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-inset"><span className={alert.tone === "danger" ? "mt-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-red-50 text-red-700 ring-1 ring-red-100" : "mt-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-amber-50 text-amber-800 ring-1 ring-amber-100"}>{alert.tone === "danger" ? <CircleAlert className="h-4 w-4" aria-hidden="true" /> : <TriangleAlert className="h-4 w-4" aria-hidden="true" />}</span><span className="min-w-0"><span className="block text-sm font-semibold text-foreground">{alert.title}</span><span className="mt-1 block text-xs leading-5 text-muted-foreground">{alert.description}</span></span><ArrowUpRight className="ml-auto mt-1 h-4 w-4 shrink-0 text-primary opacity-40 transition-opacity group-hover:opacity-100" aria-hidden="true" /></Link>)}</div> : <div className="flex flex-col items-center px-5 py-10 text-center"><CheckCircle2 className="h-7 w-7 text-emerald-600" aria-hidden="true" /><p className="mt-3 text-sm font-semibold">No governance attention items</p><p className="mt-1 max-w-xs text-xs leading-5 text-muted-foreground">No pending source validation or non-success audit event was returned for this summary.</p></div>}
        </section>
      </div>
    </div>
  );
}

function EmptyState({ icon: Icon, title, text }: { icon: typeof Activity; title: string; text: string }) {
  return <div className="flex flex-col items-center px-5 py-12 text-center"><Icon className="h-7 w-7 text-muted-foreground" aria-hidden="true" /><p className="mt-3 text-sm font-semibold text-foreground">{title}</p><p className="mt-1 max-w-sm text-xs leading-5 text-muted-foreground">{text}</p></div>;
}
