import { MetricStrip } from "@/components/dashboard/MetricStrip";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { Skeleton } from "@/components/ui/skeleton";

export default function ResourcesLoading() {
  return (
    <DashboardLayout>
      <div className="mx-auto max-w-7xl space-y-7" aria-label="Loading learning resources">
        <div className="space-y-3 border-b border-border pb-5">
          <Skeleton className="h-8 w-56 max-w-full" />
          <Skeleton className="h-4 w-full max-w-3xl" />
        </div>
        <MetricStrip loading ariaLabel="Loading learning resource metrics" />
        <Skeleton className="h-[480px] rounded-xl" />
      </div>
    </DashboardLayout>
  );
}
