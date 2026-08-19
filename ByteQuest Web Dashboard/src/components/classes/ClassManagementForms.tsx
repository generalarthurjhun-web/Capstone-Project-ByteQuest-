"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { z } from "zod";
import { Ban, Loader2, Settings2, UserMinus } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { createClient } from "@/lib/supabase/client";

export function EnrollLearnerForm({ classId }: { classId: string }) {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    const parsed = z.string().trim().email().safeParse(email);
    if (!parsed.success) {
      toast.error("Enter the learner's registered email address.");
      return;
    }

    setSubmitting(true);
    const { error } = await createClient().rpc("enroll_learner_by_email", {
      p_class_id: classId,
      p_email: parsed.data,
    });
    if (error) {
      const message =
        error.message.includes("ACTIVE_LEARNER_NOT_FOUND")
          ? "No active learner account matches that email."
          : error.message.includes("LEARNER_ALREADY_ENROLLED")
            ? "That learner is already enrolled in this class."
            : error.message;
      toast.error(message);
      setSubmitting(false);
      return;
    }

    setEmail("");
    toast.success("Learner enrolled.");
    router.refresh();
    setSubmitting(false);
  };

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-3 sm:flex-row sm:items-end">
      <div className="flex-1 space-y-2">
        <Label htmlFor="learner-email">Learner email</Label>
        <Input
          id="learner-email"
          type="email"
          value={email}
          onChange={(event) => setEmail(event.target.value)}
          placeholder="learner@school.edu.ph"
          required
        />
      </div>
      <Button type="submit" disabled={submitting} className="min-h-10">
        {submitting ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
        Enroll learner
      </Button>
    </form>
  );
}

export function DeactivateMembershipForm({
  membershipId,
  learnerName,
}: {
  membershipId: string;
  learnerName: string;
}) {
  const router = useRouter();
  const [expanded, setExpanded] = useState(false);
  const [reason, setReason] = useState("");
  const [submitting, setSubmitting] = useState(false);

  if (!expanded) {
    return (
      <Button
        type="button"
        variant="ghost"
        size="sm"
        onClick={() => setExpanded(true)}
        className="text-destructive hover:text-destructive"
      >
        <UserMinus className="mr-2 h-4 w-4" />
        Remove from class
      </Button>
    );
  }

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    if (reason.trim().length < 5) {
      toast.error("Provide a clear deactivation reason.");
      return;
    }

    setSubmitting(true);
    const { error } = await createClient().rpc("deactivate_class_membership", {
      p_membership_id: membershipId,
      p_reason: reason.trim(),
    });
    if (error) {
      toast.error(error.message);
      setSubmitting(false);
      return;
    }

    toast.success(`${learnerName} was removed from this class. History was retained.`);
    router.refresh();
  };

  return (
    <form onSubmit={handleSubmit} className="w-full space-y-2 sm:max-w-sm">
      <Label htmlFor={`deactivate-${membershipId}`}>Reason</Label>
      <Input
        id={`deactivate-${membershipId}`}
        value={reason}
        onChange={(event) => setReason(event.target.value)}
        placeholder="Reason for removing class access"
        minLength={5}
        required
      />
      <div className="flex justify-end gap-2">
        <Button type="button" variant="ghost" size="sm" onClick={() => setExpanded(false)}>
          Cancel
        </Button>
        <Button type="submit" variant="destructive" size="sm" disabled={submitting}>
          {submitting ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
          Confirm
        </Button>
      </div>
    </form>
  );
}

