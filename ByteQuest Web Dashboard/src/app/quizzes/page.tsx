import Link from "next/link";
import { Archive, BrainCircuit, FileCheck2, ListChecks, PencilLine } from "lucide-react";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { CreateQuizForm } from "@/components/quizzes/CreateQuizForm";
import { MetricStrip, type Metric } from "@/components/dashboard/MetricStrip";
import { PageHeader } from "@/components/dashboard/PageHeader";
import { Badge } from "@/components/ui/badge";
import { requireStaffProfile } from "@/lib/auth/server";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

export default async function QuizzesPage() {
  await requireStaffProfile(["instructor"]);
  const supabase = await createServerSupabaseClient();
  const [{ data: quizzes }, { data: versions }, { data: items }, { data: modules }] = await Promise.all([
    supabase.from("quizzes").select("id,title,topic,description,coc_module_id,updated_at,archived_at").order("updated_at", { ascending: false }),
    supabase.from("quiz_versions").select("id,quiz_id,version_number,status,published_at"),
    supabase.from("quiz_items").select("id,quiz_version_id,review_status,removed_at"),
    supabase.from("coc_modules").select("id,coc_code,title").order("order_index"),
  ]);

  const moduleById = new Map((modules ?? []).map((module) => [module.id, module]));
  const versionByQuiz = new Map<string, NonNullable<typeof versions>[number][]>();
  (versions ?? []).forEach((version) => versionByQuiz.set(version.quiz_id, [...(versionByQuiz.get(version.quiz_id) ?? []), version]));
  const itemCountByVersion = new Map<string, number>();
  (items ?? []).filter((item) => !item.removed_at).forEach((item) => itemCountByVersion.set(item.quiz_version_id, (itemCountByVersion.get(item.quiz_version_id) ?? 0) + 1));
  const publishedCount = (versions ?? []).filter((version) => version.status === "published").length;
  const draftCount = (versions ?? []).filter((version) => version.status === "draft").length;
  const activeItemCount = (items ?? []).filter((item) => !item.removed_at).length;
  const archivedCount = (quizzes ?? []).filter((quiz) => quiz.archived_at).length;
  const metrics: Metric[] = [
    { label: "Published quizzes", value: publishedCount, helper: "Published versions available to assigned learners", icon: FileCheck2, tone: "positive", href: "#quiz-library", linkLabel: "View published quizzes", featured: true },
    { label: "Draft versions", value: draftCount, helper: "Versions still private until you publish", icon: PencilLine, tone: "attention", href: "#quiz-library", linkLabel: "Review draft versions" },
    { label: "Quiz items", value: activeItemCount, helper: "Active questions across your quiz versions", icon: ListChecks, href: "#quiz-library", linkLabel: "View quiz items" },
    { label: "Archived quizzes", value: archivedCount, helper: "Archived quiz records retained for history", icon: Archive, tone: "neutral", href: "#quiz-library", linkLabel: "View archived quizzes" },
  ];

  return (
    <DashboardLayout>
      <div className="mx-auto max-w-7xl space-y-7">
        <PageHeader
          title="Instructor quizzes"
          description="Author supplementary quiz versions, review every question, then publish intentionally. Quiz results never determine TESDA competency."
          actions={<div className="flex items-center gap-2 rounded-lg border border-border bg-card px-3 py-2 text-xs font-medium text-muted-foreground"><BrainCircuit className="h-4 w-4 text-primary" aria-hidden="true" />AI assistance is draft-only</div>}
        />

        <MetricStrip metrics={metrics} ariaLabel="Quiz library metrics" />

        <section className="rounded-xl border border-border bg-card p-5"><h2 className="font-semibold">Create a quiz</h2><p className="mb-5 mt-1 text-sm text-muted-foreground">A version 1 draft is created automatically and remains private to you until publication.</p><CreateQuizForm modules={(modules ?? []).map((module) => ({ id: module.id, code: module.coc_code, title: module.title }))} /></section>

        <section id="quiz-library" className="overflow-hidden rounded-xl border border-border bg-card">
          <div className="border-b border-border px-5 py-4"><h2 className="font-semibold">Your quiz library</h2></div>
          {quizzes?.length ? <div className="divide-y divide-border">{quizzes.map((quiz) => {
            const quizVersions = versionByQuiz.get(quiz.id) ?? [];
            const current = quizVersions.find((version) => version.status === "draft") ?? quizVersions.find((version) => version.status === "published") ?? quizVersions.sort((a, b) => b.version_number - a.version_number)[0];
            const cocModule = quiz.coc_module_id ? moduleById.get(quiz.coc_module_id) : null;
            return <Link key={quiz.id} href={`/quizzes/${quiz.id}`} className="grid gap-3 px-5 py-4 transition-colors hover:bg-muted/35 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring md:grid-cols-[minmax(0,1fr)_auto_auto] md:items-center"><div className="min-w-0"><p className="truncate font-medium">{quiz.title}</p><p className="mt-0.5 truncate text-xs text-muted-foreground">{cocModule ? `${cocModule.coc_code.toUpperCase()} · ${cocModule.title}` : "General supplementary content"} · {quiz.topic}</p></div><div className="text-sm text-muted-foreground">v{current?.version_number ?? 1} · {current ? itemCountByVersion.get(current.id) ?? 0 : 0} items</div><Badge variant={quiz.archived_at ? "outline" : current?.status === "published" ? "secondary" : "default"}>{quiz.archived_at ? "archived" : current?.status ?? "draft"}</Badge></Link>;
          })}</div> : <div className="px-5 py-16 text-center"><ListChecks className="mx-auto h-7 w-7 text-muted-foreground" aria-hidden="true" /><p className="mt-3 text-sm font-medium">No Instructor quiz yet.</p><p className="mt-1 text-sm text-muted-foreground">Create a quiz above, then author or generate reviewable draft items.</p></div>}
        </section>
      </div>
    </DashboardLayout>
  );
}
