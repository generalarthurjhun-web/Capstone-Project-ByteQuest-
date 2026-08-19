import Link from "next/link";
import {
  ArrowUpRight,
  CalendarClock,
  CheckCircle2,
  ClipboardCheck,
  GraduationCap,
  Users,
} from "lucide-react";
import type { LucideIcon } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { SectionHeading } from "@/components/dashboard/SectionHeading";

type ClassRow = { id: string; title: string; class_code: string | null; status: string };
type AssignmentRow = { id: string; class_id: string; title: string; assignment_type: string; status: string; due_at: string | null };
type ReviewRow = { id: string; class_id: string; assignment_id: string; learner_id: string; status: string; submitted_at: string | null };
type AttemptRow = { id: string; class_id: string; assignment_id: string; learner_id: string; status: string; submitted_at: string | null; created_at: string };
type RevisionRow = { attempt_id: string; percentage: number | null; outcome: string };

function formatDate(value: string | null) {
  if (!value) return "No due date";
  return new Intl.DateTimeFormat("en-PH", { dateStyle: "medium", timeZone: "Asia/Manila" }).format(new Date(value));
}

function formatRelative(value: string | null) {
  if (!value) return "Not submitted";
  return new Intl.DateTimeFormat("en-PH", { dateStyle: "medium", timeStyle: "short", timeZone: "Asia/Manila" }).format(new Date(value));
}

function statusVariant(status: string): "default" | "secondary" | "outline" | "destructive" {
  if (status === "released") return "secondary";
  if (status === "evaluated" || status === "under_review") return "default";
  if (status === "failed" || status === "not_yet_competent") return "destructive";
  return "outline";
}

