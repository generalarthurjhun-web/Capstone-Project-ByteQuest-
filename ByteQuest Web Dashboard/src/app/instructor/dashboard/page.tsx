import Link from "next/link";
import { ArrowRight, CheckCircle2, ClipboardCheck, GraduationCap, Users } from "lucide-react";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { MetricStrip, type Metric } from "@/components/dashboard/MetricStrip";
import { PageHeader } from "@/components/dashboard/PageHeader";
import { InstructorOverviewPanels } from "@/components/dashboard/InstructorOverviewPanels";
import { Button } from "@/components/ui/button";
import { requireStaffProfile } from "@/lib/auth/server";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

export default async function InstructorDashboardPage() {
  const profile = await requireStaffProfile(["instructor"]);
  const supabase = await createServerSupabaseClient();

  const [classes, memberships, attempts, pendingAttemptCount, releasedAttemptCount, assignments, revisions] = await Promise.all([
    supabase
      .from("classes")
      .select("id,title,class_code,status,created_at")
      .order("created_at", { ascending: false }),
    supabase
      .from("class_memberships")
      .select("id,status,learner_id,class_id")
      .eq("status", "active"),
    supabase
      .from("attempts")
      .select("id,status,class_id,assignment_id,learner_id,submitted_at,created_at")
      .order("created_at", { ascending: false })
      .limit(8),
    supabase
      .from("attempts")
      .select("id", { count: "exact", head: true })
      .in("status", ["evaluated", "under_review"]),
    supabase
      .from("attempts")
      .select("id", { count: "exact", head: true })
      .eq("status", "released"),
    supabase
      .from("assignments")
      .select("id,class_id,title,assignment_type,status,due_at")
      .order("due_at", { ascending: true, nullsFirst: false }),
    supabase
      .from("score_revisions")
      .select("attempt_id,percentage,outcome")
      .eq("revision_type", "instructor_final"),
  ]);

  if (
    classes.error ||
    memberships.error ||
    attempts.error ||
    pendingAttemptCount.error ||
    releasedAttemptCount.error ||
    assignments.error ||
    revisions.error
  ) {
    throw new Error("The Instructor dashboard summary could not be loaded.");
  }

  const classRows = classes.data ?? [];
  const membershipRows = memberships.data ?? [];
  const attemptRows = attempts.data ?? [];
  const pendingReviews = pendingAttemptCount.count ?? 0;

  const learnerIds = [...new Set(attemptRows.map((attempt) => attempt.learner_id))];
  const { data: learners, error: learnersError } = learnerIds.length
    ? await supabase
        .from("profiles")
        .select("user_id,full_name")
        .in("user_id", learnerIds)
    : { data: [], error: null };
  if (learnersError) {
    throw new Error("Recent learner details could not be loaded.");
  }
  const learnerNames = new Map(
    (learners ?? []).map((learner) => [learner.user_id, learner.full_name]),
  );

  const metrics: Metric[] = [
    {
      label: "Active learners",
      value: membershipRows.length,
      helper: "Current active class memberships",
      icon: Users,
      featured: true,
      href: "/progress",
      linkLabel: "Open learner monitoring",
    },
    {
      label: "Awaiting review",
      value: pendingReviews,
      helper: pendingReviews ? "Open submitted evidence queue" : "No evaluated attempt needs review",
      icon: ClipboardCheck,
      tone: pendingReviews ? "attention" : "neutral",
      href: "/attempts",
      linkLabel: "Open assessment review queue",
    },
    {
      label: "Released results",
      value: releasedAttemptCount.count ?? 0,
      helper: "Instructor-final results released",
      icon: CheckCircle2,
      tone: "positive",
      href: "/reports?type=released_results",
      linkLabel: "Open released results report",
    },
    {
      label: "Active classes",
      value: classRows.filter((row) => row.status === "active").length,
      helper: "Classes currently open for teaching",
      icon: GraduationCap,
      href: "/classes",
      linkLabel: "Open active classes",
    },
  ];

  return (
    <DashboardLayout>
      <div className="mx-auto max-w-7xl space-y-7">
        <PageHeader title={`Welcome, ${profile.fullName}`} description="Review what needs attention, then move into your classes and evidence workflow without losing Instructor scope." actions={<><Button asChild variant="outline"><Link href="/analytics">Open analytics</Link></Button><Button asChild><Link href="/classes">Manage classes</Link></Button></>} />

        <MetricStrip metrics={metrics} ariaLabel="Instructor overview metrics" />

        {pendingReviews > 0 ? (
          <section className="flex flex-col gap-3 rounded-xl border border-amber-200 bg-amber-50 px-5 py-4 text-amber-950 shadow-xs sm:flex-row sm:items-center sm:justify-between">
            <div className="flex items-start gap-3">
              <span className="mt-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-amber-100">
                <ClipboardCheck className="h-4 w-4" aria-hidden="true" />
              </span>
              <div>
                <h2 className="text-sm font-semibold">{pendingReviews} assessment{pendingReviews === 1 ? "" : "s"} waiting for review</h2>
                <p className="mt-1 text-xs leading-5 text-amber-900">Review ordered evidence before finalization and release.</p>
              </div>
            </div>
            <Button asChild variant="outline" size="sm" className="border-amber-300 bg-white text-amber-950 hover:bg-amber-100">
              <Link href="/attempts">Open review queue <ArrowRight className="ml-1 h-4 w-4" aria-hidden="true" /></Link>
            </Button>
          </section>
        ) : null}

        <InstructorOverviewPanels
          classes={classRows}
          assignments={assignments.data ?? []}
          reviewRows={attemptRows.filter((attempt) => attempt.status === "evaluated" || attempt.status === "under_review")}
          recentAttempts={attemptRows}
          learnerNames={learnerNames}
          revisions={revisions.data ?? []}
        />

      </div>
    </DashboardLayout>
  );
}
