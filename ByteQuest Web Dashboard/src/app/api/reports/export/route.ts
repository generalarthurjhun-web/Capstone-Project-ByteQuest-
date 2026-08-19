import { NextRequest } from "next/server";
import { getInstructorAnalytics, parseAnalyticsFilters } from "@/lib/analytics/server";
import { prepareReport, reportToCsv } from "@/lib/analytics/reports";
import { reportTypeSchema } from "@/lib/analytics/types";
import { getServerProfile } from "@/lib/auth/server";

export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  const profile = await getServerProfile();
  if (!profile) {
    return Response.json({ error: "Authentication required." }, { status: 401 });
  }
  if (profile.status !== "active" || profile.role !== "instructor") {
    return Response.json({ error: "Instructor access required." }, { status: 403 });
  }
  const params = Object.fromEntries(request.nextUrl.searchParams.entries());
  const filters = parseAnalyticsFilters(params);
  const reportType = reportTypeSchema.catch("class_performance").parse(request.nextUrl.searchParams.get("type"));
  const analytics = await getInstructorAnalytics(filters);
  const report = prepareReport(reportType, analytics);
  const csv = reportToCsv(report);
  const date = new Date().toISOString().slice(0, 10);

  return new Response(csv, {
    headers: {
      "Content-Type": "text/csv; charset=utf-8",
      "Content-Disposition": `attachment; filename="bytequest-${reportType}-${date}.csv"`,
      "Cache-Control": "private, no-store",
      "X-Content-Type-Options": "nosniff",
    },
  });
}
