"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { z } from "zod";
import { Loader2, Plus } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { createClient } from "@/lib/supabase/client";

const classSchema = z.object({
  title: z.string().trim().min(2).max(160),
  code: z.string().trim().max(40).optional(),
});

export function CreateClassForm() {
  const router = useRouter();
  const [title, setTitle] = useState("");
  const [code, setCode] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    const parsed = classSchema.safeParse({ title, code: code || undefined });
    if (!parsed.success) {
      toast.error("Enter a class name between 2 and 160 characters.");
      return;
    }

    setSubmitting(true);
    const { error } = await createClient().rpc("create_class", {
      p_title: parsed.data.title,
      p_class_code: parsed.data.code ?? undefined,
    });

    if (error) {
      toast.error(error.code === "23505" ? "That class code is already in use." : error.message);
      setSubmitting(false);
      return;
    }

    setTitle("");
    setCode("");
    toast.success("Class created.");
    router.refresh();
    setSubmitting(false);
  };

  return (
    <form onSubmit={handleSubmit} className="grid gap-4 sm:grid-cols-[minmax(0,1fr)_180px_auto] sm:items-end">
      <div className="space-y-2">
        <Label htmlFor="class-title">Class name</Label>
        <Input
          id="class-title"
          value={title}
          onChange={(event) => setTitle(event.target.value)}
          placeholder="CSS NC II — Section A"
          maxLength={160}
          required
        />
      </div>
      <div className="space-y-2">
        <Label htmlFor="class-code">Class code (optional)</Label>
        <Input
          id="class-code"
          value={code}
          onChange={(event) => setCode(event.target.value)}
          placeholder="CSS2-A"
          maxLength={40}
        />
      </div>
      <Button type="submit" disabled={submitting} className="min-h-10">
        {submitting ? (
          <Loader2 className="mr-2 h-4 w-4 animate-spin" />
        ) : (
          <Plus className="mr-2 h-4 w-4" />
        )}
        Create class
      </Button>
    </form>
  );
}
