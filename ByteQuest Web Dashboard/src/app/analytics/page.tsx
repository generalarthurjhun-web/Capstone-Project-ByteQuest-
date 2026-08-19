import { InstructorAnalyticsDashboard } from "@/components/analytics/InstructorAnalyticsDashboard";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { getInstructorAnalytics, parseAnalyticsFilters } from "@/lib/analytics/server";
import { requireStaffProfile } from "@/lib/auth/server";

export const dynamic = "force-dynamic";

export default async function AnalyticsPage({
  searchParams,
}: {
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}) {
  await requireStaffProfile(["instructor"]);
  const filters = parseAnalyticsFilters(await searchParams);
  const data = await getInstructorAnalytics(filters);

  return (
    <DashboardLayout>
      <InstructorAnalyticsDashboard data={data} filters={filters} />
    </DashboardLayout>
  );
}

