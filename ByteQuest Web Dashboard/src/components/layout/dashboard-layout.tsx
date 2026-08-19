"use client";

import { Sidebar } from "./sidebar";
import { Topbar } from "./topbar";
import { Breadcrumbs } from "./breadcrumbs";
import { PageTransition } from "./page-transition";
import { ProtectedRoute } from "@/components/auth/protected-route";
import { RealtimeRouteRefresh } from "@/components/realtime/RealtimeRouteRefresh";

export function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <ProtectedRoute>
      <RealtimeRouteRefresh />
      <a href="#main-content" className="fixed left-3 top-3 z-[100] -translate-y-20 rounded-lg bg-foreground px-4 py-2 text-sm font-semibold text-background transition-transform focus:translate-y-0">Skip to main content</a>
      <div className="flex h-dvh min-h-screen overflow-hidden bg-background">
        <Sidebar />
        <div className="flex min-w-0 flex-1 flex-col overflow-hidden">
          <Topbar />
          <main id="main-content" tabIndex={-1} className="app-main flex-1 overflow-y-auto overscroll-contain p-4 focus:outline-none md:p-6 lg:p-7 xl:p-8">
            <div className="mx-auto w-full max-w-[1480px]">
              <Breadcrumbs />
              <PageTransition>{children}</PageTransition>
              <p
                role="note"
                className="mt-10 border-t border-border/70 pt-4 text-xs leading-relaxed text-muted-foreground print:hidden"
              >
                ByteQuest is a supplementary learning and assessment platform. It does not issue
                TESDA certification and does not replace assessment by an accredited TESDA provider.
              </p>
            </div>
          </main>
        </div>
      </div>
    </ProtectedRoute>
  );
}
