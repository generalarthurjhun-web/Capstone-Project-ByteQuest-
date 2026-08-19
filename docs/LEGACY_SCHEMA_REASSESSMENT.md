# Legacy Schema Reassessment

**Prepared:** 2026-08-10  
**Live project:** `rslmteqipxqfifwftugk`  
**Destructive gate:** Failed â€” no verified restorable backup  
**Cleanup result:** No destructive migration created or applied.

**Continuation result:** The backup gate was retried and remains blocked. Five additive/security-hardening migrations were applied; no legacy object or production-history row was removed.

## Decision rules applied

Live row counts, foreign keys, inbound references, triggers, policies/functions, repository queries/models, and replacement architecture were rechecked. An empty table was not treated as proof of obsolescence. Because `DATABASE_BACKUP_VERIFICATION.md` is not successful, every possible drop is deferred even when current evidence suggests a later cleanup candidate.

The continuation added a private Storage bucket and trusted resource/account-governance functions without rewriting legacy structures. After authenticated harness cleanup, the live project has zero authoritative assessment/resource rows and zero Storage objects. Twenty-five append-only audit records remain as intentional security-test evidence. These additions do not change any legacy `KEEP/DEPRECATE/DROP CANDIDATE` decision below.

## Table decisions

| Table | Rows | Production history / current references | Dependencies and replacement | Decision |
|---|---:|---|---|---|
| `profiles` | 11 | Shared live identity profile for Mobile/Web | References `auth.users` by design; used by all role helpers/RPCs | **KEEP** |
| `competencies` | 4 | Legacy catalog identity reused by version model | Inbound from `coc_modules`, `missions`; optional source FK | **KEEP/MODIFY** after source approval |
| `coc_modules` | 4 | Current four catalog modules | Eight inbound FK families including missions, progress, results, versions | **KEEP/MODIFY** |
| `missions` | 20 | Current mobile catalog identity | Ten inbound FK families, including activity versions and historical results | **KEEP/MODIFY** |
| `assessment_criteria` | 80 | Unverified four-weight legacy criteria | Referenced by legacy mission model; replacement is versioned `rubric_criteria` | **DEPRECATE/QUARANTINE**, no drop |
| `mission_results` | 28 | Client-authored historical submissions; 16 duplicate logical identities documented | Inbound from quarantine, attempts link, task results, leaderboard; replacement is attempts/evidence/revisions/releases | **KEEP/QUARANTINE** |
| `legacy_result_quarantine` | 28 | Explicit provenance and quality record for every legacy result | FK to `mission_results` | **KEEP** |
| `learner_progress` | 141 | Historical/current practice progress; mobile services still query/write allowed fields | FKs to modules/missions; future projection may replace official progress | **KEEP/MIGRATE LATER** |
| `simulation_tasks` | 0 | Mobile `mission_database_service.dart` still queries this table | FK to missions; inbound from `task_results`; versioned activity payload is intended replacement | **DEPRECATE**, drop blocked by live reference and backup |
| `task_results` | 0 | Dart legacy model remains; no current direct table query found | FKs to mission result/task/mission; attempt actions and criterion results are replacement | **DEPRECATE**, no drop |
| `activity_logs` | 0 | No current production table query found | Replaced by trusted append-only `audit_events` | **DROP CANDIDATE**, `DEFERRED FOR MANUAL REVIEW` |
| `reports` | 0 | Web reports page exists but builds reports from scoped live records rather than this persistence table | Product retention/export requirements unresolved | **DEPRECATE/REQUIRES CONFIRMATION** |
| `leaderboard_entries` | 3 | Existing gamification history and Dart model | FKs to module/mission/result; replacement direction is event-based projection | **KEEP/MIGRATE LATER** |
| `badges` | 7 | Active catalog models/UI | Inbound from `user_badges`; eventual awards must derive from approved events | **KEEP/MODIFY** |
| `user_badges` | 0 | Dart model remains | FKs to badge/module/mission | **KEEP pending gamification design** |
| `achievements` | 5 | Active catalog models/routes/UI | Inbound from `user_achievements` | **KEEP/MODIFY** |
| `user_achievements` | 0 | Dart model remains | FKs to achievement/module/mission | **KEEP pending gamification design** |
| `notifications` | 0 | Mobile dashboard and notification screen query/update it | FKs to module/mission; no replacement established | **KEEP** |
| `system_settings` | 0 | Admin settings page and audited admin RPC use it | Trusted server-side settings boundary | **KEEP** |

