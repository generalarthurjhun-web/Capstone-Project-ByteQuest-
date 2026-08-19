import { redirect } from "next/navigation";
import { dashboardPathForRole, requireStaffProfile } from "@/lib/auth/server";

export default async function DashboardRedirectPage() {
  const profile = await requireStaffProfile();
  redirect(dashboardPathForRole(profile.role));
}
