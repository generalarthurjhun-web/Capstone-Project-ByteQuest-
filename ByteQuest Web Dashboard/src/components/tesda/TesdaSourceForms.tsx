"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Loader2 } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { createClient } from "@/lib/supabase/client";

export function RegisterTesdaSourceForm() {
  const router = useRouter();
  const [qualificationCode, setQualificationCode] = useState("");
  const [title, setTitle] = useState("");
  const [edition, setEdition] = useState("");
  const [effectiveDate, setEffectiveDate] = useState("");
  const [publicationDate, setPublicationDate] = useState("");
  const [reference, setReference] = useState("");
  const [notes, setNotes] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    if (qualificationCode.trim().length < 2 || title.trim().length < 5 || reference.trim().length < 5) {
      toast.error("Qualification code, exact title, and official reference are required.");
      return;
    }
    setSubmitting(true);
    const { error } = await createClient().rpc("register_tesda_source", {
      p_qualification_code: qualificationCode.trim(),
      p_title: title.trim(),
      p_edition: edition.trim(),
      p_effective_date: effectiveDate || (null as unknown as string),
      p_publication_date: publicationDate || (null as unknown as string),
      p_source_reference: reference.trim(),
      p_validation_notes: notes.trim() || undefined,
      p_document_storage_path: undefined,
    });
    if (error) {
      toast.error(error.message);
      setSubmitting(false);
      return;
    }
    toast.success("Source registered as PENDING_TESDA_VALIDATION.");
    setQualificationCode(""); setTitle(""); setEdition(""); setEffectiveDate(""); setPublicationDate(""); setReference(""); setNotes("");
    router.refresh();
    setSubmitting(false);
  };

  return (
    <form onSubmit={handleSubmit} className="grid gap-4 md:grid-cols-2">
      <div className="space-y-2"><Label htmlFor="qualification-code">Qualification code</Label><Input id="qualification-code" value={qualificationCode} onChange={(event) => setQualificationCode(event.target.value)} placeholder="Exact official code" required /></div>
      <div className="space-y-2"><Label htmlFor="source-edition">Edition / version</Label><Input id="source-edition" value={edition} onChange={(event) => setEdition(event.target.value)} placeholder="As printed in the official document" /></div>
      <div className="space-y-2 md:col-span-2"><Label htmlFor="source-title">Exact official title</Label><Input id="source-title" value={title} onChange={(event) => setTitle(event.target.value)} required /></div>
      <div className="space-y-2"><Label htmlFor="effective-date">Effective date, if stated</Label><Input id="effective-date" type="date" value={effectiveDate} onChange={(event) => setEffectiveDate(event.target.value)} /></div>
      <div className="space-y-2"><Label htmlFor="publication-date">Publication date, if stated</Label><Input id="publication-date" type="date" value={publicationDate} onChange={(event) => setPublicationDate(event.target.value)} /></div>
      <div className="space-y-2 md:col-span-2"><Label htmlFor="source-reference">Official TESDA reference or URL</Label><Input id="source-reference" value={reference} onChange={(event) => setReference(event.target.value)} placeholder="Official source location or reference number" required /></div>
      <div className="space-y-2 md:col-span-2"><Label htmlFor="validation-notes">Registration notes</Label><Textarea id="validation-notes" value={notes} onChange={(event) => setNotes(event.target.value)} rows={3} placeholder="Document provenance, conflicts, or confirmation still needed" /></div>
      <div className="md:col-span-2"><Button type="submit" disabled={submitting}>{submitting ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}Register pending source</Button></div>
    </form>
  );
}

export function TesdaSourceGovernanceForm({ sourceId, action }: { sourceId: string; action: "approve" | "activate" }) {
  const router = useRouter();
  const [reason, setReason] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    if (reason.trim().length < 10) {
      toast.error("Record detailed verification notes or an activation reason.");
      return;
    }
    setSubmitting(true);
    const client = createClient();
    const result = action === "approve"
      ? await client.rpc("approve_tesda_source", { p_source_id: sourceId, p_validation_notes: reason.trim() })
      : await client.rpc("activate_tesda_source", { p_source_id: sourceId, p_reason: reason.trim() });
    if (result.error) toast.error(result.error.message);
    else {
      toast.success(action === "approve" ? "Source approved with an audit record." : "Approved source activated and previous version superseded.");
      setReason("");
      router.refresh();
    }
    setSubmitting(false);
  };
  return <form onSubmit={handleSubmit} className="space-y-2"><Label htmlFor={`${action}-${sourceId}`}>{action === "approve" ? "Verification notes" : "Activation reason"}</Label><Textarea id={`${action}-${sourceId}`} value={reason} onChange={(event) => setReason(event.target.value)} rows={3} required /><Button type="submit" size="sm" disabled={submitting}>{submitting ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}{action === "approve" ? "Approve verified edition" : "Activate approved edition"}</Button></form>;
}
