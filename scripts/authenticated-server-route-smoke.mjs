import { randomBytes, randomUUID } from "node:crypto";
import { createServerClient } from "@supabase/ssr";
import { createClient } from "@supabase/supabase-js";

const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
const publishableKey =
  process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ??
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const webBaseUrl = process.env.BYTEQUEST_WEB_BASE_URL ?? "http://127.0.0.1:3100";

if (!url || !publishableKey || !serviceRoleKey) {
  throw new Error("Supabase E2E environment variables are unavailable.");
}

const runId = `bq-route-e2e-${new Date().toISOString().replace(/\D/g, "").slice(0, 14)}-${randomUUID().slice(0, 8)}`;
const password = process.env.BYTEQUEST_E2E_PASSWORD;
if (!password) {
  throw new Error("BYTEQUEST_E2E_PASSWORD is required for authenticated lifecycle scripts.");
}
const domain = "bytequest-e2e.invalid";
const admin = createClient(url, serviceRoleKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});

const accountSpecs = [
  { key: "admin", role: "admin", name: "ByteQuest Route E2E Admin" },
  { key: "instructor1", role: "instructor", name: "ByteQuest Route E2E Instructor One" },
  { key: "instructor2", role: "instructor", name: "ByteQuest Route E2E Instructor Two" },
  { key: "learnerA", role: "learner", name: "ByteQuest Route E2E Learner A" },
  { key: "learnerB", role: "learner", name: "ByteQuest Route E2E Learner B" },
].map((account) => ({
  ...account,
  email: `${runId}-${account.key.toLowerCase()}@${domain}`,
}));

const users = new Map();
const sessions = new Map();
const classIds = [];
const resourceIds = [];
const storagePaths = [];
const results = [];

function record(name, status, detail = "") {
  results.push({ name, status, detail });
}

async function isDeniedPageResponse(response) {
  if ([307, 308].includes(response.status)) return true;
  if (response.status !== 200) return false;
  const html = await response.text();
  return html.includes("NEXT_REDIRECT") || html.includes("error=staff_only");
}

function createCookieSessionClient() {
  const jar = new Map();
  const client = createServerClient(url, publishableKey, {
    cookies: {
      getAll: () => Array.from(jar, ([name, value]) => ({ name, value })),
      setAll: (cookies) => {
        for (const cookie of cookies) {
          if (cookie.options?.maxAge === 0 || cookie.value === "") jar.delete(cookie.name);
          else jar.set(cookie.name, cookie.value);
        }
      },
    },
  });
  return {
    client,
    cookies: jar,
    cookieHeader: () =>
      Array.from(jar, ([name, value]) => `${name}=${value}`).join("; "),
  };
}

async function request(session, path, init = {}) {
  const headers = new Headers(init.headers);
  if (session) headers.set("cookie", session.cookieHeader());
  const response = await fetch(`${webBaseUrl}${path}`, { ...init, headers, redirect: "manual" });
  if (session && typeof response.headers.getSetCookie === "function") {
    for (const value of response.headers.getSetCookie()) {
      const [pair] = value.split(";", 1);
      const separator = pair.indexOf("=");
      if (separator <= 0) continue;
      const name = pair.slice(0, separator).trim();
      const cookieValue = pair.slice(separator + 1);
      if (cookieValue) session.cookies.set(name, cookieValue);
      else session.cookies.delete(name);
    }
  }
  return response;
}

async function createAccounts() {
  for (const account of accountSpecs) {
    const { data, error } = await admin.auth.admin.createUser({
      email: account.email,
      password,
      email_confirm: true,
      user_metadata: {
        full_name: account.name,
        bytequest_test_account: true,
        bytequest_test_run: runId,
      },
    });
    if (error || !data.user) {
      throw new Error(`Could not create ${account.key}: ${error?.message ?? "missing user"}`);
    }
    users.set(account.key, data.user.id);

    const { error: profileError } = await admin
      .from("profiles")
      .update({ full_name: account.name, role: account.role, status: "active" })
      .eq("user_id", data.user.id);
    if (profileError) throw new Error(`Could not configure ${account.key}: ${profileError.message}`);

    const session = createCookieSessionClient();
    const { data: login, error: loginError } = await session.client.auth.signInWithPassword({
      email: account.email,
      password,
    });
    if (loginError || login.user?.id !== data.user.id || !session.cookieHeader()) {
      throw new Error(`Could not establish SSR session for ${account.key}: ${loginError?.message ?? "UUID/cookie mismatch"}`);
    }
    sessions.set(account.key, session);
  }
  record("five disposable users establish real Supabase SSR cookie sessions", "PASS");
}

