"use client";

import { AlertTriangle } from "lucide-react";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { Button } from "@/components/ui/button";

export function DashboardPageError({
  title,
  description,
  reset,
}: {
  title: string;
  description: string;
  reset: () => void;
}) {
  return (
    <DashboardLayout>
      <div className="mx-auto flex min-h-[55vh] max-w-xl items-center justify-center px-4">
        <section
          role="alert"
          className="w-full rounded-xl border border-destructive/25 bg-card p-7 text-center"
        >
          <span className="mx-auto flex h-11 w-11 items-center justify-center rounded-lg bg-red-50 text-destructive ring-1 ring-red-100">
            <AlertTriangle className="h-5 w-5" aria-hidden={true} />
          </span>
          <h1 className="mt-4 text-lg font-semibold text-foreground">{title}</h1>
          <p className="mt-2 text-sm leading-6 text-muted-foreground">{description}</p>
          <Button type="button" onClick={reset} className="mt-5">
            Try again
          </Button>
        </section>
      </div>
    </DashboardLayout>
  );
}
