"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { Archive, Check, Loader2, Pencil, Plus, Send, Sparkles, Trash2, X } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { createClient } from "@/lib/supabase/client";

type ItemType = "multiple_choice" | "true_false" | "identification" | "scenario_based";
type ReviewStatus = "draft" | "approved" | "rejected";

interface QuizItem {
  id: string;
  itemCode: string;
  itemType: ItemType;
  prompt: string;
  options: string[];
  correctAnswer: string;
  explanation: string | null;
  origin: "instructor_authored" | "ai_generated_draft";
  reviewStatus: ReviewStatus;
  reviewNotes: string | null;
  orderIndex: number;
}

interface QuizGroundingCatalog {
  source: { title: string; edition: string };
  coc: { id: string; code: string; title: string };
  competency: { code: string; title: string };
  module: { title: string; version: number };
  activities: Array<{
    id: string;
    title: string;
    missionNumber: number;
    missionTitle: string;
    learningOutcome: string;
  }>;
}

const itemTypeLabels: Record<ItemType, string> = {
  multiple_choice: "Multiple choice",
  true_false: "True or false",
  identification: "Identification",
  scenario_based: "Scenario-based",
};

export function QuizAuthoringWorkspace({
  quiz,
  version,
  items,
  hasDraft,
  modules,
  classes,
  publishedVersionId,
  grounding,
}: {
  quiz: { id: string; title: string; topic: string; description: string | null; cocModuleId: string | null; archivedAt: string | null };
  version: { id: string; versionNumber: number; status: "draft" | "published" | "retired"; instructions: string | null } | null;
  items: QuizItem[];
  hasDraft: boolean;
  modules: { id: string; code: string; title: string }[];
  classes: { id: string; title: string; code: string | null }[];
  publishedVersionId: string | null;
  grounding: QuizGroundingCatalog | null;
}) {
  const router = useRouter();
  const [busy, setBusy] = useState<string | null>(null);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [itemType, setItemType] = useState<ItemType>("multiple_choice");
  const [prompt, setPrompt] = useState("");
  const [optionsText, setOptionsText] = useState("");
  const [correctAnswer, setCorrectAnswer] = useState("");
  const [explanation, setExplanation] = useState("");
  const [notes, setNotes] = useState<Record<string, string>>({});
  const [publishReason, setPublishReason] = useState("");
  const [versionSummary, setVersionSummary] = useState("");
  const [archiveReason, setArchiveReason] = useState("");
  const [quizTitle, setQuizTitle] = useState(quiz.title);
  const [quizTopic, setQuizTopic] = useState(quiz.topic);
  const [quizDescription, setQuizDescription] = useState(quiz.description ?? "");
  const [quizCocModuleId, setQuizCocModuleId] = useState(quiz.cocModuleId ?? "");
  const [aiTopic, setAiTopic] = useState(quiz.topic);
  const [aiActivityVersionId, setAiActivityVersionId] = useState(grounding?.activities[0]?.id ?? "");
  const [aiInstructorContext, setAiInstructorContext] = useState("");
  const [aiError, setAiError] = useState<string | null>(null);
  const [difficulty, setDifficulty] = useState<"foundation" | "intermediate" | "advanced">("foundation");
  const [itemCount, setItemCount] = useState(5);
  const [aiTypes, setAiTypes] = useState<ItemType[]>(["multiple_choice"]);
  const [assignmentClassId, setAssignmentClassId] = useState(classes[0]?.id ?? "");
  const [assignmentInstructions, setAssignmentInstructions] = useState("");

  const activeItems = useMemo(() => items.sort((a, b) => a.orderIndex - b.orderIndex), [items]);
  const isDraft = version?.status === "draft";

  useEffect(() => {
    setAiActivityVersionId((current) =>
      grounding?.activities.some((activity) => activity.id === current)
        ? current
        : grounding?.activities[0]?.id ?? "",
    );
    setAiError(null);
  }, [grounding]);

  function resetEditor() {
    setEditingId(null);
    setItemType("multiple_choice");
    setPrompt("");
    setOptionsText("");
    setCorrectAnswer("");
    setExplanation("");
  }

  function editItem(item: QuizItem) {
    setEditingId(item.id);
    setItemType(item.itemType);
    setPrompt(item.prompt);
    setOptionsText(item.options.join("\n"));
    setCorrectAnswer(item.correctAnswer);
    setExplanation(item.explanation ?? "");
    document.getElementById("item-editor")?.scrollIntoView({ behavior: "smooth", block: "start" });
  }

  async function saveItem(event: React.FormEvent) {
    event.preventDefault();
    if (!version || !isDraft) return;
    const options = optionsText.split("\n").map((option) => option.trim()).filter(Boolean);
    const normalizedOptions = itemType === "multiple_choice" || itemType === "scenario_based" ? options : [];
    const normalizedAnswer = itemType === "true_false" ? correctAnswer.trim().toLowerCase() : correctAnswer.trim();
    if (prompt.trim().length < 5 || !normalizedAnswer) {
      toast.error("Provide a clear prompt and correct answer.");
      return;
    }
    if ((itemType === "multiple_choice" || itemType === "scenario_based") && (normalizedOptions.length < 2 || !normalizedOptions.includes(normalizedAnswer))) {
      toast.error("Choice-based items need 2–6 options, and the correct answer must exactly match one option.");
      return;
    }
    if (itemType === "true_false" && !["true", "false"].includes(normalizedAnswer)) {
      toast.error("A true/false answer must be true or false.");
      return;
    }

    setBusy("save-item");
    const { error } = await createClient().rpc("upsert_quiz_item", {
      p_quiz_version_id: version.id,
      p_item_type: itemType,
      p_prompt: prompt.trim(),
      p_options: normalizedOptions,
      p_correct_answer: normalizedAnswer,
      p_explanation: explanation.trim() || undefined,
      p_item_id: editingId || undefined,
    });
    if (error) toast.error(error.message);
    else {
      toast.success(editingId ? "Item updated and returned to draft review." : "Draft item added.");
      resetEditor();
      router.refresh();
    }
    setBusy(null);
  }

  async function reviewItem(itemId: string, decision: "approved" | "rejected") {
    const reviewNotes = notes[itemId]?.trim() || "";
    if (decision === "rejected" && !reviewNotes) {
      toast.error("Explain why the item is rejected so the decision is auditable.");
      return;
    }
    setBusy(`${decision}-${itemId}`);
    const { error } = await createClient().rpc("review_quiz_item", {
      p_item_id: itemId,
      p_decision: decision,
      p_notes: reviewNotes || undefined,
    });
    if (error) toast.error(error.message);
    else {
      toast.success(decision === "approved" ? "Item approved for publication." : "Item rejected.");
      router.refresh();
    }
    setBusy(null);
  }

  async function removeItem(itemId: string) {
    const reason = notes[itemId]?.trim() || "";
    if (!reason) {
      toast.error("Enter a review note explaining why the draft item should be removed.");
      return;
    }
    setBusy(`remove-${itemId}`);
    const { error } = await createClient().rpc("remove_quiz_item", { p_item_id: itemId, p_reason: reason });
    if (error) toast.error(error.message);
    else {
      toast.success("Draft item removed while preserving its audit history.");
      router.refresh();
    }
    setBusy(null);
  }

  async function publishVersion() {
    if (!version || !publishReason.trim()) {
      toast.error("A publication reason is required.");
      return;
    }
    setBusy("publish");
    const { error } = await createClient().rpc("publish_quiz_version", { p_quiz_version_id: version.id, p_reason: publishReason.trim() });
    if (error) toast.error(error.message);
    else {
      toast.success("Reviewed quiz version published. No competency result was changed.");
      setPublishReason("");
      router.refresh();
    }
    setBusy(null);
  }

  async function createVersion() {
    setBusy("new-version");
    const { error } = await createClient().rpc("create_quiz_version", {
      p_quiz_id: quiz.id,
      p_change_summary: versionSummary.trim() || "New Instructor draft",
    });
    if (error) toast.error(error.message);
    else {
      toast.success("New draft version created.");
      setVersionSummary("");
      router.refresh();
    }
    setBusy(null);
  }

  async function generateAiDraft(event: React.FormEvent) {
    event.preventDefault();
    if (!version || !isDraft || aiTypes.length === 0 || !aiActivityVersionId) return;
    setAiError(null);
    setBusy("ai");
    try {
      const response = await fetch("/api/instructor/quizzes/ai-draft", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          quizVersionId: version.id,
          activityVersionId: aiActivityVersionId,
          topic: aiTopic,
          instructorContext: aiInstructorContext.trim() || undefined,
          difficulty,
          itemCount,
          itemTypes: aiTypes,
        }),
      });
      const result = (await response.json().catch(() => null)) as
        | { error?: string; generatedCount?: number }
        | null;
      if (!response.ok) {
        const message = result?.error || "AI draft generation failed without publishing any item.";
        setAiError(message);
        toast.error(message);
      } else {
        toast.success(`${result?.generatedCount ?? itemCount} AI-generated draft items require your review.`);
        router.refresh();
      }
    } catch {
      const message = "The AI service could not be reached. Manual quiz creation is still available.";
      setAiError(message);
      toast.error(message);
    } finally {
      setBusy(null);
    }
  }

  async function archiveQuiz() {
    if (!archiveReason.trim()) {
      toast.error("Explain why this quiz should be archived.");
      return;
    }
    setBusy("archive");
    const { error } = await createClient().rpc("archive_instructor_quiz", { p_quiz_id: quiz.id, p_reason: archiveReason.trim() });
    if (error) toast.error(error.message);
    else {
      toast.success("Quiz archived; published history was preserved.");
      router.push("/quizzes");
      router.refresh();
    }
    setBusy(null);
  }

  async function updateQuizMetadata(event: React.FormEvent) {
    event.preventDefault();
    if (quizTitle.trim().length < 3 || quizTopic.trim().length < 2) {
      toast.error("Quiz title and topic are required.");
      return;
    }
    setBusy("metadata");
    const { error } = await createClient().rpc("update_instructor_quiz", {
      p_quiz_id: quiz.id,
      p_title: quizTitle.trim(),
      p_topic: quizTopic.trim(),
      p_description: quizDescription.trim() || undefined,
      p_coc_module_id: quizCocModuleId || undefined,
    });
    if (error) toast.error(error.message);
    else {
      toast.success("Quiz details updated.");
      router.refresh();
    }
    setBusy(null);
  }

  async function assignPublishedQuiz(event: React.FormEvent) {
    event.preventDefault();
    if (!publishedVersionId || !assignmentClassId) return;
    setBusy("assign");
    const { error } = await createClient().rpc("assign_published_quiz", {
      p_class_id: assignmentClassId,
      p_quiz_version_id: publishedVersionId,
      p_instructions: assignmentInstructions.trim() || undefined,
    });
    if (error) {
      toast.error(error.message.includes("duplicate")
        ? "This published quiz is already assigned to that class."
        : error.message);
    } else {
      toast.success("Published quiz assigned to the selected class.");
      setAssignmentInstructions("");
      router.refresh();
    }
    setBusy(null);
  }

  return (
    <div className="space-y-7">
      {!hasDraft && !quiz.archivedAt ? (
        <section className="rounded-xl border border-border bg-card p-5">
          <h2 className="font-semibold">Start the next version</h2>
          <p className="mt-1 text-sm text-muted-foreground">Published versions are immutable. Open a new draft before changing questions.</p>
          <div className="mt-4 flex flex-col gap-3 sm:flex-row">
            <Input value={versionSummary} onChange={(event) => setVersionSummary(event.target.value)} placeholder="What will change in this version?" aria-label="Version change summary" />
            <Button onClick={createVersion} disabled={busy !== null} className="min-h-10 shrink-0">
              {busy === "new-version" ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Plus className="mr-2 h-4 w-4" />}New draft version
            </Button>
          </div>
        </section>
      ) : null}

      {version ? (
        <div className="grid gap-7 xl:grid-cols-[minmax(0,1fr)_360px]">
          <div className="space-y-7">
            {isDraft ? (
              <section id="item-editor" className="scroll-mt-6 rounded-xl border border-border bg-card p-5">
                <div className="flex items-start justify-between gap-4">
                  <div><h2 className="font-semibold">{editingId ? "Edit draft item" : "Author an item"}</h2><p className="mt-1 text-sm text-muted-foreground">Saving an edit returns the item to draft review.</p></div>
                  {editingId ? <Button variant="ghost" size="sm" onClick={resetEditor}><X className="mr-2 h-4 w-4" />Cancel edit</Button> : null}
                </div>
                <form onSubmit={saveItem} className="mt-5 space-y-4">
                  <div className="grid gap-4 md:grid-cols-[220px_minmax(0,1fr)]">
                    <div className="space-y-2"><Label htmlFor="item-type">Question type</Label><select id="item-type" value={itemType} onChange={(event) => setItemType(event.target.value as ItemType)} className="flex min-h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring">{Object.entries(itemTypeLabels).map(([value, label]) => <option key={value} value={value}>{label}</option>)}</select></div>
                    <div className="space-y-2"><Label htmlFor="item-prompt">Prompt <span aria-hidden="true">*</span></Label><Textarea id="item-prompt" value={prompt} onChange={(event) => setPrompt(event.target.value)} rows={3} maxLength={2000} required /></div>
                  </div>
                  {(itemType === "multiple_choice" || itemType === "scenario_based") ? <div className="space-y-2"><Label htmlFor="item-options">Options — one per line</Label><Textarea id="item-options" value={optionsText} onChange={(event) => setOptionsText(event.target.value)} rows={4} placeholder={'Option A\nOption B\nOption C'} /></div> : null}
                  <div className="grid gap-4 md:grid-cols-2"><div className="space-y-2"><Label htmlFor="correct-answer">Correct answer <span aria-hidden="true">*</span></Label><Input id="correct-answer" value={correctAnswer} onChange={(event) => setCorrectAnswer(event.target.value)} placeholder={itemType === "true_false" ? "true or false" : "Exact answer"} required /></div><div className="space-y-2"><Label htmlFor="item-explanation">Teaching explanation</Label><Input id="item-explanation" value={explanation} onChange={(event) => setExplanation(event.target.value)} maxLength={1500} /></div></div>
                  <Button type="submit" disabled={busy !== null} className="min-h-10">{busy === "save-item" ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : editingId ? <Pencil className="mr-2 h-4 w-4" /> : <Plus className="mr-2 h-4 w-4" />}{editingId ? "Save item changes" : "Add draft item"}</Button>
                </form>
              </section>
            ) : null}

            <section className="overflow-hidden rounded-xl border border-border bg-card">
              <div className="border-b border-border px-5 py-4"><h2 className="font-semibold">Question review</h2><p className="mt-1 text-sm text-muted-foreground">Only approved, active items can be published. AI output has no special authority.</p></div>
              {activeItems.length ? <div className="divide-y divide-border">{activeItems.map((item) => (
                <article key={item.id} className="p-5">
                  <div className="flex flex-wrap items-start justify-between gap-3"><div className="min-w-0"><div className="flex flex-wrap items-center gap-2"><span className="text-xs font-semibold text-muted-foreground">{item.itemCode}</span><Badge variant="outline">{itemTypeLabels[item.itemType]}</Badge>{item.origin === "ai_generated_draft" ? <Badge>AI generated draft</Badge> : null}<Badge variant={item.reviewStatus === "approved" ? "secondary" : item.reviewStatus === "rejected" ? "destructive" : "outline"}>{item.reviewStatus}</Badge></div><h3 className="mt-3 font-medium leading-relaxed">{item.prompt}</h3></div>{isDraft ? <Button variant="ghost" size="sm" onClick={() => editItem(item)}><Pencil className="mr-2 h-4 w-4" />Edit</Button> : null}</div>
                  {item.options.length ? <ol className="mt-3 grid gap-1.5 text-sm text-muted-foreground sm:grid-cols-2">{item.options.map((option, index) => <li key={`${item.id}-${option}`} className="rounded-md bg-muted/45 px-3 py-2"><span className="mr-2 font-semibold">{String.fromCharCode(65 + index)}.</span>{option}</li>)}</ol> : null}
                  <div className="mt-3 text-sm"><span className="font-medium">Answer:</span> {item.correctAnswer}</div>
                  {item.explanation ? <p className="mt-1 text-sm text-muted-foreground"><span className="font-medium text-foreground">Explanation:</span> {item.explanation}</p> : null}
                  {isDraft ? <div className="mt-4 rounded-lg bg-muted/35 p-3"><Label htmlFor={`review-${item.id}`}>Review note {item.reviewStatus === "draft" ? "(required for reject/remove)" : ""}</Label><Input id={`review-${item.id}`} className="mt-2" value={notes[item.id] ?? ""} onChange={(event) => setNotes((current) => ({ ...current, [item.id]: event.target.value }))} placeholder="Record the reason for this review decision" /><div className="mt-3 flex flex-wrap gap-2"><Button size="sm" onClick={() => reviewItem(item.id, "approved")} disabled={busy !== null}><Check className="mr-2 h-4 w-4" />Approve</Button><Button size="sm" variant="outline" onClick={() => reviewItem(item.id, "rejected")} disabled={busy !== null}><X className="mr-2 h-4 w-4" />Reject</Button><Button size="sm" variant="ghost" className="text-destructive hover:text-destructive" onClick={() => removeItem(item.id)} disabled={busy !== null}><Trash2 className="mr-2 h-4 w-4" />Remove draft</Button></div></div> : null}
                </article>
              ))}</div> : <div className="px-5 py-14 text-center"><p className="text-sm font-medium">No questions in this version.</p><p className="mt-1 text-sm text-muted-foreground">Author an item manually or request AI-assisted drafts for Instructor review.</p></div>}
            </section>
          </div>

          <aside className="space-y-5">
            {!quiz.archivedAt ? <section className="rounded-xl border border-border bg-card p-5"><h2 className="font-semibold">Quiz details</h2><p className="mt-1 text-sm text-muted-foreground">Update authoring metadata without changing published question history.</p><form onSubmit={updateQuizMetadata} className="mt-4 space-y-3"><div className="space-y-2"><Label htmlFor="metadata-title">Title</Label><Input id="metadata-title" value={quizTitle} onChange={(event) => setQuizTitle(event.target.value)} maxLength={200} required /></div><div className="space-y-2"><Label htmlFor="metadata-topic">Topic</Label><Input id="metadata-topic" value={quizTopic} onChange={(event) => setQuizTopic(event.target.value)} maxLength={240} required /></div><div className="space-y-2"><Label htmlFor="metadata-coc">Related COC</Label><select id="metadata-coc" value={quizCocModuleId} onChange={(event) => setQuizCocModuleId(event.target.value)} className="flex min-h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"><option value="">General supplementary quiz</option>{modules.map((module) => <option key={module.id} value={module.id}>{module.code.toUpperCase()} — {module.title}</option>)}</select></div><div className="space-y-2"><Label htmlFor="metadata-description">Description</Label><Textarea id="metadata-description" value={quizDescription} onChange={(event) => setQuizDescription(event.target.value)} rows={3} maxLength={2000} /></div><Button type="submit" variant="outline" disabled={busy !== null} className="min-h-10 w-full">{busy === "metadata" ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Pencil className="mr-2 h-4 w-4" />}Save quiz details</Button></form></section> : null}

            {isDraft ? (
              <section className="rounded-xl border border-border bg-card p-5">
                <div className="flex items-center gap-2">
                  <Sparkles className="h-5 w-5 text-primary" aria-hidden="true" />
                  <h2 className="font-semibold">Generate with AI</h2>
                </div>
                <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
                  OpenRouter uses the selected approved ByteQuest/TESDA context. Every result stays an editable draft until
                  an Instructor reviews and approves it.
                </p>

                {grounding ? (
                  <div className="mt-4 rounded-lg border border-border bg-muted/35 p-3 text-xs leading-relaxed">
                    <p className="font-semibold text-foreground">
                      {grounding.coc.code.toUpperCase()} · {grounding.competency.code}
                    </p>
                    <p className="mt-1 text-muted-foreground">
                      {grounding.source.title} · {grounding.source.edition}
                    </p>
                  </div>
                ) : (
                  <div className="mt-4 rounded-lg border border-amber-300 bg-amber-50 p-3 text-sm text-amber-950">
                    Select and save a related COC with complete approved source content before generating AI drafts.
                    Manual authoring remains available.
                  </div>
                )}

                <form onSubmit={generateAiDraft} className="mt-5 space-y-4">
                  <div className="space-y-2">
                    <Label htmlFor="ai-activity">Approved activity / learning outcome</Label>
                    <select
                      id="ai-activity"
                      value={aiActivityVersionId}
                      onChange={(event) => setAiActivityVersionId(event.target.value)}
                      disabled={!grounding}
                      required
                      className="flex min-h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-60"
                    >
                      {!grounding ? <option value="">No approved context available</option> : null}
                      {grounding?.activities.map((activity) => (
                        <option key={activity.id} value={activity.id}>
                          M{activity.missionNumber} · {activity.title}
                        </option>
                      ))}
                    </select>
                    {grounding && aiActivityVersionId ? (
                      <p className="text-xs leading-relaxed text-muted-foreground">
                        {
                          grounding.activities.find((activity) => activity.id === aiActivityVersionId)
                            ?.learningOutcome
                        }
                      </p>
                    ) : null}
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="ai-topic">Quiz focus</Label>
                    <Textarea
                      id="ai-topic"
                      value={aiTopic}
                      onChange={(event) => setAiTopic(event.target.value)}
                      rows={3}
                      maxLength={240}
                      required
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="ai-instructor-context">Additional Instructor context (optional)</Label>
                    <Textarea
                      id="ai-instructor-context"
                      value={aiInstructorContext}
                      onChange={(event) => setAiInstructorContext(event.target.value)}
                      rows={3}
                      maxLength={2000}
                      placeholder="Add class-specific emphasis without introducing new TESDA rules."
                    />
                  </div>
                  <div className="grid grid-cols-2 gap-3">
                    <div className="space-y-2">
                      <Label htmlFor="ai-difficulty">Difficulty</Label>
                      <select
                        id="ai-difficulty"
                        value={difficulty}
                        onChange={(event) => setDifficulty(event.target.value as typeof difficulty)}
                        className="flex min-h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                      >
                        <option value="foundation">Foundation</option>
                        <option value="intermediate">Intermediate</option>
                        <option value="advanced">Advanced</option>
                      </select>
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="ai-count">Questions</Label>
                      <Input
                        id="ai-count"
                        type="number"
                        min={1}
                        max={10}
                        value={itemCount}
                        onChange={(event) => setItemCount(Number(event.target.value))}
                      />
                    </div>
                  </div>
                  <fieldset>
                    <legend className="text-sm font-medium">Supported question types</legend>
                    <div className="mt-2 grid gap-2">
                      {Object.entries(itemTypeLabels).map(([value, label]) => (
                        <label
                          key={value}
                          className="flex min-h-10 cursor-pointer items-center gap-3 rounded-md border border-border px-3 text-sm focus-within:ring-2 focus-within:ring-ring"
                        >
                          <input
                            type="checkbox"
                            checked={aiTypes.includes(value as ItemType)}
                            onChange={(event) =>
                              setAiTypes((current) =>
                                event.target.checked
                                  ? [...new Set([...current, value as ItemType])]
                                  : current.filter((item) => item !== value),
                              )
                            }
                            className="h-4 w-4 accent-primary"
                          />
                          {label}
                        </label>
                      ))}
                    </div>
                  </fieldset>
                  {aiError ? (
                    <div
                      role="alert"
                      aria-live="assertive"
                      className="rounded-lg border border-destructive/30 bg-destructive/10 px-3 py-2 text-sm text-destructive"
                    >
                      {aiError}
                    </div>
                  ) : null}
                  <Button
                    type="submit"
                    disabled={busy !== null || aiTypes.length === 0 || !grounding || !aiActivityVersionId}
                    className="min-h-11 w-full"
                  >
                    {busy === "ai" ? (
                      <Loader2 className="mr-2 h-4 w-4 animate-spin" aria-hidden="true" />
                    ) : (
                      <Sparkles className="mr-2 h-4 w-4" aria-hidden="true" />
                    )}
                    {busy === "ai" ? "Generating quiz…" : "Generate with AI"}
                  </Button>
                  <p className="text-xs leading-relaxed text-muted-foreground">
                    AI-generated draft · never auto-published · does not determine learner competency
                  </p>
                </form>
              </section>
            ) : null}

            {isDraft ? <section className="rounded-xl border border-border bg-card p-5"><h2 className="font-semibold">Publish reviewed version</h2><p className="mt-1 text-sm text-muted-foreground">Publication is blocked until every active item is explicitly approved.</p><Label htmlFor="publish-reason" className="mt-4 block">Publication reason</Label><Textarea id="publish-reason" className="mt-2" value={publishReason} onChange={(event) => setPublishReason(event.target.value)} rows={3} placeholder="Reviewed for supplementary class use" /><Button onClick={publishVersion} disabled={busy !== null || !publishReason.trim()} className="mt-3 min-h-10 w-full"><Send className="mr-2 h-4 w-4" />Publish version</Button></section> : null}

            {publishedVersionId && !quiz.archivedAt ? (
              <section className="rounded-xl border border-border bg-card p-5">
                <h2 className="font-semibold">Assign published quiz</h2>
                <p className="mt-1 text-sm leading-relaxed text-muted-foreground">
                  Learners see only the immutable published version through an active class enrollment.
                </p>
                <form onSubmit={assignPublishedQuiz} className="mt-4 space-y-3">
                  <div className="space-y-2">
                    <Label htmlFor="assignment-class">Class</Label>
                    <select
                      id="assignment-class"
                      value={assignmentClassId}
                      onChange={(event) => setAssignmentClassId(event.target.value)}
                      className="flex min-h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                      required
                    >
                      <option value="">Select an owned class</option>
                      {classes.map((item) => (
                        <option key={item.id} value={item.id}>
                          {item.title}{item.code ? ` (${item.code})` : ""}
                        </option>
                      ))}
                    </select>
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="assignment-instructions">Learner instructions (optional)</Label>
                    <Textarea
                      id="assignment-instructions"
                      value={assignmentInstructions}
                      onChange={(event) => setAssignmentInstructions(event.target.value)}
                      rows={3}
                      maxLength={2000}
                    />
                  </div>
                  <Button
                    type="submit"
                    disabled={busy !== null || !assignmentClassId || classes.length === 0}
                    className="min-h-10 w-full"
                  >
                    {busy === "assign" ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Send className="mr-2 h-4 w-4" />}
                    Assign to class
                  </Button>
                </form>
              </section>
            ) : null}

            {!quiz.archivedAt ? <section className="rounded-xl border border-border bg-card p-5"><h2 className="font-semibold">Archive quiz</h2><p className="mt-1 text-sm text-muted-foreground">Removes it from active authoring while preserving every version and audit event.</p><Label htmlFor="archive-reason" className="mt-4 block">Archive reason</Label><Input id="archive-reason" className="mt-2" value={archiveReason} onChange={(event) => setArchiveReason(event.target.value)} /><Button variant="outline" onClick={archiveQuiz} disabled={busy !== null || !archiveReason.trim()} className="mt-3 min-h-10 w-full"><Archive className="mr-2 h-4 w-4" />Archive quiz</Button></section> : null}
          </aside>
        </div>
      ) : null}
    </div>
  );
}