async function exerciseProtectedPages() {
  const adminSession = sessions.get("admin");
  const instructorSession = sessions.get("instructor1");
  const learnerSession = sessions.get("learnerA");

  const adminCrossRole = await request(adminSession, "/attempts");
  const instructorCrossRole = await request(instructorSession, "/users");
  const learnerStaffPage = await request(learnerSession, "/classes");
  const anonymousPage = await request(null, "/admin/dashboard");
  const adminPage = await request(adminSession, "/admin/dashboard");
  const instructorPage = await request(instructorSession, "/instructor/dashboard");
  const classesPage = await request(instructorSession, "/classes");
  const resourcesPage = await request(instructorSession, "/resources");
  const quizzesPage = await request(instructorSession, "/quizzes");
  const analyticsPage = await request(instructorSession, "/analytics?range=30");
  const reportsPage = await request(instructorSession, "/reports?type=criterion_analysis&range=30");
  const adminAnalyticsPage = await request(adminSession, "/admin/analytics?range=30");
  const adminDestinationPaths = [
    "/admin/dashboard",
    "/users",
    "/instructors",
    "/learners",
    "/admin/access-scope",
    "/tesda-sources",
    "/admin/resources",
    "/admin/analytics?range=30",
    "/admin/reports?range=30",
    "/logs",
    "/admin/security",
    "/profile",
    "/settings",
  ];
  const adminDestinationPages = await Promise.all(adminDestinationPaths.map((path) => request(adminSession, path)));
  const anonymousAdminDestinationPages = await Promise.all(adminDestinationPaths.map((path) => request(null, path)));
  const instructorAdminDestinationPages = await Promise.all(adminDestinationPaths.map((path) => request(instructorSession, path)));
  const adminInstructorAnalytics = await request(adminSession, "/analytics");
  const instructorAdminAnalytics = await request(instructorSession, "/admin/analytics");
  const learnerReportsPage = await request(learnerSession, "/reports");
  const anonymousReportExport = await request(null, "/api/reports/export?type=class_performance&range=30");
  const learnerReportExport = await request(learnerSession, "/api/reports/export?type=class_performance&range=30");
  const adminReportExport = await request(adminSession, "/api/reports/export?type=class_performance&range=30");
  const instructorReportExport = await request(instructorSession, "/api/reports/export?type=class_performance&range=30");
  const adminQuizPage = await request(adminSession, "/quizzes");
  const adminResourcesPage = await request(adminSession, "/resources");
  const anonymousAiDraft = await request(null, "/api/instructor/quizzes/ai-draft", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({}),
  });
  const learnerAiDraft = await request(learnerSession, "/api/instructor/quizzes/ai-draft", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({}),
  });
  const instructorInvalidAiDraft = await request(instructorSession, "/api/instructor/quizzes/ai-draft", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({}),
  });

  if (adminPage.status !== 200 || !(await adminPage.text()).includes("ByteQuest")) {
    throw new Error(`Admin dashboard render failed with status ${adminPage.status}`);
  }
  if (instructorPage.status !== 200 || !(await instructorPage.text()).includes("ByteQuest")) {
    throw new Error(`Instructor dashboard render failed with status ${instructorPage.status}`);
  }
  if (classesPage.status !== 200 || !(await classesPage.text()).includes("Classes")) {
    throw new Error(`Instructor classes render failed with status ${classesPage.status}`);
  }
  if (resourcesPage.status !== 200 || !(await resourcesPage.text()).includes("Learning resources")) {
    throw new Error(`Instructor resource library render failed with status ${resourcesPage.status}`);
  }
  if (quizzesPage.status !== 200 || !(await quizzesPage.text()).includes("Instructor quizzes")) {
    throw new Error(`Instructor quiz workspace render failed with status ${quizzesPage.status}`);
  }
  const analyticsHtml = await analyticsPage.text();
  if (analyticsPage.status !== 200 || !analyticsHtml.includes("Analytics")) {
    throw new Error(`Instructor analytics render failed with status ${analyticsPage.status}: ${analyticsHtml.slice(0, 180)}`);
  }
  const reportsHtml = await reportsPage.text();
  if (reportsPage.status !== 200 || !reportsHtml.includes("Reports")) {
    throw new Error(`Instructor report preview failed with status ${reportsPage.status}: ${reportsHtml.slice(0, 180)}`);
  }
  const adminAnalyticsHtml = await adminAnalyticsPage.text();
  if (
    adminAnalyticsPage.status !== 200 ||
    !adminAnalyticsHtml.includes("AdminSystemAnalyticsDashboard") ||
    !adminAnalyticsHtml.includes("activeLearners") ||
    adminAnalyticsHtml.includes("Internal Server Error")
  ) {
    const diagnostic = (adminAnalyticsHtml.match(/.{0,100}(?:error|digest|analytics).{0,240}/gi) ?? [])
      .slice(-4)
      .join(" | ");
    throw new Error(`Admin system analytics render failed with status ${adminAnalyticsPage.status}: ${diagnostic || adminAnalyticsHtml.slice(0, 180)}`);
  }
  for (let index = 0; index < adminDestinationPages.length; index += 1) {
    const response = adminDestinationPages[index];
    const html = await response.text();
    if (response.status !== 200 || html.includes("Internal Server Error") || html.includes("Application error")) {
      throw new Error(`Admin destination ${adminDestinationPaths[index]} failed with status ${response.status}`);
    }
  }
  for (let index = 0; index < adminDestinationPaths.length; index += 1) {
    // Profile is a shared client-rendered destination. DashboardLayout's
    // ProtectedRoute removes its content and redirects unauthenticated users
    // before any profile data is queried or rendered.
    if (adminDestinationPaths[index] === "/profile") continue;
    if (!(await isDeniedPageResponse(anonymousAdminDestinationPages[index]))) {
      throw new Error(`Anonymous Admin destination ${adminDestinationPaths[index]} was not denied`);
    }
    if (!(await isDeniedPageResponse(instructorAdminDestinationPages[index]))) {
      throw new Error(`Instructor reached Admin destination ${adminDestinationPaths[index]}`);
    }
  }
  record("all Admin sidebar destinations render for an authenticated Admin session", "PASS");
  for (const [label, response] of [
    ["Admin Instructor analytics", adminInstructorAnalytics],
    ["Instructor Admin analytics", instructorAdminAnalytics],
    ["Learner reports", learnerReportsPage],
  ]) {
    if (!(await isDeniedPageResponse(response))) {
      throw new Error(`${label} cross-role access returned ${response.status}, expected redirect`);
    }
  }
  if (anonymousReportExport.status !== 401 || learnerReportExport.status !== 403 || adminReportExport.status !== 403) {
    throw new Error(`Report export boundary failed: anonymous=${anonymousReportExport.status}, learner=${learnerReportExport.status}, admin=${adminReportExport.status}`);
  }
  if (
    instructorReportExport.status !== 200 ||
    !instructorReportExport.headers.get("content-type")?.startsWith("text/csv") ||
    !instructorReportExport.headers.get("content-disposition")?.includes("bytequest-class_performance")
  ) {
    throw new Error(`Instructor report export failed with status ${instructorReportExport.status}`);
  }
  if (![307, 308].includes(adminQuizPage.status)) {
    throw new Error(`Admin ordinary quiz workspace was not redirected (${adminQuizPage.status})`);
  }
  if (!(await isDeniedPageResponse(adminResourcesPage))) {
    throw new Error(`Admin ordinary resource workspace was not denied (${adminResourcesPage.status})`);
  }
  if (anonymousAiDraft.status !== 403 || learnerAiDraft.status !== 403 || instructorInvalidAiDraft.status !== 400) {
    throw new Error(`AI draft route boundary failed: anonymous=${anonymousAiDraft.status}, learner=${learnerAiDraft.status}, instructor-invalid=${instructorInvalidAiDraft.status}`);
  }
  if (!process.env.OPENROUTER_API_KEY) {
    const unconfiguredAiDraft = await request(instructorSession, "/api/instructor/quizzes/ai-draft", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        quizVersionId: randomUUID(),
        activityVersionId: randomUUID(),
        topic: "Secure configuration check",
        difficulty: "foundation",
        itemCount: 1,
        itemTypes: ["multiple_choice"],
      }),
    });
    if (unconfiguredAiDraft.status !== 503) {
      throw new Error(`Unconfigured AI provider returned ${unconfiguredAiDraft.status}, expected fail-closed 503`);
    }
    record("AI draft provider fails closed when the server-only key is absent", "PASS");
  }
  if (
    ![307, 308].includes(adminCrossRole.status) ||
    !(
      adminCrossRole.headers.get("location")?.endsWith("/admin/dashboard") ||
      adminCrossRole.headers.get("location")?.includes("error=staff_only")
    )
  ) {
    throw new Error(`Admin cross-role route was not redirected (${adminCrossRole.status}, ${adminCrossRole.headers.get("location")})`);
  }
  if (
    ![307, 308].includes(instructorCrossRole.status) ||
    !(
      instructorCrossRole.headers.get("location")?.endsWith("/instructor/dashboard") ||
      instructorCrossRole.headers.get("location")?.includes("error=staff_only")
    )
  ) {
    throw new Error(`Instructor Admin route was not redirected (${instructorCrossRole.status}, ${instructorCrossRole.headers.get("location")})`);
  }
  if (
    ![307, 308].includes(learnerStaffPage.status) ||
    !learnerStaffPage.headers.get("location")?.includes("error=staff_only")
  ) {
    throw new Error(`Learner staff route was not denied (${learnerStaffPage.status})`);
  }
  const anonymousPageDenied = await isDeniedPageResponse(anonymousPage);
  const anonymousRedirectLocation = anonymousPage.headers.get("location");
  if (
    !anonymousPageDenied ||
    ([307, 308].includes(anonymousPage.status) && !anonymousRedirectLocation?.endsWith("/login"))
  ) {
    throw new Error(`Anonymous protected route was not denied (${anonymousPage.status})`);
  }

  record("analytics pages, report previews/exports, quiz workspace, and protected routes enforce role-safe SSR boundaries", "PASS");
}

