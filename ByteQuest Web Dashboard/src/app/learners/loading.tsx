import { Skeleton } from "@/components/ui/skeleton";

export default function LearnersLoading() { return <div className="space-y-6" role="status" aria-label="Loading Learners"><Skeleton className="h-8 w-56" /><Skeleton className="h-4 w-full max-w-2xl" /><Skeleton className="h-56 w-full rounded-2xl" /></div>; }
