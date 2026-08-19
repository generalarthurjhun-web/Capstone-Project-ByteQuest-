"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { z } from "zod";
import { CheckCircle2, Loader2, Mail, Shield } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { PasswordInput } from "./PasswordInput";
import { FormErrorMessage } from "./FormErrorMessage";
import { createClient } from "@/lib/supabase/client";

const loginSchema = z.object({
  email: z.string().trim().email("Enter a valid email address."),
  password: z.string().min(1, "Password is required."),
});

export function LoginForm() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [resetting, setResetting] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [successRole, setSuccessRole] = useState<"admin" | "instructor" | null>(null);

  useEffect(() => {
    router.prefetch("/instructor/dashboard");
    router.prefetch("/admin/dashboard");
  }, [router]);

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    setErrors({});

    const parsed = loginSchema.safeParse({ email, password });
    if (!parsed.success) {
      const fieldErrors = parsed.error.flatten().fieldErrors;
      setErrors({
        email: fieldErrors.email?.[0] ?? "",
        password: fieldErrors.password?.[0] ?? "",
      });
      return;
    }

    setLoading(true);
    const supabase = createClient();

    try {
      const { data, error } = await supabase.auth.signInWithPassword(parsed.data);
      if (error || !data.user) throw error ?? new Error("Sign-in failed.");

      const { data: profile, error: profileError } = await supabase
        .from("profiles")
        .select("role,status")
        .eq("user_id", data.user.id)
        .single();

      if (profileError || !profile) {
        await supabase.auth.signOut();
        throw new Error("Your application profile is missing. Contact an administrator.");
      }

      if (profile.status !== "active") {
        await supabase.auth.signOut();
        throw new Error("This account is not active. Contact an administrator.");
      }

      if (profile.role !== "admin" && profile.role !== "instructor") {
        await supabase.auth.signOut();
        throw new Error("Learner accounts must use the ByteQuest mobile application.");
      }

      const destination = profile.role === "admin" ? "/admin/dashboard" : "/instructor/dashboard";
      setSuccessRole(profile.role);
      toast.success("Welcome back to ByteQuest.");
      await new Promise((resolve) => window.setTimeout(resolve, 560));
      router.replace(destination);
      router.refresh();
    } catch (error) {
      const message =
        error instanceof Error
          ? error.message
          : "Unable to sign in. Check your credentials and try again.";
      setErrors({ password: message });
      toast.error(message);
    } finally {
      setLoading(false);
    }
  };

  const handlePasswordReset = async () => {
    const parsedEmail = z.string().trim().email().safeParse(email);
    if (!parsedEmail.success) {
      setErrors({ email: "Enter your account email first." });
      return;
    }

    setResetting(true);
    try {
      const supabase = createClient();
      const { error } = await supabase.auth.resetPasswordForEmail(
        parsedEmail.data,
        { redirectTo: `${window.location.origin}/login` },
      );
      if (error) throw error;
      toast.success("If the account exists, a reset link has been sent.");
    } catch {
      toast.error("The reset request could not be completed.");
    } finally {
      setResetting(false);
    }
  };

  if (successRole) {
    return (
      <div className="login-success-enter py-6 text-center" role="status" aria-live="polite">
        <span className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-emerald-50 text-emerald-700 ring-1 ring-emerald-200">
          <CheckCircle2 className="h-7 w-7" aria-hidden="true" />
        </span>
        <h2 className="mt-5 text-xl font-bold tracking-[-0.025em]">Welcome back</h2>
        <p className="mt-2 text-sm leading-6 text-muted-foreground">
          Your {successRole === "admin" ? "Administrator" : "Instructor"} workspace is ready.
        </p>
        <div className="mx-auto mt-5 h-1 w-28 overflow-hidden rounded-full bg-muted" aria-hidden="true">
          <div className="h-full w-full origin-left animate-[progress_560ms_ease-out] rounded-full bg-primary" />
        </div>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-5" noValidate>
      <div className="space-y-2">
        <Label htmlFor="email" className="text-sm font-semibold text-foreground">
          Email
        </Label>
        <div className="relative">
          <Mail className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            id="email"
            type="email"
            autoComplete="email"
            value={email}
            onChange={(event) => setEmail(event.target.value)}
            placeholder="name@school.edu.ph"
            className={`h-11 pl-10 ${errors.email ? "border-destructive" : ""}`}
            aria-invalid={Boolean(errors.email) || undefined}
            aria-describedby={errors.email ? "email-error" : undefined}
          />
        </div>
        <div id="email-error"><FormErrorMessage message={errors.email} /></div>
      </div>

      <div className="space-y-2">
        <Label htmlFor="password" className="text-sm font-semibold text-foreground">
          Password
        </Label>
        <div className="relative">
          <Shield className="pointer-events-none absolute left-3 top-1/2 z-10 h-4 w-4 -translate-y-1/2 text-muted-foreground" aria-hidden="true" />
          <PasswordInput
            id="password"
            value={password}
            onChange={setPassword}
            error={Boolean(errors.password)}
            className="pl-10"
          />
        </div>
        <div role={errors.password ? "alert" : undefined}><FormErrorMessage message={errors.password} /></div>
      </div>

      <div className="flex justify-end">
        <button
          type="button"
          onClick={handlePasswordReset}
          disabled={resetting}
          className="rounded-md text-sm font-semibold text-primary underline-offset-4 transition-colors hover:text-primary/80 hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring disabled:opacity-50"
        >
          {resetting ? "Sending reset link…" : "Forgot password?"}
        </button>
      </div>

      <Button type="submit" className="h-11 w-full font-semibold" disabled={loading}>
        {loading ? (
          <>
            <Loader2 className="mr-2 h-4 w-4 animate-spin" />
            Verifying account…
          </>
        ) : (
          "Sign in securely"
        )}
      </Button>

      <div className="rounded-xl border border-border/80 bg-muted/35 p-3.5 text-xs leading-relaxed text-muted-foreground">
        <div className="flex items-start gap-2.5">
          <Shield className="mt-0.5 h-4 w-4 shrink-0 text-primary" aria-hidden="true" />
          <span>
            Instructor and Admin accounts are provisioned by an authorized Admin.
            Learners sign in through the mobile application.
          </span>
        </div>
      </div>
    </form>
  );
}