async function exerciseResourceRoutes() {
  const instructor1 = sessions.get("instructor1");
  const instructor2 = sessions.get("instructor2");
  const learnerA = sessions.get("learnerA");
  const learnerB = sessions.get("learnerB");

  const { data: classroom, error: classError } = await instructor1.client.rpc("create_class", {
    p_title: `ByteQuest server-route E2E ${runId}`,
    p_class_code: `RT-${randomUUID().slice(0, 8)}`,
  });
  if (classError || !classroom?.id) throw new Error(`Class creation failed: ${classError?.message}`);
  classIds.push(classroom.id);

  const { error: enrollError } = await instructor1.client.rpc("enroll_learner", {
    p_class_id: classroom.id,
    p_learner_id: users.get("learnerA"),
  });
  if (enrollError) throw new Error(`Enrollment failed: ${enrollError.message}`);

  const unauthorizedForm = new FormData();
  unauthorizedForm.set("title", "Cross-scope resource");
  unauthorizedForm.set("description", `TEST_ONLY ${runId}`);
  unauthorizedForm.set("file", new Blob(["%PDF-1.4\n"], { type: "application/pdf" }), "proof.pdf");
  const crossUpload = await request(
    instructor2,
    `/api/classes/${classroom.id}/resources`,
    { method: "POST", body: unauthorizedForm },
  );
  if (crossUpload.status !== 403) {
    throw new Error(`Cross-Instructor route upload returned ${crossUpload.status}, expected 403: ${(await crossUpload.text()).slice(0, 1800)}`);
  }

  const invalidForm = new FormData();
  invalidForm.set("title", "Rejected executable");
  invalidForm.set("file", new Blob(["MZ"], { type: "application/x-msdownload" }), "payload.exe");
  const invalidUpload = await request(
    instructor1,
    `/api/classes/${classroom.id}/resources`,
    { method: "POST", body: invalidForm },
  );
  if (invalidUpload.status !== 415) {
    throw new Error(`Executable upload returned ${invalidUpload.status}, expected 415`);
  }

  const oversizedForm = new FormData();
  oversizedForm.set("title", "Rejected oversized resource");
  oversizedForm.set(
    "file",
    new Blob([new Uint8Array(50 * 1024 * 1024 + 1)], { type: "application/pdf" }),
    "oversized.pdf",
  );
  const oversizedUpload = await request(
    instructor1,
    `/api/classes/${classroom.id}/resources`,
    { method: "POST", body: oversizedForm },
  );
  if (oversizedUpload.status !== 413) {
    throw new Error(`Oversized upload returned ${oversizedUpload.status}, expected 413`);
  }
  record("resource upload route denies cross-scope, executable, and oversized requests", "PASS");

  const form = new FormData();
  form.set("title", "Authenticated route PDF proof");
  form.set("description", `TEST_ONLY ${runId}`);
  form.set("file", new Blob(["%PDF-1.4\n% ByteQuest route E2E\n"], { type: "application/pdf" }), "proof.pdf");
  const upload = await request(instructor1, `/api/classes/${classroom.id}/resources`, {
    method: "POST",
    body: form,
  });
  const uploadBody = await upload.json().catch(() => null);
  if (upload.status !== 201 || !uploadBody?.resource?.id || !uploadBody.resource.storage_path) {
    throw new Error(`Authorized route upload failed (${upload.status}): ${JSON.stringify(uploadBody)}`);
  }
  const resource = uploadBody.resource;
  resourceIds.push(resource.id);
  storagePaths.push(resource.storage_path);

  const allowedRead = await request(
    learnerA,
    `/api/classes/${classroom.id}/resources/${resource.id}`,
  );
  const wrongLearnerRead = await request(
    learnerB,
    `/api/classes/${classroom.id}/resources/${resource.id}`,
  );
  const anonymousRead = await request(
    null,
    `/api/classes/${classroom.id}/resources/${resource.id}`,
  );
  if (allowedRead.status !== 307 || !allowedRead.headers.get("location")) {
    throw new Error(`Authorized learner read returned ${allowedRead.status}, expected signed redirect`);
  }
  if (wrongLearnerRead.status !== 404 || anonymousRead.status !== 403) {
    throw new Error(`Resource read isolation failed: learnerB=${wrongLearnerRead.status}, anonymous=${anonymousRead.status}`);
  }

  const wrongInstructorArchive = await request(
    instructor2,
    `/api/classes/${classroom.id}/resources/${resource.id}`,
    {
      method: "DELETE",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ reason: "Cross-Instructor archive denial" }),
    },
  );
  if (wrongInstructorArchive.status !== 404) {
    throw new Error(`Cross-Instructor archive returned ${wrongInstructorArchive.status}, expected 404`);
  }

  const archive = await request(
    instructor1,
    `/api/classes/${classroom.id}/resources/${resource.id}`,
    {
      method: "DELETE",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ reason: "Authenticated server-route E2E archive" }),
    },
  );
  if (archive.status !== 200) {
    throw new Error(`Authorized resource archive returned ${archive.status}`);
  }
  const archivedRead = await request(
    learnerA,
    `/api/classes/${classroom.id}/resources/${resource.id}`,
  );
  if (archivedRead.status !== 404) throw new Error("Archived resource remained route-readable");
  record("resource route upload, signed learner access, archive, and post-archive denial", "PASS");
}

