import Link from "next/link";
import { CircleCheck, Shield, UserPlus, Users, UserX } from "lucide-react";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { MetricStrip } from "@/components/dashboard/MetricStrip";
import { PageHeader } from "@/components/dashboard/PageHeader";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { requireStaffProfile } from "@/lib/auth/server";
import { createAdminSupabaseClient } from "@/lib/supabase/admin";

export const dynamic = "force-dynamic";

function roleLabel(role: string) {
  if (role === "learner") return "Learner";
  if (role === "instructor") return "Instructor";
  if (role === "admin") return "Administrator";
  return "Unsupported legacy role";
}

export default async function UsersPage() {
  await requireStaffProfile(["admin"]);
  const supabase = createAdminSupabaseClient();
  const { data: profiles } = await supabase
    .from("profiles")
    .select("id,user_id,full_name,email,role,status,created_at,deactivated_at")
    .order("created_at", { ascending: false });
  const rows = profiles ?? [];
  const active = rows.filter((profile) => profile.status === "active").length;
  const inactive = rows.length - active;
  const admins = rows.filter((profile) => profile.role === "admin").length;

  return (
    <DashboardLayout>
      <div className="mx-auto max-w-7xl space-y-7">
        <PageHeader
          title="Account management"
          description="Manage real Supabase Auth profiles with independent Learner, Instructor, and Administrator roles."
          actions={<Button asChild><Link href="/users/create"><UserPlus className="mr-2 h-4 w-4" aria-hidden="true" />Create account</Link></Button>}
        />
        <MetricStrip ariaLabel="Account management metrics" metrics={[
          { label: "Total profiles", value: rows.length, helper: "Authoritative Supabase profiles", icon: Users, featured: true },
          { label: "Active accounts", value: active, helper: "Profiles currently allowed to sign in", icon: CircleCheck, tone: "positive" },
          { label: "Inactive profiles", value: inactive, helper: "Deactivated or otherwise unavailable", icon: UserX, tone: inactive ? "attention" : "neutral", href: "/users", linkLabel: "Review inactive profiles" },
          { label: "Administrators", value: admins, helper: "Accounts with Admin governance role", icon: Shield, tone: "neutral" },
        ]} />
        <section className="overflow-hidden rounded-xl border border-border bg-card">
          <div className="border-b border-border px-5 py-4"><h2 className="font-semibold">Registered accounts</h2><p className="mt-1 text-xs text-muted-foreground">{rows.length} profiles in the authoritative project</p></div>
          {rows.length ? <div className="divide-y divide-border">{rows.map((profile) => {
            const initials = profile.full_name.split(/\s+/).filter(Boolean).slice(0, 2).map((part) => part[0]?.toUpperCase()).join("") || "U";
            return <Link key={profile.user_id} href={`/users/${profile.user_id}/edit`} className="grid gap-3 px-5 py-4 transition-colors hover:bg-muted/35 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring sm:grid-cols-[minmax(0,1fr)_auto_auto] sm:items-center"><div className="flex min-w-0 items-center gap-3"><Avatar className="h-9 w-9"><AvatarFallback className="bg-primary/10 text-xs font-bold text-primary">{initials}</AvatarFallback></Avatar><div className="min-w-0"><p className="truncate text-sm font-medium">{profile.full_name}</p><p className="truncate text-xs text-muted-foreground">{profile.email}</p></div></div><div className="flex items-center gap-2 text-sm"><Shield className="h-4 w-4 text-muted-foreground" aria-hidden="true" />{roleLabel(profile.role)}</div><Badge variant={profile.status === "active" ? "secondary" : "outline"}>{profile.status}</Badge></Link>;
          })}</div> : <div className="px-5 py-16 text-center"><Users className="mx-auto h-7 w-7 text-muted-foreground" aria-hidden="true" /><p className="mt-3 text-sm font-medium">No profiles found.</p></div>}
        </section>
      </div>
    </DashboardLayout>
  );
}
