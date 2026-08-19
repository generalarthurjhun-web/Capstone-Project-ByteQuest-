import { notFound } from "next/navigation";
import { ShieldCheck } from "lucide-react";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { QuizAuthoringWorkspace } from "@/components/quizzes/QuizAuthoringWorkspace";
import { Badge } from "@/components/ui/badge";
import { getQuizGroundingCatalog, type QuizGroundingCatalog } from "@/lib/ai/quiz-grounding";
import { requireStaffProfile } from "@/lib/auth/server";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

function toStringArray(value: unknown): string[] {
  return Array.isArray(value) ? value.filter((item): item is string => typeof item === "string") : [];
}

export default async function QuizDetailPage({ params }: { params: Promise<{ id: string }> }) {
  await requireStaffProfile(["instructor"]);
  const { id } = await params;
  const supabase = await createServerSupabaseClient();
  const { data: quiz } = await supabase
    .from("quizzes")
    .select("id,title,topic,description,coc_module_id,instructor_id,archived_at")
    .eq("id", id)
    .maybeSingle();
  if (!quiz) notFound();

  const [{ data: versions }, { data: module }, { data: modules }, { data: classes }] = await Promise.all([
    supabase
      .from("quiz_versions")
      .select("id,quiz_id,version_number,status,instructions,change_summary,published_at,retired_at")
      .eq("quiz_id", quiz.id)
      .order("version_number", { ascending: false }),
    quiz.coc_module_id
      ? supabase.from("coc_modules").select("coc_code,title").eq("id", quiz.coc_module_id).maybeSingle()
      : Promise.resolve({ data: null }),
    supabase.from("coc_modules").select("id,coc_code,title").order("order_index"),
    supabase
      .from("classes")
      .select("id,title,class_code,status")
      .eq("status", "active")
      .order("title"),
  ]);
  const publishedVersion = versions?.find((version) => version.status === "published") ?? null;
  const currentVersion =
    versions?.find((version) => version.status === "draft") ??
    versions?.find((version) => version.status === "published") ??
    versions?.[0] ??
    null;
  const { data: items } = currentVersion
    ? await supabase
        .from("quiz_items")
        .select(
          "id,item_code,item_type,prompt,options,correct_answer,explanation,origin,review_status,review_notes,order_index,removed_at",
        )
        .eq("quiz_version_id", currentVersion.id)
        .is("removed_at", null)
        .order("order_index")
    : { data: [] };

  let grounding: QuizGroundingCatalog | null = null;
  if (quiz.coc_module_id) {
    try {
      grounding = await getQuizGroundingCatalog(supabase, quiz.coc_module_id);
    } catch {
      grounding = null;
    }
  }

  return (
    <DashboardLayout>
      <div className="mx-auto max-w-7xl space-y-7">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <div className="flex flex-wrap items-center gap-2">
              <h1 className="text-2xl font-bold tracking-tight">{quiz.title}</h1>
              <Badge
                variant={
                  quiz.archived_at ? "outline" : currentVersion?.status === "published" ? "secondary" : "default"
                }
              >
                {quiz.archived_at ? "archived" : currentVersion?.status ?? "draft"}
              </Badge>
            </div>
            <p className="mt-1 max-w-3xl text-sm leading-relaxed text-muted-foreground">
              {module ? `${module.coc_code.toUpperCase()} · ${module.title}` : "General supplementary quiz"} ·{" "}
              {quiz.topic}
            </p>
          </div>
          <div className="flex items-center gap-2 rounded-lg bg-muted/50 px-3 py-2 text-xs text-muted-foreground">
            <ShieldCheck className="h-4 w-4" aria-hidden="true" />
            Instructor review controls publication
          </div>
        </div>
        <section className="rounded-xl border border-blue-200 bg-blue-50 px-5 py-4 text-sm leading-relaxed text-blue-950">
          ByteQuest quizzes are supplementary learning materials. AI may draft questions, but it cannot publish, grade
          official competency, or replace accredited TESDA assessment.
        </section>
        <QuizAuthoringWorkspace
          quiz={{
            id: quiz.id,
            title: quiz.title,
            topic: quiz.topic,
            description: quiz.description,
            cocModuleId: quiz.coc_module_id,
            archivedAt: quiz.archived_at,
          }}
          version={
            currentVersion
              ? {
                  id: currentVersion.id,
                  versionNumber: currentVersion.version_number,
                  status: currentVersion.status,
                  instructions: currentVersion.instructions,
                }
              : null
          }
          items={(items ?? []).map((item) => ({
            id: item.id,
            itemCode: item.item_code,
            itemType: item.item_type,
            prompt: item.prompt,
            options: toStringArray(item.options),
            correctAnswer:
              typeof item.correct_answer === "string" ? item.correct_answer : String(item.correct_answer ?? ""),
            explanation: item.explanation,
            origin: item.origin,
            reviewStatus: item.review_status,
            reviewNotes: item.review_notes,
            orderIndex: item.order_index,
          }))}
          hasDraft={(versions ?? []).some((version) => version.status === "draft")}
          modules={(modules ?? []).map((item) => ({ id: item.id, code: item.coc_code, title: item.title }))}
          classes={(classes ?? []).map((item) => ({
            id: item.id,
            title: item.title,
            code: item.class_code,
          }))}
          publishedVersionId={publishedVersion?.id ?? null}
          grounding={grounding}
        />
        <section className="overflow-hidden rounded-xl border border-border bg-card">
          <div className="border-b border-border px-5 py-4">
            <h2 className="font-semibold">Version history</h2>
            <p className="mt-1 text-sm text-muted-foreground">
              Published and retired versions remain immutable and traceable.
            </p>
          </div>
          <div className="divide-y divide-border">
            {(versions ?? []).map((version) => (
              <div key={version.id} className="flex items-center justify-between gap-4 px-5 py-4">
                <div>
                  <p className="text-sm font-medium">Version {version.version_number}</p>
                  <p className="mt-0.5 text-xs text-muted-foreground">
                    {version.change_summary || "No change summary recorded"}
                  </p>
                </div>
                <Badge variant={version.status === "published" ? "secondary" : "outline"}>{version.status}</Badge>
              </div>
            ))}
          </div>
        </section>
      </div>
    </DashboardLayout>
  );
}
