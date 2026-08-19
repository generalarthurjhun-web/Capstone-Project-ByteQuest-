"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Loader2 } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { createClient } from "@/lib/supabase/client";
import type { Json } from "@/types/database.generated";

export function SystemSettingForm() {
  const router = useRouter();
  const [key, setKey] = useState("");
  const [value, setValue] = useState("{}");
  const [description, setDescription] = useState("");
  const [reason, setReason] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    let parsed: Json;
    try {
      parsed = JSON.parse(value) as Json;
    } catch {
      toast.error("Setting value must be valid JSON.");
      return;
    }
    if (!/^[a-z][a-z0-9_.-]{2,79}$/.test(key) || reason.trim().length < 5) {
      toast.error("Use a stable lowercase key and provide a clear governance reason.");
      return;
    }
    setSubmitting(true);
    const { error } = await createClient().rpc("admin_update_system_setting", {
      p_setting_key: key,
      p_setting_value: parsed,
      p_description: description.trim(),
      p_reason: reason.trim(),
    });
    if (error) toast.error(error.message);
    else {
      toast.success("System setting saved and audited.");
      setKey(""); setValue("{}"); setDescription(""); setReason("");
      router.refresh();
    }
    setSubmitting(false);
  };

  return (
    <form onSubmit={handleSubmit} className="grid gap-4 sm:grid-cols-2">
      <div className="space-y-2"><Label htmlFor="setting-key">Setting key</Label><Input id="setting-key" value={key} onChange={(event) => setKey(event.target.value)} placeholder="feature.example" required /></div>
      <div className="space-y-2"><Label htmlFor="setting-description">Description</Label><Input id="setting-description" value={description} onChange={(event) => setDescription(event.target.value)} required /></div>
      <div className="space-y-2 sm:col-span-2"><Label htmlFor="setting-value">JSON value</Label><Textarea id="setting-value" value={value} onChange={(event) => setValue(event.target.value)} rows={5} className="font-mono text-sm" required /></div>
      <div className="space-y-2 sm:col-span-2"><Label htmlFor="setting-reason">Required change reason</Label><Textarea id="setting-reason" value={reason} onChange={(event) => setReason(event.target.value)} rows={3} required /></div>
      <div className="sm:col-span-2"><Button type="submit" disabled={submitting}>{submitting ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}Save audited setting</Button></div>
    </form>
  );
}
