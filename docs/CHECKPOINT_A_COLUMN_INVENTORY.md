# Checkpoint A â€” Public Schema Column Inventory

Date: 2026-08-07  
Source: live Supabase `information_schema`, constraints/indexes, repository-wide reference search, and data-quality aggregates.

Decision vocabulary:

- **KEEP** â€” useful as-is or with tighter policy ownership.
- **MODIFY** â€” retain the data/meaning but change constraints, authority, lifecycle, or linkage.
- **MIGRATE** â€” preserve and map into a new authoritative structure before deprecation.
- **REQUIRES_CONFIRMATION** â€” no removal or irreversible change is authorized.

No column is approved for removal at Checkpoint A.

## `profiles`

Used by Flutter profile/auth/gamification/leaderboard services, Auth trigger and role helpers, and the leaderboard view. Required for shared identity and projections. Eleven rows exist.

| Column | Meaning | Data quality / authority | Decision |
|---|---|---|---|
| `id` | Profile row UUID primary key | Constrained, but separate from Auth UUID | KEEP for compatibility |
| `user_id` | Unique Auth user UUID | FK to `auth.users`; no orphan profiles | KEEP |
| `full_name` | Display/legal name | Learner can currently overwrite | MODIFY: allow only approved self/profile workflow |
| `email` | Mirrored Auth email | All mirrors currently match Auth | MODIFY: server/Auth synchronized |
| `avatar_url` | Optional avatar reference | No Storage bucket exists | KEEP; validate storage ownership later |
| `role` | Application role enum | Client-writable; enum includes merged role | MODIFY: trusted Admin-only assignment; retire `instructor_admin` |
| `status` | Account state enum | Client-writable; lacks deactivation metadata | MODIFY: trusted lifecycle plus reason/timestamps |
| `learner_id` | Optional institutional learner identifier | Not unique/validated | MODIFY: normalize/validate if PRD usage is confirmed |
| `school` | Optional school metadata | Free text | KEEP |
| `course_section` | Optional course/section metadata | Free text; class domain is absent | MIGRATE relationship meaning to memberships; retain display metadata |
| `current_level` | Gamification projection | Client-writable; hard-coded fallback exists | MODIFY: server-projected only |
| `total_xp` | Gamification XP projection | Client-writable; 5 profile projections disagree with results | MODIFY: server-projected only |
| `total_points` | Gamification points projection | Client-writable; projection mismatches exist | MODIFY: server-projected only |
| `total_badges` | Badge-count projection | Client-writable | MODIFY: server-projected only |
| `completed_missions` | Completion-count projection | Client-writable and derived from legacy pass flags | MODIFY: server-projected from released/final records |
| `current_streak` | Gamification streak projection | Client-writable; rule not versioned | MODIFY: server-projected/configured only |
| `created_at` | Profile creation time | Present | KEEP |
| `updated_at` | Last profile mutation time | Trigger-maintained | KEEP |
| `last_login_at` | Last successful login projection | Not reliably updated | MODIFY: trusted auth/session boundary only |
| `last_activity_at` | Last domain activity projection | Client/legacy writes | MODIFY: trusted event projection |

Required additions: `deactivated_at`, `deactivation_reason`, optional `deactivated_by`, and a safe profile-update RPC/column policy.

## `competencies`

Used by foreign keys from COCs/missions; not directly integrated by either application. Four unversioned rows exist.

| Column | Meaning | Data quality / authority | Decision |
|---|---|---|---|
| `id` | Competency identity | Valid PK | KEEP |
| `competency_code` | Unique local code | Unique but not traced to approved source | MODIFY: source-scoped uniqueness/traceability |
| `name` | Competency name | Unverified against official source | MODIFY: publish only through approved source version |
| `description` | Competency description | Unverified free text | MODIFY: version/source trace |
| `order_index` | Local sequence | Positive, but TESDA order unverified | MODIFY: source/version-specific |
| `created_at` | Creation time | Present | KEEP |
| `updated_at` | Mutation time | Trigger-maintained | KEEP |

## `coc_modules`

Used heavily by Flutter module/mission navigation and many foreign keys. Four legacy rows exist; the PRD does not approve their names/order.

