import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { CreateAccountForm } from "@/components/users/CreateAccountForm";
import { Button } from "@/components/ui/button";
import { requireStaffProfile } from "@/lib/auth/server";

export default async function CreateUserPage() {
  await requireStaffProfile(["admin"]);
  return (
    <DashboardLayout>
      <div className="mx-auto max-w-4xl space-y-7">
        <div><Button asChild variant="ghost" size="sm" className="-ml-3 mb-2"><Link href="/users"><ArrowLeft className="mr-2 h-4 w-4" aria-hidden="true" />Accounts</Link></Button><h1 className="text-2xl font-bold tracking-tight">Create a Supabase account</h1><p className="mt-1 text-sm leading-relaxed text-muted-foreground">Provision a Learner or Instructor. Administrator promotion remains a separate, audited governance action.</p></div>
        <section className="rounded-xl border border-border bg-card p-6"><CreateAccountForm /></section>
      </div>
    </DashboardLayout>
  );
}
