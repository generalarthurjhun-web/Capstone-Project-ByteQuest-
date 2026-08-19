import { MetricStrip } from "@/components/dashboard/MetricStrip";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { Skeleton } from "@/components/ui/skeleton";

export default function InstructorDashboardLoading() {
  return (
    <DashboardLayout>
      <div className="mx-auto max-w-7xl space-y-7" aria-label="Loading Instructor overview">
        <div className="space-y-3 border-b border-border pb-5">
          <Skeleton className="h-8 w-64 max-w-full" />
          <Skeleton className="h-4 w-full max-w-3xl" />
        </div>
        <MetricStrip loading ariaLabel="Loading Instructor overview metrics" />
        <div className="grid gap-6 lg:grid-cols-[minmax(0,0.8fr)_minmax(0,1.2fr)]">
          <Skeleton className="h-[360px] rounded-xl" />
          <Skeleton className="h-[360px] rounded-xl" />
        </div>
      </div>
    </DashboardLayout>
  );
}
