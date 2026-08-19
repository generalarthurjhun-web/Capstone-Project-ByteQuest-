import Link from "next/link";
import { ArrowUpRight, BookOpen, LockKeyhole, Users } from "lucide-react";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { MetricStrip } from "@/components/dashboard/MetricStrip";
import { PageHeader } from "@/components/dashboard/PageHeader";
import { AdminGovernanceTable, AdminTableCell } from "@/components/admin/AdminGovernanceTable";
import { Badge } from "@/components/ui/badge";
import { requireStaffProfile } from "@/lib/auth/server";
import { getAdminGovernanceData, formatAdminDate } from "@/lib/admin/governance";

export const dynamic = "force-dynamic";

export default async function AdminAccessScopePage() {
  await requireStaffProfile(["admin"]);
  const { profiles, classes, memberships, resources } = await getAdminGovernanceData();
  const instructorNames = new Map(profiles.filter((row) => row.role === "instructor").map((row) => [row.user_id, row.full_name]));
  const activeMemberships = memberships.filter((row) => row.status === "active");
  const activeResources = resources.filter((row) => row.status === "active");
  const learnersByClass = new Map<string, number>();
  activeMemberships.forEach((row) => learnersByClass.set(row.class_id, (learnersByClass.get(row.class_id) ?? 0) + 1));
  const resourcesByClass = new Map<string, number>();
  activeResources.forEach((row) => resourcesByClass.set(row.class_id, (resourcesByClass.get(row.class_id) ?? 0) + 1));

  return <DashboardLayout><div className="mx-auto max-w-7xl space-y-7">
    <PageHeader title="Access & scope" description="The active authorization scope is derived from Instructor-owned classes, historical memberships, and class-scoped resources. No separate unrestricted ACL is introduced here." actions={<Link href="/users" className="inline-flex min-h-10 items-center gap-2 rounded-xl border border-border bg-card px-4 text-sm font-semibold hover:border-primary/30 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring">Account management <ArrowUpRight className="h-4 w-4" aria-hidden="true" /></Link>} />
    <MetricStrip ariaLabel="Access scope metrics" metrics={[
      { label: "Active class scopes", value: classes.filter((row) => row.status === "active").length, helper: "Each scope belongs to one Instructor", icon: LockKeyhole, featured: true },
      { label: "Scoped learners", value: new Set(activeMemberships.map((row) => row.learner_id)).size, helper: "Active memberships only", icon: Users, tone: "positive" },
      { label: "Scoped resources", value: activeResources.length, helper: "Private resources attached to classes", icon: BookOpen },
      { label: "Historical memberships", value: memberships.length, helper: "Deactivated records remain retained", icon: Users, tone: "neutral" },
    ]} />
    <AdminGovernanceTable headers={["Class scope", "Owner", "Learners", "Resources", "State", "Created"]} empty="No class scopes are available.">{classes.length ? classes.map((row) => <tr key={row.id} className="transition-colors hover:bg-muted/25"><AdminTableCell><p className="font-semibold">{row.title}</p><p className="mt-0.5 text-xs text-muted-foreground">{row.class_code || "No class code"}</p></AdminTableCell><AdminTableCell><Link href={`/users/${row.instructor_id}/edit`} className="text-sm font-semibold text-primary hover:underline">{instructorNames.get(row.instructor_id) ?? "Unknown Instructor"}</Link></AdminTableCell><AdminTableCell><span className="font-semibold tabular-nums">{learnersByClass.get(row.id) ?? 0}</span></AdminTableCell><AdminTableCell><span className="font-semibold tabular-nums">{resourcesByClass.get(row.id) ?? 0}</span></AdminTableCell><AdminTableCell><Badge variant={row.status === "active" ? "secondary" : "outline"}>{row.status}</Badge></AdminTableCell><AdminTableCell muted>{formatAdminDate(row.created_at)}</AdminTableCell></tr>) : null}</AdminGovernanceTable>
  </div></DashboardLayout>;
}