| Column | Meaning | Data quality / authority | Decision |
|---|---|---|---|
| `id` | Stable COC/module identity | Valid PK | KEEP |
| `coc_code` | Unique local COC code | Unique; official mapping unverified | MODIFY: source/version trace |
| `title` | Display title | Unverified | MIGRATE into published module version |
| `module_name` | Local module label | Duplicates title concept | MIGRATE; reconciliation required before any rename/removal |
| `description` | Module description | Versionless | MIGRATE into version snapshot |
| `competency_area` | Local competency area text | Free text/unverified | MIGRATE to approved competency link |
| `competency_id` | Optional legacy competency FK | Nullable and not indexed | MODIFY: required only for approved versions; add supporting index |
| `total_missions` | Cached expected mission count | May drift from actual rows | MODIFY: derive/projection or version constraint |
| `order_index` | Local display order | Positive; official order unverified | MODIFY: version-specific |
| `status` | Draft/published/archive-like status | Published without source approval | MODIFY: stable identity status; publication belongs to version |
| `difficulty` | Instructional difficulty | Local UX metadata | KEEP in versioned content |
| `xp_reward` | Gamification reward | Unverified/local | MIGRATE to versioned gamification config, never competency |
| `icon_url` | Optional icon reference | No storage bucket | KEEP with resource validation |
| `color_hex` | UI color metadata | No format constraint | MODIFY: validate format or move to presentation config |
| `created_at` | Creation time | Present | KEEP |
| `updated_at` | Mutation time | Trigger-maintained | KEEP |

## `missions`

Used throughout Flutter, many foreign keys, and the performance view. Twenty versionless rows exist.

| Column | Meaning | Data quality / authority | Decision |
|---|---|---|---|
| `id` | Stable mission/activity identity | Valid PK | KEEP |
| `coc_id` | Parent legacy module | FK/cascade | KEEP; versions must reference immutable module version |
| `competency_id` | Optional competency | Nullable, unverified, unindexed | MODIFY: approved version linkage and index |
| `mission_code` | Unique local mission code | Unique | KEEP as stable identity code |
| `mission_number` | Legacy per-COC number | Positive/unique with COC | KEEP for compatibility; version sequence separately |
| `title` | Mission title | Versionless | MIGRATE into activity version |
| `description` | Mission description | Versionless | MIGRATE into activity version |
| `scenario` | Scenario narrative | Versionless/hard-coded alternatives in Dart | MIGRATE into activity version/content |
| `objective` | Learning objective | Versionless | MIGRATE with source trace |
| `skills_assessed` | Text-array skill labels | Unverified | MIGRATE to criterion/competency references |
| `challenge_description` | Learner challenge text | Versionless | MIGRATE into activity version |
| `mission_type` | Interaction type | Constrained enum | KEEP in versioned activity |
| `difficulty` | UX difficulty | Local metadata | KEEP in versioned activity |
| `xp_reward` | Gamification XP | Hard-coded/unverified | MIGRATE to motivational config only |
| `points_reward` | Gamification points | Hard-coded/unverified | MIGRATE to motivational config only |
| `passing_score` | Legacy pass threshold | Every row is 75; no approved TESDA source | MIGRATE as `UNVERIFIED_LEGACY_VALUE`; never activate |
| `time_limit_seconds` | Optional task time limit | Positive if set; source/policy unverified | MIGRATE to versioned activity rule with approval flag |
| `estimated_time_minutes` | UX estimate | Positive | KEEP in versioned activity |
| `status` | Versionless publication status | Allows unapproved content to be published | MODIFY: publication belongs to immutable version |
| `is_locked` | Global lock flag | Conflicts with assignment/member-specific access | MIGRATE to assignment/progress projection |
| `order_index` | Local display order | Positive | MIGRATE to module version |
| `hint_count` | Hint count metadata | May disagree with hard-coded content | MIGRATE/derive from activity version |
| `icon_url` | Optional icon URL | No bucket | KEEP with validation |
| `asset_path` | Optional local/remote asset path | Contract unclear | MIGRATE to resource metadata; REQUIRES_CONFIRMATION before removal |
| `created_at` | Creation time | Present | KEEP |
| `updated_at` | Mutation time | Trigger-maintained | KEEP |

## `simulation_tasks`

Flutter has read paths, but the live table has zero rows; actual simulations are mostly Dart definitions.

