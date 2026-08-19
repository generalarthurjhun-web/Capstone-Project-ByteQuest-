import Link from "next/link";
import { Archive, FileStack, HardDrive, ShieldCheck } from "lucide-react";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { MetricStrip } from "@/components/dashboard/MetricStrip";
import { PageHeader } from "@/components/dashboard/PageHeader";
import { AdminGovernanceTable, AdminTableCell } from "@/components/admin/AdminGovernanceTable";
import { Badge } from "@/components/ui/badge";
import { requireStaffProfile } from "@/lib/auth/server";
import { formatAdminDate, formatStorageBytes, getAdminGovernanceData } from "@/lib/admin/governance";

export const dynamic = "force-dynamic";

export default async function AdminResourceGovernancePage() {
  await requireStaffProfile(["admin"]);
  const { classes, profiles, resources } = await getAdminGovernanceData();
  const owners = new Map(profiles.map((row) => [row.user_id, row.full_name]));
  const classNames = new Map(classes.map((row) => [row.id, row.title]));
  const active = resources.filter((row) => row.status === "active");
  const archived = resources.filter((row) => row.status === "deleted");
  const bytes = active.reduce((total, row) => total + Number(row.size_bytes ?? 0), 0);

  return <DashboardLayout><div className="mx-auto max-w-7xl space-y-7">
    <PageHeader title="Resource governance" description="Review private learning-resource inventory, ownership, lifecycle state, and storage use. Instructor upload and class-scope permissions remain enforced by existing RPCs and Storage policies." actions={<Link href="/resources" className="inline-flex min-h-10 items-center gap-2 rounded-xl border border-border bg-card px-4 text-sm font-semibold hover:border-primary/30 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring">Open Instructor resources</Link>} />
    <MetricStrip ariaLabel="Resource governance metrics" metrics={[
      { label: "Active resources", value: active.length, helper: "Available through authorized class scope", icon: FileStack, featured: true, href: "/resources", linkLabel: "Open resources" },
      { label: "Classes with resources", value: new Set(active.map((row) => row.class_id)).size, helper: "Active classes with at least one resource", icon: ShieldCheck, tone: "positive" },
      { label: "Archived resources", value: archived.length, helper: "Retained metadata with deletion audit details", icon: Archive, tone: "neutral" },
      { label: "Authorized storage", value: formatStorageBytes(bytes), helper: "Active private resource metadata", icon: HardDrive },
    ]} />
    <AdminGovernanceTable headers={["Resource", "Class", "Uploaded by", "Type", "Size", "State", "Created"]} empty="No learning resources are recorded.">{resources.length ? resources.map((row) => <tr key={row.id} className="transition-colors hover:bg-muted/25"><AdminTableCell><p className="font-semibold">{row.title}</p><p className="mt-0.5 text-xs text-muted-foreground">{row.storage_bucket} · private path</p></AdminTableCell><AdminTableCell>{classNames.get(row.class_id) ?? "Unknown class"}</AdminTableCell><AdminTableCell>{owners.get(row.uploaded_by) ?? "Unknown user"}</AdminTableCell><AdminTableCell muted>{row.mime_type ?? "Type not recorded"}</AdminTableCell><AdminTableCell muted>{formatStorageBytes(Number(row.size_bytes ?? 0))}</AdminTableCell><AdminTableCell><Badge variant={row.status === "active" ? "secondary" : "outline"}>{row.status === "deleted" ? "archived" : row.status}</Badge></AdminTableCell><AdminTableCell muted>{formatAdminDate(row.created_at)}</AdminTableCell></tr>) : null}</AdminGovernanceTable>
  </div></DashboardLayout>;
}