## Column decisions

No individual column meets all deletion conditions. The decisions below cover every column on the reassessed legacy tables.

### `assessment_criteria`

| Columns | Current data/references | Replacement | Decision |
|---|---|---|---|
| `id`, `mission_id`, `criteria_name`, `description`, `max_score`, `weight`, `order_index`, `created_at`, `updated_at` | 80 historical rows; weights/max scores have no approved provenance | `rubric_versions` + `rubric_criteria` after human approval | **KEEP/QUARANTINE**; drop only with migrated provenance and verified backup |

### `mission_results`

| Columns | Current data/references | Replacement | Decision |
|---|---|---|---|
| Identity/history: `id`, `user_id`, `coc_id`, `mission_id`, `mission_title`, `attempt_number`, `completed_at`, `created_at` | Populated across 28 historical rows and referenced by quarantine/leaderboard/optional attempt link | `attempts` and captured version FKs | **KEEP** as history |
| Untrusted evaluation: `score`, `max_score`, `percentage`, `passed`, `rating`, `competency_status`, `accuracy` | Client-authoritative legacy values; not promotable | `criterion_results` + append-only `score_revisions` | **KEEP/QUARANTINE**; never use as official result |
| Legacy reward/progress: `earned_points`, `xp_earned`, `completed_tasks`, `total_tasks` | Historical client data | `gamification_events` and authoritative projections | **KEEP/QUARANTINE** |
| Telemetry: `incorrect_attempts`, `hints_used`, `time_spent_seconds`, `mistakes`, `feedback`, `remarks` | Incomplete historical evidence | `attempt_actions`, criterion observations, revision remarks | **KEEP** until archival decision |

### `learner_progress`

| Columns | Current data/references | Replacement | Decision |
|---|---|---|---|
| `id`, `user_id`, `coc_id`, `mission_id`, `status`, `completion_percentage`, `best_score`, `latest_score`, `attempts_count`, `total_time_spent_seconds`, `last_activity_at`, `unlocked_at`, `started_at`, `completed_at`, `created_at`, `updated_at` | 141 rows; mobile services still use this practice-progress projection | Event/released-result projection after approved cutover | **KEEP/MIGRATE LATER** |

### `simulation_tasks`

| Columns | Current data/references | Replacement | Decision |
|---|---|---|---|
| Identity/order: `id`, `mission_id`, `task_code`, `task_number`, `task_type`, `order_index`, `is_required`, `requires_previous_task`, `required_order` | Empty, but mobile service still queries table | Versioned `activity_versions.learner_payload` and rubric evidence rules | **DEPRECATE**; all columns drop only with table after client removal/cutover |
| Content/answers: `instruction`, `question_text`, `component_id`, `target_zone_id`, `correct_answer`, `correct_target`, `accepted_component_ids`, `options`, `points`, `hint_text`, `feedback_correct`, `feedback_incorrect` | Empty; some fields can reveal protected answers if reused | Versioned learner payload separated from protected evaluator/rubric config | **DEPRECATE**; do not populate for official assessment |
| Audit fields: `created_at`, `updated_at` | Empty | Versioned content timestamps | **DEPRECATE** |

### `task_results`

| Columns | Current data/references | Replacement | Decision |
|---|---|---|---|
| `id`, `mission_result_id`, `task_id`, `user_id`, `mission_id`, `is_correct`, `is_completed`, `selected_answer`, `selected_target`, `correct_answer`, `correct_target`, `score_obtained`, `max_score`, `attempts`, `hint_used`, `feedback`, `completed_at`, `created_at` | Empty; outbound FKs and Dart legacy model remain | `attempt_actions` + `criterion_results` | **DEPRECATE**; all-column/table drop deferred |

