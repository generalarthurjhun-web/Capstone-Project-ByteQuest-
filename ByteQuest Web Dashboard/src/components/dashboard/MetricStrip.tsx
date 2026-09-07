import React, { type ComponentType } from "react";
import Link from "next/link";
import { AlertTriangle, ArrowUpRight } from "lucide-react";
import { cn } from "@/lib/utils";

type MetricIcon = ComponentType<{
  className?: string;
  "aria-hidden"?: boolean;
}>;

export type MetricTone = "informational" | "positive" | "attention" | "neutral";

export type Metric = {
  label: string;
  value: number | string;
  helper?: string;
  icon: MetricIcon;
  featured?: boolean;
  tone?: MetricTone;
  href?: string;
  linkLabel?: string;
  trend?: {
    label: string;
    tone?: Exclude<MetricTone, "informational">;
  };
};

type MetricStripProps = {
  metrics?: Metric[];
  ariaLabel?: string;
  loading?: boolean;
  error?: boolean;
};

const toneStyles: Record<MetricTone, string> = {
  informational: "bg-blue-50/85 text-blue-700 ring-blue-100/90",
  positive: "bg-emerald-50/90 text-emerald-700 ring-emerald-100/90",
  attention: "bg-amber-50/90 text-amber-800 ring-amber-100/90",
  neutral: "bg-slate-100/90 text-slate-600 ring-slate-200/80",
};

const trendStyles: Record<Exclude<MetricTone, "informational">, string> = {
  positive: "text-emerald-700",
  attention: "text-amber-800",
  neutral: "text-muted-foreground",
};

export function MetricStrip({
  metrics = [],
  ariaLabel = "Summary metrics",
  loading = false,
  error = false,
}: MetricStripProps) {
  if (loading) {
    return <MetricStripSkeleton ariaLabel={ariaLabel} count={metrics.length || 4} />;
  }

  if (error) {
    return (
      <section
        role="alert"
        aria-label={ariaLabel}
        className="flex min-h-36 items-start gap-3 rounded-xl border border-destructive/25 bg-card p-5"
      >
        <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-red-50 text-destructive ring-1 ring-red-100">
          <AlertTriangle className="h-[18px] w-[18px]" aria-hidden={true} />
        </span>
        <div>
          <p className="text-sm font-semibold text-foreground">Summary metrics are unavailable</p>
          <p className="mt-1 text-sm leading-6 text-muted-foreground">
            Refresh the page to try again. No account or assessment data was changed.
          </p>
        </div>
      </section>
    );
  }

  return (
    <section
      aria-label={ariaLabel}
      className="grid grid-cols-1 gap-3.5 sm:grid-cols-2 sm:gap-4 xl:grid-cols-4"
    >
      {metrics.map((metric) => (
        <MetricCard key={metric.label} metric={metric} />
      ))}
    </section>
  );
}

