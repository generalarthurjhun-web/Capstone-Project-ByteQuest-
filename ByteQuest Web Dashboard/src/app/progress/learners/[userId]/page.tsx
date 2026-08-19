import Link from "next/link";
import { notFound } from "next/navigation";
import { ArrowLeft } from "lucide-react";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { requireStaffProfile } from "@/lib/auth/server";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

export default async function LearnerProgressPage({ params, searchParams }: { params: Promise<{ userId: string }>; searchParams: Promise<{ class?: string }> }) {
  await requireStaffProfile(["instructor"]);
  const [{ userId }, query] = await Promise.all([params, searchParams]);
  const supabase = await createServerSupabaseClient();
  const { data: learner } = await supabase.from("profiles").select("user_id,full_name,email,status").eq("user_id", userId).maybeSingle();
  if (!learner) notFound();
  let attemptQuery = supabase.from("attempts").select("id,class_id,assignment_id,status,started_at,submitted_at,released_at,elapsed_time_seconds").eq("learner_id", userId).order("started_at", { ascending: false });
  if (query.class) attemptQuery = attemptQuery.eq("class_id", query.class);
  const { data: attempts } = await attemptQuery;
  const attemptRows = attempts ?? [];
  const [classes, assignments, revisions] = await Promise.all([
    attemptRows.length ? supabase.from("classes").select("id,title").in("id", [...new Set(attemptRows.map((row) => row.class_id))]) : Promise.resolve({ data: [] }),
    attemptRows.length ? supabase.from("assignments").select("id,title,assignment_type").in("id", [...new Set(attemptRows.map((row) => row.assignment_id))]) : Promise.resolve({ data: [] }),
    attemptRows.length ? supabase.from("score_revisions").select("attempt_id,revision_type,percentage,outcome,remarks").in("attempt_id", attemptRows.map((row) => row.id)).eq("revision_type", "instructor_final") : Promise.resolve({ data: [] }),
  ]);
  const classById = new Map((classes.data ?? []).map((row) => [row.id, row.title]));
  const assignmentById = new Map((assignments.data ?? []).map((row) => [row.id, row]));
  const finalByAttempt = new Map((revisions.data ?? []).map((row) => [row.attempt_id, row]));
  return (
    <DashboardLayout>
      <div className="mx-auto max-w-6xl space-y-7">
        <div><Button asChild variant="ghost" size="sm" className="-ml-3 mb-2"><Link href="/progress"><ArrowLeft className="mr-2 h-4 w-4" aria-hidden="true" />Learner monitoring</Link></Button><div className="flex flex-wrap items-center gap-3"><h1 className="text-2xl font-bold tracking-tight">{learner.full_name}</h1><Badge variant={learner.status === "active" ? "secondary" : "outline"}>{learner.status}</Badge></div><p className="mt-1 text-sm text-muted-foreground">{learner.email}</p></div>
        <section className="overflow-hidden rounded-xl border border-border bg-card"><div className="border-b border-border px-5 py-4"><h2 className="font-semibold">Authoritative attempt history</h2><p className="mt-1 text-xs text-muted-foreground">Final score and outcome appear only after Instructor finalization and release.</p></div>{attemptRows.length ? <div className="divide-y divide-border">{attemptRows.map((attempt) => { const assignment = assignmentById.get(attempt.assignment_id); const final = finalByAttempt.get(attempt.id); return <Link key={attempt.id} href={`/attempts/${attempt.id}`} className="grid gap-3 px-5 py-4 transition-colors hover:bg-muted/35 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring md:grid-cols-[minmax(0,1fr)_auto_auto]"><div><p className="text-sm font-medium">{assignment?.title ?? "Assignment"}</p><p className="mt-0.5 text-xs text-muted-foreground">{classById.get(attempt.class_id) ?? "Class"} · {assignment?.assignment_type ?? "activity"}</p></div><div className="text-sm font-semibold tabular-nums">{attempt.status === "released" && final?.percentage !== null && final?.percentage !== undefined ? `${final.percentage}%` : "—"}</div><Badge variant={attempt.status === "released" && final?.outcome === "competent" ? "secondary" : "outline"}>{attempt.status === "released" ? final?.outcome.replaceAll("_", " ") ?? "released" : attempt.status.replaceAll("_", " ")}</Badge></Link>; })}</div> : <p className="px-5 py-12 text-center text-sm text-muted-foreground">No attempt is visible in your scoped classes.</p>}</section>
      </div>
    </DashboardLayout>
  );
}
