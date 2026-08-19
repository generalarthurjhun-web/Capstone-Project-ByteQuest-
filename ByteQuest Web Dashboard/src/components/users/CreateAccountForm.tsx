"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Loader2, UserPlus } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";

export function CreateAccountForm() {
  const router = useRouter();
  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [role, setRole] = useState<"learner" | "instructor">("instructor");
  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    setSubmitting(true);
    const response = await fetch("/api/admin/users", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ fullName, email, password, role }),
    });
    const payload = (await response.json()) as { error?: string };
    if (!response.ok) {
      toast.error(payload.error || "Account creation failed.");
      setSubmitting(false);
      return;
    }
    toast.success(`${role === "instructor" ? "Instructor" : "Learner"} account created in Supabase Auth.`);
    router.push("/users");
    router.refresh();
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-5">
      <div className="grid gap-4 sm:grid-cols-2">
        <div className="space-y-2"><Label htmlFor="full-name">Full name</Label><Input id="full-name" value={fullName} onChange={(event) => setFullName(event.target.value)} minLength={2} maxLength={160} required /></div>
        <div className="space-y-2"><Label htmlFor="account-email">Email</Label><Input id="account-email" type="email" value={email} onChange={(event) => setEmail(event.target.value)} required /></div>
      </div>
      <div className="grid gap-4 sm:grid-cols-2">
        <div className="space-y-2"><Label>Initial role</Label><Select value={role} onValueChange={(value) => setRole(value as "learner" | "instructor")}><SelectTrigger><SelectValue /></SelectTrigger><SelectContent><SelectItem value="instructor">Instructor</SelectItem><SelectItem value="learner">Learner</SelectItem></SelectContent></Select></div>
        <div className="space-y-2"><Label htmlFor="initial-password">Temporary password</Label><Input id="initial-password" type="password" value={password} onChange={(event) => setPassword(event.target.value)} minLength={12} autoComplete="new-password" required /><p className="text-xs text-muted-foreground">At least 12 characters. Share through an approved private channel.</p></div>
      </div>
      <div className="flex justify-end gap-2"><Button type="button" variant="outline" onClick={() => router.back()}>Cancel</Button><Button type="submit" disabled={submitting}>{submitting ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <UserPlus className="mr-2 h-4 w-4" />}Create account</Button></div>
    </form>
  );
}
