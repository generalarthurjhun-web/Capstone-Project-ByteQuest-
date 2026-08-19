import Link from "next/link";
import { notFound } from "next/navigation";
import { ArrowLeft, CheckCircle2, Circle, Clock3, ShieldCheck } from "lucide-react";
import { FinalizeAttemptForm, ReleaseAttemptForm } from "@/components/attempts/AttemptReviewActions";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { requireStaffProfile } from "@/lib/auth/server";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

function formatTimestamp(value: string | null) {
  if (!value) return "—";
  return new Intl.DateTimeFormat("en-PH", {
    dateStyle: "medium",
    timeStyle: "medium",
    timeZone: "Asia/Manila",
  }).format(new Date(value));
}

function formatSourceTrace(value: unknown) {
  if (!value) return "Source trace unavailable";
  if (typeof value === "string") return value;
  if (typeof value === "object") {
    const record = value as Record<string, unknown>;
    const classification = typeof record.classification === "string" ? record.classification : null;
    const source = typeof record.source === "string"
      ? record.source
      : typeof record.official_basis === "string"
        ? record.official_basis
        : null;
    return [classification?.replaceAll("_", " "), source].filter(Boolean).join(" · ") || "Versioned source metadata";
  }
  return "Versioned source metadata";
}

function humanize(value: string) {
  return value.replaceAll("_", " ").replace(/\b\w/g, (letter) => letter.toUpperCase());
}

function evidenceValue(value: unknown): string {
  if (value === null || value === undefined || value === "") return "Not recorded";
  if (Array.isArray(value)) return value.map((item) => evidenceValue(item)).join(", ");
  if (typeof value === "object") {
    return Object.entries(value as Record<string, unknown>)
      .filter(([key]) => !["assessment_package_id", "local_mission_code"].includes(key))
      .map(([key, item]) => `${humanize(key)}: ${evidenceValue(item)}`)
      .join("; ");
  }
  if (typeof value === "boolean") return value ? "Yes" : "No";
  return typeof value === "string" ? humanize(value) : String(value);
}

function EvidenceContract({ value }: { value: unknown }) {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return <p className="text-sm leading-relaxed">{evidenceValue(value)}</p>;
  }
  const entries = Object.entries(value as Record<string, unknown>).filter(
    ([key]) => !["assessment_package_id", "local_mission_code"].includes(key),
  );
  return (
    <dl className="space-y-2 text-sm">
      {entries.map(([key, item]) => (
        <div key={key} className="grid gap-0.5 sm:grid-cols-[9rem_minmax(0,1fr)] sm:gap-3">
          <dt className="text-xs font-medium text-muted-foreground">{humanize(key)}</dt>
          <dd className="min-w-0 break-words leading-relaxed">{evidenceValue(item)}</dd>
        </div>
      ))}
    </dl>
  );
}

function criterionCount(value: unknown) {
  if (!Array.isArray(value)) return null;
  const satisfied = value.filter((item) => {
    if (!item || typeof item !== "object") return false;
    return (item as Record<string, unknown>).observation === "satisfied";
  }).length;
  return `${satisfied} / ${value.length} criteria satisfied`;
}

const lifecycleSteps = ["evaluated", "finalized", "released"] as const;

