import Link from "next/link";
import {
  GraduationCap,
  ShieldCheck,
  UserCog,
  Users,
} from "lucide-react";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { MetricStrip, type Metric } from "@/components/dashboard/MetricStrip";
import { PageHeader } from "@/components/dashboard/PageHeader";
import { AdminOverviewPanels } from "@/components/admin/AdminOverviewPanels";
import { Button } from "@/components/ui/button";
import { requireStaffProfile } from "@/lib/auth/server";
import { createAdminSupabaseClient } from "@/lib/supabase/admin";
import { getAdminAnalytics, parseAnalyticsFilters } from "@/lib/analytics/server";

export const dynamic = "force-dynamic";

export default async function AdminDashboardPage() {
  await requireStaffProfile(["admin"]);
  const supabase = createAdminSupabaseClient();
  const overviewAnalytics = getAdminAnalytics(parseAnalyticsFilters({ range: "7" })).catch(() => null);

  const [accounts, instructors, learners, activeClasses, sources, audits, resources, analytics] = await Promise.all([
    supabase.from("profiles").select("id", { count: "exact", head: true }),
    supabase
      .from("profiles")
      .select("id", { count: "exact", head: true })
      .eq("role", "instructor")
      .eq("status", "active"),
    supabase
      .from("profiles")
      .select("id", { count: "exact", head: true })
      .eq("role", "learner")
      .eq("status", "active"),
    supabase
      .from("classes")
      .select("id", { count: "exact", head: true })
      .eq("status", "active"),
    supabase
      .from("tesda_sources")
      .select("id,status,title,edition,updated_at")
      .order("updated_at", { ascending: false }),
    supabase
      .from("audit_events")
      .select("id,action,target_type,outcome,created_at,actor_id")
      .order("created_at", { ascending: false })
      .limit(8),
    supabase
      .from("learning_resources")
      .select("id,size_bytes,mime_type,status")
      .eq("status", "active"),
    overviewAnalytics,
  ]);

  if (
    accounts.error ||
    instructors.error ||
    learners.error ||
    activeClasses.error ||
    sources.error ||
    audits.error ||
    resources.error
  ) {
    throw new Error("The system administration summary could not be loaded.");
  }

  const sourceRows = sources.data ?? [];
  const activeSources = sourceRows.filter((source) => source.status === "active").length;

  const metrics: Metric[] = [
    {
      label: "Active learners",
      value: learners.count ?? 0,
      helper: "Learner accounts currently active",
      icon: Users,
      featured: true,
      href: "/users",
      linkLabel: "Open learner account management",
    },
    {
      label: "Active instructors",
      value: instructors.count ?? 0,
      helper: "Instructor accounts currently active",
      icon: ShieldCheck,
      href: "/users",
      linkLabel: "Open instructor account management",
    },
    {
      label: "Active classes",
      value: activeClasses.count ?? 0,
      helper: "Classes active across the platform",
      icon: GraduationCap,
      tone: "neutral",
    },
    {
      label: "Registered accounts",
      value: accounts.count ?? 0,
      helper: "All application profiles",
      icon: UserCog,
      href: "/users",
      linkLabel: "Open all registered accounts",
    },
  ];

  return (
    <DashboardLayout>
      <div className="mx-auto max-w-7xl space-y-7">
        <PageHeader title="Admin overview" description="Govern accounts, source versions, platform access, and high-impact system activity without entering the ordinary Instructor assessment workflow." actions={<><Button asChild variant="outline"><Link href="/admin/analytics">System analytics</Link></Button><Button asChild variant="outline"><Link href="/tesda-sources">Review TESDA sources</Link></Button><Button asChild><Link href="/users/create">Create instructor</Link></Button></>} />

        <MetricStrip metrics={metrics} ariaLabel="System administration metrics" />

        {activeSources === 0 ? (
          <section className="rounded-xl border border-amber-300 bg-amber-50 p-5 text-amber-950">
            <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
              <div>
                <h2 className="font-semibold">TESDA source confirmation is still required</h2>
                <p className="mt-1 max-w-3xl text-sm leading-relaxed text-amber-900">
                  Official assessment assignment, evaluation, finalization, and release remain
                  blocked until an Admin approves and activates the exact official source and
                  its matching rubric. No legacy threshold has been promoted.
                </p>
              </div>
              <Button asChild variant="outline" className="border-amber-500 bg-white">
                <Link href="/tesda-sources">Open source registry</Link>
              </Button>
            </div>
          </section>
        ) : null}

        <AdminOverviewPanels
          analytics={analytics}
          sources={sourceRows}
          resources={resources.data ?? []}
          audits={audits.data ?? []}
        />

      </div>
    </DashboardLayout>
  );
}
