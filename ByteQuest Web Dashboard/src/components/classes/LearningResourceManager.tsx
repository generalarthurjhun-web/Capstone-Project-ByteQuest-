"use client";

import { useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { Download, FileUp, Loader2, Trash2 } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";

export interface LearningResourceItem {
  id: string;
  title: string;
  description: string | null;
  mime_type: string | null;
  size_bytes: number | null;
  status: "active" | "deleted";
  created_at: string;
  deletion_reason: string | null;
}

function readableSize(bytes: number | null) {
  if (!bytes) return "Size unavailable";
  if (bytes < 1024 * 1024) return `${Math.ceil(bytes / 1024)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

export function LearningResourceManager({
  classId,
  classActive,
  resources,
}: {
  classId: string;
  classActive: boolean;
  resources: LearningResourceItem[];
}) {
  const router = useRouter();
  const fileInput = useRef<HTMLInputElement>(null);
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [file, setFile] = useState<File | null>(null);
  const [uploading, setUploading] = useState(false);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [deleteReason, setDeleteReason] = useState("");

  const upload = async (event: React.FormEvent) => {
    event.preventDefault();
    if (!file || title.trim().length < 2) {
      toast.error("Choose an allowed file and provide a clear title.");
      return;
    }

    setUploading(true);
    const body = new FormData();
    body.set("file", file);
    body.set("title", title.trim());
    body.set("description", description.trim());
    const response = await fetch(`/api/classes/${classId}/resources`, { method: "POST", body });
    const payload = (await response.json()) as { error?: string };
    if (!response.ok) {
      toast.error(payload.error || "Resource upload failed.");
      setUploading(false);
      return;
    }

    setTitle("");
    setDescription("");
    setFile(null);
    if (fileInput.current) fileInput.current.value = "";
    toast.success("Learning resource uploaded and class access applied.");
    router.refresh();
    setUploading(false);
  };

  const archive = async (resourceId: string) => {
    if (deleteReason.trim().length < 5) {
      toast.error("Provide a clear archive reason.");
      return;
    }
    const response = await fetch(`/api/classes/${classId}/resources/${resourceId}`, {
      method: "DELETE",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ reason: deleteReason.trim() }),
    });
    const payload = (await response.json()) as { error?: string };
    if (!response.ok) {
      toast.error(payload.error || "Resource archive failed.");
      return;
    }
    toast.success("Resource archived. Its audit history was retained.");
    setDeletingId(null);
    setDeleteReason("");
    router.refresh();
  };

  return (
    <div className="space-y-5">
      {classActive ? (
        <form onSubmit={upload} className="grid gap-4 rounded-xl border border-border bg-card p-5 md:grid-cols-2">
          <div className="space-y-2">
            <Label htmlFor="resource-title">Resource title</Label>
            <Input id="resource-title" value={title} onChange={(event) => setTitle(event.target.value)} minLength={2} maxLength={300} required />
          </div>
          <div className="space-y-2">
            <Label htmlFor="resource-file">File</Label>
            <Input ref={fileInput} id="resource-file" type="file" accept=".pdf,.jpg,.jpeg,.png,.webp,.mp4,.webm" onChange={(event) => setFile(event.target.files?.[0] ?? null)} required />
            <p className="text-xs leading-relaxed text-muted-foreground">PDF, JPEG, PNG, WebP, MP4, or WebM. Maximum 50 MB.</p>
          </div>
          <div className="space-y-2 md:col-span-2">
            <Label htmlFor="resource-description">Description (optional)</Label>
            <Textarea id="resource-description" value={description} onChange={(event) => setDescription(event.target.value)} maxLength={2000} rows={3} />
          </div>
          <div className="md:col-span-2">
            <Button type="submit" disabled={uploading}>
              {uploading ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <FileUp className="mr-2 h-4 w-4" />}
              {uploading ? "Uploading securely…" : "Upload resource"}
            </Button>
          </div>
        </form>
      ) : null}

      <section className="overflow-hidden rounded-xl border border-border bg-card">
        <div className="border-b border-border px-5 py-4">
          <h2 className="font-semibold">Class learning resources</h2>
          <p className="mt-1 text-sm text-muted-foreground">Only active class members can open active files.</p>
        </div>
        {resources.length ? (
          <div className="divide-y divide-border">
            {resources.map((resource) => (
              <div key={resource.id} className="px-5 py-4">
                <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
                  <div className="min-w-0">
                    <p className="font-medium">{resource.title}</p>
                    {resource.description ? <p className="mt-1 text-sm leading-relaxed text-muted-foreground">{resource.description}</p> : null}
                    <p className="mt-1 text-xs text-muted-foreground">{resource.mime_type ?? "Unknown type"} · {readableSize(resource.size_bytes)} · {new Intl.DateTimeFormat("en-PH", { dateStyle: "medium" }).format(new Date(resource.created_at))}</p>
                    {resource.deletion_reason ? <p className="mt-1 text-xs text-muted-foreground">Archived reason: {resource.deletion_reason}</p> : null}
                  </div>
                  <div className="flex shrink-0 flex-wrap items-center gap-2">
                    {resource.status === "active" ? (
                      <>
                        <Button asChild size="sm" variant="outline">
                          <a href={`/api/classes/${classId}/resources/${resource.id}`} target="_blank" rel="noreferrer"><Download className="mr-2 h-4 w-4" />Open</a>
                        </Button>
                        <Button type="button" size="sm" variant="ghost" className="text-destructive hover:text-destructive" onClick={() => setDeletingId(resource.id)}><Trash2 className="mr-2 h-4 w-4" />Archive</Button>
                      </>
                    ) : (
                      <span className="rounded-md border border-border px-2 py-1 text-xs text-muted-foreground">Archived</span>
                    )}
                  </div>
                </div>
                {deletingId === resource.id ? (
                  <div className="mt-4 flex flex-col gap-3 rounded-lg bg-muted/50 p-3 sm:flex-row sm:items-end">
                    <div className="flex-1 space-y-2"><Label htmlFor={`resource-delete-${resource.id}`}>Required archive reason</Label><Input id={`resource-delete-${resource.id}`} value={deleteReason} onChange={(event) => setDeleteReason(event.target.value)} minLength={5} maxLength={1000} /></div>
                    <div className="flex gap-2"><Button type="button" variant="ghost" size="sm" onClick={() => { setDeletingId(null); setDeleteReason(""); }}>Cancel</Button><Button type="button" variant="destructive" size="sm" onClick={() => archive(resource.id)}>Confirm archive</Button></div>
                  </div>
                ) : null}
              </div>
            ))}
          </div>
        ) : (
          <p className="px-5 py-10 text-center text-sm text-muted-foreground">No learning resource has been uploaded for this class.</p>
        )}
      </section>
    </div>
  );
}
