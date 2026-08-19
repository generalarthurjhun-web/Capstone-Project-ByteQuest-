"use client";

import { useEffect, useState, type ComponentType } from "react";
import Image from "next/image";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import {
  BarChart3,
  BookOpenCheck,
  ClipboardCheck,
  FileStack,
  FileText,
  GraduationCap,
  LayoutDashboard,
  ListChecks,
  LogOut,
  KeyRound,
  Menu,
  ScrollText,
  Settings2,
  ShieldCheck,
  UserCog,
  Users,
} from "lucide-react";
import { toast } from "sonner";
import { cn } from "@/lib/utils";
import { createClient } from "@/lib/supabase/client";
import { useAuth } from "@/hooks/use-auth";
import { useIsMobile } from "@/hooks/use-mobile";
import { Sheet, SheetContent, SheetTrigger } from "@/components/ui/sheet";
import { Button } from "@/components/ui/button";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";

interface NavigationItem {
  label: string;
  href: string;
  icon: ComponentType<{ className?: string }>;
}

interface NavigationGroup {
  label: string;
  items: NavigationItem[];
}

const instructorNavigation: NavigationGroup[] = [
  {
    label: "Dashboard",
    items: [{ label: "Overview", href: "/instructor/dashboard", icon: LayoutDashboard }],
  },
  {
    label: "Teaching",
    items: [
      { label: "Classes", href: "/classes", icon: GraduationCap },
      { label: "Learners", href: "/progress", icon: Users },
      { label: "Assignments & modules", href: "/modules", icon: BookOpenCheck },
    ],
  },
  {
    label: "Assessment",
    items: [
      { label: "Reviews & results", href: "/attempts", icon: ClipboardCheck },
      { label: "Quizzes", href: "/quizzes", icon: ListChecks },
    ],
  },
  {
    label: "Content",
    items: [{ label: "Resources", href: "/resources", icon: FileStack }],
  },
  {
    label: "Insights",
    items: [
      { label: "Analytics", href: "/analytics", icon: BarChart3 },
      { label: "Reports", href: "/reports", icon: FileText },
    ],
  },
];

const adminNavigation: NavigationGroup[] = [
  {
    label: "Dashboard",
    items: [{ label: "Overview", href: "/admin/dashboard", icon: LayoutDashboard }],
  },
  { label: "User management", items: [
    { label: "Users", href: "/users", icon: UserCog },
    { label: "Instructors", href: "/instructors", icon: ShieldCheck },
    { label: "Learners", href: "/learners", icon: Users },
    { label: "Access & scope", href: "/admin/access-scope", icon: KeyRound },
  ] },
  {
    label: "System",
    items: [
      { label: "TESDA sources", href: "/tesda-sources", icon: ShieldCheck },
      { label: "Resource governance", href: "/admin/resources", icon: FileStack },
      { label: "Settings & governance", href: "/settings", icon: Settings2 },
    ],
  },
  {
    label: "Insights",
    items: [
      { label: "System analytics", href: "/admin/analytics", icon: BarChart3 },
      { label: "System reports", href: "/admin/reports", icon: FileText },
    ],
  },
  {
    label: "Security & audit",
    items: [
      { label: "Security", href: "/admin/security", icon: KeyRound },
      { label: "Audit logs", href: "/logs", icon: ScrollText },
    ],
  },
];

function NavigationLink({
  item,
  pathname,
  onNavigate,
}: {
  item: NavigationItem;
  pathname: string;
  onNavigate: () => void;
}) {
  const router = useRouter();
  const active = pathname === item.href || pathname.startsWith(`${item.href}/`);
  const Icon = item.icon;

  return (
    <Link
      href={item.href}
      prefetch={false}
      onMouseEnter={() => router.prefetch(item.href)}
      onFocus={() => router.prefetch(item.href)}
      onClick={onNavigate}
      aria-current={active ? "page" : undefined}
      className={cn(
        "group relative flex min-h-10 cursor-pointer items-center gap-3 rounded-xl px-3 py-2 text-[12px] font-semibold transition-[background-color,color,box-shadow] duration-150 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-sidebar-ring focus-visible:ring-offset-1",
        active
          ? "bg-sidebar-accent text-sidebar-accent-foreground shadow-xs"
          : "text-sidebar-foreground/65 hover:bg-sidebar-accent/55 hover:text-sidebar-foreground active:bg-sidebar-accent/80",
      )}
    >
      <span
        aria-hidden="true"
        className={cn(
          "absolute left-0 h-4 w-0.5 rounded-r-full bg-sidebar-primary opacity-0 transition-opacity duration-150",
          active && "opacity-100",
        )}
      />
      <Icon
        className={cn(
          "h-[17px] w-[17px] shrink-0 transition-colors duration-150",
          active ? "text-sidebar-primary" : "text-sidebar-foreground/45 group-hover:text-sidebar-foreground/75",
        )}
      />
      <span className="truncate">{item.label}</span>
    </Link>
  );
}

