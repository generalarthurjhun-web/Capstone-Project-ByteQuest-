import React from "react";

interface AuthLayoutProps {
  children: React.ReactNode;
  illustration?: React.ReactNode;
  centered?: boolean;
  light?: boolean;
}

export function AuthLayout({
  children,
  illustration,
  centered = false,
  light = false,
}: AuthLayoutProps) {
  if (centered) {
    return (
      <main className="flex min-h-dvh items-center justify-center overflow-y-auto bg-[#f7f9fc] px-4 py-8 sm:px-6">
        <div className="my-auto w-full max-w-[430px]">
          {children}
        </div>
      </main>
    );
  }

  return (
    <main className={`grid min-h-dvh ${light ? "bg-[#f7f9fc]" : "bg-background"} lg:grid-cols-[minmax(0,1.08fr)_minmax(420px,0.92fr)]`}>
      <div className={`relative hidden min-h-dvh overflow-hidden lg:flex ${light ? "bg-[#f7f9fc]" : "bg-slate-950"}`}>
        {illustration}
      </div>
      <div className="flex min-h-dvh items-center justify-center overflow-y-auto px-4 py-8 sm:px-8 lg:px-10">
        <div className="my-auto w-full max-w-[460px]">
          {children}
        </div>
      </div>
    </main>
  );
}