async function exerciseAdminRemovalRoute() {
  const adminSession = sessions.get("admin");
  const targetEmail = `${runId}-provisioned-instructor@${domain}`;
  const createResponse = await request(adminSession, "/api/admin/users", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({
      fullName: "ByteQuest Provisioned Instructor",
      email: targetEmail,
      password,
      role: "instructor",
    }),
  });
  const created = await createResponse.json().catch(() => null);
  if (createResponse.status !== 201 || !created?.userId) {
    throw new Error(`Admin account route creation failed (${createResponse.status}): ${JSON.stringify(created)}`);
  }
  users.set("removalTarget", created.userId);

  const { data: createdProfile, error: createdProfileError } = await admin
    .from("profiles")
    .select("role,status")
    .eq("user_id", created.userId)
    .single();
  if (
    createdProfileError ||
    createdProfile?.role !== "instructor" ||
    createdProfile?.status !== "active"
  ) {
    throw new Error(
      `Provisioned Instructor profile is invalid: ${createdProfileError?.message ?? JSON.stringify(createdProfile)}`,
    );
  }

  const activeRemoval = await request(adminSession, `/api/admin/users/${created.userId}`, {
    method: "DELETE",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ confirmationEmail: targetEmail, reason: "Authenticated route active-state denial" }),
  });
  if (activeRemoval.status !== 409) {
    throw new Error(`Active target removal returned ${activeRemoval.status}, expected 409`);
  }

  const selfRemoval = await request(adminSession, `/api/admin/users/${users.get("admin")}`, {
    method: "DELETE",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({
      confirmationEmail: accountSpecs.find((item) => item.key === "admin").email,
      reason: "Authenticated route self-removal denial",
    }),
  });
  if (selfRemoval.status !== 403) {
    throw new Error(`Admin self-removal returned ${selfRemoval.status}, expected 403`);
  }

  const { error: deactivateError } = await adminSession.client.rpc("admin_set_account_status", {
    p_user_id: created.userId,
    p_status: "deactivated",
    p_reason: "Preparing disposable target for guarded removal",
  });
  if (deactivateError) throw new Error(`Removal target deactivation failed: ${deactivateError.message}`);

  const wrongEmail = await request(adminSession, `/api/admin/users/${created.userId}`, {
    method: "DELETE",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ confirmationEmail: `wrong-${targetEmail}`, reason: "Wrong-email denial must remain safe" }),
  });
  if (wrongEmail.status !== 400) {
    throw new Error(`Wrong-email removal returned ${wrongEmail.status}, expected 400`);
  }

  const removeResponse = await request(adminSession, `/api/admin/users/${created.userId}`, {
    method: "DELETE",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({
      confirmationEmail: targetEmail,
      reason: "Authenticated disposable account permanent-removal verification",
    }),
  });
  const removed = await removeResponse.json().catch(() => null);
  if (removeResponse.status !== 200 || removed?.removed !== true) {
    throw new Error(`Guarded removal failed (${removeResponse.status}): ${JSON.stringify(removed)}`);
  }
  users.delete("removalTarget");

  const { data: deletedAuthUser } = await admin.auth.admin.getUserById(created.userId);
  if (deletedAuthUser?.user) throw new Error("Permanent-removal route left the Auth user present");

  const { data: removalAudits, error: auditError } = await admin
    .from("audit_events")
    .select("action,outcome,reason")
    .eq("target_id", created.userId)
    .in("action", ["account.permanent_removal_authorized", "account.permanently_removed"]);
  if (
    auditError ||
    removalAudits?.length !== 2 ||
    removalAudits.some((event) => event.outcome !== "success" || !event.reason)
  ) {
    throw new Error(`Permanent-removal audit chain is incomplete: ${auditError?.message ?? "unexpected rows"}`);
  }
  record("Admin Instructor create/activate plus guarded permanent-removal route and audit chain", "PASS");
}

