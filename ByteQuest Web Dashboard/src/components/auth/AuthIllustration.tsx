import Image from "next/image";
import { BarChart3, ClipboardCheck, ShieldCheck } from "lucide-react";

const capabilities = [
  {
    icon: ShieldCheck,
    title: "One trusted identity",
    description: "Supabase authentication and scoped role boundaries across the platform.",
  },
  {
    icon: ClipboardCheck,
    title: "Evidence-first review",
    description: "Ordered learner actions, criterion results, and accountable finalization.",
  },
  {
    icon: BarChart3,
    title: "Actionable class insight",
    description: "Real progress, review queues, and intervention analytics for owned classes.",
  },
];

export function AuthIllustration() {
  return (
    <div className="relative flex h-full w-full flex-col justify-between overflow-hidden px-10 py-9 text-white xl:px-14 xl:py-12">
      <div
        aria-hidden="true"
        className="absolute -right-28 top-20 h-80 w-80 rounded-full bg-blue-500/15 blur-3xl"
      />
      <div
        aria-hidden="true"
        className="absolute -bottom-20 -left-16 h-72 w-72 rounded-full bg-cyan-400/10 blur-3xl"
      />

      <div className="relative z-10 flex items-center gap-3">
        <span className="relative h-9 w-9 rounded-xl bg-white/95">
          <Image src="/ByteQuest Logo.png" alt="" fill className="object-contain p-1.5" priority />
        </span>
        <div>
          <p className="text-sm font-bold tracking-[-0.01em]">ByteQuest</p>
          <p className="mt-0.5 text-[11px] text-slate-400">Instructor and Admin portal</p>
        </div>
      </div>

      <div className="relative z-10 my-10 max-w-2xl">
        <div className="grid items-center gap-8 xl:grid-cols-[minmax(0,1fr)_minmax(260px,0.72fr)]">
          <div>
            <h2 className="max-w-xl text-3xl font-bold leading-tight tracking-[-0.045em] xl:text-[2.6rem] xl:leading-[1.08]">
              Turn simulation evidence into clear instructional decisions.
            </h2>
            <p className="mt-5 max-w-xl text-sm leading-7 text-slate-300 xl:text-[15px]">
              Manage classes, review criterion-level evidence, release accountable results, and understand where learners need support.
            </p>
          </div>
          <div className="relative mx-auto aspect-square w-full max-w-[290px] rounded-2xl border border-white/10 bg-white/[0.055] p-5 shadow-2xl shadow-black/25">
            <Image
              src="/Computer Parts.png"
              alt="Computer systems servicing components"
              fill
              className="object-contain p-5"
              priority
            />
          </div>
        </div>

        <div className="mt-10 grid gap-3 xl:grid-cols-3">
          {capabilities.map((capability) => {
            const Icon = capability.icon;
            return (
              <div key={capability.title} className="rounded-xl border border-white/10 bg-white/[0.045] p-4">
                <Icon className="h-5 w-5 text-blue-300" aria-hidden="true" />
                <h3 className="mt-3 text-sm font-semibold">{capability.title}</h3>
                <p className="mt-1.5 text-xs leading-5 text-slate-400">{capability.description}</p>
              </div>
            );
          })}
        </div>
      </div>

      <p className="relative z-10 max-w-2xl text-[11px] leading-5 text-slate-500">
        ByteQuest supplements learning and assessment. It does not issue TESDA certification or replace assessment by an accredited provider.
      </p>
    </div>
  );
}
