import { AlertTriangle, CheckCircle2, Clock3, FileCheck2, Files } from "lucide-react";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { MetricStrip } from "@/components/dashboard/MetricStrip";
import { PageHeader } from "@/components/dashboard/PageHeader";
import { RegisterTesdaSourceForm, TesdaSourceGovernanceForm } from "@/components/tesda/TesdaSourceForms";
import { Badge } from "@/components/ui/badge";
import { requireStaffProfile } from "@/lib/auth/server";
import { createAdminSupabaseClient } from "@/lib/supabase/admin";

export const dynamic = "force-dynamic";

export default async function TesdaSourcesPage() {
  await requireStaffProfile(["admin"]);
  const supabase = createAdminSupabaseClient();
  const { data: sources } = await supabase.from("tesda_sources").select("id,qualification_code,title,edition,effective_date,publication_date,source_reference,status,validation_notes,created_at,approved_at,activated_at").order("created_at", { ascending: false });
  const rows = sources ?? [];
  const ready = rows.filter((source) => source.status === "active").length;
  const pending = rows.filter((source) => source.status === "pending_tesda_validation").length;
  const approved = rows.filter((source) => source.status === "approved").length;
  return (
    <DashboardLayout>
      <div className="mx-auto max-w-6xl space-y-7">
        <PageHeader title="TESDA source registry" description="Version and approve the exact official source before any competency or passing rule can become authoritative." />
        <MetricStrip ariaLabel="TESDA source metrics" metrics={[
          { label: "Active sources", value: ready, helper: "Approved and activated versions", icon: CheckCircle2, featured: true },
          { label: "Pending validation", value: pending, helper: "Candidate sources awaiting review", icon: Clock3, tone: pending ? "attention" : "neutral" },
          { label: "Approved versions", value: approved, helper: "Approved but not yet activated", icon: FileCheck2, tone: "positive" },
          { label: "Registered versions", value: rows.length, helper: "Historical source records retained", icon: Files, tone: "neutral" },
        ]} />
        <section className="rounded-xl border border-amber-300 bg-amber-50 p-5 text-amber-950"><div className="flex gap-3"><AlertTriangle className="mt-0.5 h-5 w-5 shrink-0" aria-hidden="true" /><div><h2 className="font-semibold">TESDA SOURCE REQUIRES HUMAN CONFIRMATION</h2><p className="mt-1 text-sm leading-relaxed">The repository and approved PRD do not identify one exact official edition or validated scoring rule. Registration does not equal approval. An authorized human must compare the complete official document and record the edition-specific evidence.</p></div></div></section>
        <section className="rounded-xl border border-border bg-card p-5"><h2 className="font-semibold">Register a candidate official source</h2><p className="mb-5 mt-1 text-sm text-muted-foreground">New records always begin in PENDING_TESDA_VALIDATION.</p><RegisterTesdaSourceForm /></section>
        <section className="space-y-4"><div><h2 className="font-semibold">Version history</h2><p className="mt-1 text-sm text-muted-foreground">Completed attempts retain foreign keys to the historical source and rubric version.</p></div>{rows.length ? rows.map((source) => <article key={source.id} className="rounded-xl border border-border bg-card p-5"><div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between"><div className="min-w-0"><div className="flex flex-wrap items-center gap-2"><h3 className="font-semibold">{source.qualification_code} · {source.title}</h3><Badge variant={source.status === "active" ? "default" : "outline"}>{source.status.replaceAll("_", " ")}</Badge></div><dl className="mt-3 grid gap-2 text-sm text-muted-foreground sm:grid-cols-2"><div><dt className="font-medium text-foreground">Edition</dt><dd>{source.edition || "Not recorded"}</dd></div><div><dt className="font-medium text-foreground">Effective date</dt><dd>{source.effective_date || "Not stated"}</dd></div><div className="sm:col-span-2"><dt className="font-medium text-foreground">Official reference</dt><dd className="break-words">{source.source_reference}</dd></div>{source.validation_notes ? <div className="sm:col-span-2"><dt className="font-medium text-foreground">Validation notes</dt><dd>{source.validation_notes}</dd></div> : null}</dl></div><div className="w-full shrink-0 lg:w-80">{source.status === "pending_tesda_validation" ? <TesdaSourceGovernanceForm sourceId={source.id} action="approve" /> : source.status === "approved" ? <TesdaSourceGovernanceForm sourceId={source.id} action="activate" /> : <p className="text-sm text-muted-foreground">No transition action is available for this historical state.</p>}</div></div></article>) : <div className="rounded-xl border border-dashed border-border px-5 py-12 text-center text-sm text-muted-foreground">No source version has been registered.</div>}</section>
      </div>
    </DashboardLayout>
  );
}
