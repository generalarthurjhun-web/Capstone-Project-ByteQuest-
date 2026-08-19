"use client";

import { DashboardPageError } from "@/components/dashboard/DashboardPageError";

export default function ResourcesError({ reset }: { reset: () => void }) {
  return (
    <DashboardPageError
      title="Unable to load learning resources"
      description="The private resource request did not complete. No file, class association, or learner authorization was changed."
      reset={reset}
    />
  );
}
