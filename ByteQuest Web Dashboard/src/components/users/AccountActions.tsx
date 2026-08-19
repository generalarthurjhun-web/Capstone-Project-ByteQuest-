"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Loader2 } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { createClient } from "@/lib/supabase/client";
import type { AccountStatus, UserRole } from "@/types/auth";

export function AccountActions({
  userId,
  targetEmail,
  currentRole,
  currentStatus,
}: {
  userId: string;
  targetEmail: string;
  currentRole: UserRole;
  currentStatus: AccountStatus;
}) {
  const router = useRouter();
  const [role, setRole] = useState<UserRole>(currentRole);
  const [status, setStatus] = useState<AccountStatus>(currentStatus);
  const [reason, setReason] = useState("");
  const [confirmationEmail, setConfirmationEmail] = useState("");
  const [submitting, setSubmitting] = useState<"role" | "status" | "remove" | null>(null);

  const validateReason = () => {
    if (reason.trim().length < 5) {
      toast.error("Provide a clear reason of at least five characters.");
      return false;
    }
    return true;
  };

  const updateRole = async () => {
    if (role === currentRole || !validateReason()) return;
    setSubmitting("role");
    const { error } = await createClient().rpc("admin_change_user_role", {
      p_user_id: userId,
      p_new_role: role,
      p_reason: reason.trim(),
    });
    if (error) toast.error(error.message);
    else {
      toast.success("Role changed and audited.");
      setReason("");
      router.refresh();
    }
    setSubmitting(null);
  };

  const updateStatus = async () => {
    if (status === currentStatus) return;
    if (status !== "active" && !validateReason()) return;
    setSubmitting("status");
    const { error } = await createClient().rpc("admin_set_account_status", {
      p_user_id: userId,
      p_status: status,
      p_reason: reason.trim() || undefined,
    });
    if (error) toast.error(error.message);
    else {
      toast.success(status === "active" ? "Account restored and audited." : "Account status changed and audited.");
      setReason("");
      router.refresh();
    }
    setSubmitting(null);
  };

  const permanentlyRemove = async () => {
    if (reason.trim().length < 10) {
      toast.error("Provide a specific removal reason of at least ten characters.");
      return;
    }
    if (confirmationEmail.trim().toLowerCase() !== targetEmail.toLowerCase()) {
      toast.error("Type the account email exactly to confirm removal.");
      return;
    }
    if (!window.confirm("Permanently remove this empty Auth account? Retained academic history will block the request.")) return;

    setSubmitting("remove");
    const response = await fetch(`/api/admin/users/${encodeURIComponent(userId)}`, {
      method: "DELETE",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ confirmationEmail: confirmationEmail.trim(), reason: reason.trim() }),
    });
    const payload = (await response.json().catch(() => ({}))) as { error?: string };
    if (!response.ok) {
      toast.error(payload.error ?? "Permanent removal was blocked.");
      setSubmitting(null);
      return;
    }
    toast.success("Empty Auth account permanently removed and audited.");
    router.push("/users");
    router.refresh();
  };

  return (
    <div className="space-y-5">
      <div className="grid gap-3 sm:grid-cols-[minmax(0,1fr)_auto] sm:items-end">
        <div className="space-y-2">
          <Label>System role</Label>
          <Select value={role} onValueChange={(value) => setRole(value as UserRole)}>
            <SelectTrigger><SelectValue /></SelectTrigger>
            <SelectContent>
              <SelectItem value="learner">Learner</SelectItem>
              <SelectItem value="instructor">Instructor</SelectItem>
              <SelectItem value="admin">Administrator</SelectItem>
            </SelectContent>
          </Select>
        </div>
        <Button type="button" onClick={updateRole} disabled={role === currentRole || submitting !== null}>
          {submitting === "role" ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
          Save role
        </Button>
      </div>
      <div className="grid gap-3 sm:grid-cols-[minmax(0,1fr)_auto] sm:items-end">
        <div className="space-y-2">
          <Label>Account status</Label>
          <Select value={status} onValueChange={(value) => setStatus(value as AccountStatus)}>
            <SelectTrigger><SelectValue /></SelectTrigger>
            <SelectContent>
              <SelectItem value="active">Active</SelectItem>
              <SelectItem value="inactive">Inactive</SelectItem>
              <SelectItem value="deactivated">Deactivated</SelectItem>
              <SelectItem value="pending">Pending</SelectItem>
            </SelectContent>
          </Select>
        </div>
        <Button type="button" variant="outline" onClick={updateStatus} disabled={status === currentStatus || submitting !== null}>
          {submitting === "status" ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
          Save status
        </Button>
      </div>
      <div className="space-y-2">
        <Label htmlFor={`account-reason-${userId}`}>Required governance reason</Label>
        <Textarea id={`account-reason-${userId}`} value={reason} onChange={(event) => setReason(event.target.value)} rows={3} placeholder="Why this access change is required" />
      </div>
      <p className="text-xs leading-relaxed text-muted-foreground">
        Role and access changes are enforced by database RPCs and written to the centralized audit log.
      </p>
      {currentStatus === "deactivated" ? (
        <div className="space-y-4 rounded-lg border border-destructive/35 bg-destructive/5 p-4">
          <div>
            <p className="text-sm font-semibold text-destructive">Permanent removal safeguard</p>
            <p className="mt-1 text-xs leading-relaxed text-muted-foreground">
              Only an empty Auth identity can be removed. Any academic, class, assessment, content,
              or governance dependency blocks removal and keeps the account deactivated.
            </p>
          </div>
          <div className="space-y-2">
            <Label htmlFor={`remove-confirm-${userId}`}>Type {targetEmail} to confirm</Label>
            <input
              id={`remove-confirm-${userId}`}
              className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm outline-none ring-offset-background focus-visible:ring-2 focus-visible:ring-ring"
              value={confirmationEmail}
              onChange={(event) => setConfirmationEmail(event.target.value)}
              autoComplete="off"
            />
          </div>
          <Button
            type="button"
            variant="destructive"
            onClick={permanentlyRemove}
            disabled={submitting !== null || confirmationEmail.trim().toLowerCase() !== targetEmail.toLowerCase()}
          >
            {submitting === "remove" ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
            Permanently remove empty account
          </Button>
        </div>
      ) : null}
    </div>
  );
}
