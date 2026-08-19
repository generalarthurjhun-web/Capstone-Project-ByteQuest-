"use client";

import { useEffect, useMemo, useRef } from "react";
import { usePathname, useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { useAuth } from "@/hooks/use-auth";

const instructorTables = [
  "classes",
  "class_memberships",
  "assignments",
  "attempts",
  "criterion_results",
  "score_revisions",
  "result_releases",
  "quiz_assignments",
  "quiz_attempts",
  "quiz_results",
  "learning_resources",
] as const;

const adminTables = [
  "profiles",
  "classes",
  "class_memberships",
  "assignments",
  "attempts",
  "quiz_assignments",
  "quiz_attempts",
  "learning_resources",
  "audit_events",
  "tesda_sources",
  "system_settings",
] as const;

function routeTables(pathname: string, role: "admin" | "instructor") {
  const allowed = role === "admin" ? adminTables : instructorTables;
  if (pathname.startsWith("/attempts")) {
    return allowed.filter((table) =>
      ["attempts", "criterion_results", "score_revisions", "result_releases"].includes(table),
    );
  }
  if (pathname.startsWith("/quizzes")) {
    return allowed.filter((table) => table.startsWith("quiz_"));
  }
  if (pathname.includes("resource")) {
    return allowed.filter((table) => table === "learning_resources" || table === "audit_events");
  }
  if (pathname.startsWith("/logs") || pathname.startsWith("/admin/security")) {
    return allowed.filter((table) => table === "audit_events" || table === "profiles");
  }
  if (pathname.startsWith("/tesda-sources")) {
    return allowed.filter((table) => table === "tesda_sources" || table === "audit_events");
  }
  return allowed;
}

/**
 * RLS-scoped invalidation for authenticated dashboard pages.
 * Realtime payloads never become UI truth; a visible page is refreshed from
 * its existing server-side query after a trusted database change.
 */
export function RealtimeRouteRefresh() {
  const { user } = useAuth();
  const pathname = usePathname();
  const router = useRouter();
  const timeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const tables = useMemo(
    () => (user?.role === "admin" || user?.role === "instructor" ? routeTables(pathname, user.role) : []),
    [pathname, user?.role],
  );

  useEffect(() => {
    if (!user || tables.length === 0) return;
    const supabase = createClient();
    let channel: ReturnType<typeof supabase.channel> | null = null;
    let cancelled = false;
    const queueRefresh = () => {
      if (timeoutRef.current) clearTimeout(timeoutRef.current);
      timeoutRef.current = setTimeout(() => router.refresh(), 350);
    };

    void supabase.auth.getSession().then(({ data }) => {
      if (cancelled || !data.session) return;
      supabase.realtime.setAuth(data.session.access_token);
      channel = supabase.channel(`dashboard-refresh:${user.role}:${pathname}`);
      for (const table of tables) {
        channel.on(
          "postgres_changes",
          { event: "*", schema: "public", table },
          queueRefresh,
        );
      }
      channel.subscribe();
    });

    return () => {
      cancelled = true;
      if (timeoutRef.current) clearTimeout(timeoutRef.current);
      timeoutRef.current = null;
      if (channel) void supabase.removeChannel(channel);
    };
  }, [pathname, router, tables, user]);

  return null;
}
