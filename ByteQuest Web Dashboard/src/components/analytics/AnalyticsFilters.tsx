"use client";

import { useTransition } from "react";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { Filter, RotateCcw } from "lucide-react";
import { Button } from "@/components/ui/button";
import { dateInputValue } from "@/lib/analytics/date";
import type { AnalyticsFilters, InstructorAnalytics } from "@/lib/analytics/types";

type FilterOptions = InstructorAnalytics["filters"];

export function AnalyticsFilters({
  filters,
  options,
}: {
  filters: AnalyticsFilters;
  options: FilterOptions;
}) {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const [pending, startTransition] = useTransition();

  function submit(formData: FormData) {
    const next = new URLSearchParams(searchParams.toString());
    for (const key of ["class", "coc", "mission", "range", "from", "to"]) {
      const value = formData.get(key)?.toString().trim();
      if (value) next.set(key, value);
      else next.delete(key);
    }
    if (formData.get("range") !== "custom") {
      next.delete("from");
      next.delete("to");
    }
    next.delete("criterion");
    startTransition(() => router.push(`${pathname}?${next.toString()}`));
  }

  function clearFilters() {
    startTransition(() => router.push(`${pathname}?range=30`));
  }

  return (
    <form
      action={submit}
      className="print-hidden rounded-xl border border-border/85 bg-card p-4 shadow-xs"
      aria-label="Analytics filters"
      aria-busy={pending}
    >
      <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-[minmax(170px,1fr)_minmax(160px,0.8fr)_minmax(190px,1fr)_140px_auto] xl:items-end">
        <FilterField label="Class" name="class" defaultValue={filters.classId ?? ""}>
          <option value="">All owned classes</option>
          {options.classes.map((classroom) => (
            <option key={classroom.id} value={classroom.id}>{classroom.title}</option>
          ))}
        </FilterField>
        <FilterField label="COC" name="coc" defaultValue={filters.cocId ?? ""}>
          <option value="">All COCs</option>
          {options.cocs.map((coc) => (
            <option key={coc.id} value={coc.id}>{coc.code}</option>
          ))}
        </FilterField>
        <FilterField label="Mission" name="mission" defaultValue={filters.missionId ?? ""}>
          <option value="">All missions</option>
          {options.missions.map((mission) => (
            <option key={mission.id} value={mission.id}>{mission.code} · {mission.title}</option>
          ))}
        </FilterField>
        <FilterField label="Period" name="range" defaultValue={filters.range}>
          <option value="7">Last 7 days</option>
          <option value="30">Last 30 days</option>
          <option value="90">Last 90 days</option>
          <option value="custom">Custom range</option>
        </FilterField>
        <div className="flex items-center gap-2 md:col-span-2 xl:col-span-1">
          <Button type="submit" disabled={pending} className="min-w-24 flex-1 xl:flex-none">
            <Filter className="mr-2 h-4 w-4" aria-hidden="true" />
            {pending ? "Applying…" : "Apply"}
          </Button>
          <Button type="button" variant="ghost" size="icon" onClick={clearFilters} disabled={pending} aria-label="Clear analytics filters">
            <RotateCcw className="h-4 w-4" aria-hidden="true" />
          </Button>
        </div>
      </div>
      <p className="sr-only" aria-live="polite">{pending ? "Applying analytics filters" : "Analytics filters ready"}</p>
      {filters.range === "custom" ? (
        <div className="mt-3 grid gap-3 border-t border-border/70 pt-3 sm:grid-cols-2 xl:max-w-xl">
          <label className="grid gap-1.5 text-xs font-medium text-foreground">
            From
            <input name="from" type="date" defaultValue={dateInputValue(filters.from)} className="h-10 rounded-lg border border-input bg-background px-3 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring" />
          </label>
          <label className="grid gap-1.5 text-xs font-medium text-foreground">
            To
            <input name="to" type="date" defaultValue={dateInputValue(filters.to)} className="h-10 rounded-lg border border-input bg-background px-3 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring" />
          </label>
        </div>
      ) : null}
    </form>
  );
}

function FilterField({
  label,
  name,
  defaultValue,
  children,
}: {
  label: string;
  name: string;
  defaultValue: string;
  children: React.ReactNode;
}) {
  return (
    <label className="grid min-w-0 gap-1.5 text-xs font-medium text-foreground">
      {label}
      <select
        name={name}
        defaultValue={defaultValue}
        className="h-10 min-w-0 rounded-lg border border-input bg-card px-3 text-sm font-normal text-foreground shadow-xs transition-[border-color,box-shadow] duration-150 hover:border-primary/40 focus-visible:border-primary/50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring/25"
      >
        {children}
      </select>
    </label>
  );
}
