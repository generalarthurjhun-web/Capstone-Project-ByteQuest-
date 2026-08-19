import Link from "next/link";
import { notFound } from "next/navigation";
import { ArrowLeft, BookOpenCheck, Files, ShieldCheck, Users } from "lucide-react";
import {
  ArchiveClassForm,
  AssignmentAccessPolicyForm,
  AssignActivityForm,
  CloseAssignmentForm,
  DeactivateLearnerAccountForm,
  DeactivateMembershipForm,
  EnrollLearnerForm,
  GrantBypassForm,
} from "@/components/classes/ClassManagementForms";
import {
  LearningResourceManager,
  type LearningResourceItem,
} from "@/components/classes/LearningResourceManager";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { MetricStrip, type Metric } from "@/components/dashboard/MetricStrip";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { requireStaffProfile } from "@/lib/auth/server";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

export default async function ClassDetailPage({
  params,
  searchParams,
}: {
  params: Promise<{ id: string }>;
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}) {
  await requireStaffProfile(["instructor"]);
  const { id } = await params;
  const query = await searchParams;
  const requestedTab = Array.isArray(query.tab) ? query.tab[0] : query.tab;
  const defaultTab = ["learners", "assignments", "resources", "bypasses", "settings"].includes(
    requestedTab ?? "",
  )
    ? requestedTab
    : "learners";
  const supabase = await createServerSupabaseClient();

  const { data: classroom } = await supabase
    .from("classes")
    .select("id,title,class_code,status,created_at,archive_reason")
    .eq("id", id)
    .maybeSingle();

  if (!classroom) notFound();

  const [membershipResult, assignmentResult, activityResult, rubricResult, moduleResult, bypassResult, resourceResult] =
    await Promise.all([
      supabase
        .from("class_memberships")
        .select("id,learner_id,status,enrolled_at,deactivated_at,deactivation_reason")
        .eq("class_id", id)
        .order("enrolled_at", { ascending: false }),
      supabase
        .from("assignments")
        .select("id,title,assignment_type,status,created_at,due_at,activity_version_id,attempts_allowed,retry_enabled,retry_after_seconds,prerequisite_assignment_id")
        .eq("class_id", id)
        .order("created_at", { ascending: false }),
      supabase
        .from("activity_versions")
        .select("id,title,delivery_mode,module_version_id")
        .eq("status", "published")
        .order("title"),
      supabase
        .from("rubric_versions")
        .select("id,title,activity_version_id")
        .eq("status", "approved")
        .order("title"),
      supabase
        .from("module_versions")
        .select("id,title")
        .eq("status", "published")
        .order("title"),
      supabase
        .from("coc_bypasses")
        .select("id,learner_id,module_version_id,reason,granted_at,revoked_at")
        .eq("class_id", id)
        .order("granted_at", { ascending: false }),
      supabase
        .from("learning_resources")
        .select("id,title,description,mime_type,size_bytes,status,created_at,deletion_reason")
        .eq("class_id", id)
        .order("created_at", { ascending: false }),
    ]);

  const memberships = membershipResult.data ?? [];
  const learnerIds = [...new Set(memberships.map((membership) => membership.learner_id))];
  const { data: profiles } = learnerIds.length
    ? await supabase
        .from("profiles")
        .select("user_id,full_name,email,status")
        .in("user_id", learnerIds)
    : { data: [] };
  const profileById = new Map((profiles ?? []).map((profile) => [profile.user_id, profile]));
  const activeLearners = memberships
    .filter((membership) => membership.status === "active")
    .map((membership) => ({
      id: membership.learner_id,
      name: profileById.get(membership.learner_id)?.full_name ?? "Learner",
    }));
  const activityById = new Map(
    (activityResult.data ?? []).map((activity) => [activity.id, activity.title]),
  );
  const moduleById = new Map(
    (moduleResult.data ?? []).map((module) => [module.id, module.title]),
  );
  const activeAssignmentCount = (assignmentResult.data ?? []).filter((row) => row.status === "active").length;
  const activeBypassCount = (bypassResult.data ?? []).filter((row) => !row.revoked_at).length;
  const activeResourceCount = (resourceResult.data ?? []).filter((row) => row.status === "active").length;
  const classMetrics: Metric[] = [
    { label: "Active learners", value: activeLearners.length, helper: "Current active memberships", icon: Users, tone: "informational", href: "#learners", linkLabel: "View class learners", featured: true },
    { label: "Active assignments", value: activeAssignmentCount, helper: "Published or open content in this class", icon: BookOpenCheck, href: "#assignments", linkLabel: "View class assignments" },
    { label: "Access bypasses", value: activeBypassCount, helper: "Practice access grants still active", icon: ShieldCheck, tone: "attention", href: "#bypasses", linkLabel: "View access bypasses" },
    { label: "Active resources", value: activeResourceCount, helper: "Private resources available to this class", icon: Files, tone: "positive", href: "#resources", linkLabel: "View class resources" },
  ];

  return (
    <DashboardLayout>
      <div className="mx-auto max-w-7xl space-y-7">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <Button asChild variant="ghost" size="sm" className="-ml-3 mb-2">
              <Link href="/classes">
                <ArrowLeft className="mr-2 h-4 w-4" aria-hidden="true" />
                All classes
              </Link>
            </Button>
            <div className="flex flex-wrap items-center gap-3">
              <h1 className="text-2xl font-bold tracking-tight text-foreground">{classroom.title}</h1>
              <Badge variant={classroom.status === "active" ? "secondary" : "outline"}>
                {classroom.status}
              </Badge>
            </div>
            <p className="mt-1 text-sm text-muted-foreground">
              {classroom.class_code || "No class code"} · Instructor-scoped workspace
            </p>
          </div>
        </div>

        <MetricStrip metrics={classMetrics} ariaLabel="Class detail metrics" />

        <Tabs defaultValue={defaultTab} className="space-y-5">
          <TabsList className="h-auto flex-wrap justify-start">
            <TabsTrigger value="learners">Learners</TabsTrigger>
            <TabsTrigger value="assignments">Assignments</TabsTrigger>
            <TabsTrigger value="resources">Resources</TabsTrigger>
            <TabsTrigger value="bypasses">Access bypass</TabsTrigger>
            <TabsTrigger value="settings">Class settings</TabsTrigger>
          </TabsList>

          <TabsContent id="learners" value="learners" className="space-y-5">
            {classroom.status === "active" ? (
              <section className="rounded-xl border border-border bg-card p-5">
                <h2 className="font-semibold">Enroll a registered learner</h2>
                <p className="mb-4 mt-1 text-sm text-muted-foreground">Enrollment uses the learner&apos;s existing Supabase account and preserves class history.</p>
                <EnrollLearnerForm classId={id} />
              </section>
            ) : null}
            <section className="overflow-hidden rounded-xl border border-border bg-card">
              <div className="border-b border-border px-5 py-4"><h2 className="font-semibold">Membership history</h2></div>
              {memberships.length ? <div className="divide-y divide-border">{memberships.map((membership) => {
                const learner = profileById.get(membership.learner_id);
                return <div key={membership.id} className="flex flex-col gap-3 px-5 py-4 sm:flex-row sm:items-start sm:justify-between"><div><p className="text-sm font-medium">{learner?.full_name ?? "Learner"}</p><p className="mt-0.5 text-xs text-muted-foreground">{learner?.email ?? "Email unavailable"} · enrolled {new Intl.DateTimeFormat("en-PH", { dateStyle: "medium" }).format(new Date(membership.enrolled_at))}</p>{membership.deactivation_reason ? <p className="mt-1 text-xs text-muted-foreground">Reason: {membership.deactivation_reason}</p> : null}</div><div className="flex flex-col items-end gap-2"><Badge variant={membership.status === "active" ? "secondary" : "outline"}>{membership.status}</Badge>{membership.status === "active" && classroom.status === "active" ? <div className="flex flex-col items-end gap-2"><DeactivateMembershipForm membershipId={membership.id} learnerName={learner?.full_name ?? "Learner"} /><DeactivateLearnerAccountForm learnerId={membership.learner_id} learnerName={learner?.full_name ?? "Learner"} /></div> : null}</div></div>;
              })}</div> : <p className="px-5 py-10 text-center text-sm text-muted-foreground">No learner has been enrolled.</p>}
            </section>
          </TabsContent>

          <TabsContent id="assignments" value="assignments" className="space-y-5">
            {classroom.status === "active" ? <section className="rounded-xl border border-border bg-card p-5"><h2 className="font-semibold">Assign published content</h2><p className="mb-4 mt-1 text-sm text-muted-foreground">Assessment assignment remains gated by an approved source and matching approved rubric.</p><AssignActivityForm classId={id} activities={(activityResult.data ?? []).map((row) => ({ id: row.id, title: row.title, deliveryMode: row.delivery_mode }))} rubrics={(rubricResult.data ?? []).map((row) => ({ id: row.id, title: row.title, activityVersionId: row.activity_version_id }))} /></section> : null}
            <section className="overflow-hidden rounded-xl border border-border bg-card">
              <div className="border-b border-border px-5 py-4">
                <h2 className="font-semibold">Assignment history</h2>
                <p className="mt-1 text-xs text-muted-foreground">
                  Retry limits and prerequisites are configurable institutional rules, not TESDA numeric requirements.
                </p>
              </div>
              {assignmentResult.data?.length ? (
                <div className="divide-y divide-border">
                  {assignmentResult.data.map((assignment) => {
                    const prerequisiteTitle = assignment.prerequisite_assignment_id
                      ? assignmentResult.data?.find((row) => row.id === assignment.prerequisite_assignment_id)?.title
                      : null;
                    const otherAssignments = (assignmentResult.data ?? [])
                      .filter((row) => row.id !== assignment.id && row.status === "active")
                      .map((row) => ({ id: row.id, title: row.title }));
                    return (
                      <div key={assignment.id} className="px-5 py-4">
                        <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                          <div className="min-w-0">
                            <p className="text-sm font-semibold">{assignment.title}</p>
                            <p className="mt-1 text-xs text-muted-foreground">
                              {activityById.get(assignment.activity_version_id) ?? "Versioned activity"} · {assignment.assignment_type}
                            </p>
                            <div className="mt-3 flex flex-wrap gap-2 text-xs text-muted-foreground">
                              <span className="rounded-md border border-border px-2 py-1">
                                {assignment.attempts_allowed === null
                                  ? "No attempt limit configured"
                                  : `${assignment.attempts_allowed} attempt limit`}
                              </span>
                              <span className="rounded-md border border-border px-2 py-1">
                                {assignment.retry_enabled ? "Retry enabled" : "Retry disabled"}
                              </span>
                              {assignment.retry_after_seconds !== null ? (
                                <span className="rounded-md border border-border px-2 py-1">
                                  Retry after {Math.ceil(assignment.retry_after_seconds / 60)} min
                                </span>
                              ) : null}
                              {prerequisiteTitle ? (
                                <span className="rounded-md border border-border px-2 py-1">
                                  Requires: {prerequisiteTitle}
                                </span>
                              ) : null}
                            </div>
                          </div>
                          <div className="flex flex-wrap items-center gap-2">
                            <Badge variant={assignment.status === "active" ? "secondary" : "outline"}>
                              {assignment.status}
                            </Badge>
                            {assignment.status === "active" ? (
                              <>
                                <AssignmentAccessPolicyForm
                                  assignment={{
                                    id: assignment.id,
                                    attemptsAllowed: assignment.attempts_allowed,
                                    retryEnabled: assignment.retry_enabled,
                                    retryAfterSeconds: assignment.retry_after_seconds,
                                    prerequisiteAssignmentId: assignment.prerequisite_assignment_id,
                                  }}
                                  prerequisiteOptions={otherAssignments}
                                />
                                <CloseAssignmentForm assignmentId={assignment.id} />
                              </>
                            ) : null}
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              ) : (
                <p className="px-5 py-10 text-center text-sm text-muted-foreground">No activity has been assigned.</p>
              )}
            </section>
          </TabsContent>

          <TabsContent id="resources" value="resources">
            <LearningResourceManager
              classId={id}
              classActive={classroom.status === "active"}
              resources={(resourceResult.data ?? []) as LearningResourceItem[]}
            />
          </TabsContent>

          <TabsContent id="bypasses" value="bypasses" className="space-y-5">
            <section className="rounded-xl border border-border bg-card p-5"><h2 className="font-semibold">Grant access-only bypass</h2><p className="mb-4 mt-1 text-sm leading-relaxed text-muted-foreground">A bypass unlocks access only. It never marks competency, assigns a score, or grants XP.</p><GrantBypassForm classId={id} learners={activeLearners} modules={moduleResult.data ?? []} /></section>
            <section className="overflow-hidden rounded-xl border border-border bg-card"><div className="border-b border-border px-5 py-4"><h2 className="font-semibold">Bypass audit trail</h2></div>{bypassResult.data?.length ? <div className="divide-y divide-border">{bypassResult.data.map((bypass) => <div key={bypass.id} className="px-5 py-4"><div className="flex items-start justify-between gap-4"><div><p className="text-sm font-medium">{profileById.get(bypass.learner_id)?.full_name ?? "Learner"} · {moduleById.get(bypass.module_version_id) ?? "Module version"}</p><p className="mt-1 text-xs text-muted-foreground">{bypass.reason}</p></div><Badge variant={bypass.revoked_at ? "outline" : "secondary"}>{bypass.revoked_at ? "revoked" : "active"}</Badge></div></div>)}</div> : <p className="px-5 py-10 text-center text-sm text-muted-foreground">No access bypass has been granted.</p>}</section>
          </TabsContent>

          <TabsContent value="settings">
            <section className="rounded-xl border border-destructive/30 bg-card p-5"><h2 className="font-semibold">Archive class</h2><p className="mb-4 mt-1 max-w-2xl text-sm leading-relaxed text-muted-foreground">Archiving stops new scoped operations while retaining memberships, assignments, attempts, and audit history.</p>{classroom.status === "active" ? <ArchiveClassForm classId={id} /> : <p className="text-sm text-muted-foreground">Archived: {classroom.archive_reason}</p>}</section>
          </TabsContent>
        </Tabs>
      </div>
    </DashboardLayout>
  );
}
