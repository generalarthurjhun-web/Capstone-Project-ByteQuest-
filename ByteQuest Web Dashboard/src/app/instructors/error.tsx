"use client";

import { DashboardPageError } from "@/components/dashboard/DashboardPageError";

export default function InstructorsError({ reset }: { reset: () => void }) { return <DashboardPageError title="Unable to load Instructors" description="The Instructor directory request did not complete. No account data was changed." reset={reset} />; }
