import Link from "next/link";
import { BookOpen } from "lucide-react";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { PageHeader } from "@/components/dashboard/PageHeader";
import { Badge } from "@/components/ui/badge";
import { requireStaffProfile } from "@/lib/auth/server";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

export default async function ModulesPage() {
  await requireStaffProfile(["instructor"]);
  const supabase = await createServerSupabaseClient();
  const [versions, sources, baseModules, activities] = await Promise.all([
    supabase.from("module_versions").select("id,module_id,tesda_source_id,version_number,title,description,status,created_at,published_at").order("created_at", { ascending: false }),
    supabase.from("tesda_sources").select("id,qualification_code,edition,status"),
    supabase.from("coc_modules").select("id,coc_code,module_name,status"),
    supabase.from("activity_versions").select("id,module_version_id,status"),
  ]);
  const sourceById = new Map((sources.data ?? []).map((source) => [source.id, source]));
  const baseById = new Map((baseModules.data ?? []).map((module) => [module.id, module]));
  const rows = versions.data ?? [];
  return (
    <DashboardLayout>
      <div className="mx-auto max-w-7xl space-y-7">
        <PageHeader title="Assignments & modules" description="Browse versioned learning content traced to approved TESDA sources. Assignment controls remain scoped to each owned class." />
        {!(sources.data ?? []).some((source) => source.status === "active") ? <section className="rounded-xl border border-amber-300 bg-amber-50 p-5 text-sm leading-relaxed text-amber-950">Publishing is blocked because no exact TESDA source version is active. The current legacy module catalog is retained for migration analysis only.</section> : null}
        <section className="overflow-hidden rounded-xl border border-border bg-card">{rows.length ? <div className="divide-y divide-border">{rows.map((version) => { const source = sourceById.get(version.tesda_source_id); const base = baseById.get(version.module_id); const activityCount = (activities.data ?? []).filter((activity) => activity.module_version_id === version.id).length; return <Link key={version.id} href={`/modules/${version.id}`} className="grid gap-3 px-5 py-4 transition-colors hover:bg-muted/35 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring md:grid-cols-[minmax(0,1fr)_auto_auto]"><div><p className="text-sm font-medium">{version.title} · v{version.version_number}</p><p className="mt-0.5 text-xs text-muted-foreground">{base?.coc_code ?? "Legacy module"} · {source ? `${source.qualification_code} ${source.edition || ""}`.trim() : "Source unavailable"}</p></div><div className="text-sm text-muted-foreground">{activityCount} activit{activityCount === 1 ? "y" : "ies"}</div><Badge variant={version.status === "published" ? "secondary" : "outline"}>{version.status}</Badge></Link>; })}</div> : <div className="px-5 py-16 text-center"><BookOpen className="mx-auto h-7 w-7 text-muted-foreground" aria-hidden="true" /><p className="mt-3 text-sm font-medium">No versioned module exists.</p><p className="mt-1 text-sm text-muted-foreground">Source confirmation and safe legacy mapping must happen before publication.</p></div>}</section>
      </div>
    </DashboardLayout>
  );
}
