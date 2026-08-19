"use client";

import { useEffect, useMemo, useState } from "react";
import { usePathname, useRouter } from "next/navigation";
import { ChevronDown, Search } from "lucide-react";
import { toast } from "sonner";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import {
  CommandDialog,
  CommandEmpty,
  CommandGroup,
  CommandInput,
  CommandItem,
  CommandList,
} from "@/components/ui/command";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { useAuth } from "@/hooks/use-auth";
import { createClient } from "@/lib/supabase/client";

const roleLabel = { learner: "Learner", instructor: "Instructor", admin: "Administrator" } as const;

type SearchGroup = { label: string; items: [string, string][] };

const instructorSearch: SearchGroup[] = [
  { label: "Dashboard", items: [["Overview", "/instructor/dashboard"]] },
  { label: "Teaching", items: [["Classes", "/classes"], ["Learners", "/progress"], ["Assignments and modules", "/modules"]] },
  { label: "Assessment", items: [["Reviews and results", "/attempts"], ["Quizzes", "/quizzes"]] },
  { label: "Content", items: [["Resources", "/resources"]] },
  { label: "Insights", items: [["Analytics", "/analytics"], ["Reports", "/reports"]] },
];

const adminSearch: SearchGroup[] = [
  { label: "Dashboard", items: [["Overview", "/admin/dashboard"]] },
  { label: "User management", items: [["Users", "/users"], ["Instructors", "/instructors"], ["Learners", "/learners"], ["Access and scope", "/admin/access-scope"]] },
  { label: "System", items: [["TESDA sources", "/tesda-sources"], ["Resource governance", "/admin/resources"], ["Settings and governance", "/settings"]] },
  { label: "Insights", items: [["System analytics", "/admin/analytics"], ["System reports", "/admin/reports"]] },
  { label: "Security", items: [["Security", "/admin/security"], ["Audit logs", "/logs"]] },
];

const pageTitles: Record<string, string> = {
  "/instructor/dashboard": "Instructor overview",
  "/admin/dashboard": "Administration overview",
  "/classes": "Classes",
  "/progress": "Learners",
  "/modules": "Assignments & modules",
  "/attempts": "Assessment review",
  "/quizzes": "Quizzes",
  "/resources": "Resources",
  "/analytics": "Analytics",
  "/reports": "Reports",
  "/users": "Users & accounts",
  "/instructors": "Instructors",
  "/learners": "Learners",
  "/admin/access-scope": "Access & scope",
  "/tesda-sources": "TESDA sources",
  "/admin/resources": "Resource governance",
  "/settings": "Governance & settings",
  "/admin/analytics": "System analytics",
  "/admin/reports": "System reports",
  "/admin/security": "Security",
  "/logs": "Audit logs",
  "/profile": "My profile",
};

function currentPageTitle(pathname: string) {
  const exact = pageTitles[pathname];
  if (exact) return exact;
  const root = Object.keys(pageTitles)
    .filter((path) => pathname.startsWith(`${path}/`))
    .sort((a, b) => b.length - a.length)[0];
  return root ? pageTitles[root] : "ByteQuest workspace";
}

