import "server-only";

import { createAdminSupabaseClient } from "@/lib/supabase/admin";

export type AdminProfileRow = {
  user_id: string;
  full_name: string;
  email: string;
  role: string;
  status: string;
  created_at: string;
  last_activity_at: string | null;
};

export type AdminClassRow = {
  id: string;
  title: string;
  class_code: string | null;
  instructor_id: string;
  status: string;
  created_at: string;
};

export type AdminMembershipRow = {
  id: string;
  class_id: string;
  learner_id: string;
  status: string;
  enrolled_at: string;
};

export type AdminResourceRow = {
  id: string;
  class_id: string;
  title: string;
  storage_bucket: string;
  mime_type: string | null;
  size_bytes: number | null;
  status: string;
  uploaded_by: string;
  created_at: string;
};

export type AdminAuditRow = {
  id: string;
  action: string;
  target_type: string;
  outcome: string;
  actor_role: string | null;
  created_at: string;
};

export async function getAdminGovernanceData() {
  const supabase = createAdminSupabaseClient();
  const [profiles, classes, memberships, resources, audits] = await Promise.all([
    supabase
      .from("profiles")
      .select("user_id,full_name,email,role,status,created_at,last_activity_at")
      .order("created_at", { ascending: false }),
    supabase
      .from("classes")
      .select("id,title,class_code,instructor_id,status,created_at")
      .order("created_at", { ascending: false }),
    supabase
      .from("class_memberships")
      .select("id,class_id,learner_id,status,enrolled_at")
      .order("enrolled_at", { ascending: false }),
    supabase
      .from("learning_resources")
      .select("id,class_id,title,storage_bucket,mime_type,size_bytes,status,uploaded_by,created_at")
      .order("created_at", { ascending: false }),
    supabase
      .from("audit_events")
      .select("id,action,target_type,outcome,actor_role,created_at")
      .order("created_at", { ascending: false })
      .limit(100),
  ]);

  const failure = [profiles, classes, memberships, resources, audits].find((result) => result.error);
  if (failure?.error) throw new Error("Unable to load Admin governance data.", { cause: failure.error });

  return {
    profiles: (profiles.data ?? []) as AdminProfileRow[],
    classes: (classes.data ?? []) as AdminClassRow[],
    memberships: (memberships.data ?? []) as AdminMembershipRow[],
    resources: (resources.data ?? []) as AdminResourceRow[],
    audits: (audits.data ?? []) as AdminAuditRow[],
  };
}

export function formatAdminDate(value: string | null) {
  if (!value) return "No activity recorded";
  return new Intl.DateTimeFormat("en-PH", { dateStyle: "medium", timeZone: "Asia/Manila" }).format(new Date(value));
}

export function formatStorageBytes(value: number) {
  if (!value) return "0 B";
  const units = ["B", "KiB", "MiB", "GiB"];
  const index = Math.min(Math.floor(Math.log(value) / Math.log(1024)), units.length - 1);
  return `${(value / 1024 ** index).toFixed(index ? 1 : 0)} ${units[index]}`;
}
