import Image from "next/image";

export function LoginIllustration() {
  return (
    <section
      className="relative flex h-full w-full items-center justify-center overflow-hidden px-10 py-12 xl:px-16"
      aria-label="Welcome to ByteQuest"
    >
      <div aria-hidden="true" className="absolute left-[12%] top-[17%] h-px w-56 rotate-[68deg] bg-blue-200/60" />
      <div aria-hidden="true" className="absolute right-[9%] top-[10%] h-10 w-10 rotate-12 rounded-xl border-2 border-blue-200/80" />
      <div aria-hidden="true" className="absolute bottom-[10%] left-[7%] h-12 w-12 rounded-full border-2 border-blue-200/80" />
      <div aria-hidden="true" className="absolute bottom-[7%] right-[8%] flex gap-2">
        <span className="h-2.5 w-2.5 rounded-full bg-blue-200" />
        <span className="h-2.5 w-2.5 rounded-full bg-blue-300" />
        <span className="h-2.5 w-2.5 rounded-full bg-blue-400" />
      </div>

      <div className="relative z-10 flex w-full max-w-2xl flex-col items-center text-center">
        <div className="relative h-[clamp(260px,42vh,430px)] w-full max-w-[560px]">
          <Image
            src="/Computer Parts.png"
            alt="Computer systems servicing components including a desktop computer, motherboard, storage, memory, power supply, graphics card, and cables"
            fill
            className="object-contain drop-shadow-[0_24px_26px_rgba(15,23,42,0.16)]"
            sizes="(min-width: 1280px) 520px, 42vw"
            priority
          />
        </div>

        <div className="mt-5 flex items-center justify-center gap-2">
          <div className="relative h-8 w-8">
            <Image src="/ByteQuest Logo.png" alt="" fill className="object-contain" />
          </div>
          <span className="text-sm font-bold tracking-[-0.02em] text-slate-900">ByteQuest</span>
        </div>
        <h2 className="mt-5 text-2xl font-bold tracking-[-0.03em] text-slate-950 xl:text-3xl">
          Welcome to ByteQuest
        </h2>
        <p className="mt-3 max-w-lg text-sm leading-6 text-slate-600 xl:text-base">
          Manage learning modules, monitor learner progress, and review CSS NC II simulation performance.
        </p>
      </div>
    </section>
  );
}
