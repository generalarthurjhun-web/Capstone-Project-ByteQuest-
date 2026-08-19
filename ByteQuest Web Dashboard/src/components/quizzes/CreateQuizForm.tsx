"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Loader2, Plus } from "lucide-react";
import { toast } from "sonner";
import { z } from "zod";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { createClient } from "@/lib/supabase/client";

const quizSchema = z.object({
  title: z.string().trim().min(3).max(200),
  topic: z.string().trim().min(2).max(240),
  description: z.string().trim().max(2000),
  instructions: z.string().trim().max(2000),
  cocModuleId: z.string().uuid().optional(),
});

export function CreateQuizForm({
  modules,
}: {
  modules: { id: string; code: string; title: string }[];
}) {
  const router = useRouter();
  const [title, setTitle] = useState("");
  const [topic, setTopic] = useState("");
  const [description, setDescription] = useState("");
  const [instructions, setInstructions] = useState("");
  const [cocModuleId, setCocModuleId] = useState("");
  const [submitting, setSubmitting] = useState(false);

  async function handleSubmit(event: React.FormEvent) {
    event.preventDefault();
    const parsed = quizSchema.safeParse({
      title,
      topic,
      description,
      instructions,
      cocModuleId: cocModuleId || undefined,
    });
    if (!parsed.success) {
      toast.error("Check the title, topic, and optional description before creating the draft.");
      return;
    }

    setSubmitting(true);
    const { data, error } = await createClient().rpc("create_instructor_quiz", {
      p_title: parsed.data.title,
      p_topic: parsed.data.topic,
      p_description: parsed.data.description || undefined,
      p_coc_module_id: parsed.data.cocModuleId,
      p_instructions: parsed.data.instructions || undefined,
    });

    if (error || !data) {
      toast.error(error?.message || "The quiz draft could not be created.");
      setSubmitting(false);
      return;
    }

    toast.success("Quiz and version 1 draft created.");
    router.push(`/quizzes/${data.id}`);
    router.refresh();
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-5">
      <div className="grid gap-4 md:grid-cols-2">
        <div className="space-y-2">
          <Label htmlFor="quiz-title">Quiz title <span aria-hidden="true">*</span></Label>
          <Input id="quiz-title" value={title} onChange={(event) => setTitle(event.target.value)} maxLength={200} required placeholder="Network troubleshooting review" />
        </div>
        <div className="space-y-2">
          <Label htmlFor="quiz-topic">Topic <span aria-hidden="true">*</span></Label>
          <Input id="quiz-topic" value={topic} onChange={(event) => setTopic(event.target.value)} maxLength={240} required placeholder="Cable testing and fault isolation" />
        </div>
        <div className="space-y-2">
          <Label htmlFor="quiz-coc">Related COC (optional)</Label>
          <select id="quiz-coc" value={cocModuleId} onChange={(event) => setCocModuleId(event.target.value)} className="flex min-h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring">
            <option value="">General supplementary quiz</option>
            {modules.map((module) => <option key={module.id} value={module.id}>{module.code.toUpperCase()} — {module.title}</option>)}
          </select>
        </div>
        <div className="space-y-2">
          <Label htmlFor="quiz-instructions">Learner instructions (optional)</Label>
          <Input id="quiz-instructions" value={instructions} onChange={(event) => setInstructions(event.target.value)} maxLength={2000} placeholder="Answer each item using the lesson evidence." />
        </div>
      </div>
      <div className="space-y-2">
        <Label htmlFor="quiz-description">Instructor description (optional)</Label>
        <Textarea id="quiz-description" value={description} onChange={(event) => setDescription(event.target.value)} maxLength={2000} rows={3} placeholder="Purpose, intended learner group, or review notes." />
      </div>
      <Button type="submit" disabled={submitting} className="min-h-11">
        {submitting ? <Loader2 className="mr-2 h-4 w-4 animate-spin" aria-hidden="true" /> : <Plus className="mr-2 h-4 w-4" aria-hidden="true" />}
        Create draft quiz
      </Button>
    </form>
  );
}

