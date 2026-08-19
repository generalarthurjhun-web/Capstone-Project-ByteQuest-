import React from "react";
import { Card } from "@/components/ui/card";

interface AuthCardProps {
  children: React.ReactNode;
  compact?: boolean;
}

export function AuthCard({ children, compact = false }: AuthCardProps) {
  if (compact) {
    return (
      <Card className="overflow-hidden rounded-2xl border border-slate-200/70 bg-white shadow-[0_18px_45px_rgba(15,23,42,0.07)]">
        <div className="p-6 sm:p-8">
          {children}
        </div>
      </Card>
    );
  }

  return (
    <div className="relative">
      <div aria-hidden="true" className="absolute inset-x-10 -bottom-4 h-20 rounded-full bg-primary/10 blur-3xl" />
      <Card className="relative overflow-hidden rounded-2xl border-border/85 bg-card shadow-elevated">
        <div className="h-1 bg-primary" aria-hidden="true" />
        <div className="p-6 sm:p-8 lg:p-9">
          {children}
        </div>
      </Card>
    </div>
  );
}
