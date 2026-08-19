import { getServerProfile } from "@/lib/auth/server";
import { createServerSupabaseClient } from "@/lib/supabase/server";

function csvCell(value: unknown) {
  const text = value === null || value === undefined ? "" : String(value);
  return `"${text.replaceAll('"', '""')}"`;
}

export async function GET() {
  const profile = await getServerProfile();
  if (!profile || profile.role !== "instructor" || profile.status !== "active") {
    return new Response("Forbidden", { status: 403 });
  }
  const supabase = await createServerSupabaseClient();
  const { data: releases } = await supabase.from("result_releases").select("attempt_id,score_revision_id,released_at,release_reason").eq("is_current", true).order("released_at", { ascending: false });
  const attemptIds = [...new Set((releases ?? []).map((row) => row.attempt_id))];
  const revisionIds = [...new Set((releases ?? []).map((row) => row.score_revision_id))];
  const [attempts, revisions] = await Promise.all([
    attemptIds.length ? supabase.from("attempts").select("id,learner_id,class_id,assignment_id,elapsed_time_seconds").in("id", attemptIds) : Promise.resolve({ data: [] }),
    revisionIds.length ? supabase.from("score_revisions").select("id,percentage,outcome,remarks").in("id", revisionIds) : Promise.resolve({ data: [] }),
  ]);
  const attemptRows = attempts.data ?? [];
  const [profiles, classes, assignments] = await Promise.all([
    attemptRows.length ? supabase.from("profiles").select("user_id,full_name,email").in("user_id", [...new Set(attemptRows.map((row) => row.learner_id))]) : Promise.resolve({ data: [] }),
    attemptRows.length ? supabase.from("classes").select("id,title").in("id", [...new Set(attemptRows.map((row) => row.class_id))]) : Promise.resolve({ data: [] }),
    attemptRows.length ? supabase.from("assignments").select("id,title").in("id", [...new Set(attemptRows.map((row) => row.assignment_id))]) : Promise.resolve({ data: [] }),
  ]);
  const attemptById = new Map(attemptRows.map((row) => [row.id, row]));
  const revisionById = new Map((revisions.data ?? []).map((row) => [row.id, row]));
  const profileById = new Map((profiles.data ?? []).map((row) => [row.user_id, row]));
  const classById = new Map((classes.data ?? []).map((row) => [row.id, row.title]));
  const assignmentById = new Map((assignments.data ?? []).map((row) => [row.id, row.title]));
  const header = ["Attempt ID", "Learner", "Email", "Class", "Assignment", "Final Percentage", "Competency Outcome", "Elapsed Seconds", "Released At", "Release Reason", "Instructor Remarks"];
  const rows = (releases ?? []).map((release) => { const attempt = attemptById.get(release.attempt_id); const revision = revisionById.get(release.score_revision_id); const learner = attempt ? profileById.get(attempt.learner_id) : null; return [release.attempt_id, learner?.full_name, learner?.email, attempt ? classById.get(attempt.class_id) : null, attempt ? assignmentById.get(attempt.assignment_id) : null, revision?.percentage, revision?.outcome, attempt?.elapsed_time_seconds, release.released_at, release.release_reason, revision?.remarks].map(csvCell).join(","); });
  const csv = [header.map(csvCell).join(","), ...rows].join("\r\n");
  return new Response(csv, { headers: { "Content-Type": "text/csv; charset=utf-8", "Content-Disposition": `attachment; filename="bytequest-released-results-${new Date().toISOString().slice(0, 10)}.csv"`, "Cache-Control": "no-store" } });
}
