import Link from "next/link";
import { Activity, GraduationCap, Users } from "lucide-react";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { MetricStrip } from "@/components/dashboard/MetricStrip";
import { PageHeader } from "@/components/dashboard/PageHeader";
import { AdminGovernanceTable, AdminTableCell } from "@/components/admin/AdminGovernanceTable";
import { Badge } from "@/components/ui/badge";
import { requireStaffProfile } from "@/lib/auth/server";
import { formatAdminDate, getAdminGovernanceData } from "@/lib/admin/governance";

export const dynamic = "force-dynamic";

export default async function AdminLearnersPage() {
  await requireStaffProfile(["admin"]);
  const { profiles, classes, memberships } = await getAdminGovernanceData();
  const learners = profiles.filter((profile) => profile.role === "learner");
  const activeMemberships = memberships.filter((row) => row.status === "active");
  const classesByLearner = new Map<string, number>();
  activeMemberships.forEach((row) => classesByLearner.set(row.learner_id, (classesByLearner.get(row.learner_id) ?? 0) + 1));

  return <DashboardLayout><div className="mx-auto max-w-7xl space-y-7">
    <PageHeader title="Learners" description="Review learner account state and historical enrollment without entering Instructor assessment workflows." />
    <MetricStrip ariaLabel="Learner governance metrics" metrics={[
      { label: "Active learners", value: learners.filter((row) => row.status === "active").length, helper: "Learner accounts currently active", icon: Users, featured: true },
      { label: "Enrolled learners", value: new Set(activeMemberships.map((row) => row.learner_id)).size, helper: "Learners with at least one active class membership", icon: GraduationCap, tone: "positive" },
      { label: "Active classes", value: classes.filter((row) => row.status === "active").length, helper: "Available class contexts", icon: GraduationCap },
      { label: "Needs account review", value: learners.filter((row) => row.status !== "active").length, helper: "Deactivated or otherwise inactive accounts", icon: Activity, tone: "attention", href: "/users", linkLabel: "Review learner accounts" },
    ]} />
    <AdminGovernanceTable headers={["Learner", "Account", "Active classes", "Last activity", "Account record"]} empty="No learner profiles are available.">{learners.length ? learners.map((row) => <tr key={row.user_id} className="transition-colors hover:bg-muted/25"><AdminTableCell><Link href={`/users/${row.user_id}/edit`} className="font-semibold text-foreground hover:text-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring">{row.full_name}</Link><p className="mt-0.5 text-xs text-muted-foreground">{row.email}</p></AdminTableCell><AdminTableCell><Badge variant={row.status === "active" ? "secondary" : "outline"}>{row.status}</Badge></AdminTableCell><AdminTableCell><span className="font-semibold tabular-nums">{classesByLearner.get(row.user_id) ?? 0}</span></AdminTableCell><AdminTableCell muted>{formatAdminDate(row.last_activity_at)}</AdminTableCell><AdminTableCell><Badge variant="outline">History preserved</Badge></AdminTableCell></tr>) : null}</AdminGovernanceTable>
  </div></DashboardLayout>;
}