function MetricCard({ metric }: { metric: Metric }) {
  const Icon = metric.icon;
  const tone = metric.tone ?? "informational";
  const cardClassName = cn(
    "group relative flex min-h-[142px] min-w-0 flex-col overflow-hidden rounded-2xl border bg-card p-4 shadow-card sm:p-[18px]",
    metric.featured
      ? "border-primary bg-primary text-primary-foreground"
      : "border-border/75 text-foreground",
    metric.href &&
      "cursor-pointer transition-[border-color,box-shadow,background-color,transform] duration-200 ease-out hover:-translate-y-0.5 hover:shadow-card-hover focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 motion-reduce:transform-none motion-reduce:transition-none",
    metric.href &&
      (metric.featured
        ? "hover:border-primary hover:bg-primary/90"
        : "hover:border-primary/30 hover:bg-card"),
  );

  const content = (
    <>
      <div className="flex items-start justify-between gap-4">
        <p
          className={cn(
            "min-w-0 text-[12px] font-semibold leading-5 tracking-[0.01em]",
            metric.featured ? "text-primary-foreground/80" : "text-muted-foreground",
          )}
        >
          {metric.label}
        </p>
        <span
          className={cn(
            "flex h-8 w-8 shrink-0 items-center justify-center rounded-lg ring-1",
            metric.featured
              ? "bg-primary-foreground/10 text-primary-foreground ring-primary-foreground/20"
              : toneStyles[tone],
          )}
        >
          <Icon className="h-4 w-4" aria-hidden={true} />
        </span>
      </div>

      <p
        className={cn(
          "mt-4 break-words text-[clamp(1.5rem,2.5vw,1.75rem)] font-bold leading-none tabular-nums tracking-[-0.035em]",
          metric.featured ? "text-primary-foreground" : "text-foreground",
        )}
      >
        {metric.value}
      </p>

      <div className="mt-auto flex min-h-8 items-end justify-between gap-3 pt-2.5">
        <div className="min-w-0">
          {metric.helper ? (
            <p
              className={cn(
                "line-clamp-2 text-[11px] leading-5",
                metric.featured
                  ? "text-primary-foreground/75"
                  : "text-muted-foreground",
              )}
            >
              {metric.helper}
            </p>
          ) : null}
          {metric.trend ? (
            <p
              className={cn(
                "mt-1 text-[11px] font-semibold leading-5",
                trendStyles[metric.trend.tone ?? "neutral"],
              )}
            >
              {metric.trend.label}
            </p>
          ) : null}
        </div>
        {metric.href ? (
          <span
            className={cn(
              metric.featured
                ? "flex h-7 w-7 shrink-0 items-center justify-center rounded-lg text-primary-foreground opacity-70 transition-[opacity,background-color] duration-200 group-hover:bg-primary-foreground/10 group-hover:opacity-100 group-focus-visible:bg-primary-foreground/10 group-focus-visible:opacity-100 motion-reduce:transition-none"
                : "flex h-7 w-7 shrink-0 items-center justify-center rounded-lg text-primary opacity-35 transition-[opacity,background-color] duration-200 group-hover:bg-primary/[0.07] group-hover:opacity-100 group-focus-visible:bg-primary/[0.07] group-focus-visible:opacity-100 motion-reduce:transition-none",
            )}
          >
            <ArrowUpRight className="h-4 w-4" aria-hidden={true} />
            <span className="sr-only">
              {metric.linkLabel ?? `Open ${metric.label.toLowerCase()}`}
            </span>
          </span>
        ) : null}
      </div>
    </>
  );

  if (metric.href) {
    return (
      <Link href={metric.href} className={cardClassName}>
        {content}
      </Link>
    );
  }

  return <article className={cardClassName}>{content}</article>;
}

export function MetricStripSkeleton({
  count = 4,
  ariaLabel = "Loading summary metrics",
}: {
  count?: number;
  ariaLabel?: string;
}) {
  return (
    <section
      role="status"
      aria-label={ariaLabel}
      className="grid grid-cols-1 gap-3.5 sm:grid-cols-2 sm:gap-4 xl:grid-cols-4"
    >
      <span className="sr-only">Loading summary metrics</span>
      {Array.from({ length: count }, (_, index) => (
        <div
          key={index}
          aria-hidden="true"
          className="flex min-h-[132px] flex-col rounded-2xl border border-border/70 bg-card p-4 shadow-card sm:min-h-[142px] sm:p-[18px]"
        >
          <div className="flex items-start justify-between gap-4">
            <div className="h-4 w-28 animate-pulse rounded-md bg-muted" />
            <div className="h-8 w-8 animate-pulse rounded-lg bg-muted" />
          </div>
          <div className="mt-3 h-8 w-20 animate-pulse rounded-md bg-muted" />
          <div className="mt-auto h-4 w-36 animate-pulse rounded-md bg-muted" />
        </div>
      ))}
    </section>
  );
}