export function DeactivateLearnerAccountForm({
  learnerId,
  learnerName,
}: {
  learnerId: string;
  learnerName: string;
}) {
  const router = useRouter();
  const [expanded, setExpanded] = useState(false);
  const [reason, setReason] = useState("");
  const [submitting, setSubmitting] = useState(false);

  if (!expanded) {
    return (
      <Button
        type="button"
        variant="ghost"
        size="sm"
        onClick={() => setExpanded(true)}
        className="text-destructive hover:text-destructive"
      >
        <Ban className="mr-2 h-4 w-4" />
        Deactivate account
      </Button>
    );
  }

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    if (reason.trim().length < 5) {
      toast.error("Provide a clear account-deactivation reason.");
      return;
    }

    setSubmitting(true);
    const { error } = await createClient().rpc("instructor_deactivate_learner_account", {
      p_learner_id: learnerId,
      p_reason: reason.trim(),
    });
    if (error) {
      const message = error.message.includes("LEARNER_HAS_OTHER_INSTRUCTOR_SCOPE")
        ? "This learner has another Instructor's active class. Ask an Administrator to coordinate account deactivation."
        : error.message.includes("ASSIGNED_LEARNER_SCOPE_REQUIRED")
          ? "You can deactivate only a learner currently assigned to your class."
          : error.message;
      toast.error(message);
      setSubmitting(false);
      return;
    }

    toast.success(`${learnerName}'s ByteQuest account was deactivated. Academic history was retained.`);
    router.refresh();
  };

  return (
    <form onSubmit={handleSubmit} className="w-full space-y-2 rounded-lg bg-destructive/[0.04] p-3 sm:max-w-md">
      <p className="text-xs leading-relaxed text-muted-foreground">
        This blocks ByteQuest access and deactivates your active memberships. It is denied if another Instructor currently teaches this learner.
      </p>
      <Label htmlFor={`deactivate-account-${learnerId}`}>Required reason</Label>
      <Input
        id={`deactivate-account-${learnerId}`}
        value={reason}
        onChange={(event) => setReason(event.target.value)}
        placeholder="Reason for learner account deactivation"
        minLength={5}
        maxLength={1000}
        required
      />
      <div className="flex justify-end gap-2">
        <Button type="button" variant="ghost" size="sm" onClick={() => setExpanded(false)}>
          Cancel
        </Button>
        <Button type="submit" variant="destructive" size="sm" disabled={submitting}>
          {submitting ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
          Confirm account deactivation
        </Button>
      </div>
    </form>
  );
}

interface ActivityOption {
  id: string;
  title: string;
  deliveryMode: "practice" | "assessment" | "both";
}

interface RubricOption {
  id: string;
  activityVersionId: string;
  title: string;
}