| Column | Meaning | Data quality / authority | Decision |
|---|---|---|---|
| `id` | Task UUID | No rows | MIGRATE to activity-version task identity |
| `mission_id` | Parent mission | FK/cascade | MIGRATE to activity version |
| `task_code` | Optional task code | No uniqueness constraint | MODIFY in versioned schema |
| `task_number` | Per-mission number | Positive/unique with mission | MIGRATE |
| `task_type` | Interaction type | Uses mission enum | MIGRATE; use explicit activity/task type if needed |
| `instruction` | Learner instruction | Versionless | MIGRATE |
| `question_text` | Optional question | Versionless | MIGRATE |
| `component_id` | UI component identifier | Client-specific/free text | MIGRATE with schema validation |
| `target_zone_id` | UI target identifier | Can reveal answer | MIGRATE; hide in assessment delivery payload |
| `correct_answer` | Exact answer | Client-readable authoritative answer | MIGRATE to protected rule/evaluator storage |
| `correct_target` | Exact target | Client-readable authoritative answer | MIGRATE to protected rule/evaluator storage |
| `accepted_component_ids` | Accepted component IDs | Versionless | MIGRATE to protected evaluator rule |
| `options` | JSON answer/options | Shape unconstrained | MIGRATE with validated JSON schema |
| `points` | Legacy task points | Unverified | MIGRATE as inactive legacy value |
| `hint_text` | Practice/feedback hint | No practice/assessment boundary | MIGRATE with delivery mode policy |
| `feedback_correct` | Correct feedback | Versionless | MIGRATE |
| `feedback_incorrect` | Incorrect feedback | Versionless | MIGRATE |
| `requires_previous_task` | Sequence requirement flag | Does not preserve actual action order | MIGRATE to evaluator rule |
| `required_order` | Expected order | Nullable/versionless | MIGRATE to evaluator rule |
| `order_index` | Display sequence | Positive | MIGRATE |
| `is_required` | Required flag | Local rule | MIGRATE to versioned rubric/activity |
| `created_at` | Creation time | No rows | KEEP during migration |
| `updated_at` | Mutation time | Trigger-maintained | KEEP during migration |

## `assessment_criteria`

Eighty rows exist but neither app uses them for trusted evaluation. All weights/scores are unapproved legacy values.

| Column | Meaning | Data quality / authority | Decision |
|---|---|---|---|
| `id` | Legacy criterion UUID | Valid PK | MIGRATE/preserve legacy identity |
| `mission_id` | Parent mission | FK/cascade | MIGRATE to rubric/activity version |
| `criteria_name` | Criterion label | Unverified | MIGRATE only after source mapping |
| `description` | Criterion description | Unverified | MIGRATE only after source mapping |
| `max_score` | Legacy max score | 15/20/25/40 distributions | MIGRATE as inactive unverified value |
| `weight` | Legacy weighting | 0.15/0.20/0.25/0.40 | MIGRATE as inactive unverified value |
| `order_index` | Criterion display order | Positive | MIGRATE into rubric version |
| `created_at` | Creation time | Present | KEEP |
| `updated_at` | Mutation time | Trigger-maintained | KEEP |

## `levels`

Eight gamification-only rows; used by Flutter and `get_level_from_xp`.

| Column | Meaning | Data quality / authority | Decision |
|---|---|---|---|
| `id` | Level UUID | Valid PK | KEEP |
| `level_number` | Unique positive level | Constrained | KEEP |
| `level_name` | Display name | Local gamification | KEEP |
| `min_xp` | Inclusive minimum XP | Non-negative | KEEP/MODIFY: server config only |
| `max_xp` | Optional maximum XP | Constrained against minimum, but overlap/gap not constrained | MODIFY: validate ranges |
| `badge_icon` | Icon reference | Unvalidated | KEEP with resource validation |
| `created_at` | Creation time | Present | KEEP |

## `mission_results`

Twenty-eight client-authored rows. Sixteen duplicate attempt identities; all 28 lack task evidence. Preserve as historical legacy imports, not authoritative TESDA outcomes.