function SidebarPanel({ onNavigate }: { onNavigate: () => void }) {
  const pathname = usePathname();
  const router = useRouter();
  const { user } = useAuth();
  const navigation = user?.role === "admin" ? adminNavigation : instructorNavigation;

  const handleLogout = async () => {
    const { error } = await createClient().auth.signOut();
    if (error) {
      toast.error("Unable to sign out. Please try again.");
      return;
    }
    toast.success("Signed out securely.");
    router.replace("/login");
    router.refresh();
  };

  return (
    <div className="flex h-full flex-col border-r border-sidebar-border bg-sidebar text-sidebar-foreground">
      <div className="border-b border-sidebar-border/80 px-4 py-4">
        <Link
          href={user?.role === "admin" ? "/admin/dashboard" : "/instructor/dashboard"}
          className="flex min-h-11 items-center gap-3 rounded-xl px-2 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-sidebar-ring"
        >
          <span className="relative flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-primary/[0.08] ring-1 ring-primary/10">
            <Image
              src="/ByteQuest Logo.png"
              alt=""
              fill
              className="object-contain p-1.5"
              priority
            />
          </span>
          <span className="min-w-0">
            <span className="block text-[15px] font-bold leading-tight tracking-[-0.02em]">ByteQuest</span>
            <span className="mt-0.5 block truncate text-[11px] leading-tight text-sidebar-foreground/55">
              {user?.role === "admin" ? "System administration" : "Instructor workspace"}
            </span>
          </span>
        </Link>
      </div>

      <nav aria-label="Primary navigation" className="flex-1 overflow-y-auto px-3 py-3">
        <div className="space-y-4">
          {navigation.map((group) => (
            <section key={group.label} aria-labelledby={`nav-${group.label.replace(/\s+/g, "-").toLowerCase()}`}>
              <h2
                id={`nav-${group.label.replace(/\s+/g, "-").toLowerCase()}`}
                className="mb-1.5 px-3 text-[10px] font-bold uppercase tracking-[0.14em] text-sidebar-foreground/45"
              >
                {group.label}
              </h2>
              <div className="space-y-0.5">
                {group.items.map((item) => (
                  <NavigationLink
                    key={item.href}
                    item={item}
                    pathname={pathname}
                    onNavigate={onNavigate}
                  />
                ))}
              </div>
            </section>
          ))}
        </div>
      </nav>

      <div className="space-y-1 border-t border-sidebar-border/80 px-3 py-3">
        <NavigationLink
          item={{ label: "My profile", href: "/profile", icon: UserCog }}
          pathname={pathname}
          onNavigate={onNavigate}
        />
        <AlertDialog>
          <AlertDialogTrigger asChild>
            <button className="flex min-h-10 w-full cursor-pointer items-center gap-3 rounded-xl px-3 py-2 text-[12px] font-semibold text-destructive/80 transition-colors duration-150 hover:bg-destructive/[0.06] hover:text-destructive focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-destructive">
              <LogOut className="h-[17px] w-[17px] shrink-0" />
              <span>Sign out</span>
            </button>
          </AlertDialogTrigger>
          <AlertDialogContent>
            <AlertDialogHeader>
              <AlertDialogTitle>Sign out of ByteQuest?</AlertDialogTitle>
              <AlertDialogDescription>
                Your authenticated dashboard session will end on this device.
              </AlertDialogDescription>
            </AlertDialogHeader>
            <AlertDialogFooter>
              <AlertDialogCancel>Stay signed in</AlertDialogCancel>
              <AlertDialogAction
                onClick={handleLogout}
                className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
              >
                Sign out
              </AlertDialogAction>
            </AlertDialogFooter>
          </AlertDialogContent>
        </AlertDialog>
      </div>
    </div>
  );
}

export function Sidebar() {
  const isMobile = useIsMobile();
  const [mounted, setMounted] = useState(false);
  const [open, setOpen] = useState(false);

  useEffect(() => setMounted(true), []);
  if (!mounted) return <div className="hidden w-[240px] shrink-0 md:block" />;

  if (isMobile) {
    return (
      <Sheet open={open} onOpenChange={setOpen}>
        <SheetTrigger asChild>
          <Button
            variant="ghost"
            size="icon"
            className="fixed left-3 top-2.5 z-50 h-10 w-10 md:hidden"
            aria-label="Open navigation"
          >
            <Menu className="h-5 w-5" />
          </Button>
        </SheetTrigger>
        <SheetContent side="left" className="w-[288px] p-0 sm:max-w-[320px]">
          <SidebarPanel onNavigate={() => setOpen(false)} />
        </SheetContent>
      </Sheet>
    );
  }

  return (
    <aside className="hidden h-full w-[240px] shrink-0 flex-col md:flex">
      <SidebarPanel onNavigate={() => undefined} />
    </aside>
  );
}
