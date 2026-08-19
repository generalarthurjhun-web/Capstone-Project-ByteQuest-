import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { MetricStrip } from "@/components/dashboard/MetricStrip";
import { Skeleton } from "@/components/ui/skeleton";

export default function AdminLoading() {
  return <DashboardLayout><div className="mx-auto max-w-7xl space-y-7" role="status" aria-label="Loading Admin workspace"><div className="space-y-3 border-b border-border pb-5"><Skeleton className="h-8 w-64" /><Skeleton className="h-4 w-full max-w-2xl" /></div><MetricStrip loading ariaLabel="Loading Admin metrics" /><Skeleton className="h-[360px] w-full rounded-2xl" /></div></DashboardLayout>;
}