| Column | Meaning | Data quality / authority | Decision |
|---|---|---|---|
| `id` | Legacy result UUID | Valid PK | KEEP for traceability |
| `user_id` | Learner Auth UUID | FK; client supplies own ID | MIGRATE to attempt learner |
| `coc_id` | Legacy module | Nullable FK | MIGRATE to versioned assignment/module |
| `mission_id` | Legacy mission | FK | MIGRATE to activity version |
| `mission_title` | Denormalized title | Can drift | KEEP only in legacy snapshot |
| `attempt_number` | Client-calculated ordinal | 16 duplicate identities | MIGRATE; replace with unique attempt UUID/idempotency |
| `score` | Client-computed total | Authoritative-looking/untrusted | MIGRATE as `legacy_client_score` only |
| `max_score` | Client-supplied maximum | Unverified | MIGRATE as legacy payload |
| `percentage` | Client-computed percent | Differs from score on 5 rows | MIGRATE as legacy payload |
| `earned_points` | Gamification points | Client-computed | MIGRATE to idempotent event only |
| `xp_earned` | Gamification XP | Client-computed | MIGRATE to idempotent event only |
| `passed` | Client-computed pass | Based on unapproved threshold | MIGRATE as untrusted legacy flag |
| `rating` | Client/legacy rating band | Hard-coded rule | MIGRATE as untrusted legacy label |
| `competency_status` | Client competency label | No approved rubric | MIGRATE as untrusted legacy label |
| `completed_tasks` | Client aggregate | No task rows exist | MIGRATE as legacy payload |
| `total_tasks` | Client aggregate | No task rows exist | MIGRATE as legacy payload |
| `incorrect_attempts` | Client aggregate | No action evidence | MIGRATE as legacy payload |
| `hints_used` | Client aggregate | No action evidence | MIGRATE as legacy payload |
| `time_spent_seconds` | Client duration | Non-negative but unverified | MIGRATE as legacy duration |
| `accuracy` | Client percentage | Optional/unverified | MIGRATE as legacy payload |
| `mistakes` | Client text array | Incomplete/opaque | MIGRATE to legacy notes; new system uses ordered actions |
| `feedback` | Client-generated feedback | Not criterion-level | MIGRATE as legacy note |
| `remarks` | Client/general remarks | Actor provenance absent | MIGRATE as legacy note |
| `completed_at` | Client completion timestamp | Duplicate pairs within seconds | MIGRATE with duplicate flag |
| `created_at` | Insert timestamp | Present | KEEP for provenance |

## `task_results`

Zero rows. Flutter can write client answers and even the correct answers supplied by the client.

| Column | Meaning | Data quality / authority | Decision |
|---|---|---|---|
| `id` | Legacy task result UUID | No rows | MIGRATE to action/criterion evidence if ever populated |
| `mission_result_id` | Parent legacy result | FK/cascade | MIGRATE to attempt |
| `task_id` | Optional task | FK/set null | MIGRATE to versioned activity task |
| `user_id` | Learner | FK | MIGRATE; derive from attempt |
| `mission_id` | Legacy mission | FK | MIGRATE; derive from attempt version |
| `is_correct` | Client correctness flag | Untrusted | MIGRATE only as legacy observation |
| `is_completed` | Client completion flag | Untrusted | MIGRATE only as legacy observation |
| `selected_answer` | Learner answer | Evidence value | MIGRATE to ordered action evidence |
| `selected_target` | Learner target | Evidence value | MIGRATE to ordered action evidence |
| `correct_answer` | Correct answer copied by client | Exposes/provides authority to client | MIGRATE evaluator-side only; do not deliver in assessment mode |
| `correct_target` | Correct target copied by client | Exposes/provides authority to client | MIGRATE evaluator-side only |
| `score_obtained` | Client score | Untrusted | MIGRATE only as legacy observation |
| `max_score` | Client max | Unverified | MIGRATE only as legacy observation |
| `attempts` | Local task attempt count | No chronology | MIGRATE to action sequence |
| `hint_used` | Hint flag | Client supplied | MIGRATE to action evidence |
| `feedback` | Client feedback | No provenance | MIGRATE as legacy note |
| `completed_at` | Task completion time | No rows | MIGRATE to event time |
| `created_at` | Insert time | No rows | KEEP during transition |

## `learner_progress`

141 rows, unique by learner/mission. Directly writable by learners and initialized for every mission.

| Column | Meaning | Data quality / authority | Decision |
|---|---|---|---|
| `id` | Projection row UUID | Valid PK | KEEP |
| `user_id` | Learner | FK | KEEP |
| `coc_id` | Legacy module | FK/cascade | MODIFY: relate to assigned/versioned scope |
| `mission_id` | Legacy mission | FK/cascade | MODIFY: relate to activity version/assignment |
| `status` | Unlock/progress state | Learner-writable | MODIFY: trusted projection only |
| `completion_percentage` | Progress percent | Learner-writable | MODIFY: trusted projection; distinguish learning vs assessment |
| `best_score` | Legacy best client score | Untrusted | MIGRATE from released/final revisions only |
| `latest_score` | Legacy latest client score | Untrusted | MIGRATE from released/final revisions only |
| `attempts_count` | Attempt projection | Learner-writable | MODIFY: derive from attempts |
| `total_time_spent_seconds` | Duration projection | Learner-writable | MODIFY: derive from trusted attempts |
| `last_activity_at` | Last activity | Learner-writable | MODIFY: derive from events |
| `unlocked_at` | Unlock time | Learner-writable | MODIFY: trusted assignment/bypass transition |
| `started_at` | First start | Learner-writable | MODIFY: derive from attempt |
| `completed_at` | Completion time | Learner-writable | MODIFY: derive from released/final state per policy |
| `created_at` | Creation time | Present | KEEP |
| `updated_at` | Mutation time | Trigger-maintained | KEEP |