export default async function AttemptDetailPage({ params }: { params: Promise<{ id: string }> }) {
  await requireStaffProfile(["instructor"]);
  const { id } = await params;
  const supabase = await createServerSupabaseClient();
  const { data: attempt } = await supabase
    .from("attempts")
    .select("id,learner_id,class_id,assignment_id,status,started_at,submitted_at,evaluated_at,finalized_at,released_at,elapsed_time_seconds,tesda_source_id,rubric_version_id")
    .eq("id", id)
    .maybeSingle();
  if (!attempt) notFound();

  const [learner, classroom, assignment, source, rubric, actions, criteria, revisions, releases] = await Promise.all([
    supabase.from("profiles").select("full_name,email").eq("user_id", attempt.learner_id).maybeSingle(),
    supabase.from("classes").select("title,class_code").eq("id", attempt.class_id).maybeSingle(),
    supabase.from("assignments").select("title,assignment_type,instructions,activity_version_id").eq("id", attempt.assignment_id).maybeSingle(),
    attempt.tesda_source_id ? supabase.from("tesda_sources").select("title,edition,qualification_code").eq("id", attempt.tesda_source_id).maybeSingle() : Promise.resolve({ data: null }),
    attempt.rubric_version_id ? supabase.from("rubric_versions").select("title,version_number,scoring_method").eq("id", attempt.rubric_version_id).maybeSingle() : Promise.resolve({ data: null }),
    supabase.from("attempt_actions").select("id,sequence_number,action_type,target,value,client_occurred_at,recorded_at").eq("attempt_id", id).order("sequence_number"),
    supabase.from("criterion_results").select("id,rubric_criterion_id,expected_rule,observed_evidence,observation,score_value,remarks,evaluated_at").eq("attempt_id", id).order("evaluated_at"),
    supabase.from("score_revisions").select("id,revision_number,revision_type,total_value,max_value,percentage,outcome,criterion_values,reason,remarks,created_at,actor_role").eq("attempt_id", id).order("revision_number"),
    supabase.from("result_releases").select("id,release_number,released_at,release_reason,is_current").eq("attempt_id", id).order("release_number"),
  ]);

  const { data: activity } = assignment.data?.activity_version_id
    ? await supabase
        .from("activity_versions")
        .select("title,version_number,mission_id,module_version_id")
        .eq("id", assignment.data.activity_version_id)
        .maybeSingle()
    : { data: null };
  const [mission, moduleVersion] = await Promise.all([
    activity?.mission_id
      ? supabase.from("missions").select("mission_code,title,coc_id").eq("id", activity.mission_id).maybeSingle()
      : Promise.resolve({ data: null }),
    activity?.module_version_id
      ? supabase.from("module_versions").select("version_number,module_id").eq("id", activity.module_version_id).maybeSingle()
      : Promise.resolve({ data: null }),
  ]);
  const { data: cocModule } = moduleVersion.data?.module_id
    ? await supabase
        .from("coc_modules")
        .select("coc_code,module_name")
        .eq("id", moduleVersion.data.module_id)
        .maybeSingle()
    : { data: null };

  const criterionRows = criteria.data ?? [];
  const criterionIds = [...new Set(criterionRows.map((row) => row.rubric_criterion_id))];
  const { data: criterionDefinitions } = criterionIds.length
    ? await supabase.from("rubric_criteria").select("id,criterion_code,title,source_trace,order_index").in("id", criterionIds)
    : { data: [] };
  const criterionById = new Map((criterionDefinitions ?? []).map((row) => [row.id, row]));
  const revisionRows = revisions.data ?? [];
  const provisional = [...revisionRows].reverse().find((row) => row.revision_type === "automated_provisional");
  const lifecycleIndex = lifecycleSteps.indexOf(attempt.status as (typeof lifecycleSteps)[number]);
  const satisfiedCount = criterionRows.filter((row) => row.observation === "satisfied").length;
  const authorityLabel = attempt.status === "released"
    ? "Released"
    : attempt.status === "finalized"
      ? "Instructor final"
      : "Automated / provisional";

  return (
    <DashboardLayout>
      <div className="mx-auto max-w-7xl space-y-7">
        <div>
          <Button asChild variant="ghost" size="sm" className="-ml-3 mb-2"><Link href="/attempts"><ArrowLeft className="mr-2 h-4 w-4" aria-hidden="true" />Review queue</Link></Button>
          <div className="flex flex-wrap items-center gap-3"><h1 className="text-2xl font-bold tracking-[-0.035em]">{learner.data?.full_name ?? "Learner attempt"}</h1><Badge variant={attempt.status === "released" ? "secondary" : "outline"}>{attempt.status.replaceAll("_", " ")}</Badge><Badge variant="outline" className={attempt.status === "released" ? "border-emerald-200 bg-emerald-50 text-emerald-800" : attempt.status === "finalized" ? "border-blue-200 bg-blue-50 text-blue-800" : "border-amber-200 bg-amber-50 text-amber-900"}>{authorityLabel}</Badge></div>
          <p className="mt-1 text-sm text-muted-foreground">{assignment.data?.title ?? "Assignment"} · {classroom.data?.title ?? "Class"}</p>
        </div>

        <section className="grid gap-4 rounded-xl border border-border bg-card p-5 shadow-xs sm:grid-cols-2 xl:grid-cols-5">
          <div><p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">Learner</p><p className="mt-1 text-sm font-medium">{learner.data?.email ?? "Email unavailable"}</p></div>
          <div><p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">Mission</p><p className="mt-1 text-sm font-medium">{mission.data ? `${cocModule?.coc_code.toUpperCase() ?? "COC"} · ${mission.data.title}` : activity?.title ?? "Versioned activity"}</p><p className="mt-1 text-xs text-muted-foreground">{mission.data?.mission_code.toUpperCase().replaceAll("_", "-")} · Activity v{activity?.version_number ?? "—"} · Module v{moduleVersion.data?.version_number ?? "—"}</p></div>
          <div><p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">TESDA source</p><p className="mt-1 text-sm font-medium">{source.data ? `${source.data.qualification_code} · ${source.data.edition || "edition not recorded"}` : "Practice / no approved source"}</p></div>
          <div><p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">Rubric</p><p className="mt-1 text-sm font-medium">{rubric.data ? `${rubric.data.title} v${rubric.data.version_number}` : "No assessment rubric"}</p></div>
          <div><p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">Elapsed time</p><p className="mt-1 flex items-center gap-2 text-sm font-medium"><Clock3 className="h-4 w-4 text-muted-foreground" aria-hidden="true" />{attempt.elapsed_time_seconds === null ? "Not submitted" : `${attempt.elapsed_time_seconds} seconds`}</p></div>
        </section>

        <section aria-labelledby="review-lifecycle-title" className="rounded-xl border border-border bg-card p-5 shadow-xs">
          <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
            <div>
              <h2 id="review-lifecycle-title" className="font-semibold">Assessment authority lifecycle</h2>
              <p className="mt-1 text-xs leading-relaxed text-muted-foreground">
                Automated evidence remains provisional until Instructor finalization. Learner visibility begins only after release.
              </p>
            </div>
            <div className="grid min-w-0 grid-cols-3 gap-2" aria-label={`Current lifecycle state: ${attempt.status.replaceAll("_", " ")}`}>
              {lifecycleSteps.map((step, index) => {
                const complete = lifecycleIndex >= index;
                return (
                  <div key={step} className="flex min-w-0 items-center gap-2 rounded-lg border border-border px-3 py-2">
                    {complete ? (
                      <CheckCircle2 className="h-4 w-4 shrink-0 text-emerald-700" aria-hidden="true" />
                    ) : (
                      <Circle className="h-4 w-4 shrink-0 text-muted-foreground" aria-hidden="true" />
                    )}
                    <span className="truncate text-xs font-semibold capitalize">{step}</span>
                  </div>
                );
              })}
            </div>
          </div>
        </section>

        <div className="grid gap-6 xl:grid-cols-[minmax(0,1.15fr)_minmax(320px,0.85fr)]">
          <div className="space-y-6">
            <section className="overflow-hidden rounded-xl border border-border bg-card"><div className="border-b border-border px-5 py-4"><h2 className="font-semibold">Chronological action evidence</h2><p className="mt-1 text-xs text-muted-foreground">Sequence numbers are authoritative; final selected-set equality is not used for ordered procedures.</p></div>{actions.data?.length ? <ol className="divide-y divide-border">{actions.data.map((action) => <li key={action.id} className="grid gap-3 px-5 py-4 sm:grid-cols-[3rem_minmax(0,1fr)_auto]"><span className="font-mono text-sm text-muted-foreground">#{action.sequence_number}</span><div className="min-w-0"><p className="text-sm font-medium">{humanize(action.action_type)}{action.target ? ` · ${humanize(action.target)}` : ""}</p><div className="mt-2 rounded-lg bg-muted/60 p-3"><EvidenceContract value={action.value} /></div></div><time className="text-xs text-muted-foreground">{formatTimestamp(action.client_occurred_at)}</time></li>)}</ol> : <p className="px-5 py-10 text-center text-sm text-muted-foreground">No action evidence has been recorded.</p>}</section>

            <section className="overflow-hidden rounded-xl border border-border bg-card">
              <div className="flex flex-col gap-3 border-b border-border px-5 py-4 sm:flex-row sm:items-center sm:justify-between">
                <div>
                  <h2 className="font-semibold">Criterion-level evaluation</h2>
                  <p className="mt-1 text-xs text-muted-foreground">
                    Expected rule, observed evidence, and outcome remain traceable to the immutable rubric version.
                  </p>
                </div>
                {criterionRows.length ? (
                  <div className="flex items-center gap-2 text-sm font-semibold">
                    <ShieldCheck className="h-4 w-4 text-primary" aria-hidden="true" />
                    {satisfiedCount} / {criterionRows.length} satisfied
                  </div>
                ) : null}
              </div>
              {criterionRows.length ? (
                <div className="divide-y divide-border">
                  {criterionRows.map((result) => {
                    const definition = criterionById.get(result.rubric_criterion_id);
                    return (
                      <article key={result.id} className="space-y-4 px-5 py-5">
                        <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
                          <div>
                            <p className="text-sm font-semibold">
                              {definition ? `${definition.criterion_code} · ${definition.title}` : "Rubric criterion"}
                            </p>
                            <p className="mt-1 text-xs leading-relaxed text-muted-foreground">
                              {formatSourceTrace(definition?.source_trace)}
                            </p>
                          </div>
                          <Badge variant={result.observation === "satisfied" ? "secondary" : "outline"}>
                            {result.observation.replaceAll("_", " ")}
                          </Badge>
                        </div>
                        <details className="group rounded-lg border border-border bg-muted/20">
                          <summary className="cursor-pointer px-4 py-3 text-sm font-medium focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring">
                            Inspect evaluation contract and captured evidence
                          </summary>
                          <div className="grid gap-3 border-t border-border p-4 sm:grid-cols-2">
                            <div>
                              <p className="mb-1 text-xs font-medium text-muted-foreground">Expected rule</p>
                              <div className="rounded-lg bg-background p-3"><EvidenceContract value={result.expected_rule} /></div>
                            </div>
                            <div>
                              <p className="mb-1 text-xs font-medium text-muted-foreground">Observed evidence</p>
                              <div className="rounded-lg bg-background p-3"><EvidenceContract value={result.observed_evidence} /></div>
                            </div>
                          </div>
                        </details>
                        {result.remarks ? <p className="text-sm text-muted-foreground">{result.remarks}</p> : null}
                      </article>
                    );
                  })}
                </div>
              ) : (
                <p className="px-5 py-10 text-center text-sm text-muted-foreground">
                  Trusted evaluation has not produced criterion results yet.
                </p>
              )}
            </section>
          </div>

          <aside className="space-y-6">
            <section className="overflow-hidden rounded-xl border border-border bg-card">
              <div className="border-b border-border px-5 py-4">
                <h2 className="font-semibold">Immutable decision history</h2>
                <p className="mt-1 text-xs text-muted-foreground">Every automated, adjusted, and final decision remains append-only.</p>
              </div>
              {revisionRows.length ? (
                <ol className="divide-y divide-border">
                  {revisionRows.map((revision) => (
                    <li key={revision.id} className="px-5 py-4">
                      <div className="flex items-start justify-between gap-3">
                        <div>
                          <p className="text-sm font-semibold">
                            Revision {revision.revision_number} · {revision.revision_type.replaceAll("_", " ")}
                          </p>
                          <p className="mt-1 text-xs capitalize text-muted-foreground">
                            {criterionCount(revision.criterion_values) ?? "Criterion evidence retained"} · {revision.outcome.replaceAll("_", " ")}
                          </p>
                        </div>
                        <time className="text-xs text-muted-foreground">{formatTimestamp(revision.created_at)}</time>
                      </div>
                      {revision.reason ? <p className="mt-2 text-sm text-muted-foreground">Reason: {revision.reason}</p> : null}
                      {revision.remarks ? <p className="mt-2 text-sm text-muted-foreground">Remarks: {revision.remarks}</p> : null}
                    </li>
                  ))}
                </ol>
              ) : (
                <p className="px-5 py-8 text-center text-sm text-muted-foreground">No decision revision yet.</p>
              )}
            </section>

            {attempt.status === "evaluated" && provisional ? <section className="rounded-xl border border-border bg-card p-5"><h2 className="font-semibold">Instructor review and finalization</h2><p className="mb-4 mt-1 text-sm leading-relaxed text-muted-foreground">Confirm the trusted provisional result or make a justified, append-only adjustment.</p><FinalizeAttemptForm attemptId={id} scoringMethod={rubric.data?.scoring_method ?? null} provisional={{ totalValue: provisional.total_value, maxValue: provisional.max_value, percentage: provisional.percentage, outcome: provisional.outcome, criterionValues: provisional.criterion_values }} /></section> : null}
            {attempt.status === "finalized" ? <section className="rounded-xl border border-border bg-card p-5"><h2 className="font-semibold">Release to learner</h2><p className="mb-4 mt-1 text-sm leading-relaxed text-muted-foreground">Only released final results become visible to the learner. The release RPC is idempotent.</p><ReleaseAttemptForm attemptId={id} /></section> : null}
            {attempt.status === "released" ? <section className="rounded-xl border border-emerald-300 bg-emerald-50 p-5 text-emerald-950"><h2 className="font-semibold">Result released</h2><p className="mt-1 text-sm">Released {formatTimestamp(attempt.released_at)}. The learner can view the current final revision.</p>{releases.data?.[0]?.release_reason ? <p className="mt-2 text-sm">Note: {releases.data[0].release_reason}</p> : null}</section> : null}
          </aside>
        </div>
      </div>
    </DashboardLayout>
  );
}
