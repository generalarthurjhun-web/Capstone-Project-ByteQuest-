import Link from "next/link";
import { notFound } from "next/navigation";
import { ArrowLeft } from "lucide-react";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { requireStaffProfile } from "@/lib/auth/server";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

export default async function ModuleVersionPage({ params }: { params: Promise<{ id: string }> }) {
  await requireStaffProfile(["instructor"]);
  const { id } = await params;
  const supabase = await createServerSupabaseClient();
  const { data: version } = await supabase.from("module_versions").select("id,module_id,tesda_source_id,version_number,title,description,source_trace,content_metadata,status,created_at,published_at").eq("id", id).maybeSingle();
  if (!version) notFound();
  const [source, baseModule, activities] = await Promise.all([
    supabase.from("tesda_sources").select("qualification_code,title,edition,status,source_reference").eq("id", version.tesda_source_id).maybeSingle(),
    supabase.from("coc_modules").select("coc_code,module_name,description,status").eq("id", version.module_id).maybeSingle(),
    supabase.from("activity_versions").select("id,title,version_number,instructions,delivery_mode,status,published_at").eq("module_version_id", id).order("version_number"),
  ]);
  return (
    <DashboardLayout>
      <div className="mx-auto max-w-6xl space-y-7">
        <div><Button asChild variant="ghost" size="sm" className="-ml-3 mb-2"><Link href="/modules"><ArrowLeft className="mr-2 h-4 w-4" aria-hidden="true" />Modules</Link></Button><div className="flex flex-wrap items-center gap-3"><h1 className="text-2xl font-bold tracking-tight">{version.title}</h1><Badge variant={version.status === "published" ? "secondary" : "outline"}>{version.status}</Badge></div><p className="mt-1 text-sm text-muted-foreground">Version {version.version_number} · {baseModule.data?.coc_code ?? "legacy base module"}</p></div>
        <section className="grid gap-5 rounded-xl border border-border bg-card p-5 md:grid-cols-2"><div><h2 className="font-semibold">Version description</h2><p className="mt-2 text-sm leading-relaxed text-muted-foreground">{version.description || "No description recorded."}</p></div><div><h2 className="font-semibold">Source authority</h2><p className="mt-2 text-sm leading-relaxed">{source.data ? `${source.data.qualification_code} · ${source.data.title}${source.data.edition ? ` · ${source.data.edition}` : ""}` : "Source record unavailable"}</p><p className="mt-1 text-xs text-muted-foreground">{source.data?.source_reference}</p><Badge variant={source.data?.status === "active" ? "default" : "outline"} className="mt-3">{source.data?.status.replaceAll("_", " ") ?? "unknown"}</Badge></div><div className="md:col-span-2"><h2 className="font-semibold">Source trace</h2><pre className="mt-2 overflow-auto rounded-lg bg-muted p-4 text-xs leading-relaxed">{JSON.stringify(version.source_trace, null, 2)}</pre></div></section>
        <section className="overflow-hidden rounded-xl border border-border bg-card"><div className="border-b border-border px-5 py-4"><h2 className="font-semibold">Versioned activities</h2></div>{activities.data?.length ? <div className="divide-y divide-border">{activities.data.map((activity) => <div key={activity.id} className="grid gap-3 px-5 py-4 sm:grid-cols-[minmax(0,1fr)_auto_auto]"><div><p className="text-sm font-medium">{activity.title} · v{activity.version_number}</p><p className="mt-0.5 text-xs text-muted-foreground">{activity.instructions || "No learner instructions recorded."}</p></div><Badge variant="outline">{activity.delivery_mode}</Badge><Badge variant={activity.status === "published" ? "secondary" : "outline"}>{activity.status}</Badge></div>)}</div> : <p className="px-5 py-12 text-center text-sm text-muted-foreground">No versioned activity belongs to this module.</p>}</section>
      </div>
    </DashboardLayout>
  );
}
