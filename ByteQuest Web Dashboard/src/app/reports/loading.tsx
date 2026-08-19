import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { Skeleton } from "@/components/ui/skeleton";

export default function ReportsLoading() {
  return <DashboardLayout><div className="mx-auto max-w-[1500px] space-y-6"><div className="space-y-2 border-b border-border pb-5"><Skeleton className="h-8 w-40" /><Skeleton className="h-4 w-full max-w-3xl" /></div><div className="grid gap-4 xl:grid-cols-[minmax(260px,0.6fr)_minmax(0,1.4fr)]"><Skeleton className="h-28 rounded-xl" /><Skeleton className="h-28 rounded-xl" /></div><Skeleton className="h-[520px] rounded-xl" /></div></DashboardLayout>;
}

