"use client";

import { DashboardPageError } from "@/components/dashboard/DashboardPageError";

export default function InstructorDashboardError({ reset }: { reset: () => void }) {
  return (
    <DashboardPageError
      title="Unable to load the Instructor overview"
      description="The scoped dashboard request did not complete. Your classes, assessments, and learner records were not changed."
      reset={reset}
    />
  );
}
