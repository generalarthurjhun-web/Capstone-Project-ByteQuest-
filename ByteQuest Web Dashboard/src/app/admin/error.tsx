"use client";

import { DashboardPageError } from "@/components/dashboard/DashboardPageError";

export default function AdminError({ reset }: { reset: () => void }) {
  return <DashboardPageError title="Unable to load Admin workspace" description="The governance request did not complete. No account, access, resource, or audit record was changed." reset={reset} />;
}
