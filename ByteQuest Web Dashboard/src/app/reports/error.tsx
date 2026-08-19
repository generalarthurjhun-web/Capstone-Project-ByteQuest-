"use client";

import { AlertTriangle } from "lucide-react";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { Button } from "@/components/ui/button";

export default function ReportsError({ reset }: { error: Error & { digest?: string }; reset: () => void }) {
  return (
    <DashboardLayout>
      <div className="mx-auto flex min-h-[55vh] max-w-xl items-center justify-center">
        <div role="alert" className="w-full rounded-xl border border-destructive/25 bg-card p-7 text-center">
          <AlertTriangle className="mx-auto h-7 w-7 text-destructive" aria-hidden="true" />
          <h1 className="mt-4 text-lg font-semibold">Unable to prepare this report</h1>
          <p className="mt-2 text-sm leading-6 text-muted-foreground">The scoped report query failed safely. Change the filters or retry; no assessment record was modified.</p>
          <Button type="button" onClick={reset} className="mt-5">Retry report</Button>
        </div>
      </div>
    </DashboardLayout>
  );
}
