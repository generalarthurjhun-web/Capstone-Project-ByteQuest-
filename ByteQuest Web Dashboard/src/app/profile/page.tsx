"use client";

import { useEffect, useState } from "react";
import { Loader2, Save, ShieldCheck } from "lucide-react";
import { toast } from "sonner";
import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { PageHeader } from "@/components/dashboard/PageHeader";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useAuth } from "@/hooks/use-auth";
import { createClient } from "@/lib/supabase/client";

const roleLabel = { learner: "Learner", instructor: "Instructor", admin: "Administrator" } as const;

export default function ProfilePage() {
  const { user } = useAuth();
  const [fullName, setFullName] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [savingProfile, setSavingProfile] = useState(false);
  const [savingPassword, setSavingPassword] = useState(false);

  useEffect(() => {
    if (user) setFullName(user.fullName);
  }, [user]);

  const saveProfile = async (event: React.FormEvent) => {
    event.preventDefault();
    if (!user || fullName.trim().length < 2) return;
    setSavingProfile(true);
    const { error } = await createClient()
      .from("profiles")
      .update({ full_name: fullName.trim() })
      .eq("user_id", user.userId);
    if (error) toast.error(error.message);
    else toast.success("Profile name updated in Supabase.");
    setSavingProfile(false);
  };

  const updatePassword = async (event: React.FormEvent) => {
    event.preventDefault();
    if (password.length < 12) {
      toast.error("Use a password with at least 12 characters.");
      return;
    }
    if (password !== confirmPassword) {
      toast.error("Password confirmation does not match.");
      return;
    }
    setSavingPassword(true);
    const { error } = await createClient().auth.updateUser({ password });
    if (error) toast.error(error.message);
    else {
      toast.success("Password updated securely.");
      setPassword("");
      setConfirmPassword("");
    }
    setSavingPassword(false);
  };

  const initials = user?.fullName.split(/\s+/).filter(Boolean).slice(0, 2).map((part) => part[0]?.toUpperCase()).join("") || "U";

  return (
    <DashboardLayout>
      <div className="mx-auto max-w-5xl space-y-7">
        <PageHeader title="My profile" description="Manage your shared Supabase identity and sign-in security." />
        <div className="grid gap-6 lg:grid-cols-[18rem_minmax(0,1fr)]">
          <Card className="h-fit"><CardContent className="p-6 text-center"><Avatar className="mx-auto h-20 w-20"><AvatarFallback className="bg-primary/10 text-xl font-bold text-primary">{initials}</AvatarFallback></Avatar><h2 className="mt-4 text-lg font-bold">{user?.fullName ?? "Loading profile"}</h2><p className="mt-1 text-sm text-muted-foreground">{user ? roleLabel[user.role] : ""}</p><Badge variant={user?.status === "active" ? "secondary" : "outline"} className="mt-4"><ShieldCheck className="mr-1.5 h-3.5 w-3.5" aria-hidden="true" />{user?.status ?? "loading"}</Badge></CardContent></Card>
          <div className="space-y-6">
            <Card><CardHeader><CardTitle className="text-lg">Personal information</CardTitle><CardDescription>Your email is controlled by Supabase Auth and is not changed by this form.</CardDescription></CardHeader><CardContent><form onSubmit={saveProfile} className="space-y-4"><div className="grid gap-4 sm:grid-cols-2"><div className="space-y-2"><Label htmlFor="profile-name">Full name</Label><Input id="profile-name" value={fullName} onChange={(event) => setFullName(event.target.value)} minLength={2} maxLength={160} required /></div><div className="space-y-2"><Label htmlFor="profile-email">Email</Label><Input id="profile-email" type="email" value={user?.email ?? ""} disabled /></div></div><div className="flex justify-end"><Button type="submit" disabled={!user || savingProfile}>{savingProfile ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Save className="mr-2 h-4 w-4" />}Save profile</Button></div></form></CardContent></Card>
            <Card><CardHeader><CardTitle className="text-lg">Password</CardTitle><CardDescription>Choose a unique password with at least 12 characters.</CardDescription></CardHeader><CardContent><form onSubmit={updatePassword} className="space-y-4"><div className="grid gap-4 sm:grid-cols-2"><div className="space-y-2"><Label htmlFor="new-password">New password</Label><Input id="new-password" type="password" autoComplete="new-password" value={password} onChange={(event) => setPassword(event.target.value)} minLength={12} required /></div><div className="space-y-2"><Label htmlFor="confirm-password">Confirm new password</Label><Input id="confirm-password" type="password" autoComplete="new-password" value={confirmPassword} onChange={(event) => setConfirmPassword(event.target.value)} minLength={12} required /></div></div><div className="flex justify-end"><Button type="submit" variant="outline" disabled={savingPassword}>{savingPassword ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}Update password</Button></div></form></CardContent></Card>
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
}
