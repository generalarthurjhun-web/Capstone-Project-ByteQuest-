import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { MetricStrip } from "@/components/dashboard/MetricStrip";
import { Skeleton } from "@/components/ui/skeleton";

export default function AnalyticsLoading() {
  return (
    <DashboardLayout>
      <div className="mx-auto max-w-[1500px] space-y-7" aria-label="Loading analytics">
        <div className="space-y-2 border-b border-border pb-5"><Skeleton className="h-8 w-48" /><Skeleton className="h-4 w-full max-w-3xl" /></div>
        <Skeleton className="h-28 w-full rounded-xl" />
        <MetricStrip loading ariaLabel="Loading filtered Instructor analytics metrics" />
        <div className="grid gap-6 xl:grid-cols-[minmax(0,1.55fr)_minmax(330px,0.75fr)]"><Skeleton className="h-[390px] rounded-xl" /><Skeleton className="h-[390px] rounded-xl" /></div>
        <Skeleton className="h-[390px] rounded-xl" />
      </div>
    </DashboardLayout>
  );
}