export function InstructorOverviewPanels({
  classes,
  assignments,
  reviewRows,
  recentAttempts,
  learnerNames,
  revisions,
}: {
  classes: ClassRow[];
  assignments: AssignmentRow[];
  reviewRows: ReviewRow[];
  recentAttempts: AttemptRow[];
  learnerNames: Map<string, string>;
  revisions: RevisionRow[];
}) {
  const classNames = new Map(classes.map((row) => [row.id, row.title]));
  const assignmentNames = new Map(assignments.map((row) => [row.id, row.title]));
  const activeAssignments = assignments.filter((row) => row.status === "active");
  const upcoming = activeAssignments
    .filter((row) => row.due_at && new Date(row.due_at).getTime() >= Date.now())
    .sort((a, b) => new Date(a.due_at ?? 0).getTime() - new Date(b.due_at ?? 0).getTime())
    .slice(0, 5);
  const revisionByAttempt = new Map(revisions.map((row) => [row.attempt_id, row]));
  const classAssignmentCounts = new Map<string, number>();
  activeAssignments.forEach((row) => classAssignmentCounts.set(row.class_id, (classAssignmentCounts.get(row.class_id) ?? 0) + 1));
  const maxAssignments = Math.max(1, ...classAssignmentCounts.values());

  return (
    <div className="grid gap-5 xl:grid-cols-[minmax(0,1.05fr)_minmax(0,1fr)_minmax(0,1.35fr)]">
      <section className="overflow-hidden rounded-2xl border border-border/75 bg-card shadow-card">
        <SectionHeading title="Pending review queue" description="Submitted evidence that still needs your review." action={<Button asChild variant="ghost" size="sm"><Link href="/attempts">View all <ArrowUpRight className="ml-1 h-3.5 w-3.5" aria-hidden="true" /></Link></Button>} />
        {reviewRows.length ? <div className="divide-y divide-border/70">{reviewRows.slice(0, 5).map((row) => <Link key={row.id} href={`/attempts/${row.id}`} className="flex items-center gap-3 px-5 py-3.5 transition-colors hover:bg-muted/30 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-inset"><span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-amber-50 text-amber-800 ring-1 ring-amber-100"><ClipboardCheck className="h-4 w-4" aria-hidden="true" /></span><span className="min-w-0 flex-1"><span className="block truncate text-sm font-semibold">{assignmentNames.get(row.assignment_id) ?? "Versioned assignment"}</span><span className="mt-0.5 block truncate text-[11px] text-muted-foreground">{learnerNames.get(row.learner_id) ?? "Learner"} · {classNames.get(row.class_id) ?? "Class"}</span></span><Badge variant={statusVariant(row.status)}>{row.status.replaceAll("_", " ")}</Badge></Link>)}</div> : <Empty title="Review queue is clear" text="No evaluated or under-review attempt is waiting for your decision." icon={CheckCircle2} />}
        <div className="border-t border-border/70 px-5 py-3 text-xs text-muted-foreground">{reviewRows.length} item{reviewRows.length === 1 ? "" : "s"} in the current queue</div>
      </section>

      <section className="overflow-hidden rounded-2xl border border-border/75 bg-card shadow-card">
        <SectionHeading title="Owned classes" description="Your active teaching boundaries and assigned content." action={<Button asChild variant="ghost" size="sm"><Link href="/classes">View all <ArrowUpRight className="ml-1 h-3.5 w-3.5" aria-hidden="true" /></Link></Button>} />
        {classes.length ? <div className="divide-y divide-border/70">{classes.filter((row) => row.status === "active").slice(0, 6).map((row) => { const assignmentsCount = classAssignmentCounts.get(row.id) ?? 0; return <Link key={row.id} href={`/classes/${row.id}`} className="block px-5 py-3.5 transition-colors hover:bg-muted/30 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-inset"><div className="flex items-center justify-between gap-3"><span className="flex min-w-0 items-center gap-2"><span className="h-2 w-2 shrink-0 rounded-full bg-primary" aria-hidden="true" /><span className="truncate text-sm font-semibold">{row.title}</span></span><span className="shrink-0 text-xs text-muted-foreground">{assignmentsCount} assigned</span></div><div className="mt-2 h-1.5 overflow-hidden rounded-full bg-muted"><div className="h-full rounded-full bg-primary" style={{ width: `${Math.round((assignmentsCount / maxAssignments) * 100)}%` }} aria-label={`${assignmentsCount} active assignments`} /></div></Link>; })}</div> : <Empty title="No classes yet" text="Create a class to establish an enrollment and assessment boundary." icon={GraduationCap} />}
        <div className="flex items-center justify-between border-t border-border/70 px-5 py-3 text-xs"><span className="text-muted-foreground">Active assignments</span><span className="font-bold tabular-nums">{activeAssignments.length}</span></div>
      </section>

      <div className="grid gap-5">
        <section className="overflow-hidden rounded-2xl border border-border/75 bg-card shadow-card">
          <SectionHeading title="Recent learner attempts" description="Latest scoped activity from your classes." action={<Button asChild variant="ghost" size="sm"><Link href="/attempts">Review queue <ArrowUpRight className="ml-1 h-3.5 w-3.5" aria-hidden="true" /></Link></Button>} />
          {recentAttempts.length ? <div className="divide-y divide-border/70">{recentAttempts.slice(0, 5).map((attempt) => { const revision = revisionByAttempt.get(attempt.id); return <Link key={attempt.id} href={`/attempts/${attempt.id}`} className="grid gap-2 px-5 py-3 text-xs transition-colors hover:bg-muted/30 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-inset sm:grid-cols-[minmax(0,1fr)_minmax(0,1fr)_auto_auto] sm:items-center"><span className="min-w-0"><span className="block truncate text-sm font-semibold">{learnerNames.get(attempt.learner_id) ?? "Learner"}</span><span className="mt-0.5 block truncate text-[11px] text-muted-foreground">{classNames.get(attempt.class_id) ?? "Class"}</span></span><span className="min-w-0 truncate text-muted-foreground">{assignmentNames.get(attempt.assignment_id) ?? "Assignment"}</span><span className="whitespace-nowrap text-muted-foreground">{formatRelative(attempt.submitted_at ?? attempt.created_at)}</span><span className="text-right"><span className="block font-semibold tabular-nums">{attempt.status === "released" && revision?.percentage !== null && revision?.percentage !== undefined ? `${revision.percentage}%` : "—"}</span><Badge variant={statusVariant(attempt.status)}>{attempt.status.replaceAll("_", " ")}</Badge></span></Link>; })}</div> : <Empty title="No learner attempts yet" text="Attempts appear after assigned assessment content is used from the learner app." icon={Users} />}
        </section>

        <div className="grid gap-5 sm:grid-cols-2">
          <section className="overflow-hidden rounded-2xl border border-border/75 bg-card shadow-card"><SectionHeading title="Upcoming tasks" description="Only assignments with a configured due date are shown." /><div className="divide-y divide-border/70">{upcoming.length ? upcoming.map((assignment) => <Link key={assignment.id} href={`/classes/${assignment.class_id}?tab=assignments`} className="flex items-center gap-3 px-5 py-3.5 transition-colors hover:bg-muted/30 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-inset"><span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-primary/[0.08] text-primary"><CalendarClock className="h-4 w-4" aria-hidden="true" /></span><span className="min-w-0 flex-1"><span className="block truncate text-sm font-semibold">{assignment.title}</span><span className="mt-0.5 block truncate text-[11px] text-muted-foreground">{classNames.get(assignment.class_id) ?? "Class"} · {assignment.assignment_type}</span></span><time dateTime={assignment.due_at ?? undefined} className="shrink-0 text-[11px] font-medium text-muted-foreground">{formatDate(assignment.due_at)}</time></Link>) : <div className="px-5 py-8 text-center text-xs text-muted-foreground">No future due dates are configured.</div>}</div></section>
          <section className="overflow-hidden rounded-2xl border border-border/75 bg-card shadow-card"><SectionHeading title="Assignment workload" description="Open assignments grouped by class." /><div className="divide-y divide-border/70">{classes.filter((row) => row.status === "active").slice(0, 5).map((row) => <div key={row.id} className="flex items-center justify-between gap-3 px-5 py-3.5"><span className="min-w-0 truncate text-sm font-semibold">{row.title}</span><span className="shrink-0 text-xs tabular-nums text-muted-foreground">{classAssignmentCounts.get(row.id) ?? 0} active</span></div>)}</div><div className="border-t border-border/70 px-5 py-3 text-xs text-muted-foreground">Review signals are scoped to your owned classes.</div></section>
        </div>
      </div>
    </div>
  );
}

function Empty({ title, text, icon: Icon }: { title: string; text: string; icon: LucideIcon }) {
  return <div className="flex flex-col items-center px-5 py-10 text-center"><Icon className="h-7 w-7 text-muted-foreground" aria-hidden="true" /><p className="mt-3 text-sm font-semibold">{title}</p><p className="mt-1 max-w-xs text-xs leading-5 text-muted-foreground">{text}</p></div>;
}
