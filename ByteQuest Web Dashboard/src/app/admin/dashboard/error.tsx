"use client";

import { DashboardPageError } from "@/components/dashboard/DashboardPageError";

export default function AdminDashboardError({ reset }: { reset: () => void }) {
  return (
    <DashboardPageError
      title="Unable to load system administration"
      description="The system summary request did not complete. No account, access, TESDA source, or audit record was changed."
      reset={reset}
    />
  );
}
