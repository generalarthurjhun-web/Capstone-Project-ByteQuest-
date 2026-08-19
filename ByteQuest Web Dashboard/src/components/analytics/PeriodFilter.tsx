"use client";

import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { useTransition } from "react";
import { CalendarRange } from "lucide-react";
import { Button } from "@/components/ui/button";
import type { AnalyticsFilters } from "@/lib/analytics/types";

export function PeriodFilter({ range }: Pick<AnalyticsFilters, "range">) {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const [pending, startTransition] = useTransition();
  function submit(formData: FormData) {
    const next = new URLSearchParams(searchParams.toString());
    next.set("range", String(formData.get("range") ?? "30"));
    startTransition(() => router.push(`${pathname}?${next.toString()}`));
  }
  return <form action={submit} className="flex items-end gap-2 print-hidden"><label className="grid gap-1.5 text-xs font-medium">Period<select name="range" defaultValue={range} className="h-10 min-w-36 rounded-lg border border-input bg-background px-3 text-sm font-normal focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"><option value="7">Last 7 days</option><option value="30">Last 30 days</option><option value="90">Last 90 days</option></select></label><Button type="submit" variant="outline" disabled={pending}><CalendarRange className="mr-2 h-4 w-4" aria-hidden="true" />{pending ? "Applying…" : "Apply"}</Button></form>;
}

