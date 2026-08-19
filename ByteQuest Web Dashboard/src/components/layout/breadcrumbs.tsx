"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { ChevronRight, Home } from "lucide-react";
import { useAuth } from "@/hooks/use-auth";

export function Breadcrumbs() {
  const pathname = usePathname();
  const { user } = useAuth();
  const paths = pathname.split("/").filter(Boolean);
  const dashboardHref = user?.role === "admin" ? "/admin/dashboard" : "/instructor/dashboard";
  const crumbs = paths
    .map((path, index) => ({
      path,
      href: `/${paths.slice(0, index + 1).join("/")}`,
    }))
    .filter(({ path }) => path !== "admin" && path !== "instructor" && path !== "dashboard");

  if (paths.length === 0 || pathname === "/admin/dashboard" || pathname === "/instructor/dashboard") return null;

  return (
    <nav aria-label="Breadcrumb" className="mb-5 flex min-w-0 items-center gap-1.5 overflow-x-auto text-xs text-muted-foreground print:hidden">
      <Link
        href={dashboardHref}
        className="flex min-h-8 shrink-0 cursor-pointer items-center gap-1.5 rounded-md px-1.5 font-medium transition-colors hover:bg-muted hover:text-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
      >
        <Home className="h-3.5 w-3.5" aria-hidden="true" />
        <span>Dashboard</span>
      </Link>

      {crumbs.map(({ path, href }, index) => {
        const isLast = index === crumbs.length - 1;
        const label = path.charAt(0).toUpperCase() + path.slice(1).replace(/-/g, " ");

        return (
          <div key={`${href}-${index}`} className="flex min-w-0 items-center gap-1.5">
            <ChevronRight className="h-3.5 w-3.5 text-muted-foreground/40" aria-hidden="true" />
            {isLast ? (
              <span className="max-w-48 truncate px-1.5 font-semibold text-foreground">{label}</span>
            ) : (
              <Link
                href={href}
                className="max-w-40 truncate rounded-md px-1.5 py-1.5 font-medium transition-colors hover:bg-muted hover:text-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
              >
                {label}
              </Link>
            )}
          </div>
        );
      })}
    </nav>
  );
}