## `badges`

Seven catalog rows. Flutter model fields do not match the live schema.

| Column | Meaning | Data quality / authority | Decision |
|---|---|---|---|
| `id` | Badge UUID | Valid PK | KEEP |
| `badge_code` | Unique code | Unique | KEEP |
| `title` | Badge title | Model currently expects `name` | KEEP; align client contract |
| `description` | Badge description | Optional | KEEP |
| `icon_url` | Icon reference | No storage bucket | KEEP with validation |
| `condition_type` | Award condition category | Client interprets | MODIFY: trusted evaluator only |
| `condition_value` | Condition JSON | Shape unconstrained | MODIFY: version/validate schema |
| `xp_reward` | Bonus XP | Motivational but client-awarded | MODIFY: server event only |
| `created_at` | Creation time | Present | KEEP |
| `updated_at` | Mutation time | Trigger-maintained | KEEP |

## `user_badges`

Zero rows; learners can insert their own awards.

| Column | Meaning | Data quality / authority | Decision |
|---|---|---|---|
| `id` | Award UUID | Valid PK | KEEP/MIGRATE |
| `user_id` | Awarded learner | FK | KEEP |
| `badge_id` | Badge | FK | KEEP |
| `mission_id` | Optional origin mission | FK | MIGRATE to source event/activity version |
| `coc_id` | Optional origin module | FK | MIGRATE to source event/module version |
| `earned_at` | Award time | Client-controlled insert | MODIFY: trusted event time |
| `created_at` | Insert time | Present | KEEP |

## `achievements`

Five catalog rows. Flutter model expects fields not present in the database.

| Column | Meaning | Data quality / authority | Decision |
|---|---|---|---|
| `id` | Achievement UUID | Valid PK | KEEP |
| `achievement_code` | Unique code | Unique | KEEP |
| `title` | Display title | Present | KEEP |
| `description` | Description | Optional | KEEP |
| `icon_url` | Icon reference | No storage bucket | KEEP with validation |
| `condition_type` | Condition category | Client interpreted | MODIFY: trusted evaluator |
| `condition_value` | Condition JSON | Shape unconstrained | MODIFY: validate/version |
| `created_at` | Creation time | Present | KEEP |
| `updated_at` | Mutation time | Trigger-maintained | KEEP |

## `user_achievements`

Zero rows; learners can insert their own achievements.

| Column | Meaning | Data quality / authority | Decision |
|---|---|---|---|
| `id` | Award UUID | Valid PK | KEEP/MIGRATE |
| `user_id` | Learner | FK | KEEP |
| `achievement_id` | Achievement | FK | KEEP |
| `mission_id` | Optional origin | FK | MIGRATE to source event/activity version |
| `coc_id` | Optional origin | FK | MIGRATE to source event/module version |
| `earned_at` | Award time | Client-controlled insert | MODIFY: trusted event time |
| `created_at` | Insert time | Present | KEEP |

## `leaderboard_entries`

Three rows. Client can calculate and write ranking points; the legacy trigger function contains another hard-coded formula.

| Column | Meaning | Data quality / authority | Decision |
|---|---|---|---|
| `id` | Entry UUID | Valid PK | KEEP for legacy provenance |
| `user_id` | Learner | FK | KEEP |
| `coc_id` | Optional legacy module | FK | MIGRATE to event/version scope |
| `mission_id` | Optional legacy mission | FK | MIGRATE to event/version scope |
| `mission_result_id` | Optional legacy result | FK but lacks covering index | MIGRATE to gamification event/attempt |
| `score` | Legacy client score | Untrusted | MIGRATE as legacy only |
| `xp` | Client-calculated XP | Untrusted | MIGRATE to server event |
| `time_spent_seconds` | Client duration | Untrusted | MIGRATE only if ranking policy later approves it |
| `incorrect_attempts` | Client error count | No evidence | MIGRATE only as legacy |
| `ranking_points` | Client/hard-coded formula output | Unapproved | MIGRATE; new projection server-owned and motivational only |
| `leaderboard_type` | Ranking scope | Enum | KEEP if approved UX requires scope |
| `completed_at` | Event completion time | Client supplied | MIGRATE from trusted attempt/release event |
| `created_at` | Insert time | Present | KEEP |