### `activity_logs`

| Columns | Current data/references | Replacement | Decision |
|---|---|---|---|
| `id`, `user_id`, `action`, `entity_type`, `entity_id`, `description`, `metadata`, `created_at` | Empty; no current direct app query found | `audit_events` with server-derived actor/role/outcome | **DROP CANDIDATE**; all-column/table drop deferred for backup/manual review |

### `reports`

| Columns | Current data/references | Replacement | Decision |
|---|---|---|---|
| `id`, `generated_by`, `report_type`, `title`, `filters`, `data`, `created_at` | Empty; product has real dynamic reports/export but persistence/retention need confirmation | Scoped live query/API exports or a future audited report artifact | **REQUIRES CONFIRMATION** |

### `leaderboard_entries`

| Columns | Current data/references | Replacement | Decision |
|---|---|---|---|
| `id`, `user_id`, `coc_id`, `mission_id`, `mission_result_id`, `score`, `xp`, `time_spent_seconds`, `incorrect_attempts`, `ranking_points`, `leaderboard_type`, `completed_at`, `created_at` | Three historical rows; multiple FKs and mobile model | Projection derived from `gamification_events`, never official score | **KEEP/MIGRATE LATER** |

### Badges and achievements

| Table / columns | Current data/references | Replacement | Decision |
|---|---|---|---|
| `badges`: `id`, `badge_code`, `title`, `description`, `icon_url`, `condition_type`, `condition_value`, `xp_reward`, `created_at`, `updated_at` | Seven catalog rows; UI/model and user FK | Event-driven award policy | **KEEP/MODIFY**; `xp_reward` requires separate gamification approval |
| `user_badges`: `id`, `user_id`, `badge_id`, `mission_id`, `coc_id`, `earned_at`, `created_at` | Empty; model/FKs remain | Event-driven award projection | **KEEP** pending cutover |
| `achievements`: `id`, `achievement_code`, `title`, `description`, `icon_url`, `condition_type`, `condition_value`, `created_at`, `updated_at` | Five catalog rows; UI/model and user FK | Event-driven award policy | **KEEP/MODIFY** |
| `user_achievements`: `id`, `user_id`, `achievement_id`, `mission_id`, `coc_id`, `earned_at`, `created_at` | Empty; model/FKs remain | Event-driven award projection | **KEEP** pending cutover |

### `notifications`

| Columns | Current data/references | Replacement | Decision |
|---|---|---|---|
| `id`, `user_id`, `title`, `message`, `type`, `is_read`, `related_mission_id`, `related_coc_id`, `metadata`, `created_at`, `read_at` | Empty today but actively queried/updated by mobile | No replacement | **KEEP** |

### `system_settings`

| Columns | Current data/references | Replacement | Decision |
|---|---|---|---|
| `setting_key`, `setting_value`, `description`, `updated_by`, `updated_at` | Empty today; admin page/RPC/audit boundary is active | No replacement | **KEEP** |

## Views/functions/triggers and repository check

- No materialized views exist.
- Two public views remain and were not modified.
- `simulation_tasks` and `learner_progress` still have direct Flutter query references.
- `notifications` still has direct Flutter read/update references.
- `mission_results`, `learner_progress`, `missions`, and `coc_modules` participate in historical FK graphs.
- Legacy catalog tables have `updated_at` triggers; authoritative attempt/revision/gamification tables have integrity/audit triggers.
- No old applied migration was edited and no cleanup migration was created.

## Final cleanup decision

`activity_logs` is the strongest later drop candidate, followed by `task_results`, `simulation_tasks`, and possibly persisted `reports`; none is currently safe to delete. Backup/restore verification, removal of remaining client references/models, historical export decisions, replacement tests, and explicit human approval are still required.

