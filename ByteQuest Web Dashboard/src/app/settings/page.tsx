import { AlertTriangle, Bell, Database, ShieldCheck, SlidersHorizontal } from "lucide-react";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { MetricStrip } from "@/components/dashboard/MetricStrip";
import { PageHeader } from "@/components/dashboard/PageHeader";
import { SystemSettingForm } from "@/components/settings/SystemSettingForm";
import { requireStaffProfile } from "@/lib/auth/server";
import { createAdminSupabaseClient } from "@/lib/supabase/admin";

export const dynamic = "force-dynamic";

export default async function SettingsPage() {
  await requireStaffProfile(["admin"]);
  const supabase = createAdminSupabaseClient();
  const { data: settings } = await supabase.from("system_settings").select("setting_key,setting_value,description,updated_at,updated_by").order("setting_key");
  const rows = settings ?? [];
  return (
    <DashboardLayout>
      <div className="mx-auto max-w-6xl space-y-7">
        <PageHeader title="Governance & settings" description="Manage audited global configuration. A setting affects behavior only when an implemented server or client consumer explicitly uses it." />
        <MetricStrip ariaLabel="Governance settings metrics" metrics={[
          { label: "Configured settings", value: rows.length, helper: "Audited system configuration records", icon: SlidersHorizontal, featured: true },
          { label: "Security controls", value: rows.filter((setting) => /security|password|session|access/i.test(setting.setting_key)).length, helper: "Settings with a security or access scope", icon: ShieldCheck, tone: "positive" },
          { label: "Notification rules", value: rows.filter((setting) => /notification/i.test(setting.setting_key)).length, helper: "Persisted notification configuration only", icon: Bell, tone: "neutral" },
          { label: "Storage controls", value: rows.filter((setting) => /storage|resource/i.test(setting.setting_key)).length, helper: "Persisted resource/storage configuration", icon: Database, tone: "neutral" },
        ]} />
        <section className="rounded-xl border border-amber-300 bg-amber-50 p-5 text-amber-950"><div className="flex gap-3"><AlertTriangle className="mt-0.5 h-5 w-5 shrink-0" aria-hidden="true" /><p className="text-sm leading-relaxed">Do not enter an unverified TESDA threshold, weight, passing rule, or reward formula here. Policy configuration must remain PENDING_TESDA_VALIDATION until supported by the approved source.</p></div></section>
        <section className="rounded-xl border border-border bg-card p-5"><h2 className="font-semibold">Create or update a setting</h2><p className="mb-5 mt-1 text-sm text-muted-foreground">Updates use an Admin-only RPC and preserve an audit record with the required reason.</p><SystemSettingForm /></section>
        <section className="overflow-hidden rounded-xl border border-border bg-card"><div className="border-b border-border px-5 py-4"><h2 className="font-semibold">Current configuration</h2></div>{rows.length ? <div className="divide-y divide-border">{rows.map((setting) => <article key={setting.setting_key} className="grid gap-3 px-5 py-4 md:grid-cols-[minmax(0,0.55fr)_minmax(0,1fr)_auto]"><div><p className="font-mono text-sm font-medium">{setting.setting_key}</p><p className="mt-1 text-xs text-muted-foreground">{setting.description || "No description"}</p></div><pre className="overflow-auto rounded-lg bg-muted p-3 text-xs">{JSON.stringify(setting.setting_value, null, 2)}</pre><time className="text-xs text-muted-foreground">{new Intl.DateTimeFormat("en-PH", { dateStyle: "medium" }).format(new Date(setting.updated_at))}</time></article>)}</div> : <p className="px-5 py-12 text-center text-sm text-muted-foreground">No global setting has been created.</p>}</section>
      </div>
    </DashboardLayout>
  );
}
