import Link from "next/link";
import { Activity, CalendarDays, GraduationCap, Users } from "lucide-react";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { CreateClassForm } from "@/components/classes/CreateClassForm";
import { MetricStrip, type Metric } from "@/components/dashboard/MetricStrip";
import { PageHeader } from "@/components/dashboard/PageHeader";
import { Badge } from "@/components/ui/badge";
import { requireStaffProfile } from "@/lib/auth/server";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

export default async function ClassesPage() {
  await requireStaffProfile(["instructor"]);
  const supabase = await createServerSupabaseClient();

  const [{ data: classes }, { data: memberships }] = await Promise.all([
    supabase
      .from("classes")
      .select("id,title,class_code,status,created_at")
      .order("created_at", { ascending: false }),
    supabase
      .from("class_memberships")
      .select("class_id,status")
      .eq("status", "active"),
  ]);

  const memberCountByClass = new Map<string, number>();
  (memberships ?? []).forEach((membership) => {
    memberCountByClass.set(
      membership.class_id,
      (memberCountByClass.get(membership.class_id) ?? 0) + 1,
    );
  });

  const classRows = classes ?? [];
  const activeClassCount = classRows.filter((row) => row.status === "active").length;
  const totalActiveLearners = (memberships ?? []).length;
  const metrics: Metric[] = [
    { label: "Total classes", value: classRows.length, helper: "Classes in your Instructor scope", icon: GraduationCap, href: "#class-roster", linkLabel: "Jump to class roster", featured: true },
    { label: "Active classes", value: activeClassCount, helper: "Currently open for teaching", icon: Activity, tone: "positive", href: "#class-roster", linkLabel: "View active classes" },
    { label: "Active learners", value: totalActiveLearners, helper: "Current active memberships", icon: Users, href: "/progress", linkLabel: "Open learner monitoring" },
    { label: "Other class states", value: Math.max(0, classRows.length - activeClassCount), helper: "Draft or archived classes", icon: CalendarDays, tone: "neutral", href: "#class-roster", linkLabel: "Review class states" },
  ];

  return (
    <DashboardLayout>
      <div className="mx-auto max-w-6xl space-y-7">
        <PageHeader
          title="Classes"
          description="Create and manage the learner boundary for enrollment, assignments, resources, assessment review, and analytics."
        />

        <MetricStrip metrics={metrics} ariaLabel="Class overview metrics" />

        <section className="rounded-xl border border-border bg-card p-5">
          <h2 className="font-semibold text-foreground">Create a class</h2>
          <p className="mb-4 mt-1 text-sm text-muted-foreground">
            You become the scoped Instructor owner. Ownership cannot be changed by the client.
          </p>
          <CreateClassForm />
        </section>

        <section id="class-roster" className="overflow-hidden rounded-xl border border-border bg-card">
          <div className="border-b border-border px-5 py-4">
            <h2 className="font-semibold text-foreground">Your class roster</h2>
          </div>
          {classRows.length ? (
            <div className="divide-y divide-border">
              {classRows.map((classroom) => (
                <Link
                  key={classroom.id}
                  href={`/classes/${classroom.id}`}
                  className="grid gap-3 px-5 py-4 transition-colors hover:bg-muted/35 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring sm:grid-cols-[minmax(0,1fr)_auto_auto] sm:items-center"
                >
                  <div className="min-w-0">
                    <p className="truncate font-medium text-foreground">{classroom.title}</p>
                    <p className="mt-0.5 text-xs text-muted-foreground">
                      {classroom.class_code || "No class code"}
                    </p>
                  </div>
                  <div className="flex items-center gap-2 text-sm text-muted-foreground">
                    <Users className="h-4 w-4" aria-hidden="true" />
                    <span className="tabular-nums">
                      {memberCountByClass.get(classroom.id) ?? 0} learners
                    </span>
                  </div>
                  <div className="flex items-center gap-3">
                    <span className="hidden items-center gap-1.5 text-xs text-muted-foreground md:flex">
                      <CalendarDays className="h-3.5 w-3.5" aria-hidden="true" />
                      {new Intl.DateTimeFormat("en-PH", { dateStyle: "medium" }).format(
                        new Date(classroom.created_at),
                      )}
                    </span>
                    <Badge variant={classroom.status === "active" ? "secondary" : "outline"}>
                      {classroom.status}
                    </Badge>
                  </div>
                </Link>
              ))}
            </div>
          ) : (
            <div className="px-5 py-12 text-center">
              <p className="text-sm font-medium text-foreground">No classes yet.</p>
              <p className="mt-1 text-sm text-muted-foreground">
                Use the form above to establish the first enrollment boundary.
              </p>
            </div>
          )}
        </section>
      </div>
    </DashboardLayout>
  );
}
