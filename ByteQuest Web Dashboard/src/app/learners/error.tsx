"use client";

import { DashboardPageError } from "@/components/dashboard/DashboardPageError";

export default function LearnersError({ reset }: { reset: () => void }) { return <DashboardPageError title="Unable to load Learners" description="The learner directory request did not complete. No account data was changed." reset={reset} />; }
