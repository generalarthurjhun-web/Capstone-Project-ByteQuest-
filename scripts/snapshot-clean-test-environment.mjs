import { createHash } from "node:crypto";
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import { createClient } from "@supabase/supabase-js";

const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const outputDirectory = process.argv[2];

if (!url || !serviceRoleKey) {
  throw new Error("Supabase server configuration is incomplete.");
}
if (!outputDirectory) {
  throw new Error("Usage: node scripts/snapshot-clean-test-environment.mjs <output-directory>");
}

const projectRef = new URL(url).hostname.split(".")[0];
const client = createClient(url, serviceRoleKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});

const tables = [
  "achievements",
  "activity_logs",
  "activity_versions",
  "ai_quiz_generations",
  "assessment_criteria",
  "assignments",
  "attempt_actions",
  "attempts",
  "audit_events",
  "badges",
  "class_memberships",
  "classes",
  "coc_bypasses",
  "coc_modules",
  "competencies",
  "criterion_results",
  "gamification_events",
  "leaderboard_entries",
  "learner_progress",
  "learning_resources",
  "legacy_result_quarantine",
  "levels",
  "mission_results",
  "missions",
  "module_versions",
  "notifications",
  "profiles",
  "quiz_answers",
  "quiz_assignments",
  "quiz_attempts",
  "quiz_items",
  "quiz_results",
  "quiz_versions",
  "quizzes",
  "reports",
  "result_releases",
  "rubric_criteria",
  "rubric_versions",
  "score_revisions",
  "simulation_tasks",
  "system_settings",
  "task_results",
  "tesda_sources",
  "user_achievements",
  "user_badges",
  "user_settings",
];

async function readAllRows(table) {
  const rows = [];
  const pageSize = 500;
  for (let start = 0; ; start += pageSize) {
    const { data, error } = await client
      .from(table)
      .select("*")
      .range(start, start + pageSize - 1);
    if (error) throw new Error(`${table}: ${error.message}`);
    rows.push(...data);
    if (data.length < pageSize) break;
  }
  return rows;
}

async function listStorageObjects(bucketId, prefix = "") {
  const objects = [];
  let offset = 0;
  const limit = 100;
  while (true) {
    const { data, error } = await client.storage.from(bucketId).list(prefix, {
      limit,
      offset,
      sortBy: { column: "name", order: "asc" },
    });
    if (error) throw new Error(`Storage ${bucketId}/${prefix}: ${error.message}`);
    for (const item of data) {
      const objectPath = prefix ? `${prefix}/${item.name}` : item.name;
      if (item.id) {
        objects.push({ path: objectPath, metadata: item });
      } else {
        objects.push(...(await listStorageObjects(bucketId, objectPath)));
      }
    }
    if (data.length < limit) break;
    offset += limit;
  }
  return objects;
}

function sha256(value) {
  return createHash("sha256").update(value).digest("hex");
}

await mkdir(outputDirectory, { recursive: true });

const tableCounts = {};
const tableHashes = {};
for (const table of tables) {
  const rows = await readAllRows(table);
  const body = `${JSON.stringify(rows, null, 2)}\n`;
  await writeFile(path.join(outputDirectory, `${table}.json`), body, {
    encoding: "utf8",
    mode: 0o600,
  });
  tableCounts[table] = rows.length;
  tableHashes[table] = sha256(body);
}

const profiles = JSON.parse(
  await import("node:fs/promises").then(({ readFile }) =>
    readFile(path.join(outputDirectory, "profiles.json"), "utf8"),
  ),
);
const authUsersById = new Map();
const authLookupErrors = [];
try {
  for (let page = 1; ; page += 1) {
    const { data, error } = await client.auth.admin.listUsers({ page, perPage: 100 });
    if (error) throw error;
    for (const user of data.users) authUsersById.set(user.id, user);
    if (data.users.length < 100) break;
  }
} catch (error) {
  authLookupErrors.push({
    userId: null,
    error: `Auth list fallback: ${error instanceof Error ? error.message : String(error)}`,
  });
}
for (const profile of profiles) {
  if (authUsersById.has(profile.user_id)) continue;
  const { data, error } = await client.auth.admin.getUserById(profile.user_id);
  if (error || !data.user) {
    authLookupErrors.push({ userId: profile.user_id, error: error?.message ?? "Not found" });
    continue;
  }
  authUsersById.set(data.user.id, data.user);
}
const authUsers = [...authUsersById.values()].map((user) => ({
    id: user.id,
    email: user.email,
    createdAt: user.created_at,
    updatedAt: user.updated_at,
    confirmedAt: user.email_confirmed_at,
    bannedUntil: user.banned_until,
    appMetadata: user.app_metadata,
    userMetadata: user.user_metadata,
  }));
const authBody = `${JSON.stringify(authUsers, null, 2)}\n`;
await writeFile(path.join(outputDirectory, "auth-users-metadata.json"), authBody, {
  encoding: "utf8",
  mode: 0o600,
});

const { data: buckets, error: bucketsError } = await client.storage.listBuckets();
if (bucketsError) throw bucketsError;
const storageManifest = [];
for (const bucket of buckets) {
  const objects = await listStorageObjects(bucket.id);
  for (const object of objects) {
    const { data, error } = await client.storage.from(bucket.id).download(object.path);
    if (error) throw new Error(`Download ${bucket.id}/${object.path}: ${error.message}`);
    const bytes = Buffer.from(await data.arrayBuffer());
    const destination = path.join(outputDirectory, "storage", bucket.id, ...object.path.split("/"));
    await mkdir(path.dirname(destination), { recursive: true });
    await writeFile(destination, bytes, { mode: 0o600 });
    storageManifest.push({
      bucketId: bucket.id,
      path: object.path,
      bytes: bytes.length,
      sha256: sha256(bytes),
      metadata: object.metadata,
    });
  }
}

const manifest = {
  formatVersion: 1,
  createdAt: new Date().toISOString(),
  projectRef,
  scope: "ByteQuest public tables, Auth metadata, and Storage object bytes",
  restoreNote:
    "Auth passwords and tokens are intentionally not exported. Restore accounts through Supabase Admin Auth.",
  tableCounts,
  tableHashes,
  authUsers: authUsers.length,
  authLookupErrors,
  storageObjects: storageManifest,
};
const manifestBody = `${JSON.stringify(manifest, null, 2)}\n`;
await writeFile(path.join(outputDirectory, "manifest.json"), manifestBody, {
  encoding: "utf8",
  mode: 0o600,
});

console.log(
  JSON.stringify({
    status: "PASS",
    outputDirectory,
    projectRef,
    tables: tables.length,
    rows: Object.values(tableCounts).reduce((sum, count) => sum + count, 0),
    authUsers: authUsers.length,
    authLookupErrors: authLookupErrors.length,
    storageObjects: storageManifest.length,
    manifestSha256: sha256(manifestBody),
  }),
);
