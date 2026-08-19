import type { ReactNode } from "react";

export function AdminGovernanceTable({
  headers,
  children,
  empty,
}: {
  headers: string[];
  children: ReactNode;
  empty?: ReactNode;
}) {
  return (
    <div className="overflow-hidden rounded-2xl border border-border bg-card shadow-xs">
      <div className="overflow-x-auto">
        {children ? (
          <table className="w-full min-w-[680px] border-collapse text-left text-[13px]">
            <thead className="bg-muted/35 text-[10px] font-bold uppercase tracking-[0.12em] text-muted-foreground">
              <tr>{headers.map((header) => <th key={header} className="whitespace-nowrap px-5 py-3 font-bold">{header}</th>)}</tr>
            </thead>
            <tbody className="divide-y divide-border">{children}</tbody>
          </table>
        ) : <div className="px-5 py-14 text-center text-sm text-muted-foreground">{empty ?? "No records are available."}</div>}
      </div>
    </div>
  );
}

export function AdminTableCell({ children, muted = false }: { children: ReactNode; muted?: boolean }) {
  return <td className={muted ? "px-5 py-3.5 text-xs text-muted-foreground" : "px-5 py-3.5 align-middle"}>{children}</td>;
}
