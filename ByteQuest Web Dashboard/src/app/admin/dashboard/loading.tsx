import { MetricStrip } from "@/components/dashboard/MetricStrip";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { Skeleton } from "@/components/ui/skeleton";

export default function AdminDashboardLoading() {
  return (
    <DashboardLayout>
      <div className="mx-auto max-w-7xl space-y-7" aria-label="Loading system administration">
        <div className="space-y-3 border-b border-border pb-5">
          <Skeleton className="h-8 w-64 max-w-full" />
          <Skeleton className="h-4 w-full max-w-3xl" />
        </div>
        <MetricStrip loading ariaLabel="Loading system administration metrics" />
        <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_minmax(320px,0.7fr)]">
          <Skeleton className="h-[390px] rounded-xl" />
          <Skeleton className="h-[390px] rounded-xl" />
        </div>
      </div>
    </DashboardLayout>
  );
}
