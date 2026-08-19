import Link from "next/link";
import { BookOpen, ShieldCheck, Users } from "lucide-react";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { MetricStrip } from "@/components/dashboard/MetricStrip";
import { PageHeader } from "@/components/dashboard/PageHeader";
import { AdminGovernanceTable, AdminTableCell } from "@/components/admin/AdminGovernanceTable";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { requireStaffProfile } from "@/lib/auth/server";
import { formatAdminDate, getAdminGovernanceData } from "@/lib/admin/governance";

export const dynamic = "force-dynamic";

export default async function AdminInstructorsPage() {
  await requireStaffProfile(["admin"]);
  const { profiles, classes, memberships } = await getAdminGovernanceData();
  const instructors = profiles.filter((profile) => profile.role === "instructor");
  const activeClasses = classes.filter((row) => row.status === "active");
  const membershipByClass = new Map<string, number>();
  memberships.filter((row) => row.status === "active").forEach((row) => membershipByClass.set(row.class_id, (membershipByClass.get(row.class_id) ?? 0) + 1));

  return <DashboardLayout><div className="mx-auto max-w-7xl space-y-7">
    <PageHeader title="Instructors" description="Review Instructor accounts and the classes they currently own. Changes to account state remain governed by Account management." actions={<Button asChild><Link href="/users/create">Create account</Link></Button>} />
    <MetricStrip ariaLabel="Instructor governance metrics" metrics={[
      { label: "Active instructors", value: instructors.filter((row) => row.status === "active").length, helper: "Staff accounts currently active", icon: ShieldCheck, featured: true },
      { label: "Owned classes", value: activeClasses.length, helper: "Active classes across all Instructors", icon: BookOpen },
      { label: "Active enrollments", value: memberships.filter((row) => row.status === "active").length, helper: "Learner memberships in active classes", icon: Users, tone: "positive" },
      { label: "Needs review", value: instructors.filter((row) => row.status !== "active").length, helper: "Instructor accounts not currently active", icon: ShieldCheck, tone: "attention", href: "/users", linkLabel: "Review account states" },
    ]} />
    <AdminGovernanceTable headers={["Instructor", "Account", "Owned classes", "Last activity", "Scope"]} empty="No Instructor profiles are available.">{instructors.length ? instructors.map((row) => {
      const owned = classes.filter((item) => item.instructor_id === row.user_id);
      const activeOwned = owned.filter((item) => item.status === "active");
      const learners = activeOwned.reduce((total, item) => total + (membershipByClass.get(item.id) ?? 0), 0);
      return <tr key={row.user_id} className="transition-colors hover:bg-muted/25"><AdminTableCell><Link href={`/users/${row.user_id}/edit`} className="font-semibold text-foreground hover:text-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring">{row.full_name}</Link><p className="mt-0.5 text-xs text-muted-foreground">{row.email}</p></AdminTableCell><AdminTableCell><Badge variant={row.status === "active" ? "secondary" : "outline"}>{row.status}</Badge></AdminTableCell><AdminTableCell><span className="font-semibold tabular-nums">{activeOwned.length}</span><span className="ml-2 text-xs text-muted-foreground">{learners} learner{learners === 1 ? "" : "s"}</span></AdminTableCell><AdminTableCell muted>{formatAdminDate(row.last_activity_at)}</AdminTableCell><AdminTableCell><Link href="/admin/access-scope" className="text-xs font-semibold text-primary hover:underline">View scope</Link></AdminTableCell></tr>;
    }) : null}</AdminGovernanceTable>
  </div></DashboardLayout>;
}
