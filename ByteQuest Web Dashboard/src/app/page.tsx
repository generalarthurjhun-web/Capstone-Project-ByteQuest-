import { redirect } from "next/navigation";
import { dashboardPathForRole, getServerProfile } from "@/lib/auth/server";

export default async function Home() {
  const profile = await getServerProfile();
  if (!profile || profile.status !== "active") redirect("/login");
  redirect(dashboardPathForRole(profile.role));
}
