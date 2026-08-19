import Link from "next/link";
import { Activity, LockKeyhole, ShieldCheck, UserCog } from "lucide-react";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { MetricStrip } from "@/components/dashboard/MetricStrip";
import { PageHeader } from "@/components/dashboard/PageHeader";
import { SectionHeading } from "@/components/dashboard/SectionHeading";
import { AdminGovernanceTable, AdminTableCell } from "@/components/admin/AdminGovernanceTable";
import { Badge } from "@/components/ui/badge";
import { requireStaffProfile } from "@/lib/auth/server";
import { formatAdminDate, getAdminGovernanceData } from "@/lib/admin/governance";

export const dynamic = "force-dynamic";

export default async function AdminSecurityPage() {
  await requireStaffProfile(["admin"]);
  const { profiles, audits } = await getAdminGovernanceData();
  const failed = audits.filter((row) => row.outcome !== "success");
  const inactive = profiles.filter((row) => row.status !== "active");
  const admins = profiles.filter((row) => row.role === "admin" && row.status === "active");

  return <DashboardLayout><div className="mx-auto max-w-7xl space-y-7">
    <PageHeader title="Security" description="Review account posture and audited authorization outcomes. This page surfaces live operational evidence; RLS and privileged RPC enforcement remain server-side." actions={<Link href="/logs" className="inline-flex min-h-10 items-center gap-2 rounded-xl border border-border bg-card px-4 text-sm font-semibold hover:border-primary/30 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring">Open audit logs</Link>} />
    <MetricStrip ariaLabel="Security posture metrics" metrics={[
      { label: "Active administrators", value: admins.length, helper: "Accounts allowed to govern system state", icon: ShieldCheck, featured: true, href: "/users", linkLabel: "Review administrators" },
      { label: "Inactive accounts", value: inactive.length, helper: "Deactivated or otherwise unavailable profiles", icon: UserCog, tone: inactive.length ? "attention" : "positive", href: "/users", linkLabel: "Review inactive accounts" },
      { label: "Audited events", value: audits.length, helper: "Most recent trusted events loaded", icon: Activity, tone: "neutral", href: "/logs", linkLabel: "Open audit logs" },
      { label: "Non-success outcomes", value: failed.length, helper: "Events requiring operational review", icon: LockKeyhole, tone: failed.length ? "attention" : "positive" },
    ]} />
    <section className="overflow-hidden rounded-2xl border border-border bg-card shadow-xs"><SectionHeading title="Security controls" description="ByteQuest keeps privileged decisions in authenticated server routes, PostgreSQL functions, RLS, and append-only audit records." /><div className="grid gap-3 p-5 sm:grid-cols-3"><div className="rounded-xl border border-border bg-muted/20 p-4"><ShieldCheck className="h-5 w-5 text-primary" aria-hidden="true" /><p className="mt-3 text-sm font-semibold">Role separation</p><p className="mt-1 text-xs leading-5 text-muted-foreground">Admin and Instructor sessions use independent server guards and navigation scopes.</p></div><div className="rounded-xl border border-border bg-muted/20 p-4"><LockKeyhole className="h-5 w-5 text-primary" aria-hidden="true" /><p className="mt-3 text-sm font-semibold">Scoped access</p><p className="mt-1 text-xs leading-5 text-muted-foreground">Classes, learners, resources, and assessment records are constrained at the trusted boundary.</p></div><div className="rounded-xl border border-border bg-muted/20 p-4"><Activity className="h-5 w-5 text-primary" aria-hidden="true" /><p className="mt-3 text-sm font-semibold">Auditability</p><p className="mt-1 text-xs leading-5 text-muted-foreground">High-impact account and assessment operations are retained as audit events.</p></div></div></section>
    <AdminGovernanceTable headers={["Event", "Target", "Outcome", "Actor role", "Recorded"]} empty="No non-success security outcomes are recorded in the recent audit window.">{failed.length ? failed.slice(0, 40).map((row) => <tr key={row.id} className="transition-colors hover:bg-muted/25"><AdminTableCell><p className="font-semibold">{row.action}</p></AdminTableCell><AdminTableCell muted>{row.target_type}</AdminTableCell><AdminTableCell><Badge variant="destructive">{row.outcome}</Badge></AdminTableCell><AdminTableCell muted>{row.actor_role ?? "system"}</AdminTableCell><AdminTableCell muted>{formatAdminDate(row.created_at)}</AdminTableCell></tr>) : null}</AdminGovernanceTable>
  </div></DashboardLayout>;
}
