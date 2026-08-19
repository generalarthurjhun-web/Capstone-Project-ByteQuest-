import type { ReactNode } from "react";

export function SectionHeading({
  title,
  description,
  action,
}: {
  title: string;
  description?: string;
  action?: ReactNode;
}) {
  return (
    <div className="flex flex-col gap-2 border-b border-border/70 px-5 py-4 sm:flex-row sm:items-start sm:justify-between">
      <div>
        <h2 className="text-[15px] font-semibold tracking-[-0.015em] text-foreground">{title}</h2>
        {description ? <p className="mt-1 max-w-3xl text-[12px] leading-5 text-muted-foreground">{description}</p> : null}
      </div>
      {action ? <div className="shrink-0 print-hidden">{action}</div> : null}
    </div>
  );
}
