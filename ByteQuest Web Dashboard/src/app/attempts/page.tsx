import Link from "next/link";
import { Activity, CheckCircle2, ClipboardCheck, Clock3 } from "lucide-react";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { MetricStrip, type Metric } from "@/components/dashboard/MetricStrip";
import { PageHeader } from "@/components/dashboard/PageHeader";
import { Badge } from "@/components/ui/badge";
import { requireStaffProfile } from "@/lib/auth/server";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

function formatTimestamp(value: string | null) {
  if (!value) return "Not submitted";
  return new Intl.DateTimeFormat("en-PH", {
    dateStyle: "medium",
    timeStyle: "short",
    timeZone: "Asia/Manila",
  }).format(new Date(value));
}

export default async function AttemptsPage() {
  await requireStaffProfile(["instructor"]);
  const supabase = await createServerSupabaseClient();
  const { data: attempts } = await supabase
    .from("attempts")
    .select("id,learner_id,class_id,assignment_id,status,started_at,submitted_at,released_at")
    .order("started_at", { ascending: false });

  const rows = attempts ?? [];
  const learnerIds = [...new Set(rows.map((row) => row.learner_id))];
  const classIds = [...new Set(rows.map((row) => row.class_id))];
  const assignmentIds = [...new Set(rows.map((row) => row.assignment_id))];
  const [profiles, classes, assignments] = await Promise.all([
    learnerIds.length
      ? supabase.from("profiles").select("user_id,full_name,email").in("user_id", learnerIds)
      : Promise.resolve({ data: [] }),
    classIds.length
      ? supabase.from("classes").select("id,title").in("id", classIds)
      : Promise.resolve({ data: [] }),
    assignmentIds.length
      ? supabase.from("assignments").select("id,title,assignment_type").in("id", assignmentIds)
      : Promise.resolve({ data: [] }),
  ]);
  const profileById = new Map((profiles.data ?? []).map((row) => [row.user_id, row]));
  const classById = new Map((classes.data ?? []).map((row) => [row.id, row]));
  const assignmentById = new Map((assignments.data ?? []).map((row) => [row.id, row]));
  const pendingCount = rows.filter((row) => row.status === "evaluated" || row.status === "under_review").length;
  const releasedCount = rows.filter((row) => row.status === "released").length;
  const activeCount = rows.filter((row) => !row.submitted_at).length;
  const metrics: Metric[] = [
    { label: "Awaiting review", value: pendingCount, helper: pendingCount ? "Evaluated submissions need your decision" : "Review queue is clear", icon: ClipboardCheck, tone: pendingCount ? "attention" : "neutral", href: "#attempt-list", linkLabel: "View attempts awaiting review", featured: pendingCount > 0 },
    { label: "Released results", value: releasedCount, helper: "Instructor-final results visible to learners", icon: CheckCircle2, tone: "positive", href: "#attempt-list", linkLabel: "View released attempts" },
    { label: "Active attempts", value: activeCount, helper: "Learner work not yet submitted", icon: Activity, tone: "informational", href: "#attempt-list", linkLabel: "View active attempts" },
    { label: "Total attempts", value: rows.length, helper: "Authoritative attempts in your scope", icon: Clock3, tone: "neutral", href: "#attempt-list", linkLabel: "View all attempts" },
  ];

  return (
    <DashboardLayout>
      <div className="mx-auto max-w-7xl space-y-7">
        <PageHeader title="Attempt review" description="Review chronological evidence and criterion-level evaluation for learners in your classes." />
        <MetricStrip metrics={metrics} ariaLabel="Attempt review metrics" />
        <section id="attempt-list" className="overflow-hidden rounded-xl border border-border bg-card">
          {rows.length ? (
            <div className="divide-y divide-border">
              {rows.map((attempt) => {
                const learner = profileById.get(attempt.learner_id);
                const classroom = classById.get(attempt.class_id);
                const assignment = assignmentById.get(attempt.assignment_id);
                const needsReview = attempt.status === "evaluated" || attempt.status === "under_review";
                return (
                  <Link key={attempt.id} href={`/attempts/${attempt.id}`} className="grid gap-3 px-5 py-4 transition-colors hover:bg-muted/35 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring md:grid-cols-[minmax(0,1fr)_minmax(0,0.8fr)_auto] md:items-center">
                    <div className="min-w-0"><p className="truncate text-sm font-medium">{learner?.full_name ?? "Learner"}</p><p className="mt-0.5 truncate text-xs text-muted-foreground">{learner?.email ?? "Email unavailable"} · {classroom?.title ?? "Class"}</p></div>
                    <div className="min-w-0"><p className="truncate text-sm">{assignment?.title ?? "Versioned assignment"}</p><p className="mt-0.5 text-xs text-muted-foreground">{formatTimestamp(attempt.submitted_at)}</p></div>
                    <Badge variant={needsReview ? "default" : attempt.status === "released" ? "secondary" : "outline"}>{attempt.status.replaceAll("_", " ")}</Badge>
                  </Link>
                );
              })}
            </div>
          ) : (
            <div className="px-5 py-16 text-center"><ClipboardCheck className="mx-auto h-7 w-7 text-muted-foreground" aria-hidden="true" /><p className="mt-3 text-sm font-medium">No authoritative attempts yet.</p><p className="mt-1 text-sm text-muted-foreground">The queue will populate after approved content is assigned and submitted from mobile.</p></div>
          )}
        </section>
      </div>
    </DashboardLayout>
  );
}
