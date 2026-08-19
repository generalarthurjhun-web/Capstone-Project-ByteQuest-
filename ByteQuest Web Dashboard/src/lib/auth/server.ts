import "server-only";

import { redirect } from "next/navigation";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import type { AppProfile, UserRole } from "@/types/auth";

export async function getServerProfile(): Promise<AppProfile | null> {
  const supabase = await createServerSupabaseClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) return null;

  const { data } = await supabase
    .from("profiles")
    .select(
      "id,user_id,full_name,email,avatar_url,role,status,created_at,updated_at,deactivated_at,deactivation_reason",
    )
    .eq("user_id", user.id)
    .maybeSingle();

  if (!data) return null;

  return {
    id: data.id,
    userId: data.user_id,
    fullName: data.full_name,
    email: data.email,
    avatarUrl: data.avatar_url,
    role: data.role as UserRole,
    status: data.status,
    createdAt: data.created_at,
    updatedAt: data.updated_at,
    deactivatedAt: data.deactivated_at,
    deactivationReason: data.deactivation_reason,
  };
}

export async function requireStaffProfile(
  allowedRoles: readonly UserRole[] = ["instructor", "admin"],
): Promise<AppProfile> {
  const profile = await getServerProfile();

  if (!profile) redirect("/login");
  if (profile.status !== "active") redirect("/login?error=account_inactive");
  if (!allowedRoles.includes(profile.role)) redirect("/login?error=staff_only");

  return profile;
}

export function dashboardPathForRole(role: UserRole): string {
  if (role === "admin") return "/admin/dashboard";
  if (role === "instructor") return "/instructor/dashboard";
  return "/login?error=staff_only";
}