export function Topbar() {
  const router = useRouter();
  const pathname = usePathname();
  const { user } = useAuth();
  const [commandOpen, setCommandOpen] = useState(false);
  const [logoutOpen, setLogoutOpen] = useState(false);
  const navigation = useMemo(
    () => (user?.role === "admin" ? adminSearch : instructorSearch),
    [user?.role],
  );

  useEffect(() => {
    const handleKeydown = (event: KeyboardEvent) => {
      if (event.key.toLowerCase() === "k" && (event.ctrlKey || event.metaKey)) {
        event.preventDefault();
        setCommandOpen((open) => !open);
      }
    };
    document.addEventListener("keydown", handleKeydown);
    return () => document.removeEventListener("keydown", handleKeydown);
  }, []);

  const handleLogout = async () => {
    const { error } = await createClient().auth.signOut();
    if (error) {
      toast.error("Sign out failed. Please try again.");
      return;
    }
    toast.success("Signed out securely.");
    router.replace("/login");
    router.refresh();
  };

  const navigate = (href: string) => {
    setCommandOpen(false);
    router.push(href);
  };

  const initials =
    user?.fullName
      .split(/\s+/)
      .filter(Boolean)
      .slice(0, 2)
      .map((part) => part[0]?.toUpperCase())
      .join("") || "BQ";

  return (
    <>
      <header
        role="banner"
        className="sticky top-0 z-20 flex h-[68px] items-center justify-between gap-3 border-b border-border/70 bg-background/92 px-3 pl-14 print:hidden md:px-6"
      >
        <div className="hidden min-w-0 lg:block">
            <p className="truncate text-[13px] font-semibold tracking-[-0.01em] text-foreground">
            {currentPageTitle(pathname)}
          </p>
          <p className="mt-0.5 text-[11px] text-muted-foreground">
            {user?.role === "admin" ? "System governance" : "Teaching workspace"}
          </p>
        </div>

        <button
          type="button"
          onClick={() => setCommandOpen(true)}
          className="group flex min-h-10 min-w-0 flex-1 cursor-pointer items-center gap-2 rounded-xl border border-border/80 bg-card px-3 text-[13px] text-muted-foreground shadow-xs transition-[border-color,background-color,box-shadow] duration-150 hover:border-primary/25 hover:bg-card hover:shadow-card focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring lg:max-w-md"
          aria-label="Search dashboard navigation"
        >
          <Search className="h-4 w-4 shrink-0 text-muted-foreground/75 transition-colors group-hover:text-primary" aria-hidden="true" />
          <span className="truncate">Search pages and actions</span>
          <kbd className="ml-auto hidden rounded-md border border-border bg-card px-1.5 py-0.5 font-sans text-[10px] font-semibold text-muted-foreground sm:inline">
            Ctrl K
          </kbd>
        </button>

        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <button
              type="button"
              className="flex min-h-11 cursor-pointer items-center gap-2 rounded-xl px-1.5 py-1 transition-colors duration-150 hover:bg-muted/65 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring sm:px-2"
              aria-label="Open account menu"
            >
              <Avatar className="h-8 w-8 ring-2 ring-background">
                <AvatarFallback className="bg-primary/10 text-xs font-bold text-primary">{initials}</AvatarFallback>
              </Avatar>
              <div className="hidden max-w-44 text-left sm:block">
                <p className="truncate text-xs font-semibold">{user?.fullName ?? "ByteQuest staff"}</p>
                <p className="text-[11px] text-muted-foreground">{user ? roleLabel[user.role] : "Loading"}</p>
              </div>
              <ChevronDown className="hidden h-3.5 w-3.5 text-muted-foreground sm:block" aria-hidden="true" />
            </button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="w-56">
            <DropdownMenuLabel>
              <span className="block text-sm">{user?.fullName ?? "My account"}</span>
              <span className="mt-0.5 block text-xs font-normal text-muted-foreground">{user?.email}</span>
            </DropdownMenuLabel>
            <DropdownMenuSeparator />
            <DropdownMenuItem onSelect={() => router.push("/profile")}>Profile and password</DropdownMenuItem>
            {user?.role === "admin" ? (
              <DropdownMenuItem onSelect={() => router.push("/settings")}>System settings</DropdownMenuItem>
            ) : null}
            <DropdownMenuSeparator />
            <DropdownMenuItem className="text-destructive focus:text-destructive" onSelect={() => setLogoutOpen(true)}>
              Sign out
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </header>

      <CommandDialog open={commandOpen} onOpenChange={setCommandOpen}>
        <CommandInput placeholder="Search available pages…" />
        <CommandList>
          <CommandEmpty>No accessible page found.</CommandEmpty>
          {navigation.map((group) => (
            <CommandGroup key={group.label} heading={group.label}>
              {group.items.map(([label, href]) => (
                <CommandItem key={href} onMouseEnter={() => router.prefetch(href)} onFocus={() => router.prefetch(href)} onSelect={() => navigate(href)}>
                  {label}
                </CommandItem>
              ))}
            </CommandGroup>
          ))}
          <CommandGroup heading="Account">
            <CommandItem onSelect={() => navigate("/profile")}>My profile</CommandItem>
          </CommandGroup>
        </CommandList>
      </CommandDialog>

      <AlertDialog open={logoutOpen} onOpenChange={setLogoutOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Sign out of ByteQuest?</AlertDialogTitle>
            <AlertDialogDescription>Your current Supabase session will end on this browser.</AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Stay signed in</AlertDialogCancel>
            <AlertDialogAction onClick={handleLogout}>Sign out</AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}
