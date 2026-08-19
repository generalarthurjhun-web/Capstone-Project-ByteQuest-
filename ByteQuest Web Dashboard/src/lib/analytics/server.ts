import "server-only";

import { z } from "zod";
import { createServerSupabaseClient } from "@/lib/supabase/server";
import {
  adminAnalyticsSchema,
  analyticsFiltersSchema,
  instructorAnalyticsSchema,
  type AdminAnalytics,
  type AnalyticsFilters,
  type InstructorAnalytics,
} from "@/lib/analytics/types";

const DAY_MS = 86_400_000;
const UUID_SCHEMA = z.string().uuid();

function queryValue(value: string | string[] | undefined): string | undefined {
  return Array.isArray(value) ? value[0] : value;
}

function optionalUuid(value: string | undefined): string | null {
  const parsed = UUID_SCHEMA.safeParse(value);
  return parsed.success ? parsed.data : null;
}

function isoDateAtManilaBoundary(value: string, boundary: "start" | "end"): string | null {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return null;
  const suffix = boundary === "start" ? "T00:00:00.000+08:00" : "T23:59:59.999+08:00";
  const parsed = new Date(`${value}${suffix}`);
  return Number.isNaN(parsed.getTime()) ? null : parsed.toISOString();
}

export function parseAnalyticsFilters(
  searchParams: Record<string, string | string[] | undefined>,
): AnalyticsFilters {
  const requestedRange = queryValue(searchParams.range);
  const range = requestedRange === "7" || requestedRange === "90" || requestedRange === "custom"
    ? requestedRange
    : "30";
  const now = new Date();
  const customFrom = queryValue(searchParams.from);
  const customTo = queryValue(searchParams.to);
  const parsedFrom = customFrom ? isoDateAtManilaBoundary(customFrom, "start") : null;
  const parsedTo = customTo ? isoDateAtManilaBoundary(customTo, "end") : null;
  const days = Number(range === "custom" ? 30 : range);
  const defaultFrom = new Date(now.getTime() - (days - 1) * DAY_MS);

  const from = range === "custom" && parsedFrom ? parsedFrom : defaultFrom.toISOString();
  const to = range === "custom" && parsedTo ? parsedTo : now.toISOString();
  const safeFrom = new Date(from);
  const safeTo = new Date(to);
  const validRange = safeFrom <= safeTo && safeTo.getTime() - safeFrom.getTime() <= 366 * DAY_MS;

  return analyticsFiltersSchema.parse({
    classId: optionalUuid(queryValue(searchParams.class)),
    cocId: optionalUuid(queryValue(searchParams.coc)),
    missionId: optionalUuid(queryValue(searchParams.mission)),
    from: validRange ? from : defaultFrom.toISOString(),
    to: validRange ? to : now.toISOString(),
    range,
  });
}

export async function getInstructorAnalytics(
  filters: AnalyticsFilters,
): Promise<InstructorAnalytics> {
  const supabase = await createServerSupabaseClient();
  const { data, error } = await supabase.rpc("get_instructor_analytics", {
    p_class_id: filters.classId ?? undefined,
    p_coc_id: filters.cocId ?? undefined,
    p_mission_id: filters.missionId ?? undefined,
    p_from: filters.from,
    p_to: filters.to,
  });

  if (error) {
    throw new Error("Unable to load scoped Instructor analytics.", { cause: error });
  }

  return instructorAnalyticsSchema.parse(data);
}

export async function getAdminAnalytics(
  filters: Pick<AnalyticsFilters, "from" | "to">,
): Promise<AdminAnalytics> {
  const supabase = await createServerSupabaseClient();
  const { data, error } = await supabase.rpc("get_admin_system_analytics", {
    p_from: filters.from,
    p_to: filters.to,
  });

  if (error) {
    throw new Error("Unable to load Admin system analytics.", { cause: error });
  }

  return adminAnalyticsSchema.parse(data);
}
