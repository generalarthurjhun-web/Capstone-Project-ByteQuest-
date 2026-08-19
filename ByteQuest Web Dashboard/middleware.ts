import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";
import type { Database } from "@/types/database.generated";

const PUBLIC_PATHS = new Set(["/login", "/signup"]);
const ADMIN_PREFIXES = ["/admin", "/users", "/logs", "/settings", "/tesda-sources"];
const INSTRUCTOR_PREFIXES = [
  "/instructor",
  "/classes",
  "/attempts",
  "/modules",
  "/progress",
  "/analytics",
  "/reports",
  "/leaderboard",
  "/assessment-criteria",
  "/competencies",
  "/scenarios",
];

function matchesPrefix(pathname: string, prefixes: readonly string[]) {
  return prefixes.some(
    (prefix) => pathname === prefix || pathname.startsWith(`${prefix}/`),
  );
}

function redirectWithCookies(
  request: NextRequest,
  response: NextResponse,
  pathname: string,
) {
  const target = request.nextUrl.clone();
  const [path, query = ""] = pathname.split("?");
  target.pathname = path;
  target.search = query ? `?${query}` : "";
  const redirectResponse = NextResponse.redirect(target);
  response.cookies.getAll().forEach((cookie) => {
    redirectResponse.cookies.set(cookie);
  });
  return redirectResponse;
}

export async function middleware(request: NextRequest) {
  let response = NextResponse.next({ request });
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key =
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ??
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

  if (!url || !key) {
    return redirectWithCookies(request, response, "/login?error=configuration");
  }

  const supabase = createServerClient<Database>(url, key, {
    cookies: {
      getAll: () => request.cookies.getAll(),
      setAll(cookiesToSet) {
        cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value));
        response = NextResponse.next({ request });
        cookiesToSet.forEach(({ name, value, options }) => {
          response.cookies.set(name, value, options);
        });
      },
    },
  });

  const pathname = request.nextUrl.pathname;
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    if (PUBLIC_PATHS.has(pathname)) return response;
    return redirectWithCookies(request, response, "/login");
  }

  const { data: profile } = await supabase
    .from("profiles")
    .select("role,status")
    .eq("user_id", user.id)
    .maybeSingle();

  if (!profile || profile.status !== "active") {
    if (pathname === "/login") return response;
    return redirectWithCookies(request, response, "/login?error=account_inactive");
  }

  if (profile.role !== "admin" && profile.role !== "instructor") {
    if (pathname === "/login") return response;
    return redirectWithCookies(request, response, "/login?error=staff_only");
  }

  const roleDashboard =
    profile.role === "admin" ? "/admin/dashboard" : "/instructor/dashboard";

  if (PUBLIC_PATHS.has(pathname) || pathname === "/" || pathname === "/dashboard") {
    return redirectWithCookies(request, response, roleDashboard);
  }

  if (profile.role === "admin" && matchesPrefix(pathname, INSTRUCTOR_PREFIXES)) {
    return redirectWithCookies(request, response, "/admin/dashboard");
  }

  if (profile.role === "instructor" && matchesPrefix(pathname, ADMIN_PREFIXES)) {
    return redirectWithCookies(request, response, "/instructor/dashboard");
  }

  return response;
}

export const config = {
  matcher: [
    "/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)",
  ],
};
