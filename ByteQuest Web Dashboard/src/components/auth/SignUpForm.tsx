"use client";

import { ShieldCheck } from "lucide-react";
import { AuthFooterLink } from "./AuthFooterLink";

export function SignUpForm() {
  return (
    <div className="space-y-5">
      <div className="rounded-xl border border-primary/20 bg-primary/[0.04] p-5">
        <ShieldCheck className="mb-3 h-7 w-7 text-primary" />
        <h2 className="font-semibold text-foreground">Provisioned staff accounts</h2>
        <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
          Public dashboard registration is disabled. An authorized Admin creates
          Instructor accounts and assigns access through the audited account workflow.
        </p>
      </div>
      <p className="text-sm leading-relaxed text-muted-foreground">
        If you need staff access, contact the ByteQuest system administrator. Learner
        registration and sign-in are handled by the mobile application.
      </p>
      <AuthFooterLink
        text="Already have a provisioned account?"
        linkText="Sign in"
        href="/login"
      />
    </div>
  );
}