## `notifications`

Zero rows. Mobile uses `is_read` but also incorrectly writes a nonexistent `is_unread` field.

| Column | Meaning | Data quality / authority | Decision |
|---|---|---|---|
| `id` | Notification UUID | Valid PK | KEEP |
| `user_id` | Recipient | FK | KEEP |
| `title` | Notification title | Required | KEEP |
| `message` | Notification body | Required | KEEP |
| `type` | Notification category | Enum/default | KEEP |
| `is_read` | Read state | Correct live field | KEEP; align mobile contract |
| `related_mission_id` | Optional legacy mission | FK | MIGRATE/add versioned target metadata |
| `related_coc_id` | Optional legacy module | FK | MIGRATE/add versioned target metadata |
| `metadata` | Extra JSON | Shape unconstrained | MODIFY: validate/minimize |
| `created_at` | Creation time | Present | KEEP |
| `read_at` | Read timestamp | Not automatically tied to `is_read` | MODIFY: enforce consistent transition |

## `user_settings`

Eight rows. Learner preferences only; web global settings currently live in Firebase.

| Column | Meaning | Data quality / authority | Decision |
|---|---|---|---|
| `id` | Settings UUID | Valid PK | KEEP |
| `user_id` | Unique learner/user | FK/unique | KEEP |
| `notifications_enabled` | Preference | Boolean | KEEP |
| `sound_enabled` | Preference | Boolean | KEEP |
| `vibration_enabled` | Preference | Boolean | KEEP |
| `theme_mode` | Theme preference | Checked light/dark/system | KEEP |
| `language` | Language preference | Unvalidated text | MODIFY: supported locale constraint later |
| `created_at` | Creation time | Present | KEEP |
| `updated_at` | Mutation time | Trigger-maintained | KEEP |

## `reports`

Zero rows. Web reporting is dummy data and does not use this table.

| Column | Meaning | Data quality / authority | Decision |
|---|---|---|---|
| `id` | Report snapshot UUID | Valid PK | REQUIRES_CONFIRMATION |
| `generated_by` | Generator Auth user | FK/set null | REQUIRES_CONFIRMATION |
| `report_type` | Report enum | Legacy shape | REQUIRES_CONFIRMATION pending approved report list |
| `title` | Report title | Required | REQUIRES_CONFIRMATION |
| `filters` | JSON filters | Unvalidated | REQUIRES_CONFIRMATION |
| `data` | Stored report payload | Could duplicate sensitive analytics | REQUIRES_CONFIRMATION; prefer generated/scoped report where possible |
| `created_at` | Creation time | Present | KEEP while table is retained |

## `activity_logs`

Zero rows. Any authenticated client can insert arbitrary actor/action content, so this cannot be an authoritative audit log.

| Column | Meaning | Data quality / authority | Decision |
|---|---|---|---|
| `id` | Legacy log UUID | Valid PK | MIGRATE/deprecate |
| `user_id` | Claimed actor | Nullable and client-spoofable | MIGRATE; new audit actor derives from `auth.uid()` |
| `action` | Claimed action | Free text/client-spoofable | MIGRATE to constrained trusted action code |
| `entity_type` | Target type | Free text | MIGRATE to validated target type |
| `entity_id` | Target UUID | No FK/polymorphic | MIGRATE to audited target reference |
| `description` | Narrative | Free text | MIGRATE as optional trusted detail |
| `metadata` | JSON metadata | Unvalidated/client-spoofable | MIGRATE with size/schema limits |
| `created_at` | Insert time | Database default | KEEP for any legacy rows |

## Column cleanup gate

Before any later column removal, the cleanup migration must include:

1. Repository-wide reference proof.
2. View/function/trigger/RPC/FK dependency proof.
3. Row/data migration and reconciliation evidence.
4. A logical backup or confirmed managed restore point.
5. A reversible expand/migrate/contract path.
6. Mobile and web cutover verification.
7. End-to-end attempt â†’ review â†’ finalization â†’ release validation.

Until all seven are satisfied, every legacy column remains retained even when marked MIGRATE or REQUIRES_CONFIRMATION.