async function cleanup() {
  const errors = [];
  if (storagePaths.length > 0) {
    const { error } = await admin.storage.from("learning-resources").remove(storagePaths);
    if (error && !error.message.toLowerCase().includes("not found")) errors.push(error.message);
  }
  if (resourceIds.length > 0) {
    const { error } = await admin.from("learning_resources").delete().in("id", resourceIds);
    if (error) errors.push(error.message);
  }
  if (classIds.length > 0) {
    const { error: membershipsError } = await admin
      .from("class_memberships")
      .delete()
      .in("class_id", classIds);
    if (membershipsError) errors.push(membershipsError.message);
    const { error: classesError } = await admin.from("classes").delete().in("id", classIds);
    if (classesError) errors.push(classesError.message);
  }
  for (const session of sessions.values()) await session.client.auth.signOut();
  for (const userId of Array.from(users.values()).reverse()) {
    const { error } = await admin.auth.admin.deleteUser(userId, false);
    if (error) errors.push(`${userId}: ${error.message}`);
  }
  if (errors.length > 0) throw new Error(errors.join(" | "));
}

let failed = false;
try {
  await createAccounts();
  await exerciseProtectedPages();
  await exerciseResourceRoutes();
  await exerciseAdminRemovalRoute();
} catch (error) {
  failed = true;
  record("authenticated server-route smoke suite", "FAIL", error instanceof Error ? error.message : String(error));
} finally {
  try {
    await cleanup();
    record("server-route disposable account/domain/storage cleanup", "PASS");
  } catch (error) {
    failed = true;
    record("server-route disposable account/domain/storage cleanup", "FAIL", error instanceof Error ? error.message : String(error));
  }
}

console.log(JSON.stringify({ runId, webBaseUrl, results }, null, 2));
if (failed) process.exitCode = 1;
