import { AdminSystemAnalyticsDashboard } from "@/components/analytics/AdminSystemAnalyticsDashboard";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { getAdminAnalytics, parseAnalyticsFilters } from "@/lib/analytics/server";
import { requireStaffProfile } from "@/lib/auth/server";

export const dynamic = "force-dynamic";

export default async function AdminAnalyticsPage({ searchParams }: { searchParams: Promise<Record<string, string | string[] | undefined>> }) {
  await requireStaffProfile(["admin"]);
  const filters = parseAnalyticsFilters(await searchParams);
  const data = await getAdminAnalytics(filters);
  return <DashboardLayout><AdminSystemAnalyticsDashboard data={data} range={filters.range} /></DashboardLayout>;
}

