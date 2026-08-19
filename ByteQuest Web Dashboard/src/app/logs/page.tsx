import { Activity, Clock3, ShieldCheck, TriangleAlert, XCircle } from "lucide-react";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { MetricStrip } from "@/components/dashboard/MetricStrip";
import { PageHeader } from "@/components/dashboard/PageHeader";
import { Badge } from "@/components/ui/badge";
import { requireStaffProfile } from "@/lib/auth/server";
import { createAdminSupabaseClient } from "@/lib/supabase/admin";

export const dynamic = "force-dynamic";

export default async function LogsPage() {
  await requireStaffProfile(["admin"]);
  const supabase = createAdminSupabaseClient();
  const { data: events } = await supabase.from("audit_events").select("id,actor_id,actor_role,action,target_type,target_id,reason,metadata,outcome,created_at").order("created_at", { ascending: false }).limit(500);
  const rows = events ?? [];
  const failures = rows.filter((event) => event.outcome !== "success").length;
  const securityEvents = rows.filter((event) => /auth|role|access|security|account/i.test(event.action)).length;
  const actorCount = new Set(rows.map((event) => event.actor_id).filter(Boolean)).size;
  const actorIds = [...new Set(rows.flatMap((row) => row.actor_id ? [row.actor_id] : []))];
  const { data: actorRows } = actorIds.length ? await supabase.from("profiles").select("user_id,full_name,email").in("user_id", actorIds) : { data: [] };
  const actorById = new Map((actorRows ?? []).map((actor) => [actor.user_id, actor]));
  return (
    <DashboardLayout>
      <div className="mx-auto max-w-7xl space-y-7">
        <PageHeader title="Authoritative audit log" description="Inspect high-impact events written by trusted database workflows. Client-supplied actor identities are never accepted." />
        <MetricStrip ariaLabel="Audit log metrics" metrics={[
          { label: "Recent events", value: rows.length, helper: "Latest trusted events loaded", icon: Activity, featured: true },
          { label: "Security-relevant", value: securityEvents, helper: "Auth, role, access, or account actions", icon: ShieldCheck, tone: "neutral" },
          { label: "Non-success outcomes", value: failures, helper: "Denied or failed events requiring review", icon: XCircle, tone: failures ? "attention" : "positive", href: "/admin/security", linkLabel: "Review security outcomes" },
          { label: "Distinct actors", value: actorCount, helper: "Trusted actor identities in this window", icon: TriangleAlert, tone: "neutral" },
        ]} />
        <section className="overflow-hidden rounded-xl border border-border bg-card">
          {rows.length ? <div className="divide-y divide-border">{rows.map((event) => { const actor = event.actor_id ? actorById.get(event.actor_id) : null; return <article key={event.id} className="grid gap-3 px-5 py-4 lg:grid-cols-[minmax(0,1fr)_minmax(0,0.8fr)_auto] lg:items-start"><div><div className="flex flex-wrap items-center gap-2"><ShieldCheck className="h-4 w-4 text-primary" aria-hidden="true" /><p className="text-sm font-medium">{event.action}</p><Badge variant={event.outcome === "success" ? "secondary" : "destructive"}>{event.outcome}</Badge></div><p className="mt-1 text-xs text-muted-foreground">{event.target_type}{event.target_id ? ` · ${event.target_id}` : ""}</p>{event.reason ? <p className="mt-2 text-sm text-muted-foreground">Reason: {event.reason}</p> : null}</div><div><p className="text-sm">{actor?.full_name ?? "Trusted service"}</p><p className="mt-0.5 text-xs text-muted-foreground">{event.actor_role ?? "service_role"}{actor?.email ? ` · ${actor.email}` : ""}</p></div><time className="flex items-center gap-2 whitespace-nowrap text-xs text-muted-foreground"><Clock3 className="h-3.5 w-3.5" aria-hidden="true" />{new Intl.DateTimeFormat("en-PH", { dateStyle: "medium", timeStyle: "short", timeZone: "Asia/Manila" }).format(new Date(event.created_at))}</time></article>; })}</div> : <p className="px-5 py-14 text-center text-sm text-muted-foreground">No authoritative audit event has been recorded.</p>}
        </section>
      </div>
    </DashboardLayout>
  );
}
