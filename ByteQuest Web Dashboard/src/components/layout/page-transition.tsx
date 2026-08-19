"use client";

import { usePathname, useSearchParams } from "next/navigation";

export function PageTransition({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const transitionKey = `${pathname}?${searchParams.toString()}`;

  return (
    <div key={transitionKey} className="dashboard-page-enter">
      {children}
    </div>
  );
}
