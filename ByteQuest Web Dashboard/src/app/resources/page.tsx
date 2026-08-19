import Link from "next/link";
import { FileImage, Files, FileText, Video } from "lucide-react";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { MetricStrip } from "@/components/dashboard/MetricStrip";
import { PageHeader } from "@/components/dashboard/PageHeader";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { requireStaffProfile } from "@/lib/auth/server";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

function formatBytes(value: number) {
  if (!value) return "0 B";
  const units = ["B", "KiB", "MiB", "GiB"];
  const index = Math.min(Math.floor(Math.log(value) / Math.log(1024)), units.length - 1);
  return `${(value / 1024 ** index).toFixed(index ? 1 : 0)} ${units[index]}`;
}

function ResourceIcon({ mimeType }: { mimeType: string }) {
  if (mimeType.startsWith("image/")) return <FileImage className="h-4 w-4" aria-hidden="true" />;
  if (mimeType.startsWith("video/")) return <Video className="h-4 w-4" aria-hidden="true" />;
  return <FileText className="h-4 w-4" aria-hidden="true" />;
}

export default async function ResourcesPage() {
  await requireStaffProfile(["instructor"]);
  const supabase = await createServerSupabaseClient();
  const [resourceResult, classResult] = await Promise.all([
    supabase
      .from("learning_resources")
      .select("id,class_id,title,description,mime_type,size_bytes,status,created_at,deletion_reason")
      .order("created_at", { ascending: false }),
    supabase.from("classes").select("id,title,status").order("title"),
  ]);

  if (resourceResult.error || classResult.error) {
    throw new Error("The learning-resource summary could not be loaded.");
  }

  const resources = resourceResult.data;
  const classes = classResult.data;
  const rows = resources ?? [];
  const classById = new Map((classes ?? []).map((classroom) => [classroom.id, classroom]));
  const activeRows = rows.filter((resource) => resource.status === "active");
  const totalBytes = activeRows.reduce((total, resource) => total + Number(resource.size_bytes || 0), 0);
  const classCount = new Set(activeRows.map((resource) => resource.class_id)).size;

  return (
    <DashboardLayout>
      <div className="mx-auto max-w-7xl space-y-7">
        <PageHeader
          title="Learning resources"
          description="Manage the private files attached to your owned classes. Learners receive authorized access only through their active class scope."
          actions={
            <Button asChild>
              <Link href="/classes">Open a class to upload</Link>
            </Button>
          }
        />

        <MetricStrip
          ariaLabel="Learning resource metrics"
          metrics={[
            {
              label: "Active resources",
              value: activeRows.length,
              helper: "Available to authorized class members",
              icon: Files,
              featured: true,
              href: "#resource-library",
              linkLabel: "Open the active resource library",
            },
            {
              label: "Classes with resources",
              value: classCount,
              helper: "Owned classes with active resources",
              icon: FileText,
              href: "/classes",
              linkLabel: "Open owned classes",
            },
            {
              label: "Archived resources",
              value: rows.length - activeRows.length,
              helper: "Retained outside learner access",
              icon: FileImage,
              tone: "neutral",
            },
            {
              label: "Authorized storage",
              value: formatBytes(totalBytes),
              helper: "Active private resource objects",
              icon: Video,
              tone: "neutral",
            },
          ]}
        />

        <section id="resource-library" className="scroll-mt-24 overflow-hidden rounded-xl border border-border bg-card shadow-xs">
          <div className="border-b border-border/80 px-5 py-4">
            <h2 className="font-semibold">Resource library</h2>
            <p className="mt-1 text-sm text-muted-foreground">
              Upload, archive, and deletion controls remain inside the owning class workspace.
            </p>
          </div>
          {rows.length ? (
            <div className="divide-y divide-border/80">
              {rows.map((resource) => {
                const classroom = classById.get(resource.class_id);
                return (
                  <Link
                    key={resource.id}
                    href={`/classes/${resource.class_id}?tab=resources`}
                    className="grid gap-3 px-5 py-4 transition-colors duration-150 hover:bg-muted/35 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-ring md:grid-cols-[minmax(0,1fr)_minmax(180px,0.45fr)_auto_auto] md:items-center"
                  >
                    <div className="flex min-w-0 items-start gap-3">
                      <span className="mt-0.5 flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-primary/[0.07] text-primary">
                        <ResourceIcon mimeType={resource.mime_type ?? "application/octet-stream"} />
                      </span>
                      <div className="min-w-0">
                        <p className="truncate text-sm font-semibold">{resource.title}</p>
                        <p className="mt-1 line-clamp-1 text-xs text-muted-foreground">
                          {resource.description || resource.mime_type}
                        </p>
                      </div>
                    </div>
                    <div className="min-w-0">
                      <p className="truncate text-sm font-medium">{classroom?.title ?? "Owned class"}</p>
                      <p className="mt-0.5 text-xs text-muted-foreground">Private class resource</p>
                    </div>
                    <span className="text-xs tabular-nums text-muted-foreground">{formatBytes(Number(resource.size_bytes))}</span>
                    <Badge variant={resource.status === "active" ? "secondary" : "outline"}>
                      {resource.status.replaceAll("_", " ")}
                    </Badge>
                  </Link>
                );
              })}
            </div>
          ) : (
            <div className="px-5 py-16 text-center">
              <span className="mx-auto flex h-11 w-11 items-center justify-center rounded-xl bg-muted text-muted-foreground">
                <Files className="h-5 w-5" aria-hidden="true" />
              </span>
              <p className="mt-4 text-sm font-semibold">No learning resources yet</p>
              <p className="mx-auto mt-1 max-w-md text-sm text-muted-foreground">
                Open an active class to upload a validated PDF, image, or supported video resource.
              </p>
            </div>
          )}
        </section>
      </div>
    </DashboardLayout>
  );
}
