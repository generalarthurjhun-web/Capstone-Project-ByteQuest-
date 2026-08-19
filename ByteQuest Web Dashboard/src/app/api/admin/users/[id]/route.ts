import { NextResponse } from "next/server";
import { z } from "zod";
import { getServerProfile } from "@/lib/auth/server";
import { createAdminSupabaseClient } from "@/lib/supabase/admin";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import type { Json } from "@/types/database.generated";

const removalSchema = z.object({
  confirmationEmail: z.string().trim().email().max(320),
  reason: z.string().trim().min(10).max(1000),
});

type RemovalBlocker = {
  schema: string;
  table: string;
  column: string;
  rows: number;
};

function readBlockers(value: Json): RemovalBlocker[] | null {
  if (!value || Array.isArray(value) || typeof value !== "object") return null;
  if (value.safe_to_remove === true && Array.isArray(value.blockers)) return [];
  if (value.safe_to_remove !== false || !Array.isArray(value.blockers)) return null;

  const blockers: RemovalBlocker[] = [];
  for (const raw of value.blockers) {
    if (!raw || Array.isArray(raw) || typeof raw !== "object") return null;
    if (
      typeof raw.schema !== "string" ||
      typeof raw.table !== "string" ||
      typeof raw.column !== "string" ||
      typeof raw.rows !== "number"
    ) {
      return null;
    }
    blockers.push({
      schema: raw.schema,
      table: raw.table,
      column: raw.column,
      rows: raw.rows,
    });
  }
  return blockers;
}

export async function DELETE(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const actor = await getServerProfile();
  if (!actor || actor.role !== "admin" || actor.status !== "active") {
    return NextResponse.json({ error: "Administrator access is required." }, { status: 403 });
  }

  const { id: targetUserId } = await params;
  const parsed = removalSchema.safeParse(await request.json().catch(() => null));
  if (!z.string().uuid().safeParse(targetUserId).success || !parsed.success) {
    return NextResponse.json(
      { error: "Provide a valid account, confirmation email, and removal reason." },
      { status: 400 },
    );
  }
  if (actor.userId === targetUserId) {
    return NextResponse.json({ error: "Administrators cannot remove their own account." }, { status: 403 });
  }

  const admin = createAdminSupabaseClient();
  const { data: target, error: targetError } = await admin
    .from("profiles")
    .select("id,user_id,full_name,email,role,status,created_at,deactivated_at,deactivation_reason")
    .eq("user_id", targetUserId)
    .maybeSingle();

  if (targetError || !target) {
    return NextResponse.json({ error: "The target account no longer exists." }, { status: 404 });
  }
  if (target.email.toLowerCase() !== parsed.data.confirmationEmail.toLowerCase()) {
    return NextResponse.json({ error: "The confirmation email does not match." }, { status: 400 });
  }
  if (target.status !== "deactivated") {
    return NextResponse.json(
      { error: "Deactivate the account and preserve its access history before requesting removal." },
      { status: 409 },
    );
  }

  const scoped = await createServerSupabaseClient();
  const { data: readiness, error: readinessError } = await scoped.rpc(
    "admin_account_removal_readiness",
    { p_user_id: targetUserId },
  );
  const blockers = readiness ? readBlockers(readiness) : null;
  if (readinessError || blockers === null) {
    return NextResponse.json(
      { error: "Account retention safeguards could not be verified." },
      { status: 500 },
    );
  }
  if (blockers.length > 0) {
    return NextResponse.json(
      {
        error:
          "Permanent removal is blocked because academic, instructional, or governance history must be retained. Keep this account deactivated.",
        blockers,
      },
      { status: 409 },
    );
  }

  const { error: authorizationAuditError } = await admin.from("audit_events").insert({
    actor_id: actor.userId,
    actor_role: "admin",
    action: "account.permanent_removal_authorized",
    target_type: "auth_user",
    target_id: targetUserId,
    old_value: target,
    reason: parsed.data.reason,
    outcome: "success",
    metadata: {
      retained_history_check: "NO_RESTRICT_DEPENDENCIES",
      exact_email_confirmation: true,
    },
  });
  if (authorizationAuditError) {
    return NextResponse.json(
      { error: "Permanent removal was stopped because its authorization audit could not be recorded." },
      { status: 500 },
    );
  }

  const { error: deleteError } = await admin.auth.admin.deleteUser(targetUserId, false);
  if (deleteError) {
    await admin.from("audit_events").insert({
      actor_id: actor.userId,
      actor_role: "admin",
      action: "account.permanent_removal_failed",
      target_type: "auth_user",
      target_id: targetUserId,
      old_value: target,
      reason: parsed.data.reason,
      outcome: "failed",
      metadata: { auth_error: deleteError.message },
    });
    return NextResponse.json(
      { error: "Supabase Auth rejected permanent removal; the account remains deactivated." },
      { status: 409 },
    );
  }

  const { error: auditError } = await admin.from("audit_events").insert({
    actor_id: actor.userId,
    actor_role: "admin",
    action: "account.permanently_removed",
    target_type: "auth_user",
    target_id: targetUserId,
    old_value: target,
    reason: parsed.data.reason,
    outcome: "success",
    metadata: {
      retained_history_check: "NO_RESTRICT_DEPENDENCIES",
      removed_from_supabase_auth: true,
    },
  });
  if (auditError) {
    return NextResponse.json(
      {
        error:
          "The Auth identity was removed, but the audit confirmation write failed. Escalate this event immediately.",
      },
      { status: 500 },
    );
  }

  return NextResponse.json({ removed: true });
}
