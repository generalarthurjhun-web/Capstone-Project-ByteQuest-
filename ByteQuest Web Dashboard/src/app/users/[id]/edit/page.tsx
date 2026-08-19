import Link from "next/link";
import { notFound } from "next/navigation";
import { ArrowLeft } from "lucide-react";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { AccountActions } from "@/components/users/AccountActions";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { requireStaffProfile } from "@/lib/auth/server";
import { createAdminSupabaseClient } from "@/lib/supabase/admin";
import type { AccountStatus, UserRole } from "@/types/auth";

export const dynamic = "force-dynamic";

export default async function EditUserPage({ params }: { params: Promise<{ id: string }> }) {
  await requireStaffProfile(["admin"]);
  const { id } = await params;
  const supabase = createAdminSupabaseClient();
  const { data: profile } = await supabase.from("profiles").select("user_id,full_name,email,role,status,created_at,deactivated_at,deactivation_reason").eq("user_id", id).maybeSingle();
  if (!profile) notFound();

  return (
    <DashboardLayout>
      <div className="mx-auto max-w-4xl space-y-7">
        <div><Button asChild variant="ghost" size="sm" className="-ml-3 mb-2"><Link href="/users"><ArrowLeft className="mr-2 h-4 w-4" aria-hidden="true" />Accounts</Link></Button><div className="flex flex-wrap items-center gap-3"><h1 className="text-2xl font-bold tracking-tight">{profile.full_name}</h1><Badge variant={profile.status === "active" ? "secondary" : "outline"}>{profile.status}</Badge></div><p className="mt-1 text-sm text-muted-foreground">{profile.email}</p></div>
        <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_18rem]">
          <section className="rounded-xl border border-border bg-card p-6"><h2 className="font-semibold">Access governance</h2><p className="mb-5 mt-1 text-sm leading-relaxed text-muted-foreground">Change role or lifecycle status through verified Admin RPCs. The database prevents self-demotion and self-deactivation.</p><AccountActions userId={profile.user_id} targetEmail={profile.email} currentRole={profile.role as UserRole} currentStatus={profile.status as AccountStatus} /></section>
          <aside className="h-fit rounded-xl border border-border bg-card p-5"><h2 className="font-semibold">Account record</h2><dl className="mt-4 space-y-4 text-sm"><div><dt className="text-xs font-medium uppercase tracking-wide text-muted-foreground">User ID</dt><dd className="mt-1 break-all font-mono text-xs">{profile.user_id}</dd></div><div><dt className="text-xs font-medium uppercase tracking-wide text-muted-foreground">Created</dt><dd className="mt-1">{new Intl.DateTimeFormat("en-PH", { dateStyle: "medium" }).format(new Date(profile.created_at))}</dd></div>{profile.deactivation_reason ? <div><dt className="text-xs font-medium uppercase tracking-wide text-muted-foreground">Deactivation reason</dt><dd className="mt-1 leading-relaxed">{profile.deactivation_reason}</dd></div> : null}</dl></aside>
        </div>
      </div>
    </DashboardLayout>
  );
}
