"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Loader2 } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { createClient } from "@/lib/supabase/client";
import type { Json } from "@/types/database.generated";

type Outcome = "competent" | "not_yet_competent";

interface ProvisionalRevision {
  totalValue: number | null;
  maxValue: number | null;
  percentage: number | null;
  outcome: "pending_tesda_validation" | Outcome;
  criterionValues: Json;
}

export function FinalizeAttemptForm({
  attemptId,
  provisional,
  scoringMethod,
}: {
  attemptId: string;
  provisional: ProvisionalRevision;
  scoringMethod: string | null;
}) {
  const router = useRouter();
  const [outcome, setOutcome] = useState<Outcome | "">(
    provisional.outcome === "pending_tesda_validation" ? "" : provisional.outcome,
  );
  const [reason, setReason] = useState("");
  const [remarks, setRemarks] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    if (!outcome) {
      toast.error("Select the Instructor-reviewed competency outcome.");
      return;
    }

    const changed = outcome !== provisional.outcome;
    if (changed && reason.trim().length < 5) {
      toast.error("A clear reason is mandatory when changing the provisional result.");
      return;
    }

    setSubmitting(true);
    const { error } = await createClient().rpc("finalize_attempt", {
      p_attempt_id: attemptId,
      p_total_value: provisional.totalValue as number,
      p_max_value: provisional.maxValue as number,
      p_percentage: provisional.percentage as number,
      p_outcome: outcome,
      p_criterion_values: provisional.criterionValues,
      p_reason: reason.trim() || undefined,
      p_remarks: remarks.trim() || undefined,
    });
    if (error) {
      toast.error(error.message);
      setSubmitting(false);
      return;
    }

    toast.success(changed ? "Adjustment recorded and result finalized." : "Result finalized.");
    router.refresh();
  };

  return (
    <form onSubmit={handleSubmit} className="grid gap-4 sm:grid-cols-2">
      <div className="rounded-lg border border-border bg-muted/25 p-4 sm:col-span-2">
        <p className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">
          Automated provisional evidence summary
        </p>
        <div className="mt-3 grid gap-3 sm:grid-cols-3">
          <div>
            <p className="text-xs text-muted-foreground">Criteria satisfied</p>
            <p className="mt-1 text-lg font-bold tabular-nums">
              {provisional.totalValue ?? "—"} / {provisional.maxValue ?? "—"}
            </p>
          </div>
          <div>
            <p className="text-xs text-muted-foreground">Decision method</p>
            <p className="mt-1 text-sm font-semibold">
              {scoringMethod === "binary_sum" ? "All required criteria" : scoringMethod ?? "Versioned rubric"}
            </p>
          </div>
          <div>
            <p className="text-xs text-muted-foreground">Automated outcome</p>
            <p className="mt-1 text-sm font-semibold capitalize">
              {provisional.outcome.replaceAll("_", " ")}
            </p>
          </div>
        </div>
        <p className="mt-3 text-xs leading-relaxed text-muted-foreground">
          The 1/0 values are technical encodings of SATISFIED / NOT SATISFIED. They are not TESDA weights or a TESDA passing percentage.
        </p>
      </div>
      <div className="space-y-2 sm:col-span-2">
        <Label>Instructor-reviewed outcome</Label>
        <Select value={outcome} onValueChange={(value) => setOutcome(value as Outcome)}>
          <SelectTrigger><SelectValue placeholder="Select outcome" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="competent">Competent</SelectItem>
            <SelectItem value="not_yet_competent">Not yet competent</SelectItem>
          </SelectContent>
        </Select>
      </div>
      <div className="space-y-2 sm:col-span-2"><Label htmlFor="adjustment-reason">Adjustment reason</Label><Textarea id="adjustment-reason" value={reason} onChange={(event) => setReason(event.target.value)} placeholder="Required only if any provisional value is changed" rows={3} /></div>
      <div className="space-y-2 sm:col-span-2"><Label htmlFor="review-remarks">Instructor remarks</Label><Textarea id="review-remarks" value={remarks} onChange={(event) => setRemarks(event.target.value)} rows={3} /></div>
      <div className="sm:col-span-2"><Button type="submit" disabled={submitting}>{submitting ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}Finalize result</Button></div>
    </form>
  );
}

export function ReleaseAttemptForm({ attemptId }: { attemptId: string }) {
  const router = useRouter();
  const [reason, setReason] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    setSubmitting(true);
    const { error } = await createClient().rpc("release_attempt", {
      p_attempt_id: attemptId,
      p_release_reason: reason.trim() || undefined,
    });
    if (error) {
      toast.error(error.message);
      setSubmitting(false);
      return;
    }
    toast.success("Final result released to the learner. Projection and reward event were applied once.");
    router.refresh();
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-3">
      <div className="space-y-2"><Label htmlFor="release-reason">Release note (optional)</Label><Textarea id="release-reason" value={reason} onChange={(event) => setReason(event.target.value)} rows={3} /></div>
      <Button type="submit" disabled={submitting}>{submitting ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}Release final result</Button>
    </form>
  );
}
