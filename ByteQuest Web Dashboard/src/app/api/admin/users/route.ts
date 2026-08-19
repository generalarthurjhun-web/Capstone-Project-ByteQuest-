import { NextResponse } from "next/server";
import { z } from "zod";
import { getServerProfile } from "@/lib/auth/server";
import { createAdminSupabaseClient } from "@/lib/supabase/admin";
import { createServerSupabaseClient } from "@/lib/supabase/server";

const createAccountSchema = z.object({
  fullName: z.string().trim().min(2).max(160),
  email: z.string().trim().email().max(320),
  password: z.string().min(12).max(128),
  role: z.enum(["learner", "instructor"]),
});

export async function POST(request: Request) {
  const actor = await getServerProfile();
  if (!actor || actor.role !== "admin" || actor.status !== "active") {
    return NextResponse.json({ error: "Administrator access is required." }, { status: 403 });
  }

  const parsed = createAccountSchema.safeParse(await request.json().catch(() => null));
  if (!parsed.success) {
    return NextResponse.json({ error: "Provide a valid name, email, role, and 12-character password." }, { status: 400 });
  }

  const admin = createAdminSupabaseClient();
  const { data, error } = await admin.auth.admin.createUser({
    email: parsed.data.email,
    password: parsed.data.password,
    email_confirm: true,
    user_metadata: { full_name: parsed.data.fullName },
  });

  if (error || !data.user) {
    const message = error?.message.toLowerCase().includes("already")
      ? "An account with that email already exists."
      : "Supabase Auth could not create the account.";
    return NextResponse.json({ error: message }, { status: 400 });
  }

  const supabase = await createServerSupabaseClient();
  const { error: roleError } = await supabase.rpc("admin_change_user_role", {
    p_user_id: data.user.id,
    p_new_role: parsed.data.role,
    p_reason: `Initial ${parsed.data.role} account provisioned by Administrator`,
  });

  if (roleError) {
    await admin.auth.admin.deleteUser(data.user.id);
    return NextResponse.json(
      { error: "Account provisioning was rolled back because profile authorization failed." },
      { status: 500 },
    );
  }

  return NextResponse.json({ userId: data.user.id }, { status: 201 });
}