export function AssignActivityForm({
  classId,
  activities,
  rubrics,
}: {
  classId: string;
  activities: ActivityOption[];
  rubrics: RubricOption[];
}) {
  const router = useRouter();
  const [activityId, setActivityId] = useState("");
  const [assignmentType, setAssignmentType] = useState<"practice" | "assessment">("practice");
  const [title, setTitle] = useState("");
  const [instructions, setInstructions] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const matchingRubric = rubrics.find((rubric) => rubric.activityVersionId === activityId);

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    if (!activityId || title.trim().length < 2) {
      toast.error("Select an activity and enter an assignment title.");
      return;
    }
    if (assignmentType === "assessment" && !matchingRubric) {
      toast.error("This activity has no approved matching rubric.");
      return;
    }

    setSubmitting(true);
    const { error } = await createClient().rpc("assign_activity", {
      p_class_id: classId,
      p_activity_version_id: activityId,
      p_rubric_version_id:
        assignmentType === "assessment"
          ? matchingRubric?.id ?? ""
          : (null as unknown as string),
      p_assignment_type: assignmentType,
      p_title: title.trim(),
      p_instructions: instructions.trim() || undefined,
      p_available_at: undefined,
      p_due_at: undefined,
    });

    if (error) {
      toast.error(error.message);
      setSubmitting(false);
      return;
    }

    setActivityId("");
    setTitle("");
    setInstructions("");
    toast.success("Activity assigned.");
    router.refresh();
    setSubmitting(false);
  };

  if (!activities.length) {
    return (
      <p className="rounded-lg border border-dashed border-border p-4 text-sm leading-relaxed text-muted-foreground">
        No published activity is available. An active approved TESDA source and a published
        module/activity version are required first.
      </p>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="grid gap-4 md:grid-cols-2">
      <div className="space-y-2">
        <Label>Published activity</Label>
        <Select value={activityId} onValueChange={setActivityId}>
          <SelectTrigger><SelectValue placeholder="Select activity" /></SelectTrigger>
          <SelectContent>
            {activities.map((activity) => (
              <SelectItem key={activity.id} value={activity.id}>{activity.title}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>
      <div className="space-y-2">
        <Label>Assignment type</Label>
        <Select
          value={assignmentType}
          onValueChange={(value) => setAssignmentType(value as "practice" | "assessment")}
        >
          <SelectTrigger><SelectValue /></SelectTrigger>
          <SelectContent>
            <SelectItem value="practice">Practice</SelectItem>
            <SelectItem value="assessment">Assessment</SelectItem>
          </SelectContent>
        </Select>
      </div>
      <div className="space-y-2 md:col-span-2">
        <Label htmlFor="assignment-title">Assignment title</Label>
        <Input
          id="assignment-title"
          value={title}
          onChange={(event) => setTitle(event.target.value)}
          maxLength={300}
          required
        />
      </div>
      <div className="space-y-2 md:col-span-2">
        <Label htmlFor="assignment-instructions">Class instructions (optional)</Label>
        <Textarea
          id="assignment-instructions"
          value={instructions}
          onChange={(event) => setInstructions(event.target.value)}
          rows={3}
        />
      </div>
      {assignmentType === "assessment" && !matchingRubric && activityId ? (
        <p className="text-sm text-amber-700 md:col-span-2">
          Assessment is blocked because this activity has no Admin-approved rubric.
        </p>
      ) : null}
      <div className="md:col-span-2">
        <Button type="submit" disabled={submitting}>
          {submitting ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
          Assign activity
        </Button>
      </div>
    </form>
  );
}

interface AssignmentPolicyOption {
  id: string;
  title: string;
}

export function AssignmentAccessPolicyForm({
  assignment,
  prerequisiteOptions,
}: {
  assignment: {
    id: string;
    attemptsAllowed: number | null;
    retryEnabled: boolean;
    retryAfterSeconds: number | null;
    prerequisiteAssignmentId: string | null;
  };
  prerequisiteOptions: AssignmentPolicyOption[];
}) {
  const router = useRouter();
  const [expanded, setExpanded] = useState(false);
  const [attemptsAllowed, setAttemptsAllowed] = useState(
    assignment.attemptsAllowed?.toString() ?? "",
  );
  const [retryEnabled, setRetryEnabled] = useState(assignment.retryEnabled);
  const [retryDelayMinutes, setRetryDelayMinutes] = useState(
    assignment.retryAfterSeconds === null
      ? ""
      : Math.ceil(assignment.retryAfterSeconds / 60).toString(),
  );
  const [prerequisiteId, setPrerequisiteId] = useState(
    assignment.prerequisiteAssignmentId ?? "none",
  );
  const [reason, setReason] = useState("");
  const [submitting, setSubmitting] = useState(false);

  if (!expanded) {
    return (
      <Button type="button" variant="outline" size="sm" onClick={() => setExpanded(true)}>
        <Settings2 className="mr-2 h-4 w-4" aria-hidden="true" />
        Access rules
      </Button>
    );
  }

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    const attempts = attemptsAllowed.trim() ? Number(attemptsAllowed) : null;
    const delayMinutes = retryDelayMinutes.trim() ? Number(retryDelayMinutes) : null;
    if (attempts !== null && (!Number.isInteger(attempts) || attempts <= 0)) {
      toast.error("Attempts allowed must be a positive whole number or left unset.");
      return;
    }
    if (delayMinutes !== null && (!Number.isInteger(delayMinutes) || delayMinutes < 0)) {
      toast.error("Retry delay must be a non-negative number of minutes or left unset.");
      return;
    }
    if (reason.trim().length < 5) {
      toast.error("Provide a clear reason for changing assignment access rules.");
      return;
    }

    setSubmitting(true);
    const { error } = await createClient().rpc("configure_assignment_access", {
      p_assignment_id: assignment.id,
      p_attempts_allowed: attempts as number,
      p_retry_enabled: retryEnabled,
      p_retry_after_seconds:
        delayMinutes === null ? (null as unknown as number) : delayMinutes * 60,
      p_prerequisite_assignment_id:
        prerequisiteId === "none" ? (null as unknown as string) : prerequisiteId,
      p_reason: reason.trim(),
    });
    if (error) {
      toast.error(error.message);
      setSubmitting(false);
      return;
    }

    toast.success("Assignment access rules updated and audited.");
    setReason("");
    setExpanded(false);
    router.refresh();
    setSubmitting(false);
  };

  return (
    <form
      onSubmit={handleSubmit}
      className="mt-3 grid gap-4 rounded-lg border border-border bg-muted/20 p-4 sm:grid-cols-2"
    >
      <div className="space-y-2">
        <Label htmlFor={`attempt-limit-${assignment.id}`}>Attempt limit (optional)</Label>
        <Input
          id={`attempt-limit-${assignment.id}`}
          inputMode="numeric"
          min={1}
          step={1}
          value={attemptsAllowed}
          onChange={(event) => setAttemptsAllowed(event.target.value)}
          placeholder="No institutional limit"
        />
        <p className="text-xs leading-relaxed text-muted-foreground">
          Leave unset when no institution-approved limit applies. This is not a TESDA rule.
        </p>
      </div>
      <div className="space-y-2">
        <Label htmlFor={`retry-delay-${assignment.id}`}>Retry delay in minutes (optional)</Label>
        <Input
          id={`retry-delay-${assignment.id}`}
          inputMode="numeric"
          min={0}
          step={1}
          value={retryDelayMinutes}
          onChange={(event) => setRetryDelayMinutes(event.target.value)}
          placeholder="No delay configured"
          disabled={!retryEnabled}
        />
      </div>
      <div className="space-y-2">
        <Label>Prerequisite assignment (optional)</Label>
        <Select value={prerequisiteId} onValueChange={setPrerequisiteId}>
          <SelectTrigger><SelectValue /></SelectTrigger>
          <SelectContent>
            <SelectItem value="none">No prerequisite configured</SelectItem>
            {prerequisiteOptions.map((option) => (
              <SelectItem key={option.id} value={option.id}>{option.title}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>
      <div className="flex items-start justify-between gap-4 rounded-lg border border-border bg-background p-3">
        <div>
          <Label htmlFor={`retry-enabled-${assignment.id}`}>Allow retry</Label>
          <p className="mt-1 text-xs leading-relaxed text-muted-foreground">
            Every attempt is retained. Disabling retry never deletes history.
          </p>
        </div>
        <Switch
          id={`retry-enabled-${assignment.id}`}
          checked={retryEnabled}
          onCheckedChange={setRetryEnabled}
        />
      </div>
      <div className="space-y-2 sm:col-span-2">
        <Label htmlFor={`policy-reason-${assignment.id}`}>Required reason</Label>
        <Textarea
          id={`policy-reason-${assignment.id}`}
          value={reason}
          onChange={(event) => setReason(event.target.value)}
          placeholder="Why these operational access rules are appropriate for this class"
          minLength={5}
          rows={2}
          required
        />
      </div>
      <div className="flex flex-wrap justify-end gap-2 sm:col-span-2">
        <Button type="button" variant="ghost" onClick={() => setExpanded(false)}>
          Cancel
        </Button>
        <Button type="submit" disabled={submitting}>
          {submitting ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
          Save access rules
        </Button>
      </div>
    </form>
  );
}

export function GrantBypassForm({
  classId,
  learners,
  modules,
}: {
  classId: string;
  learners: Array<{ id: string; name: string }>;
  modules: Array<{ id: string; title: string }>;
}) {
  const router = useRouter();
  const [learnerId, setLearnerId] = useState("");
  const [moduleId, setModuleId] = useState("");
  const [reason, setReason] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    if (!learnerId || !moduleId || reason.trim().length < 5) {
      toast.error("Select a learner and module, then provide a clear reason.");
      return;
    }

    setSubmitting(true);
    const { error } = await createClient().rpc("grant_coc_bypass", {
      p_class_id: classId,
      p_learner_id: learnerId,
      p_module_version_id: moduleId,
      p_reason: reason.trim(),
      p_scope: { effect: "UNLOCK_ACCESS_ONLY" },
    });
    if (error) {
      toast.error(error.message);
      setSubmitting(false);
      return;
    }

    toast.success("Access bypass granted without score, competency, XP, or rewards.");
    setReason("");
    router.refresh();
    setSubmitting(false);
  };

  if (!learners.length || !modules.length) {
    return (
      <p className="text-sm leading-relaxed text-muted-foreground">
        An active learner and a published module under an active TESDA source are required.
      </p>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="grid gap-4 md:grid-cols-2">
      <div className="space-y-2">
        <Label>Learner</Label>
        <Select value={learnerId} onValueChange={setLearnerId}>
          <SelectTrigger><SelectValue placeholder="Select learner" /></SelectTrigger>
          <SelectContent>{learners.map((learner) => <SelectItem key={learner.id} value={learner.id}>{learner.name}</SelectItem>)}</SelectContent>
        </Select>
      </div>
      <div className="space-y-2">
        <Label>Module version</Label>
        <Select value={moduleId} onValueChange={setModuleId}>
          <SelectTrigger><SelectValue placeholder="Select module" /></SelectTrigger>
          <SelectContent>{modules.map((module) => <SelectItem key={module.id} value={module.id}>{module.title}</SelectItem>)}</SelectContent>
        </Select>
      </div>
      <div className="space-y-2 md:col-span-2">
        <Label htmlFor="bypass-reason">Required reason</Label>
        <Textarea id="bypass-reason" value={reason} onChange={(event) => setReason(event.target.value)} rows={3} required />
      </div>
      <div className="md:col-span-2">
        <Button type="submit" disabled={submitting}>
          {submitting ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
          Grant access bypass
        </Button>
      </div>
    </form>
  );
}

export function ArchiveClassForm({ classId }: { classId: string }) {
  const router = useRouter();
  const [reason, setReason] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    if (reason.trim().length < 5) {
      toast.error("Provide a clear archive reason.");
      return;
    }

    setSubmitting(true);
    const { error } = await createClient().rpc("archive_class", {
      p_class_id: classId,
      p_reason: reason.trim(),
    });
    if (error) {
      toast.error(error.message);
      setSubmitting(false);
      return;
    }

    toast.success("Class archived. Enrollment history was retained.");
    router.push("/classes");
    router.refresh();
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-3">
      <div className="space-y-2">
        <Label htmlFor="archive-class-reason">Required reason</Label>
        <Textarea
          id="archive-class-reason"
          value={reason}
          onChange={(event) => setReason(event.target.value)}
          placeholder="Why this class is being archived"
          rows={3}
          required
        />
      </div>
      <Button type="submit" variant="destructive" disabled={submitting}>
        {submitting ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
        Archive class
      </Button>
    </form>
  );
}

export function CloseAssignmentForm({ assignmentId }: { assignmentId: string }) {
  const router = useRouter();
  const [expanded, setExpanded] = useState(false);
  const [reason, setReason] = useState("");
  const [submitting, setSubmitting] = useState(false);

  if (!expanded) {
    return (
      <Button type="button" variant="ghost" size="sm" onClick={() => setExpanded(true)}>
        Close
      </Button>
    );
  }

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    if (reason.trim().length < 5) {
      toast.error("Provide a clear close reason.");
      return;
    }
    setSubmitting(true);
    const { error } = await createClient().rpc("close_assignment", {
      p_assignment_id: assignmentId,
      p_reason: reason.trim(),
    });
    if (error) {
      toast.error(error.message);
      setSubmitting(false);
      return;
    }
    toast.success("Assignment closed. Existing attempts were retained.");
    router.refresh();
  };

  return (
    <form onSubmit={handleSubmit} className="min-w-56 space-y-2">
      <Label htmlFor={`close-${assignmentId}`}>Required reason</Label>
      <Input
        id={`close-${assignmentId}`}
        value={reason}
        onChange={(event) => setReason(event.target.value)}
        minLength={5}
        required
      />
      <div className="flex justify-end gap-2">
        <Button type="button" variant="ghost" size="sm" onClick={() => setExpanded(false)}>
          Cancel
        </Button>
        <Button type="submit" variant="outline" size="sm" disabled={submitting}>
          {submitting ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
          Confirm close
        </Button>
      </div>
    </form>
  );
}
