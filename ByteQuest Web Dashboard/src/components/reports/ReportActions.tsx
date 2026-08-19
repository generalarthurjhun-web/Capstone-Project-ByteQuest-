"use client";

import { Download, Printer } from "lucide-react";
import { useSearchParams } from "next/navigation";
import { Button } from "@/components/ui/button";

export function ReportActions() {
  const searchParams = useSearchParams();
  const exportUrl = `/api/reports/export?${searchParams.toString()}`;
  return (
    <div className="flex flex-wrap gap-2">
      <Button type="button" variant="outline" onClick={() => window.print()}>
        <Printer className="mr-2 h-4 w-4" aria-hidden="true" />Print / Save PDF
      </Button>
      <Button asChild>
        <a href={exportUrl}><Download className="mr-2 h-4 w-4" aria-hidden="true" />Export CSV</a>
      </Button>
    </div>
  );
}

