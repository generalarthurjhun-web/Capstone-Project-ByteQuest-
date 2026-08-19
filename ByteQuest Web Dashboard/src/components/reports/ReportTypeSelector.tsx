"use client";

import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { useTransition } from "react";
import { FileSearch } from "lucide-react";
import { Button } from "@/components/ui/button";
import { REPORT_OPTIONS } from "@/lib/analytics/reports";
import type { ReportType } from "@/lib/analytics/types";

export function ReportTypeSelector({ reportType }: { reportType: ReportType }) {
  const pathname = usePathname();
  const router = useRouter();
  const searchParams = useSearchParams();
  const [pending, startTransition] = useTransition();

  function submit(formData: FormData) {
    const next = new URLSearchParams(searchParams.toString());
    next.set("type", String(formData.get("type") ?? "class_performance"));
    startTransition(() => router.push(`${pathname}?${next.toString()}#report-preview`));
  }

  return (
    <form action={submit} className="print-hidden rounded-xl border border-border/85 bg-card p-4 shadow-xs" aria-busy={pending}>
      <div className="grid gap-3 sm:grid-cols-[minmax(0,1fr)_auto] sm:items-end">
        <label className="grid gap-1.5 text-xs font-medium text-foreground">
          Report type
          <select name="type" defaultValue={reportType} className="h-10 rounded-lg border border-input bg-card px-3 text-sm font-normal shadow-xs transition-colors hover:border-primary/40 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring/25">
            {REPORT_OPTIONS.map((option) => <option key={option.value} value={option.value}>{option.label}</option>)}
          </select>
        </label>
        <Button type="submit" variant="outline" disabled={pending}><FileSearch className="mr-2 h-4 w-4" aria-hidden="true" />{pending ? "Preparing…" : "Preview report"}</Button>
      </div>
      <p className="mt-2 text-xs text-muted-foreground">{REPORT_OPTIONS.find((option) => option.value === reportType)?.description}</p>
    </form>
  );
}
