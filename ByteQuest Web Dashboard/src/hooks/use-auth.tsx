"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";
import { createClient } from "@/lib/supabase/client";
import type { AppProfile, UserRole } from "@/types/auth";

interface AuthContextType {
  user: AppProfile | null;
  loading: boolean;
  isAdmin: boolean;
  isInstructor: boolean;
  refreshProfile: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

function isApplicationRole(role: string): role is UserRole {
  return role === "learner" || role === "instructor" || role === "admin";
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<AppProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const supabase = useMemo(() => createClient(), []);

  const refreshProfile = useCallback(async () => {
    const {
      data: { user: authUser },
    } = await supabase.auth.getUser();

    if (!authUser) {
      setUser(null);
      setLoading(false);
      return;
    }

    const { data } = await supabase
      .from("profiles")
      .select(
        "id,user_id,full_name,email,avatar_url,role,status,created_at,updated_at,deactivated_at,deactivation_reason",
      )
      .eq("user_id", authUser.id)
      .maybeSingle();

    if (!data || !isApplicationRole(data.role)) {
      setUser(null);
      setLoading(false);
      return;
    }

    setUser({
      id: data.id,
      userId: data.user_id,
      fullName: data.full_name,
      email: data.email,
      avatarUrl: data.avatar_url,
      role: data.role,
      status: data.status,
      createdAt: data.created_at,
      updatedAt: data.updated_at,
      deactivatedAt: data.deactivated_at,
      deactivationReason: data.deactivation_reason,
    });
    setLoading(false);
  }, [supabase]);

  useEffect(() => {
    void supabase.auth.getSession().then(({ data }) => {
      if (data.session) supabase.realtime.setAuth(data.session.access_token);
      return refreshProfile();
    });

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      if (!session) {
        setUser(null);
        setLoading(false);
        return;
      }

      supabase.realtime.setAuth(session.access_token);
      queueMicrotask(() => void refreshProfile());
    });

    return () => subscription.unsubscribe();
  }, [refreshProfile, supabase]);

  useEffect(() => {
    if (!user?.userId) return;
    const channel = supabase
      .channel(`account-state:${user.userId}`)
      .on(
        "postgres_changes",
        {
          event: "UPDATE",
          schema: "public",
          table: "profiles",
          filter: `user_id=eq.${user.userId}`,
        },
        () => void refreshProfile(),
      )
      .subscribe();

    return () => {
      void supabase.removeChannel(channel);
    };
  }, [refreshProfile, supabase, user?.userId]);

  const value = useMemo<AuthContextType>(
    () => ({
      user,
      loading,
      isAdmin: user?.role === "admin",
      isInstructor: user?.role === "instructor",
      refreshProfile,
    }),
    [loading, refreshProfile, user],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) throw new Error("useAuth must be used within AuthProvider");
  return context;
}
