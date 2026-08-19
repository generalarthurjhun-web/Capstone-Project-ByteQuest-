import React from "react";
import Image from "next/image";

interface AuthBrandProps {
  title: string;
  subtitle: string;
  centered?: boolean;
}

export function AuthBrand({ title, subtitle, centered = false }: AuthBrandProps) {
  if (centered) {
    return (
      <div className="mb-7 text-center">
        <div className="mb-7 flex items-center justify-center gap-2.5">
          <div className="relative h-9 w-9">
            <Image
              src="/ByteQuest Logo.png"
              alt=""
              fill
              className="object-contain"
              priority
            />
          </div>
          <span className="text-lg font-bold tracking-[-0.025em] text-slate-900">
            ByteQuest
          </span>
        </div>
        <h1 className="text-2xl font-bold tracking-[-0.03em] text-slate-900 sm:text-[1.7rem]">
          {title}
        </h1>
        <p className="mt-2 text-sm leading-6 text-slate-500">
          {subtitle}
        </p>
      </div>
    );
  }

  return (
    <div className="mb-7">
      <div className="mb-7 flex items-center gap-3">
        <div className="relative h-10 w-10 rounded-xl bg-primary/[0.07] ring-1 ring-primary/10">
          <Image
            src="/ByteQuest Logo.png"
            alt=""
            fill
            className="object-contain p-1.5"
            priority
          />
        </div>
        <div>
          <span className="block text-lg font-bold tracking-[-0.025em] text-foreground">ByteQuest</span>
          <span className="block text-[11px] font-medium text-muted-foreground">CSS NC II learning platform</span>
        </div>
      </div>
      <h1 className="text-2xl font-bold tracking-[-0.035em] text-foreground sm:text-[1.85rem]">
        {title}
      </h1>
      <p className="mt-2 text-sm leading-6 text-muted-foreground">
        {subtitle}
      </p>
    </div>
  );
}
