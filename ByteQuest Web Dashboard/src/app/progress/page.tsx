import Link from "next/link";
import { Activity, Users } from "lucide-react";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { PageHeader } from "@/components/dashboard/PageHeader";
import { Badge } from "@/components/ui/badge";
import { requireStaffProfile } from "@/lib/auth/server";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

export default async function ProgressPage() {
  await requireStaffProfile(["instructor"]);
  const supabase = await createServerSupabaseClient();
  const [memberships, classes, attempts, revisions] = await Promise.all([
    supabase.from("class_memberships").select("id,class_id,learner_id,status,enrolled_at").eq("status", "active"),
    supabase.from("classes").select("id,title"),
    supabase.from("attempts").select("id,class_id,learner_id,status,started_at,released_at").order("started_at", { ascending: false }),
    supabase.from("score_revisions").select("attempt_id,revision_type,percentage,outcome").eq("revision_type", "instructor_final"),
  ]);
  const memberRows = memberships.data ?? [];
  const learnerIds = [...new Set(memberRows.map((row) => row.learner_id))];
  const { data: profiles } = learnerIds.length ? await supabase.from("profiles").select("user_id,full_name,email,status").in("user_id", learnerIds) : { data: [] };
  const profileById = new Map((profiles ?? []).map((row) => [row.user_id, row]));
  const classById = new Map((classes.data ?? []).map((row) => [row.id, row.title]));
  const finalByAttempt = new Map((revisions.data ?? []).map((row) => [row.attempt_id, row]));
  return (
    <DashboardLayout>
      <div className="mx-auto max-w-7xl space-y-7">
        <PageHeader title="Learner monitoring" description="Review enrollment-scoped activity, assessment state, and released competency outcomes. XP remains separate from official evaluation." />
        <section className="overflow-hidden rounded-xl border border-border bg-card">
          {memberRows.length ? <div className="divide-y divide-border">{memberRows.map((membership) => { const profile = profileById.get(membership.learner_id); const learnerAttempts = (attempts.data ?? []).filter((attempt) => attempt.learner_id === membership.learner_id && attempt.class_id === membership.class_id); const released = learnerAttempts.flatMap((attempt) => { const final = finalByAttempt.get(attempt.id); return attempt.status === "released" && final ? [final] : []; }); const latestOutcome = released[0]?.outcome; const needsReview = learnerAttempts.some((attempt) => attempt.status === "evaluated" || attempt.status === "under_review"); const needsIntervention = latestOutcome === "not_yet_competent"; return <Link key={membership.id} href={`/progress/learners/${membership.learner_id}?class=${membership.class_id}`} className="grid gap-3 px-5 py-4 transition-colors hover:bg-muted/35 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring md:grid-cols-[minmax(0,1fr)_auto_auto_auto] md:items-center"><div className="min-w-0"><p className="truncate text-sm font-medium">{profile?.full_name ?? "Learner"}</p><p className="mt-0.5 truncate text-xs text-muted-foreground">{profile?.email ?? "Email unavailable"} · {classById.get(membership.class_id) ?? "Class"}</p></div><div className="text-sm"><span className="font-semibold tabular-nums">{learnerAttempts.length}</span> attempts</div><div className="text-sm"><span className="font-semibold tabular-nums">{released.length}</span> released</div><Badge variant={needsIntervention ? "destructive" : needsReview ? "default" : latestOutcome === "competent" ? "secondary" : "outline"}>{needsIntervention ? "intervention" : needsReview ? "review pending" : latestOutcome?.replaceAll("_", " ") ?? "no released result"}</Badge></Link>; })}</div> : <div className="px-5 py-16 text-center"><Users className="mx-auto h-7 w-7 text-muted-foreground" aria-hidden="true" /><p className="mt-3 text-sm font-medium">No active class memberships.</p><p className="mt-1 text-sm text-muted-foreground">Enroll registered learners from a class workspace.</p></div>}
        </section>
        <p className="flex items-center gap-2 text-xs text-muted-foreground"><Activity className="h-3.5 w-3.5" aria-hidden="true" />Intervention is an operational flag, not an invented TESDA decision rule.</p>
      </div>
    </DashboardLayout>
  );
}
