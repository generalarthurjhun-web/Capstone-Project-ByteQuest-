export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.5"
  }
  public: {
    Tables: {
      achievements: {
        Row: {
          achievement_code: string
          condition_type: Database["public"]["Enums"]["condition_type"]
          condition_value: Json | null
          created_at: string
          description: string | null
          icon_url: string | null
          id: string
          title: string
          updated_at: string
        }
        Insert: {
          achievement_code: string
          condition_type: Database["public"]["Enums"]["condition_type"]
          condition_value?: Json | null
          created_at?: string
          description?: string | null
          icon_url?: string | null
          id?: string
          title: string
          updated_at?: string
        }
        Update: {
          achievement_code?: string
          condition_type?: Database["public"]["Enums"]["condition_type"]
          condition_value?: Json | null
          created_at?: string
          description?: string | null
          icon_url?: string | null
          id?: string
          title?: string
          updated_at?: string
        }
        Relationships: []
      }
      activity_logs: {
        Row: {
          action: string
          created_at: string
          description: string | null
          entity_id: string | null
          entity_type: string | null
          id: string
          metadata: Json | null
          user_id: string | null
        }
        Insert: {
          action: string
          created_at?: string
          description?: string | null
          entity_id?: string | null
          entity_type?: string | null
          id?: string
          metadata?: Json | null
          user_id?: string | null
        }
        Update: {
          action?: string
          created_at?: string
          description?: string | null
          entity_id?: string | null
          entity_type?: string | null
          id?: string
          metadata?: Json | null
          user_id?: string | null
        }
        Relationships: []
      }
      activity_versions: {
        Row: {
          created_at: string
          created_by: string
          delivery_mode: Database["public"]["Enums"]["activity_delivery_mode"]
          evaluator_config: Json
          id: string
          instructions: string | null
          learner_payload: Json
          mission_id: string
          module_version_id: string
          published_at: string | null
          published_by: string | null
          retired_at: string | null
          status: Database["public"]["Enums"]["content_version_status"]
          title: string
          updated_at: string
          version_number: number
        }
        Insert: {
          created_at?: string
          created_by: string
          delivery_mode?: Database["public"]["Enums"]["activity_delivery_mode"]
          evaluator_config?: Json
          id?: string
          instructions?: string | null
          learner_payload?: Json
          mission_id: string
          module_version_id: string
          published_at?: string | null
          published_by?: string | null
          retired_at?: string | null
          status?: Database["public"]["Enums"]["content_version_status"]
          title: string
          updated_at?: string
          version_number: number
        }
        Update: {
          created_at?: string
          created_by?: string
          delivery_mode?: Database["public"]["Enums"]["activity_delivery_mode"]
          evaluator_config?: Json
          id?: string
          instructions?: string | null
          learner_payload?: Json
          mission_id?: string
          module_version_id?: string
          published_at?: string | null
          published_by?: string | null
          retired_at?: string | null
          status?: Database["public"]["Enums"]["content_version_status"]
          title?: string
          updated_at?: string
          version_number?: number
        }
        Relationships: [
          {
            foreignKeyName: "activity_versions_mission_id_fkey"
            columns: ["mission_id"]
            isOneToOne: false
            referencedRelation: "missions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "activity_versions_mission_id_fkey"
            columns: ["mission_id"]
            isOneToOne: false
            referencedRelation: "view_mission_performance_summary"
            referencedColumns: ["mission_id"]
          },
          {
            foreignKeyName: "activity_versions_module_version_id_fkey"
            columns: ["module_version_id"]
            isOneToOne: false
            referencedRelation: "module_versions"
            referencedColumns: ["id"]
          },
        ]
      }
      ai_quiz_generations: {
        Row: {
          completed_at: string | null
          failure_code: string | null
          generated_count: number
          id: string
          input_context: Json
          instructor_id: string
          model: string
          provider: string
          quiz_version_id: string
          requested_at: string
          requested_count: number
          status: Database["public"]["Enums"]["ai_generation_status"]
        }
        Insert: {
          completed_at?: string | null
          failure_code?: string | null
          generated_count?: number
          id?: string
          input_context?: Json
          instructor_id: string
          model: string
          provider?: string
          quiz_version_id: string
          requested_at?: string
          requested_count: number
          status?: Database["public"]["Enums"]["ai_generation_status"]
        }
        Update: {
          completed_at?: string | null
          failure_code?: string | null
          generated_count?: number
          id?: string
          input_context?: Json
          instructor_id?: string
          model?: string
          provider?: string
          quiz_version_id?: string
          requested_at?: string
          requested_count?: number
          status?: Database["public"]["Enums"]["ai_generation_status"]
        }
        Relationships: [
          {
            foreignKeyName: "ai_quiz_generations_quiz_version_id_fkey"
            columns: ["quiz_version_id"]
            isOneToOne: false
            referencedRelation: "quiz_versions"
            referencedColumns: ["id"]
          },
        ]
      }
      assessment_criteria: {
        Row: {
          created_at: string
          criteria_name: string
          description: string | null
          id: string
          max_score: number
          mission_id: string
          order_index: number
          updated_at: string
          weight: number
        }
        Insert: {
          created_at?: string
          criteria_name: string
          description?: string | null
          id?: string
          max_score?: number
          mission_id: string
          order_index?: number
          updated_at?: string
          weight?: number
        }
        Update: {
          created_at?: string
          criteria_name?: string
          description?: string | null
          id?: string
          max_score?: number
          mission_id?: string
          order_index?: number
          updated_at?: string
          weight?: number
        }
        Relationships: [
          {
            foreignKeyName: "assessment_criteria_mission_id_fkey"
            columns: ["mission_id"]
            isOneToOne: false
            referencedRelation: "missions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "assessment_criteria_mission_id_fkey"
            columns: ["mission_id"]
            isOneToOne: false
            referencedRelation: "view_mission_performance_summary"
            referencedColumns: ["mission_id"]
          },
        ]
      }
      assignments: {
        Row: {
          activity_version_id: string
          assigned_by: string
          assignment_type: Database["public"]["Enums"]["assignment_type"]
          attempts_allowed: number | null
          available_at: string | null
          class_id: string
          close_reason: string | null
          closed_at: string | null
          created_at: string
          due_at: string | null
          id: string
          instructions: string | null
          prerequisite_assignment_id: string | null
          retry_after_seconds: number | null
          retry_enabled: boolean
          rubric_version_id: string | null
          status: Database["public"]["Enums"]["assignment_status"]
          title: string
          updated_at: string
        }
        Insert: {
          activity_version_id: string
          assigned_by: string
          assignment_type?: Database["public"]["Enums"]["assignment_type"]
          attempts_allowed?: number | null
          available_at?: string | null
          class_id: string
          close_reason?: string | null
          closed_at?: string | null
          created_at?: string
          due_at?: string | null
          id?: string
          instructions?: string | null
          prerequisite_assignment_id?: string | null
          retry_after_seconds?: number | null
          retry_enabled?: boolean
          rubric_version_id?: string | null
          status?: Database["public"]["Enums"]["assignment_status"]
          title: string
          updated_at?: string
        }
        Update: {
          activity_version_id?: string
          assigned_by?: string
          assignment_type?: Database["public"]["Enums"]["assignment_type"]
          attempts_allowed?: number | null
          available_at?: string | null
          class_id?: string
          close_reason?: string | null
          closed_at?: string | null
          created_at?: string
          due_at?: string | null
          id?: string
          instructions?: string | null
          prerequisite_assignment_id?: string | null
          retry_after_seconds?: number | null
          retry_enabled?: boolean
          rubric_version_id?: string | null
          status?: Database["public"]["Enums"]["assignment_status"]
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "assignments_activity_version_id_fkey"
            columns: ["activity_version_id"]
            isOneToOne: false
            referencedRelation: "activity_versions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "assignments_class_id_fkey"
            columns: ["class_id"]
            isOneToOne: false
            referencedRelation: "classes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "assignments_prerequisite_assignment_id_fkey"
            columns: ["prerequisite_assignment_id"]
            isOneToOne: false
            referencedRelation: "assignments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "assignments_rubric_version_id_fkey"
            columns: ["rubric_version_id"]
            isOneToOne: false
            referencedRelation: "rubric_versions"
            referencedColumns: ["id"]
          },
        ]
      }
      attempt_actions: {
        Row: {
          action_type: string
          attempt_id: string
          client_occurred_at: string
          id: string
          recorded_at: string
          sequence_number: number
          target: string | null
          value: Json
        }
        Insert: {
          action_type: string
          attempt_id: string
          client_occurred_at: string
          id?: string
          recorded_at?: string
          sequence_number: number
          target?: string | null
          value?: Json
        }
        Update: {
          action_type?: string
          attempt_id?: string
          client_occurred_at?: string
          id?: string
          recorded_at?: string
          sequence_number?: number
          target?: string | null
          value?: Json
        }
        Relationships: [
          {
            foreignKeyName: "attempt_actions_attempt_id_fkey"
            columns: ["attempt_id"]
            isOneToOne: false
            referencedRelation: "attempts"
            referencedColumns: ["id"]
          },
        ]
      }
      attempts: {
        Row: {
          activity_version_id: string
          assignment_id: string
          class_id: string
          client_start_key: string
          created_at: string
          elapsed_time_seconds: number | null
          evaluated_at: string | null
          finalized_at: string | null
          id: string
          learner_id: string
          legacy_mission_result_id: string | null
          released_at: string | null
          rubric_version_id: string | null
          started_at: string
          status: Database["public"]["Enums"]["attempt_status"]
          submission_key: string | null
          submitted_at: string | null
          tesda_source_id: string | null
          updated_at: string
        }
        Insert: {
          activity_version_id: string
          assignment_id: string
          class_id: string
          client_start_key: string
          created_at?: string
          elapsed_time_seconds?: number | null
          evaluated_at?: string | null
          finalized_at?: string | null
          id?: string
          learner_id: string
          legacy_mission_result_id?: string | null
          released_at?: string | null
          rubric_version_id?: string | null
          started_at?: string
          status?: Database["public"]["Enums"]["attempt_status"]
          submission_key?: string | null
          submitted_at?: string | null
          tesda_source_id?: string | null
          updated_at?: string
        }
        Update: {
          activity_version_id?: string
          assignment_id?: string
          class_id?: string
          client_start_key?: string
          created_at?: string
          elapsed_time_seconds?: number | null
          evaluated_at?: string | null
          finalized_at?: string | null
          id?: string
          learner_id?: string
          legacy_mission_result_id?: string | null
          released_at?: string | null
          rubric_version_id?: string | null
          started_at?: string
          status?: Database["public"]["Enums"]["attempt_status"]
          submission_key?: string | null
          submitted_at?: string | null
          tesda_source_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "attempts_activity_version_id_fkey"
            columns: ["activity_version_id"]
            isOneToOne: false
            referencedRelation: "activity_versions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "attempts_assignment_id_fkey"
            columns: ["assignment_id"]
            isOneToOne: false
            referencedRelation: "assignments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "attempts_class_id_fkey"
            columns: ["class_id"]
            isOneToOne: false
            referencedRelation: "classes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "attempts_legacy_mission_result_id_fkey"
            columns: ["legacy_mission_result_id"]
            isOneToOne: true
            referencedRelation: "mission_results"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "attempts_rubric_version_id_fkey"
            columns: ["rubric_version_id"]
            isOneToOne: false
            referencedRelation: "rubric_versions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "attempts_tesda_source_id_fkey"
            columns: ["tesda_source_id"]
            isOneToOne: false
            referencedRelation: "tesda_sources"
            referencedColumns: ["id"]
          },
        ]
      }
      audit_events: {
        Row: {
          action: string
          actor_id: string | null
          actor_role: Database["public"]["Enums"]["user_role"] | null
          created_at: string
          id: string
          metadata: Json
          new_value: Json | null
          old_value: Json | null
          outcome: string
          reason: string | null
          target_id: string | null
          target_type: string
        }
        Insert: {
          action: string
          actor_id?: string | null
          actor_role?: Database["public"]["Enums"]["user_role"] | null
          created_at?: string
          id?: string
          metadata?: Json
          new_value?: Json | null
          old_value?: Json | null
          outcome?: string
          reason?: string | null
          target_id?: string | null
          target_type: string
        }
        Update: {
          action?: string
          actor_id?: string | null
          actor_role?: Database["public"]["Enums"]["user_role"] | null
          created_at?: string
          id?: string
          metadata?: Json
          new_value?: Json | null
          old_value?: Json | null
          outcome?: string
          reason?: string | null
          target_id?: string | null
          target_type?: string
        }
        Relationships: []
      }
      badges: {
        Row: {
          badge_code: string
          condition_type: Database["public"]["Enums"]["condition_type"]
          condition_value: Json | null
          created_at: string
          description: string | null
          icon_url: string | null
          id: string
          title: string
          updated_at: string
          xp_reward: number
        }
        Insert: {
          badge_code: string
          condition_type: Database["public"]["Enums"]["condition_type"]
          condition_value?: Json | null
          created_at?: string
          description?: string | null
          icon_url?: string | null
          id?: string
          title: string
          updated_at?: string
          xp_reward?: number
        }
        Update: {
          badge_code?: string
          condition_type?: Database["public"]["Enums"]["condition_type"]
          condition_value?: Json | null
          created_at?: string
          description?: string | null
          icon_url?: string | null
          id?: string
          title?: string
          updated_at?: string
          xp_reward?: number
        }
        Relationships: []
      }
      class_memberships: {
        Row: {
          class_id: string
          created_at: string
          deactivated_at: string | null
          deactivated_by: string | null
          deactivation_reason: string | null
          enrolled_at: string
          enrolled_by: string
          id: string
          learner_id: string
          status: Database["public"]["Enums"]["membership_status"]
          updated_at: string
        }
        Insert: {
          class_id: string
          created_at?: string
          deactivated_at?: string | null
          deactivated_by?: string | null
          deactivation_reason?: string | null
          enrolled_at?: string
          enrolled_by: string
          id?: string
          learner_id: string
          status?: Database["public"]["Enums"]["membership_status"]
          updated_at?: string
        }
        Update: {
          class_id?: string
          created_at?: string
          deactivated_at?: string | null
          deactivated_by?: string | null
          deactivation_reason?: string | null
          enrolled_at?: string
          enrolled_by?: string
          id?: string
          learner_id?: string
          status?: Database["public"]["Enums"]["membership_status"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "class_memberships_class_id_fkey"
            columns: ["class_id"]
            isOneToOne: false
            referencedRelation: "classes"
            referencedColumns: ["id"]
          },
        ]
      }
      classes: {
        Row: {
          archive_reason: string | null
          archived_at: string | null
          archived_by: string | null
          class_code: string | null
          created_at: string
          created_by: string
          id: string
          instructor_id: string
          status: Database["public"]["Enums"]["class_status"]
          title: string
          updated_at: string
        }
        Insert: {
          archive_reason?: string | null
          archived_at?: string | null
          archived_by?: string | null
          class_code?: string | null
          created_at?: string
          created_by: string
          id?: string
          instructor_id: string
          status?: Database["public"]["Enums"]["class_status"]
          title: string
          updated_at?: string
        }
        Update: {
          archive_reason?: string | null
          archived_at?: string | null
          archived_by?: string | null
          class_code?: string | null
          created_at?: string
          created_by?: string
          id?: string
          instructor_id?: string
          status?: Database["public"]["Enums"]["class_status"]
          title?: string
          updated_at?: string
        }
        Relationships: []
      }
      coc_bypasses: {
        Row: {
          class_id: string
          created_at: string
          granted_at: string
          id: string
          instructor_id: string
          learner_id: string
          module_version_id: string
          reason: string
          revocation_reason: string | null
          revoked_at: string | null
          revoked_by: string | null
          scope: Json
        }
        Insert: {
          class_id: string
          created_at?: string
          granted_at?: string
          id?: string
          instructor_id: string
          learner_id: string
          module_version_id: string
          reason: string
          revocation_reason?: string | null
          revoked_at?: string | null
          revoked_by?: string | null
          scope?: Json
        }
        Update: {
          class_id?: string
          created_at?: string
          granted_at?: string
          id?: string
          instructor_id?: string
          learner_id?: string
          module_version_id?: string
          reason?: string
          revocation_reason?: string | null
          revoked_at?: string | null
          revoked_by?: string | null
          scope?: Json
        }
        Relationships: [
          {
            foreignKeyName: "coc_bypasses_class_id_fkey"
            columns: ["class_id"]
            isOneToOne: false
            referencedRelation: "classes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "coc_bypasses_module_version_id_fkey"
            columns: ["module_version_id"]
            isOneToOne: false
            referencedRelation: "module_versions"
            referencedColumns: ["id"]
          },
        ]
      }
      coc_modules: {
        Row: {
          coc_code: string
          color_hex: string | null
          competency_area: string
          competency_id: string | null
          created_at: string
          description: string | null
          difficulty: Database["public"]["Enums"]["difficulty_level"] | null
          icon_url: string | null
          id: string
          module_name: string
          order_index: number
          status: Database["public"]["Enums"]["mission_status"]
          title: string
          total_missions: number
          updated_at: string
          xp_reward: number
        }
        Insert: {
          coc_code: string
          color_hex?: string | null
          competency_area: string
          competency_id?: string | null
          created_at?: string
          description?: string | null
          difficulty?: Database["public"]["Enums"]["difficulty_level"] | null
          icon_url?: string | null
          id?: string
          module_name: string
          order_index: number
          status?: Database["public"]["Enums"]["mission_status"]
          title: string
          total_missions?: number
          updated_at?: string
          xp_reward?: number
        }
        Update: {
          coc_code?: string
          color_hex?: string | null
          competency_area?: string
          competency_id?: string | null
          created_at?: string
          description?: string | null
          difficulty?: Database["public"]["Enums"]["difficulty_level"] | null
          icon_url?: string | null
          id?: string
          module_name?: string
          order_index?: number
          status?: Database["public"]["Enums"]["mission_status"]
          title?: string
          total_missions?: number
          updated_at?: string
          xp_reward?: number
        }
        Relationships: [
          {
            foreignKeyName: "coc_modules_competency_id_fkey"
            columns: ["competency_id"]
            isOneToOne: false
            referencedRelation: "competencies"
            referencedColumns: ["id"]
          },
        ]
      }
      competencies: {
        Row: {
          competency_code: string
          created_at: string
          description: string | null
          id: string
          name: string
          order_index: number
          source_trace: string | null
          tesda_source_id: string | null
          updated_at: string
        }
        Insert: {
          competency_code: string
          created_at?: string
          description?: string | null
          id?: string
          name: string
          order_index: number
          source_trace?: string | null
          tesda_source_id?: string | null
          updated_at?: string
        }
        Update: {
          competency_code?: string
          created_at?: string
          description?: string | null
          id?: string
          name?: string
          order_index?: number
          source_trace?: string | null
          tesda_source_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "competencies_tesda_source_id_fkey"
            columns: ["tesda_source_id"]
            isOneToOne: false
            referencedRelation: "tesda_sources"
            referencedColumns: ["id"]
          },
        ]
      }
      criterion_results: {
        Row: {
          attempt_id: string
          evaluated_at: string
          evaluation_run_id: string
          expected_rule: Json
          id: string
          observation: Database["public"]["Enums"]["criterion_observation"]
          observed_evidence: Json
          remarks: string | null
          rubric_criterion_id: string
          score_value: number | null
        }
        Insert: {
          attempt_id: string
          evaluated_at?: string
          evaluation_run_id: string
          expected_rule: Json
          id?: string
          observation: Database["public"]["Enums"]["criterion_observation"]
          observed_evidence: Json
          remarks?: string | null
          rubric_criterion_id: string
          score_value?: number | null
        }
        Update: {
          attempt_id?: string
          evaluated_at?: string
          evaluation_run_id?: string
          expected_rule?: Json
          id?: string
          observation?: Database["public"]["Enums"]["criterion_observation"]
          observed_evidence?: Json
          remarks?: string | null
          rubric_criterion_id?: string
          score_value?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "criterion_results_attempt_id_fkey"
            columns: ["attempt_id"]
            isOneToOne: false
            referencedRelation: "attempts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "criterion_results_rubric_criterion_id_fkey"
            columns: ["rubric_criterion_id"]
            isOneToOne: false
            referencedRelation: "rubric_criteria"
            referencedColumns: ["id"]
          },
        ]
      }
      gamification_events: {
        Row: {
          created_at: string
          created_by: string | null
          event_type: string
          id: string
          idempotency_key: string
          learner_id: string
          metadata: Json
          points_delta: number
          source_id: string | null
          source_type: string
          xp_delta: number
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          event_type: string
          id?: string
          idempotency_key: string
          learner_id: string
          metadata?: Json
          points_delta?: number
          source_id?: string | null
          source_type: string
          xp_delta?: number
        }
        Update: {
          created_at?: string
          created_by?: string | null
          event_type?: string
          id?: string
          idempotency_key?: string
          learner_id?: string
          metadata?: Json
          points_delta?: number
          source_id?: string | null
          source_type?: string
          xp_delta?: number
        }
        Relationships: []
      }
      leaderboard_entries: {
        Row: {
          coc_id: string | null
          completed_at: string
          created_at: string
          id: string
          incorrect_attempts: number
          leaderboard_type: Database["public"]["Enums"]["leaderboard_type"]
          mission_id: string | null
          mission_result_id: string | null
          ranking_points: number
          score: number
          time_spent_seconds: number
          user_id: string
          xp: number
        }
        Insert: {
          coc_id?: string | null
          completed_at?: string
          created_at?: string
          id?: string
          incorrect_attempts?: number
          leaderboard_type?: Database["public"]["Enums"]["leaderboard_type"]
          mission_id?: string | null
          mission_result_id?: string | null
          ranking_points?: number
          score?: number
          time_spent_seconds?: number
          user_id: string
          xp?: number
        }
        Update: {
          coc_id?: string | null
          completed_at?: string
          created_at?: string
          id?: string
          incorrect_attempts?: number
          leaderboard_type?: Database["public"]["Enums"]["leaderboard_type"]
          mission_id?: string | null
          mission_result_id?: string | null
          ranking_points?: number
          score?: number
          time_spent_seconds?: number
          user_id?: string
          xp?: number
        }
        Relationships: [
          {
            foreignKeyName: "leaderboard_entries_coc_id_fkey"
            columns: ["coc_id"]
            isOneToOne: false
            referencedRelation: "coc_modules"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "leaderboard_entries_mission_id_fkey"
            columns: ["mission_id"]
            isOneToOne: false
            referencedRelation: "missions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "leaderboard_entries_mission_id_fkey"
            columns: ["mission_id"]
            isOneToOne: false
            referencedRelation: "view_mission_performance_summary"
            referencedColumns: ["mission_id"]
          },
          {
            foreignKeyName: "leaderboard_entries_mission_result_id_fkey"
            columns: ["mission_result_id"]
            isOneToOne: false
            referencedRelation: "mission_results"
            referencedColumns: ["id"]
          },
        ]
      }
      learner_progress: {
        Row: {
          attempts_count: number
          best_score: number
          coc_id: string
          completed_at: string | null
          completion_percentage: number
          created_at: string
          id: string
          last_activity_at: string | null
          latest_score: number
          mission_id: string
          started_at: string | null
          status: Database["public"]["Enums"]["progress_status"]
          total_time_spent_seconds: number
          unlocked_at: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          attempts_count?: number
          best_score?: number
          coc_id: string
          completed_at?: string | null
          completion_percentage?: number
          created_at?: string
          id?: string
          last_activity_at?: string | null
          latest_score?: number
          mission_id: string
          started_at?: string | null
          status?: Database["public"]["Enums"]["progress_status"]
          total_time_spent_seconds?: number
          unlocked_at?: string | null
          updated_at?: string
          user_id: string
        }
        Update: {
          attempts_count?: number
          best_score?: number
          coc_id?: string
          completed_at?: string | null
          completion_percentage?: number
          created_at?: string
          id?: string
          last_activity_at?: string | null
          latest_score?: number
          mission_id?: string
          started_at?: string | null
          status?: Database["public"]["Enums"]["progress_status"]
          total_time_spent_seconds?: number
          unlocked_at?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "learner_progress_coc_id_fkey"
            columns: ["coc_id"]
            isOneToOne: false
            referencedRelation: "coc_modules"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "learner_progress_mission_id_fkey"
            columns: ["mission_id"]
            isOneToOne: false
            referencedRelation: "missions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "learner_progress_mission_id_fkey"
            columns: ["mission_id"]
            isOneToOne: false
            referencedRelation: "view_mission_performance_summary"
            referencedColumns: ["mission_id"]
          },
        ]
      }
      learning_resources: {
        Row: {
          class_id: string
          created_at: string
          deleted_at: string | null
          deleted_by: string | null
          deletion_reason: string | null
          description: string | null
          id: string
          mime_type: string | null
          size_bytes: number | null
          status: Database["public"]["Enums"]["resource_status"]
          storage_bucket: string
          storage_path: string
          title: string
          uploaded_by: string
        }
        Insert: {
          class_id: string
          created_at?: string
          deleted_at?: string | null
          deleted_by?: string | null
          deletion_reason?: string | null
          description?: string | null
          id?: string
          mime_type?: string | null
          size_bytes?: number | null
          status?: Database["public"]["Enums"]["resource_status"]
          storage_bucket: string
          storage_path: string
          title: string
          uploaded_by: string
        }
        Update: {
          class_id?: string
          created_at?: string
          deleted_at?: string | null
          deleted_by?: string | null
          deletion_reason?: string | null
          description?: string | null
          id?: string
          mime_type?: string | null
          size_bytes?: number | null
          status?: Database["public"]["Enums"]["resource_status"]
          storage_bucket?: string
          storage_path?: string
          title?: string
          uploaded_by?: string
        }
        Relationships: [
          {
            foreignKeyName: "learning_resources_class_id_fkey"
            columns: ["class_id"]
            isOneToOne: false
            referencedRelation: "classes"
            referencedColumns: ["id"]
          },
        ]
      }
      legacy_result_quarantine: {
        Row: {
          created_at: string
          duplicate_group_key: string
          integrity_flags: string[]
          legacy_mission_result_id: string
          migration_status: string
          review_reason: string | null
          reviewed_at: string | null
          reviewed_by: string | null
        }
        Insert: {
          created_at?: string
          duplicate_group_key: string
          integrity_flags?: string[]
          legacy_mission_result_id: string
          migration_status?: string
          review_reason?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
        }
        Update: {
          created_at?: string
          duplicate_group_key?: string
          integrity_flags?: string[]
          legacy_mission_result_id?: string
          migration_status?: string
          review_reason?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "legacy_result_quarantine_legacy_mission_result_id_fkey"
            columns: ["legacy_mission_result_id"]
            isOneToOne: true
            referencedRelation: "mission_results"
            referencedColumns: ["id"]
          },
        ]
      }
      levels: {
        Row: {
          badge_icon: string | null
          created_at: string
          id: string
          level_name: string
          level_number: number
          max_xp: number | null
          min_xp: number
        }
        Insert: {
          badge_icon?: string | null
          created_at?: string
          id?: string
          level_name: string
          level_number: number
          max_xp?: number | null
          min_xp: number
        }
        Update: {
          badge_icon?: string | null
          created_at?: string
          id?: string
          level_name?: string
          level_number?: number
          max_xp?: number | null
          min_xp?: number
        }
        Relationships: []
      }
      mission_results: {
        Row: {
          accuracy: number | null
          attempt_number: number
          coc_id: string | null
          competency_status:
            | Database["public"]["Enums"]["competency_status"]
            | null
          completed_at: string
          completed_tasks: number
          created_at: string
          earned_points: number
          feedback: string | null
          hints_used: number
          id: string
          incorrect_attempts: number
          max_score: number
          mission_id: string
          mission_title: string | null
          mistakes: string[] | null
          passed: boolean
          percentage: number
          rating: Database["public"]["Enums"]["rating_type"] | null
          remarks: string | null
          score: number
          time_spent_seconds: number
          total_tasks: number
          user_id: string
          xp_earned: number
        }
        Insert: {
          accuracy?: number | null
          attempt_number?: number
          coc_id?: string | null
          competency_status?:
            | Database["public"]["Enums"]["competency_status"]
            | null
          completed_at?: string
          completed_tasks?: number
          created_at?: string
          earned_points?: number
          feedback?: string | null
          hints_used?: number
          id?: string
          incorrect_attempts?: number
          max_score?: number
          mission_id: string
          mission_title?: string | null
          mistakes?: string[] | null
          passed: boolean
          percentage: number
          rating?: Database["public"]["Enums"]["rating_type"] | null
          remarks?: string | null
          score: number
          time_spent_seconds?: number
          total_tasks?: number
          user_id: string
          xp_earned?: number
        }
        Update: {
          accuracy?: number | null
          attempt_number?: number
          coc_id?: string | null
          competency_status?:
            | Database["public"]["Enums"]["competency_status"]
            | null
          completed_at?: string
          completed_tasks?: number
          created_at?: string
          earned_points?: number
          feedback?: string | null
          hints_used?: number
          id?: string
          incorrect_attempts?: number
          max_score?: number
          mission_id?: string
          mission_title?: string | null
          mistakes?: string[] | null
          passed?: boolean
          percentage?: number
          rating?: Database["public"]["Enums"]["rating_type"] | null
          remarks?: string | null
          score?: number
          time_spent_seconds?: number
          total_tasks?: number
          user_id?: string
          xp_earned?: number
        }
        Relationships: [
          {
            foreignKeyName: "mission_results_coc_id_fkey"
            columns: ["coc_id"]
            isOneToOne: false
            referencedRelation: "coc_modules"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "mission_results_mission_id_fkey"
            columns: ["mission_id"]
            isOneToOne: false
            referencedRelation: "missions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "mission_results_mission_id_fkey"
            columns: ["mission_id"]
            isOneToOne: false
            referencedRelation: "view_mission_performance_summary"
            referencedColumns: ["mission_id"]
          },
        ]
      }
      missions: {
        Row: {
          asset_path: string | null
          challenge_description: string | null
          coc_id: string
          competency_id: string | null
          created_at: string
          description: string | null
          difficulty: Database["public"]["Enums"]["difficulty_level"] | null
          estimated_time_minutes: number | null
          hint_count: number
          icon_url: string | null
          id: string
          is_locked: boolean
          mission_code: string
          mission_number: number
          mission_type: Database["public"]["Enums"]["mission_type"]
          objective: string | null
          order_index: number
          passing_score: number
          points_reward: number
          scenario: string | null
          skills_assessed: string[] | null
          status: Database["public"]["Enums"]["mission_status"]
          time_limit_seconds: number | null
          title: string
          updated_at: string
          xp_reward: number
        }
        Insert: {
          asset_path?: string | null
          challenge_description?: string | null
          coc_id: string
          competency_id?: string | null
          created_at?: string
          description?: string | null
          difficulty?: Database["public"]["Enums"]["difficulty_level"] | null
          estimated_time_minutes?: number | null
          hint_count?: number
          icon_url?: string | null
          id?: string
          is_locked?: boolean
          mission_code: string
          mission_number: number
          mission_type: Database["public"]["Enums"]["mission_type"]
          objective?: string | null
          order_index: number
          passing_score?: number
          points_reward?: number
          scenario?: string | null
          skills_assessed?: string[] | null
          status?: Database["public"]["Enums"]["mission_status"]
          time_limit_seconds?: number | null
          title: string
          updated_at?: string
          xp_reward?: number
        }
        Update: {
          asset_path?: string | null
          challenge_description?: string | null
          coc_id?: string
          competency_id?: string | null
          created_at?: string
          description?: string | null
          difficulty?: Database["public"]["Enums"]["difficulty_level"] | null
          estimated_time_minutes?: number | null
          hint_count?: number
          icon_url?: string | null
          id?: string
          is_locked?: boolean
          mission_code?: string
          mission_number?: number
          mission_type?: Database["public"]["Enums"]["mission_type"]
          objective?: string | null
          order_index?: number
          passing_score?: number
          points_reward?: number
          scenario?: string | null
          skills_assessed?: string[] | null
          status?: Database["public"]["Enums"]["mission_status"]
          time_limit_seconds?: number | null
          title?: string
          updated_at?: string
          xp_reward?: number
        }
        Relationships: [
          {
            foreignKeyName: "missions_coc_id_fkey"
            columns: ["coc_id"]
            isOneToOne: false
            referencedRelation: "coc_modules"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "missions_competency_id_fkey"
            columns: ["competency_id"]
            isOneToOne: false
            referencedRelation: "competencies"
            referencedColumns: ["id"]
          },
        ]
      }
      module_versions: {
        Row: {
          content_metadata: Json
          created_at: string
          created_by: string
          description: string | null
          id: string
          module_id: string
          published_at: string | null
          published_by: string | null
          retired_at: string | null
          source_trace: Json
          status: Database["public"]["Enums"]["content_version_status"]
          tesda_source_id: string
          title: string
          updated_at: string
          version_number: number
        }
        Insert: {
          content_metadata?: Json
          created_at?: string
          created_by: string
          description?: string | null
          id?: string
          module_id: string
          published_at?: string | null
          published_by?: string | null
          retired_at?: string | null
          source_trace?: Json
          status?: Database["public"]["Enums"]["content_version_status"]
          tesda_source_id: string
          title: string
          updated_at?: string
          version_number: number
        }
        Update: {
          content_metadata?: Json
          created_at?: string
          created_by?: string
          description?: string | null
          id?: string
          module_id?: string
          published_at?: string | null
          published_by?: string | null
          retired_at?: string | null
          source_trace?: Json
          status?: Database["public"]["Enums"]["content_version_status"]
          tesda_source_id?: string
          title?: string
          updated_at?: string
          version_number?: number
        }
        Relationships: [
          {
            foreignKeyName: "module_versions_module_id_fkey"
            columns: ["module_id"]
            isOneToOne: false
            referencedRelation: "coc_modules"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "module_versions_tesda_source_id_fkey"
            columns: ["tesda_source_id"]
            isOneToOne: false
            referencedRelation: "tesda_sources"
            referencedColumns: ["id"]
          },
        ]
      }
      notifications: {
        Row: {
          created_at: string
          id: string
          is_read: boolean
          message: string
          metadata: Json | null
          read_at: string | null
          related_coc_id: string | null
          related_mission_id: string | null
          title: string
          type: Database["public"]["Enums"]["notification_type"]
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          is_read?: boolean
          message: string
          metadata?: Json | null
          read_at?: string | null
          related_coc_id?: string | null
          related_mission_id?: string | null
          title: string
          type?: Database["public"]["Enums"]["notification_type"]
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          is_read?: boolean
          message?: string
          metadata?: Json | null
          read_at?: string | null
          related_coc_id?: string | null
          related_mission_id?: string | null
          title?: string
          type?: Database["public"]["Enums"]["notification_type"]
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "notifications_related_coc_id_fkey"
            columns: ["related_coc_id"]
            isOneToOne: false
            referencedRelation: "coc_modules"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notifications_related_mission_id_fkey"
            columns: ["related_mission_id"]
            isOneToOne: false
            referencedRelation: "missions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "notifications_related_mission_id_fkey"
            columns: ["related_mission_id"]
            isOneToOne: false
            referencedRelation: "view_mission_performance_summary"
            referencedColumns: ["mission_id"]
          },
        ]
      }
      profiles: {
        Row: {
          avatar_url: string | null
          completed_missions: number
          course_section: string | null
          created_at: string
          current_level: number
          current_streak: number
          deactivated_at: string | null
          deactivated_by: string | null
          deactivation_reason: string | null
          email: string
          full_name: string
          id: string
          last_activity_at: string | null
          last_login_at: string | null
          learner_id: string | null
          role: Database["public"]["Enums"]["user_role"]
          school: string | null
          status: Database["public"]["Enums"]["account_status"]
          total_badges: number
          total_points: number
          total_xp: number
          updated_at: string
          user_id: string
        }
        Insert: {
          avatar_url?: string | null
          completed_missions?: number
          course_section?: string | null
          created_at?: string
          current_level?: number
          current_streak?: number
          deactivated_at?: string | null
          deactivated_by?: string | null
          deactivation_reason?: string | null
          email: string
          full_name: string
          id?: string
          last_activity_at?: string | null
          last_login_at?: string | null
          learner_id?: string | null
          role?: Database["public"]["Enums"]["user_role"]
          school?: string | null
          status?: Database["public"]["Enums"]["account_status"]
          total_badges?: number
          total_points?: number
          total_xp?: number
          updated_at?: string
          user_id: string
        }
        Update: {
          avatar_url?: string | null
          completed_missions?: number
          course_section?: string | null
          created_at?: string
          current_level?: number
          current_streak?: number
          deactivated_at?: string | null
          deactivated_by?: string | null
          deactivation_reason?: string | null
          email?: string
          full_name?: string
          id?: string
          last_activity_at?: string | null
          last_login_at?: string | null
          learner_id?: string | null
          role?: Database["public"]["Enums"]["user_role"]
          school?: string | null
          status?: Database["public"]["Enums"]["account_status"]
          total_badges?: number
          total_points?: number
          total_xp?: number
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      quiz_answers: {
        Row: {
          answer: Json
          answered_at: string
          id: string
          is_correct: boolean | null
          quiz_attempt_id: string
          quiz_item_id: string
          quiz_version_id: string
          updated_at: string
        }
        Insert: {
          answer: Json
          answered_at?: string
          id?: string
          is_correct?: boolean | null
          quiz_attempt_id: string
          quiz_item_id: string
          quiz_version_id: string
          updated_at?: string
        }
        Update: {
          answer?: Json
          answered_at?: string
          id?: string
          is_correct?: boolean | null
          quiz_attempt_id?: string
          quiz_item_id?: string
          quiz_version_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "quiz_answers_quiz_attempt_id_fkey"
            columns: ["quiz_attempt_id"]
            isOneToOne: false
            referencedRelation: "quiz_attempts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quiz_answers_quiz_item_id_fkey"
            columns: ["quiz_item_id"]
            isOneToOne: false
            referencedRelation: "quiz_items"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quiz_answers_quiz_version_id_fkey"
            columns: ["quiz_version_id"]
            isOneToOne: false
            referencedRelation: "quiz_versions"
            referencedColumns: ["id"]
          },
        ]
      }
      quiz_assignments: {
        Row: {
          assigned_by: string
          attempts_allowed: number | null
          available_at: string | null
          class_id: string
          close_reason: string | null
          closed_at: string | null
          created_at: string
          due_at: string | null
          id: string
          instructions: string | null
          quiz_version_id: string
          status: Database["public"]["Enums"]["assignment_status"]
          updated_at: string
        }
        Insert: {
          assigned_by: string
          attempts_allowed?: number | null
          available_at?: string | null
          class_id: string
          close_reason?: string | null
          closed_at?: string | null
          created_at?: string
          due_at?: string | null
          id?: string
          instructions?: string | null
          quiz_version_id: string
          status?: Database["public"]["Enums"]["assignment_status"]
          updated_at?: string
        }
        Update: {
          assigned_by?: string
          attempts_allowed?: number | null
          available_at?: string | null
          class_id?: string
          close_reason?: string | null
          closed_at?: string | null
          created_at?: string
          due_at?: string | null
          id?: string
          instructions?: string | null
          quiz_version_id?: string
          status?: Database["public"]["Enums"]["assignment_status"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "quiz_assignments_class_id_fkey"
            columns: ["class_id"]
            isOneToOne: false
            referencedRelation: "classes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quiz_assignments_quiz_version_id_fkey"
            columns: ["quiz_version_id"]
            isOneToOne: false
            referencedRelation: "quiz_versions"
            referencedColumns: ["id"]
          },
        ]
      }
      quiz_attempts: {
        Row: {
          class_id: string
          client_start_key: string
          completed_at: string | null
          created_at: string
          id: string
          learner_id: string
          quiz_assignment_id: string
          quiz_version_id: string
          started_at: string
          status: Database["public"]["Enums"]["quiz_attempt_status"]
          submission_key: string | null
          submitted_at: string | null
          updated_at: string
        }
        Insert: {
          class_id: string
          client_start_key: string
          completed_at?: string | null
          created_at?: string
          id?: string
          learner_id: string
          quiz_assignment_id: string
          quiz_version_id: string
          started_at?: string
          status?: Database["public"]["Enums"]["quiz_attempt_status"]
          submission_key?: string | null
          submitted_at?: string | null
          updated_at?: string
        }
        Update: {
          class_id?: string
          client_start_key?: string
          completed_at?: string | null
          created_at?: string
          id?: string
          learner_id?: string
          quiz_assignment_id?: string
          quiz_version_id?: string
          started_at?: string
          status?: Database["public"]["Enums"]["quiz_attempt_status"]
          submission_key?: string | null
          submitted_at?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "quiz_attempts_class_id_fkey"
            columns: ["class_id"]
            isOneToOne: false
            referencedRelation: "classes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quiz_attempts_quiz_assignment_id_fkey"
            columns: ["quiz_assignment_id"]
            isOneToOne: false
            referencedRelation: "quiz_assignments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quiz_attempts_quiz_version_id_fkey"
            columns: ["quiz_version_id"]
            isOneToOne: false
            referencedRelation: "quiz_versions"
            referencedColumns: ["id"]
          },
        ]
      }
      quiz_items: {
        Row: {
          ai_generation_id: string | null
          correct_answer: Json
          created_at: string
          created_by: string
          explanation: string | null
          id: string
          item_code: string
          item_type: Database["public"]["Enums"]["quiz_item_type"]
          options: Json
          order_index: number
          origin: Database["public"]["Enums"]["quiz_item_origin"]
          prompt: string
          quiz_version_id: string
          removal_reason: string | null
          removed_at: string | null
          removed_by: string | null
          review_notes: string | null
          review_status: Database["public"]["Enums"]["quiz_item_review_status"]
          reviewed_at: string | null
          reviewed_by: string | null
          updated_at: string
        }
        Insert: {
          ai_generation_id?: string | null
          correct_answer: Json
          created_at?: string
          created_by: string
          explanation?: string | null
          id?: string
          item_code: string
          item_type: Database["public"]["Enums"]["quiz_item_type"]
          options?: Json
          order_index: number
          origin?: Database["public"]["Enums"]["quiz_item_origin"]
          prompt: string
          quiz_version_id: string
          removal_reason?: string | null
          removed_at?: string | null
          removed_by?: string | null
          review_notes?: string | null
          review_status?: Database["public"]["Enums"]["quiz_item_review_status"]
          reviewed_at?: string | null
          reviewed_by?: string | null
          updated_at?: string
        }
        Update: {
          ai_generation_id?: string | null
          correct_answer?: Json
          created_at?: string
          created_by?: string
          explanation?: string | null
          id?: string
          item_code?: string
          item_type?: Database["public"]["Enums"]["quiz_item_type"]
          options?: Json
          order_index?: number
          origin?: Database["public"]["Enums"]["quiz_item_origin"]
          prompt?: string
          quiz_version_id?: string
          removal_reason?: string | null
          removed_at?: string | null
          removed_by?: string | null
          review_notes?: string | null
          review_status?: Database["public"]["Enums"]["quiz_item_review_status"]
          reviewed_at?: string | null
          reviewed_by?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "quiz_items_ai_generation_id_fkey"
            columns: ["ai_generation_id"]
            isOneToOne: false
            referencedRelation: "ai_quiz_generations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quiz_items_quiz_version_id_fkey"
            columns: ["quiz_version_id"]
            isOneToOne: false
            referencedRelation: "quiz_versions"
            referencedColumns: ["id"]
          },
        ]
      }
      quiz_versions: {
        Row: {
          change_summary: string | null
          created_at: string
          created_by: string
          id: string
          instructions: string | null
          published_at: string | null
          published_by: string | null
          quiz_id: string
          retired_at: string | null
          status: Database["public"]["Enums"]["content_version_status"]
          updated_at: string
          version_number: number
        }
        Insert: {
          change_summary?: string | null
          created_at?: string
          created_by: string
          id?: string
          instructions?: string | null
          published_at?: string | null
          published_by?: string | null
          quiz_id: string
          retired_at?: string | null
          status?: Database["public"]["Enums"]["content_version_status"]
          updated_at?: string
          version_number: number
        }
        Update: {
          change_summary?: string | null
          created_at?: string
          created_by?: string
          id?: string
          instructions?: string | null
          published_at?: string | null
          published_by?: string | null
          quiz_id?: string
          retired_at?: string | null
          status?: Database["public"]["Enums"]["content_version_status"]
          updated_at?: string
          version_number?: number
        }
        Relationships: [
          {
            foreignKeyName: "quiz_versions_quiz_id_fkey"
            columns: ["quiz_id"]
            isOneToOne: false
            referencedRelation: "quizzes"
            referencedColumns: ["id"]
          },
        ]
      }
      quiz_results: {
        Row: {
          correct_count: number
          created_at: string
          evaluated_at: string
          id: string
          item_results: Json
          question_count: number
          quiz_attempt_id: string
        }
        Insert: {
          correct_count: number
          created_at?: string
          evaluated_at?: string
          id?: string
          item_results: Json
          question_count: number
          quiz_attempt_id: string
        }
        Update: {
          correct_count?: number
          created_at?: string
          evaluated_at?: string
          id?: string
          item_results?: Json
          question_count?: number
          quiz_attempt_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "quiz_results_quiz_attempt_id_fkey"
            columns: ["quiz_attempt_id"]
            isOneToOne: true
            referencedRelation: "quiz_attempts"
            referencedColumns: ["id"]
          },
        ]
      }
      quizzes: {
        Row: {
          archive_reason: string | null
          archived_at: string | null
          archived_by: string | null
          coc_module_id: string | null
          created_at: string
          created_by: string
          description: string | null
          id: string
          instructor_id: string
          title: string
          topic: string
          updated_at: string
        }
        Insert: {
          archive_reason?: string | null
          archived_at?: string | null
          archived_by?: string | null
          coc_module_id?: string | null
          created_at?: string
          created_by: string
          description?: string | null
          id?: string
          instructor_id: string
          title: string
          topic: string
          updated_at?: string
        }
        Update: {
          archive_reason?: string | null
          archived_at?: string | null
          archived_by?: string | null
          coc_module_id?: string | null
          created_at?: string
          created_by?: string
          description?: string | null
          id?: string
          instructor_id?: string
          title?: string
          topic?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "quizzes_coc_module_id_fkey"
            columns: ["coc_module_id"]
            isOneToOne: false
            referencedRelation: "coc_modules"
            referencedColumns: ["id"]
          },
        ]
      }
      reports: {
        Row: {
          created_at: string
          data: Json | null
          filters: Json | null
          generated_by: string | null
          id: string
          report_type: Database["public"]["Enums"]["report_type"]
          title: string
        }
        Insert: {
          created_at?: string
          data?: Json | null
          filters?: Json | null
          generated_by?: string | null
          id?: string
          report_type: Database["public"]["Enums"]["report_type"]
          title: string
        }
        Update: {
          created_at?: string
          data?: Json | null
          filters?: Json | null
          generated_by?: string | null
          id?: string
          report_type?: Database["public"]["Enums"]["report_type"]
          title?: string
        }
        Relationships: []
      }
      result_releases: {
        Row: {
          attempt_id: string
          created_at: string
          id: string
          is_current: boolean
          release_number: number
          release_reason: string | null
          released_at: string
          released_by: string
          revocation_reason: string | null
          revoked_at: string | null
          revoked_by: string | null
          score_revision_id: string
        }
        Insert: {
          attempt_id: string
          created_at?: string
          id?: string
          is_current?: boolean
          release_number: number
          release_reason?: string | null
          released_at?: string
          released_by: string
          revocation_reason?: string | null
          revoked_at?: string | null
          revoked_by?: string | null
          score_revision_id: string
        }
        Update: {
          attempt_id?: string
          created_at?: string
          id?: string
          is_current?: boolean
          release_number?: number
          release_reason?: string | null
          released_at?: string
          released_by?: string
          revocation_reason?: string | null
          revoked_at?: string | null
          revoked_by?: string | null
          score_revision_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "result_releases_attempt_id_fkey"
            columns: ["attempt_id"]
            isOneToOne: false
            referencedRelation: "attempts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "result_releases_score_revision_id_fkey"
            columns: ["score_revision_id"]
            isOneToOne: false
            referencedRelation: "score_revisions"
            referencedColumns: ["id"]
          },
        ]
      }
      rubric_criteria: {
        Row: {
          created_at: string
          criterion_code: string
          description: string | null
          evidence_rule: Json
          id: string
          is_required: boolean
          max_value: number | null
          order_index: number
          rubric_version_id: string
          scoring_rule: Json
          source_trace: string
          title: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          criterion_code: string
          description?: string | null
          evidence_rule?: Json
          id?: string
          is_required?: boolean
          max_value?: number | null
          order_index: number
          rubric_version_id: string
          scoring_rule?: Json
          source_trace: string
          title: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          criterion_code?: string
          description?: string | null
          evidence_rule?: Json
          id?: string
          is_required?: boolean
          max_value?: number | null
          order_index?: number
          rubric_version_id?: string
          scoring_rule?: Json
          source_trace?: string
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "rubric_criteria_rubric_version_id_fkey"
            columns: ["rubric_version_id"]
            isOneToOne: false
            referencedRelation: "rubric_versions"
            referencedColumns: ["id"]
          },
        ]
      }
      rubric_versions: {
        Row: {
          activity_version_id: string
          approved_at: string | null
          approved_by: string | null
          created_at: string
          created_by: string
          id: string
          passing_rule: Json
          retired_at: string | null
          scoring_method: string
          status: Database["public"]["Enums"]["rubric_status"]
          tesda_source_id: string
          title: string
          updated_at: string
          version_number: number
        }
        Insert: {
          activity_version_id: string
          approved_at?: string | null
          approved_by?: string | null
          created_at?: string
          created_by: string
          id?: string
          passing_rule?: Json
          retired_at?: string | null
          scoring_method?: string
          status?: Database["public"]["Enums"]["rubric_status"]
          tesda_source_id: string
          title: string
          updated_at?: string
          version_number: number
        }
        Update: {
          activity_version_id?: string
          approved_at?: string | null
          approved_by?: string | null
          created_at?: string
          created_by?: string
          id?: string
          passing_rule?: Json
          retired_at?: string | null
          scoring_method?: string
          status?: Database["public"]["Enums"]["rubric_status"]
          tesda_source_id?: string
          title?: string
          updated_at?: string
          version_number?: number
        }
        Relationships: [
          {
            foreignKeyName: "rubric_versions_activity_version_id_fkey"
            columns: ["activity_version_id"]
            isOneToOne: false
            referencedRelation: "activity_versions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "rubric_versions_tesda_source_id_fkey"
            columns: ["tesda_source_id"]
            isOneToOne: false
            referencedRelation: "tesda_sources"
            referencedColumns: ["id"]
          },
        ]
      }
      score_revisions: {
        Row: {
          actor_id: string | null
          actor_role: Database["public"]["Enums"]["user_role"] | null
          attempt_id: string
          created_at: string
          criterion_values: Json
          evaluation_run_id: string | null
          id: string
          max_value: number | null
          outcome: Database["public"]["Enums"]["evaluation_outcome"]
          percentage: number | null
          reason: string | null
          remarks: string | null
          revision_number: number
          revision_type: Database["public"]["Enums"]["score_revision_type"]
          rubric_version_id: string
          supersedes_revision_id: string | null
          tesda_source_id: string
          total_value: number | null
        }
        Insert: {
          actor_id?: string | null
          actor_role?: Database["public"]["Enums"]["user_role"] | null
          attempt_id: string
          created_at?: string
          criterion_values?: Json
          evaluation_run_id?: string | null
          id?: string
          max_value?: number | null
          outcome: Database["public"]["Enums"]["evaluation_outcome"]
          percentage?: number | null
          reason?: string | null
          remarks?: string | null
          revision_number: number
          revision_type: Database["public"]["Enums"]["score_revision_type"]
          rubric_version_id: string
          supersedes_revision_id?: string | null
          tesda_source_id: string
          total_value?: number | null
        }
        Update: {
          actor_id?: string | null
          actor_role?: Database["public"]["Enums"]["user_role"] | null
          attempt_id?: string
          created_at?: string
          criterion_values?: Json
          evaluation_run_id?: string | null
          id?: string
          max_value?: number | null
          outcome?: Database["public"]["Enums"]["evaluation_outcome"]
          percentage?: number | null
          reason?: string | null
          remarks?: string | null
          revision_number?: number
          revision_type?: Database["public"]["Enums"]["score_revision_type"]
          rubric_version_id?: string
          supersedes_revision_id?: string | null
          tesda_source_id?: string
          total_value?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "score_revisions_attempt_id_fkey"
            columns: ["attempt_id"]
            isOneToOne: false
            referencedRelation: "attempts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "score_revisions_rubric_version_id_fkey"
            columns: ["rubric_version_id"]
            isOneToOne: false
            referencedRelation: "rubric_versions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "score_revisions_supersedes_revision_id_fkey"
            columns: ["supersedes_revision_id"]
            isOneToOne: false
            referencedRelation: "score_revisions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "score_revisions_tesda_source_id_fkey"
            columns: ["tesda_source_id"]
            isOneToOne: false
            referencedRelation: "tesda_sources"
            referencedColumns: ["id"]
          },
        ]
      }
      simulation_tasks: {
        Row: {
          accepted_component_ids: string[] | null
          component_id: string | null
          correct_answer: string | null
          correct_target: string | null
          created_at: string
          feedback_correct: string | null
          feedback_incorrect: string | null
          hint_text: string | null
          id: string
          instruction: string
          is_required: boolean
          mission_id: string
          options: Json | null
          order_index: number
          points: number
          question_text: string | null
          required_order: number | null
          requires_previous_task: boolean
          target_zone_id: string | null
          task_code: string | null
          task_number: number
          task_type: Database["public"]["Enums"]["mission_type"]
          updated_at: string
        }
        Insert: {
          accepted_component_ids?: string[] | null
          component_id?: string | null
          correct_answer?: string | null
          correct_target?: string | null
          created_at?: string
          feedback_correct?: string | null
          feedback_incorrect?: string | null
          hint_text?: string | null
          id?: string
          instruction: string
          is_required?: boolean
          mission_id: string
          options?: Json | null
          order_index: number
          points?: number
          question_text?: string | null
          required_order?: number | null
          requires_previous_task?: boolean
          target_zone_id?: string | null
          task_code?: string | null
          task_number: number
          task_type: Database["public"]["Enums"]["mission_type"]
          updated_at?: string
        }
        Update: {
          accepted_component_ids?: string[] | null
          component_id?: string | null
          correct_answer?: string | null
          correct_target?: string | null
          created_at?: string
          feedback_correct?: string | null
          feedback_incorrect?: string | null
          hint_text?: string | null
          id?: string
          instruction?: string
          is_required?: boolean
          mission_id?: string
          options?: Json | null
          order_index?: number
          points?: number
          question_text?: string | null
          required_order?: number | null
          requires_previous_task?: boolean
          target_zone_id?: string | null
          task_code?: string | null
          task_number?: number
          task_type?: Database["public"]["Enums"]["mission_type"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "simulation_tasks_mission_id_fkey"
            columns: ["mission_id"]
            isOneToOne: false
            referencedRelation: "missions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "simulation_tasks_mission_id_fkey"
            columns: ["mission_id"]
            isOneToOne: false
            referencedRelation: "view_mission_performance_summary"
            referencedColumns: ["mission_id"]
          },
        ]
      }
      system_settings: {
        Row: {
          description: string | null
          setting_key: string
          setting_value: Json
          updated_at: string
          updated_by: string
        }
        Insert: {
          description?: string | null
          setting_key: string
          setting_value: Json
          updated_at?: string
          updated_by: string
        }
        Update: {
          description?: string | null
          setting_key?: string
          setting_value?: Json
          updated_at?: string
          updated_by?: string
        }
        Relationships: []
      }
      task_results: {
        Row: {
          attempts: number
          completed_at: string | null
          correct_answer: string | null
          correct_target: string | null
          created_at: string
          feedback: string | null
          hint_used: boolean
          id: string
          is_completed: boolean
          is_correct: boolean
          max_score: number
          mission_id: string
          mission_result_id: string
          score_obtained: number
          selected_answer: string | null
          selected_target: string | null
          task_id: string | null
          user_id: string
        }
        Insert: {
          attempts?: number
          completed_at?: string | null
          correct_answer?: string | null
          correct_target?: string | null
          created_at?: string
          feedback?: string | null
          hint_used?: boolean
          id?: string
          is_completed?: boolean
          is_correct?: boolean
          max_score?: number
          mission_id: string
          mission_result_id: string
          score_obtained?: number
          selected_answer?: string | null
          selected_target?: string | null
          task_id?: string | null
          user_id: string
        }
        Update: {
          attempts?: number
          completed_at?: string | null
          correct_answer?: string | null
          correct_target?: string | null
          created_at?: string
          feedback?: string | null
          hint_used?: boolean
          id?: string
          is_completed?: boolean
          is_correct?: boolean
          max_score?: number
          mission_id?: string
          mission_result_id?: string
          score_obtained?: number
          selected_answer?: string | null
          selected_target?: string | null
          task_id?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "task_results_mission_id_fkey"
            columns: ["mission_id"]
            isOneToOne: false
            referencedRelation: "missions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "task_results_mission_id_fkey"
            columns: ["mission_id"]
            isOneToOne: false
            referencedRelation: "view_mission_performance_summary"
            referencedColumns: ["mission_id"]
          },
          {
            foreignKeyName: "task_results_mission_result_id_fkey"
            columns: ["mission_result_id"]
            isOneToOne: false
            referencedRelation: "mission_results"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "task_results_task_id_fkey"
            columns: ["task_id"]
            isOneToOne: false
            referencedRelation: "simulation_tasks"
            referencedColumns: ["id"]
          },
        ]
      }
      tesda_sources: {
        Row: {
          activated_at: string | null
          activated_by: string | null
          approved_at: string | null
          approved_by: string | null
          created_at: string
          created_by: string
          document_storage_path: string | null
          edition: string | null
          effective_date: string | null
          id: string
          publication_date: string | null
          qualification_code: string
          source_reference: string
          status: Database["public"]["Enums"]["tesda_source_status"]
          title: string
          updated_at: string
          validation_notes: string | null
        }
        Insert: {
          activated_at?: string | null
          activated_by?: string | null
          approved_at?: string | null
          approved_by?: string | null
          created_at?: string
          created_by: string
          document_storage_path?: string | null
          edition?: string | null
          effective_date?: string | null
          id?: string
          publication_date?: string | null
          qualification_code: string
          source_reference: string
          status?: Database["public"]["Enums"]["tesda_source_status"]
          title: string
          updated_at?: string
          validation_notes?: string | null
        }
        Update: {
          activated_at?: string | null
          activated_by?: string | null
          approved_at?: string | null
          approved_by?: string | null
          created_at?: string
          created_by?: string
          document_storage_path?: string | null
          edition?: string | null
          effective_date?: string | null
          id?: string
          publication_date?: string | null
          qualification_code?: string
          source_reference?: string
          status?: Database["public"]["Enums"]["tesda_source_status"]
          title?: string
          updated_at?: string
          validation_notes?: string | null
        }
        Relationships: []
      }
      user_achievements: {
        Row: {
          achievement_id: string
          coc_id: string | null
          created_at: string
          earned_at: string
          id: string
          mission_id: string | null
          user_id: string
        }
        Insert: {
          achievement_id: string
          coc_id?: string | null
          created_at?: string
          earned_at?: string
          id?: string
          mission_id?: string | null
          user_id: string
        }
        Update: {
          achievement_id?: string
          coc_id?: string | null
          created_at?: string
          earned_at?: string
          id?: string
          mission_id?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_achievements_achievement_id_fkey"
            columns: ["achievement_id"]
            isOneToOne: false
            referencedRelation: "achievements"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_achievements_coc_id_fkey"
            columns: ["coc_id"]
            isOneToOne: false
            referencedRelation: "coc_modules"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_achievements_mission_id_fkey"
            columns: ["mission_id"]
            isOneToOne: false
            referencedRelation: "missions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_achievements_mission_id_fkey"
            columns: ["mission_id"]
            isOneToOne: false
            referencedRelation: "view_mission_performance_summary"
            referencedColumns: ["mission_id"]
          },
        ]
      }
      user_badges: {
        Row: {
          badge_id: string
          coc_id: string | null
          created_at: string
          earned_at: string
          id: string
          mission_id: string | null
          user_id: string
        }
        Insert: {
          badge_id: string
          coc_id?: string | null
          created_at?: string
          earned_at?: string
          id?: string
          mission_id?: string | null
          user_id: string
        }
        Update: {
          badge_id?: string
          coc_id?: string | null
          created_at?: string
          earned_at?: string
          id?: string
          mission_id?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_badges_badge_id_fkey"
            columns: ["badge_id"]
            isOneToOne: false
            referencedRelation: "badges"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_badges_coc_id_fkey"
            columns: ["coc_id"]
            isOneToOne: false
            referencedRelation: "coc_modules"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_badges_mission_id_fkey"
            columns: ["mission_id"]
            isOneToOne: false
            referencedRelation: "missions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_badges_mission_id_fkey"
            columns: ["mission_id"]
            isOneToOne: false
            referencedRelation: "view_mission_performance_summary"
            referencedColumns: ["mission_id"]
          },
        ]
      }
      user_settings: {
        Row: {
          created_at: string
          id: string
          language: string
          notifications_enabled: boolean
          sound_enabled: boolean
          theme_mode: string
          updated_at: string
          user_id: string
          vibration_enabled: boolean
        }
        Insert: {
          created_at?: string
          id?: string
          language?: string
          notifications_enabled?: boolean
          sound_enabled?: boolean
          theme_mode?: string
          updated_at?: string
          user_id: string
          vibration_enabled?: boolean
        }
        Update: {
          created_at?: string
          id?: string
          language?: string
          notifications_enabled?: boolean
          sound_enabled?: boolean
          theme_mode?: string
          updated_at?: string
          user_id?: string
          vibration_enabled?: boolean
        }
        Relationships: []
      }
    }
    Views: {
      view_leaderboard_overall: {
        Row: {
          avatar_url: string | null
          completed_missions: number | null
          current_level: number | null
          full_name: string | null
          rank: number | null
          total_badges: number | null
          total_points: number | null
          total_xp: number | null
          user_id: string | null
        }
        Relationships: []
      }
      view_mission_performance_summary: {
        Row: {
          average_score: number | null
          average_time_seconds: number | null
          coc_code: string | null
          failed_count: number | null
          mission_code: string | null
          mission_id: string | null
          mission_title: string | null
          module_name: string | null
          passed_count: number | null
          total_attempts: number | null
          unique_learners: number | null
        }
        Relationships: []
      }
    }
    Functions: {
      activate_tesda_source: {
        Args: { p_reason: string; p_source_id: string }
        Returns: {
          activated_at: string | null
          activated_by: string | null
          approved_at: string | null
          approved_by: string | null
          created_at: string
          created_by: string
          document_storage_path: string | null
          edition: string | null
          effective_date: string | null
          id: string
          publication_date: string | null
          qualification_code: string
          source_reference: string
          status: Database["public"]["Enums"]["tesda_source_status"]
          title: string
          updated_at: string
          validation_notes: string | null
        }
        SetofOptions: {
          from: "*"
          to: "tesda_sources"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      assign_published_quiz: {
        Args: {
          p_class_id: string
          p_quiz_version_id: string
          p_available_at?: string
          p_due_at?: string
          p_attempts_allowed?: number
          p_instructions?: string
        }
        Returns: {
          assigned_by: string
          attempts_allowed: number | null
          available_at: string | null
          class_id: string
          close_reason: string | null
          closed_at: string | null
          created_at: string
          due_at: string | null
          id: string
          instructions: string | null
          quiz_version_id: string
          status: string
          updated_at: string
        }
      }
      admin_account_removal_readiness: {
        Args: { p_user_id: string }
        Returns: Json
      }
      get_admin_system_analytics: {
        Args: { p_from?: string; p_to?: string }
        Returns: Json
      }
      get_instructor_analytics: {
        Args: {
          p_class_id?: string
          p_coc_id?: string
          p_from?: string
          p_mission_id?: string
          p_to?: string
        }
        Returns: Json
      }
      admin_change_user_role: {
        Args: {
          p_new_role: Database["public"]["Enums"]["user_role"]
          p_reason: string
          p_user_id: string
        }
        Returns: {
          avatar_url: string | null
          completed_missions: number
          course_section: string | null
          created_at: string
          current_level: number
          current_streak: number
          deactivated_at: string | null
          deactivated_by: string | null
          deactivation_reason: string | null
          email: string
          full_name: string
          id: string
          last_activity_at: string | null
          last_login_at: string | null
          learner_id: string | null
          role: Database["public"]["Enums"]["user_role"]
          school: string | null
          status: Database["public"]["Enums"]["account_status"]
          total_badges: number
          total_points: number
          total_xp: number
          updated_at: string
          user_id: string
        }
        SetofOptions: {
          from: "*"
          to: "profiles"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      admin_set_account_status: {
        Args: {
          p_reason?: string
          p_status: Database["public"]["Enums"]["account_status"]
          p_user_id: string
        }
        Returns: {
          avatar_url: string | null
          completed_missions: number
          course_section: string | null
          created_at: string
          current_level: number
          current_streak: number
          deactivated_at: string | null
          deactivated_by: string | null
          deactivation_reason: string | null
          email: string
          full_name: string
          id: string
          last_activity_at: string | null
          last_login_at: string | null
          learner_id: string | null
          role: Database["public"]["Enums"]["user_role"]
          school: string | null
          status: Database["public"]["Enums"]["account_status"]
          total_badges: number
          total_points: number
          total_xp: number
          updated_at: string
          user_id: string
        }
        SetofOptions: {
          from: "*"
          to: "profiles"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      admin_update_system_setting: {
        Args: {
          p_description: string
          p_reason: string
          p_setting_key: string
          p_setting_value: Json
        }
        Returns: {
          description: string | null
          setting_key: string
          setting_value: Json
          updated_at: string
          updated_by: string
        }
        SetofOptions: {
          from: "*"
          to: "system_settings"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      append_attempt_action: {
        Args: {
          p_action_type: string
          p_attempt_id: string
          p_client_occurred_at: string
          p_sequence_number: number
          p_target: string
          p_value: Json
        }
        Returns: {
          action_type: string
          attempt_id: string
          client_occurred_at: string
          id: string
          recorded_at: string
          sequence_number: number
          target: string | null
          value: Json
        }
        SetofOptions: {
          from: "*"
          to: "attempt_actions"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      approve_rubric_version: {
        Args: {
          p_passing_rule: Json
          p_reason: string
          p_rubric_version_id: string
          p_scoring_method: string
        }
        Returns: {
          activity_version_id: string
          approved_at: string | null
          approved_by: string | null
          created_at: string
          created_by: string
          id: string
          passing_rule: Json
          retired_at: string | null
          scoring_method: string
          status: Database["public"]["Enums"]["rubric_status"]
          tesda_source_id: string
          title: string
          updated_at: string
          version_number: number
        }
        SetofOptions: {
          from: "*"
          to: "rubric_versions"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      approve_tesda_source: {
        Args: { p_source_id: string; p_validation_notes: string }
        Returns: {
          activated_at: string | null
          activated_by: string | null
          approved_at: string | null
          approved_by: string | null
          created_at: string
          created_by: string
          document_storage_path: string | null
          edition: string | null
          effective_date: string | null
          id: string
          publication_date: string | null
          qualification_code: string
          source_reference: string
          status: Database["public"]["Enums"]["tesda_source_status"]
          title: string
          updated_at: string
          validation_notes: string | null
        }
        SetofOptions: {
          from: "*"
          to: "tesda_sources"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      archive_class: {
        Args: { p_class_id: string; p_reason: string }
        Returns: {
          archive_reason: string | null
          archived_at: string | null
          archived_by: string | null
          class_code: string | null
          created_at: string
          created_by: string
          id: string
          instructor_id: string
          status: Database["public"]["Enums"]["class_status"]
          title: string
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "classes"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      archive_instructor_quiz: {
        Args: { p_quiz_id: string; p_reason: string }
        Returns: {
          archive_reason: string | null
          archived_at: string | null
          archived_by: string | null
          coc_module_id: string | null
          created_at: string
          created_by: string
          description: string | null
          id: string
          instructor_id: string
          title: string
          topic: string
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "quizzes"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      assign_activity: {
        Args: {
          p_activity_version_id: string
          p_assignment_type: Database["public"]["Enums"]["assignment_type"]
          p_available_at?: string
          p_class_id: string
          p_due_at?: string
          p_instructions?: string
          p_rubric_version_id: string
          p_title: string
        }
        Returns: {
          activity_version_id: string
          assigned_by: string
          assignment_type: Database["public"]["Enums"]["assignment_type"]
          attempts_allowed: number | null
          available_at: string | null
          class_id: string
          close_reason: string | null
          closed_at: string | null
          created_at: string
          due_at: string | null
          id: string
          instructions: string | null
          prerequisite_assignment_id: string | null
          retry_after_seconds: number | null
          retry_enabled: boolean
          rubric_version_id: string | null
          status: Database["public"]["Enums"]["assignment_status"]
          title: string
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "assignments"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      begin_ai_quiz_generation: {
        Args: {
          p_input_context: Json
          p_model: string
          p_provider: string
          p_quiz_version_id: string
          p_requested_count: number
        }
        Returns: {
          completed_at: string | null
          failure_code: string | null
          generated_count: number
          id: string
          input_context: Json
          instructor_id: string
          model: string
          provider: string
          quiz_version_id: string
          requested_at: string
          requested_count: number
          status: Database["public"]["Enums"]["ai_generation_status"]
        }
        SetofOptions: {
          from: "*"
          to: "ai_quiz_generations"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      close_assignment: {
        Args: { p_assignment_id: string; p_reason: string }
        Returns: {
          activity_version_id: string
          assigned_by: string
          assignment_type: Database["public"]["Enums"]["assignment_type"]
          attempts_allowed: number | null
          available_at: string | null
          class_id: string
          close_reason: string | null
          closed_at: string | null
          created_at: string
          due_at: string | null
          id: string
          instructions: string | null
          prerequisite_assignment_id: string | null
          retry_after_seconds: number | null
          retry_enabled: boolean
          rubric_version_id: string | null
          status: Database["public"]["Enums"]["assignment_status"]
          title: string
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "assignments"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      complete_ai_quiz_generation: {
        Args: {
          p_actor_id: string
          p_generation_id: string
          p_items: Json
          p_model: string
          p_provider: string
        }
        Returns: number
      }
      configure_assignment_access: {
        Args: {
          p_assignment_id: string
          p_attempts_allowed?: number
          p_prerequisite_assignment_id?: string
          p_reason?: string
          p_retry_after_seconds?: number
          p_retry_enabled?: boolean
        }
        Returns: {
          activity_version_id: string
          assigned_by: string
          assignment_type: Database["public"]["Enums"]["assignment_type"]
          attempts_allowed: number | null
          available_at: string | null
          class_id: string
          close_reason: string | null
          closed_at: string | null
          created_at: string
          due_at: string | null
          id: string
          instructions: string | null
          prerequisite_assignment_id: string | null
          retry_after_seconds: number | null
          retry_enabled: boolean
          rubric_version_id: string | null
          status: Database["public"]["Enums"]["assignment_status"]
          title: string
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "assignments"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      create_class: {
        Args: { p_class_code?: string; p_title: string }
        Returns: {
          archive_reason: string | null
          archived_at: string | null
          archived_by: string | null
          class_code: string | null
          created_at: string
          created_by: string
          id: string
          instructor_id: string
          status: Database["public"]["Enums"]["class_status"]
          title: string
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "classes"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      create_instructor_quiz: {
        Args: {
          p_coc_module_id?: string
          p_description?: string
          p_instructions?: string
          p_title: string
          p_topic: string
        }
        Returns: {
          archive_reason: string | null
          archived_at: string | null
          archived_by: string | null
          coc_module_id: string | null
          created_at: string
          created_by: string
          description: string | null
          id: string
          instructor_id: string
          title: string
          topic: string
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "quizzes"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      create_learning_resource: {
        Args: {
          p_class_id: string
          p_description: string
          p_mime_type: string
          p_resource_id: string
          p_size_bytes: number
          p_storage_path: string
          p_title: string
        }
        Returns: {
          class_id: string
          created_at: string
          deleted_at: string | null
          deleted_by: string | null
          deletion_reason: string | null
          description: string | null
          id: string
          mime_type: string | null
          size_bytes: number | null
          status: Database["public"]["Enums"]["resource_status"]
          storage_bucket: string
          storage_path: string
          title: string
          uploaded_by: string
        }
        SetofOptions: {
          from: "*"
          to: "learning_resources"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      create_quiz_version: {
        Args: {
          p_change_summary?: string
          p_instructions?: string
          p_quiz_id: string
        }
        Returns: {
          change_summary: string | null
          created_at: string
          created_by: string
          id: string
          instructions: string | null
          published_at: string | null
          published_by: string | null
          quiz_id: string
          retired_at: string | null
          status: Database["public"]["Enums"]["content_version_status"]
          updated_at: string
          version_number: number
        }
        SetofOptions: {
          from: "*"
          to: "quiz_versions"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      current_app_role: {
        Args: never
        Returns: Database["public"]["Enums"]["user_role"]
      }
      deactivate_class_membership: {
        Args: { p_membership_id: string; p_reason: string }
        Returns: {
          class_id: string
          created_at: string
          deactivated_at: string | null
          deactivated_by: string | null
          deactivation_reason: string | null
          enrolled_at: string
          enrolled_by: string
          id: string
          learner_id: string
          status: Database["public"]["Enums"]["membership_status"]
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "class_memberships"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      delete_learning_resource: {
        Args: { p_reason: string; p_resource_id: string }
        Returns: {
          class_id: string
          created_at: string
          deleted_at: string | null
          deleted_by: string | null
          deletion_reason: string | null
          description: string | null
          id: string
          mime_type: string | null
          size_bytes: number | null
          status: Database["public"]["Enums"]["resource_status"]
          storage_bucket: string
          storage_path: string
          title: string
          uploaded_by: string
        }
        SetofOptions: {
          from: "*"
          to: "learning_resources"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      enroll_learner: {
        Args: { p_class_id: string; p_learner_id: string }
        Returns: {
          class_id: string
          created_at: string
          deactivated_at: string | null
          deactivated_by: string | null
          deactivation_reason: string | null
          enrolled_at: string
          enrolled_by: string
          id: string
          learner_id: string
          status: Database["public"]["Enums"]["membership_status"]
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "class_memberships"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      enroll_learner_by_email: {
        Args: { p_class_id: string; p_email: string }
        Returns: {
          class_id: string
          created_at: string
          deactivated_at: string | null
          deactivated_by: string | null
          deactivation_reason: string | null
          enrolled_at: string
          enrolled_by: string
          id: string
          learner_id: string
          status: Database["public"]["Enums"]["membership_status"]
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "class_memberships"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      evaluate_submitted_attempt: {
        Args: { p_attempt_id: string }
        Returns: {
          actor_id: string | null
          actor_role: Database["public"]["Enums"]["user_role"] | null
          attempt_id: string
          created_at: string
          criterion_values: Json
          evaluation_run_id: string | null
          id: string
          max_value: number | null
          outcome: Database["public"]["Enums"]["evaluation_outcome"]
          percentage: number | null
          reason: string | null
          remarks: string | null
          revision_number: number
          revision_type: Database["public"]["Enums"]["score_revision_type"]
          rubric_version_id: string
          supersedes_revision_id: string | null
          tesda_source_id: string
          total_value: number | null
        }
        SetofOptions: {
          from: "*"
          to: "score_revisions"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      fail_ai_quiz_generation: {
        Args: {
          p_actor_id: string
          p_failure_code: string
          p_generation_id: string
        }
        Returns: undefined
      }
      finalize_attempt: {
        Args: {
          p_attempt_id: string
          p_criterion_values: Json
          p_max_value: number
          p_outcome: Database["public"]["Enums"]["evaluation_outcome"]
          p_percentage: number
          p_reason?: string
          p_remarks?: string
          p_total_value: number
        }
        Returns: {
          actor_id: string | null
          actor_role: Database["public"]["Enums"]["user_role"] | null
          attempt_id: string
          created_at: string
          criterion_values: Json
          evaluation_run_id: string | null
          id: string
          max_value: number | null
          outcome: Database["public"]["Enums"]["evaluation_outcome"]
          percentage: number | null
          reason: string | null
          remarks: string | null
          revision_number: number
          revision_type: Database["public"]["Enums"]["score_revision_type"]
          rubric_version_id: string
          supersedes_revision_id: string | null
          tesda_source_id: string
          total_value: number | null
        }
        SetofOptions: {
          from: "*"
          to: "score_revisions"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      get_bypassed_activities: {
        Args: never
        Returns: {
          activity_title: string
          activity_version_id: string
          bypass_id: string
          class_id: string
          class_title: string
          granted_at: string
          instructions: string
          learner_payload: Json
          mission_code: string
          mission_id: string
          module_version_id: string
        }[]
      }
      get_level_from_xp: { Args: { p_xp: number }; Returns: number }
      get_rating: {
        Args: { p_score: number }
        Returns: Database["public"]["Enums"]["rating_type"]
      }
      grant_coc_bypass: {
        Args: {
          p_class_id: string
          p_learner_id: string
          p_module_version_id: string
          p_reason: string
          p_scope?: Json
        }
        Returns: {
          class_id: string
          created_at: string
          granted_at: string
          id: string
          instructor_id: string
          learner_id: string
          module_version_id: string
          reason: string
          revocation_reason: string | null
          revoked_at: string | null
          revoked_by: string | null
          scope: Json
        }
        SetofOptions: {
          from: "*"
          to: "coc_bypasses"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      instructor_deactivate_learner_account: {
        Args: { p_learner_id: string; p_reason: string }
        Returns: {
          avatar_url: string | null
          completed_missions: number
          course_section: string | null
          created_at: string
          current_level: number
          current_streak: number
          deactivated_at: string | null
          deactivated_by: string | null
          deactivation_reason: string | null
          email: string
          full_name: string
          id: string
          last_activity_at: string | null
          last_login_at: string | null
          learner_id: string | null
          role: Database["public"]["Enums"]["user_role"]
          school: string | null
          status: Database["public"]["Enums"]["account_status"]
          total_badges: number
          total_points: number
          total_xp: number
          updated_at: string
          user_id: string
        }
        SetofOptions: {
          from: "*"
          to: "profiles"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      instructor_owns_class: { Args: { p_class_id: string }; Returns: boolean }
      is_active_user: { Args: never; Returns: boolean }
      is_admin: { Args: never; Returns: boolean }
      is_instructor: { Args: never; Returns: boolean }
      is_learner: { Args: never; Returns: boolean }
      is_own_user: { Args: { target_user_id: string }; Returns: boolean }
      is_staff: { Args: never; Returns: boolean }
      learner_is_enrolled: {
        Args: { p_class_id: string; p_learner_id?: string }
        Returns: boolean
      }
      publish_activity_version: {
        Args: { p_activity_version_id: string; p_reason: string }
        Returns: {
          created_at: string
          created_by: string
          delivery_mode: Database["public"]["Enums"]["activity_delivery_mode"]
          evaluator_config: Json
          id: string
          instructions: string | null
          learner_payload: Json
          mission_id: string
          module_version_id: string
          published_at: string | null
          published_by: string | null
          retired_at: string | null
          status: Database["public"]["Enums"]["content_version_status"]
          title: string
          updated_at: string
          version_number: number
        }
        SetofOptions: {
          from: "*"
          to: "activity_versions"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      publish_module_version: {
        Args: { p_module_version_id: string; p_reason: string }
        Returns: {
          content_metadata: Json
          created_at: string
          created_by: string
          description: string | null
          id: string
          module_id: string
          published_at: string | null
          published_by: string | null
          retired_at: string | null
          source_trace: Json
          status: Database["public"]["Enums"]["content_version_status"]
          tesda_source_id: string
          title: string
          updated_at: string
          version_number: number
        }
        SetofOptions: {
          from: "*"
          to: "module_versions"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      publish_quiz_version: {
        Args: { p_quiz_version_id: string; p_reason: string }
        Returns: {
          change_summary: string | null
          created_at: string
          created_by: string
          id: string
          instructions: string | null
          published_at: string | null
          published_by: string | null
          quiz_id: string
          retired_at: string | null
          status: Database["public"]["Enums"]["content_version_status"]
          updated_at: string
          version_number: number
        }
        SetofOptions: {
          from: "*"
          to: "quiz_versions"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      record_provisional_evaluation: {
        Args: {
          p_attempt_id: string
          p_criterion_results: Json
          p_evaluation_run_id: string
          p_max_value: number
          p_outcome: Database["public"]["Enums"]["evaluation_outcome"]
          p_percentage: number
          p_remarks?: string
          p_total_value: number
        }
        Returns: {
          actor_id: string | null
          actor_role: Database["public"]["Enums"]["user_role"] | null
          attempt_id: string
          created_at: string
          criterion_values: Json
          evaluation_run_id: string | null
          id: string
          max_value: number | null
          outcome: Database["public"]["Enums"]["evaluation_outcome"]
          percentage: number | null
          reason: string | null
          remarks: string | null
          revision_number: number
          revision_type: Database["public"]["Enums"]["score_revision_type"]
          rubric_version_id: string
          supersedes_revision_id: string | null
          tesda_source_id: string
          total_value: number | null
        }
        SetofOptions: {
          from: "*"
          to: "score_revisions"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      register_tesda_source: {
        Args: {
          p_document_storage_path?: string
          p_edition: string
          p_effective_date: string
          p_publication_date: string
          p_qualification_code: string
          p_source_reference: string
          p_title: string
          p_validation_notes?: string
        }
        Returns: {
          activated_at: string | null
          activated_by: string | null
          approved_at: string | null
          approved_by: string | null
          created_at: string
          created_by: string
          document_storage_path: string | null
          edition: string | null
          effective_date: string | null
          id: string
          publication_date: string | null
          qualification_code: string
          source_reference: string
          status: Database["public"]["Enums"]["tesda_source_status"]
          title: string
          updated_at: string
          validation_notes: string | null
        }
        SetofOptions: {
          from: "*"
          to: "tesda_sources"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      release_attempt: {
        Args: { p_attempt_id: string; p_release_reason?: string }
        Returns: {
          attempt_id: string
          created_at: string
          id: string
          is_current: boolean
          release_number: number
          release_reason: string | null
          released_at: string
          released_by: string
          revocation_reason: string | null
          revoked_at: string | null
          revoked_by: string | null
          score_revision_id: string
        }
        SetofOptions: {
          from: "*"
          to: "result_releases"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      remove_quiz_item: {
        Args: { p_item_id: string; p_reason: string }
        Returns: {
          ai_generation_id: string | null
          correct_answer: Json
          created_at: string
          created_by: string
          explanation: string | null
          id: string
          item_code: string
          item_type: Database["public"]["Enums"]["quiz_item_type"]
          options: Json
          order_index: number
          origin: Database["public"]["Enums"]["quiz_item_origin"]
          prompt: string
          quiz_version_id: string
          removal_reason: string | null
          removed_at: string | null
          removed_by: string | null
          review_notes: string | null
          review_status: Database["public"]["Enums"]["quiz_item_review_status"]
          reviewed_at: string | null
          reviewed_by: string | null
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "quiz_items"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      review_quiz_item: {
        Args: {
          p_decision: Database["public"]["Enums"]["quiz_item_review_status"]
          p_item_id: string
          p_notes?: string
        }
        Returns: {
          ai_generation_id: string | null
          correct_answer: Json
          created_at: string
          created_by: string
          explanation: string | null
          id: string
          item_code: string
          item_type: Database["public"]["Enums"]["quiz_item_type"]
          options: Json
          order_index: number
          origin: Database["public"]["Enums"]["quiz_item_origin"]
          prompt: string
          quiz_version_id: string
          removal_reason: string | null
          removed_at: string | null
          removed_by: string | null
          review_notes: string | null
          review_status: Database["public"]["Enums"]["quiz_item_review_status"]
          reviewed_at: string | null
          reviewed_by: string | null
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "quiz_items"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      show_limit: { Args: never; Returns: number }
      show_trgm: { Args: { "": string }; Returns: string[] }
      start_attempt: {
        Args: { p_assignment_id: string; p_client_start_key: string }
        Returns: {
          activity_version_id: string
          assignment_id: string
          class_id: string
          client_start_key: string
          created_at: string
          elapsed_time_seconds: number | null
          evaluated_at: string | null
          finalized_at: string | null
          id: string
          learner_id: string
          legacy_mission_result_id: string | null
          released_at: string | null
          rubric_version_id: string | null
          started_at: string
          status: Database["public"]["Enums"]["attempt_status"]
          submission_key: string | null
          submitted_at: string | null
          tesda_source_id: string | null
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "attempts"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      submit_attempt: {
        Args: {
          p_attempt_id: string
          p_elapsed_time_seconds: number
          p_submission_key: string
        }
        Returns: {
          activity_version_id: string
          assignment_id: string
          class_id: string
          client_start_key: string
          created_at: string
          elapsed_time_seconds: number | null
          evaluated_at: string | null
          finalized_at: string | null
          id: string
          learner_id: string
          legacy_mission_result_id: string | null
          released_at: string | null
          rubric_version_id: string | null
          started_at: string
          status: Database["public"]["Enums"]["attempt_status"]
          submission_key: string | null
          submitted_at: string | null
          tesda_source_id: string | null
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "attempts"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      update_instructor_quiz: {
        Args: {
          p_coc_module_id?: string
          p_description?: string
          p_quiz_id: string
          p_title: string
          p_topic: string
        }
        Returns: {
          archive_reason: string | null
          archived_at: string | null
          archived_by: string | null
          coc_module_id: string | null
          created_at: string
          created_by: string
          description: string | null
          id: string
          instructor_id: string
          title: string
          topic: string
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "quizzes"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      upsert_quiz_item: {
        Args: {
          p_correct_answer: Json
          p_explanation?: string
          p_item_id?: string
          p_item_type: Database["public"]["Enums"]["quiz_item_type"]
          p_options: Json
          p_order_index?: number
          p_prompt: string
          p_quiz_version_id: string
        }
        Returns: {
          ai_generation_id: string | null
          correct_answer: Json
          created_at: string
          created_by: string
          explanation: string | null
          id: string
          item_code: string
          item_type: Database["public"]["Enums"]["quiz_item_type"]
          options: Json
          order_index: number
          origin: Database["public"]["Enums"]["quiz_item_origin"]
          prompt: string
          quiz_version_id: string
          removal_reason: string | null
          removed_at: string | null
          removed_by: string | null
          review_notes: string | null
          review_status: Database["public"]["Enums"]["quiz_item_review_status"]
          reviewed_at: string | null
          reviewed_by: string | null
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "quiz_items"
          isOneToOne: true
          isSetofReturn: false
        }
      }
    }
    Enums: {
      account_status:
        | "active"
        | "inactive"
        | "suspended"
        | "pending"
        | "deactivated"
      activity_delivery_mode: "practice" | "assessment" | "both"
      ai_generation_status: "requested" | "completed" | "failed"
      assignment_status: "active" | "closed"
      assignment_type: "practice" | "assessment"
      attempt_status:
        | "in_progress"
        | "submitted"
        | "evaluated"
        | "under_review"
        | "finalized"
        | "released"
      class_status: "active" | "archived"
      competency_status: "competent" | "not_yet_competent"
      condition_type:
        | "mission_count"
        | "coc_completion"
        | "streak"
        | "score_threshold"
        | "time_based"
        | "perfect_score"
        | "no_mistake"
        | "special"
      content_version_status: "draft" | "published" | "retired"
      criterion_observation:
        | "satisfied"
        | "not_satisfied"
        | "not_evaluated"
        | "requires_review"
      difficulty_level: "beginner" | "intermediate" | "advanced"
      evaluation_outcome:
        | "pending_tesda_validation"
        | "competent"
        | "not_yet_competent"
      leaderboard_type: "overall" | "coc" | "mission" | "weekly" | "monthly"
      membership_status: "active" | "deactivated"
      mission_status: "draft" | "published" | "archived"
      mission_type:
        | "identification"
        | "drag_and_drop"
        | "configuration_form"
        | "step_procedure"
        | "troubleshooting"
        | "checklist"
        | "matching"
      notification_type:
        | "mission"
        | "badge"
        | "achievement"
        | "progress"
        | "system"
        | "admin_message"
      progress_status:
        | "locked"
        | "not_started"
        | "in_progress"
        | "completed"
        | "failed"
      quiz_item_origin: "instructor_authored" | "ai_generated_draft"
      quiz_item_review_status: "draft" | "approved" | "rejected"
      quiz_attempt_status: "in_progress" | "submitted" | "completed"
      quiz_item_type:
        | "multiple_choice"
        | "true_false"
        | "identification"
        | "scenario_based"
      rating_type:
        | "excellent"
        | "very_good"
        | "good"
        | "needs_improvement"
        | "poor"
      report_type:
        | "individual_learner"
        | "class_summary"
        | "coc_performance"
        | "mission_result"
        | "competency_achievement"
        | "progress_report"
        | "pass_fail_summary"
        | "analytics_dashboard"
      resource_status: "active" | "deleted"
      rubric_status:
        | "pending_tesda_validation"
        | "draft"
        | "approved"
        | "retired"
      score_revision_type:
        | "automated_provisional"
        | "instructor_adjustment"
        | "instructor_final"
      task_type:
        | "select_image"
        | "drag_drop"
        | "arrange_sequence"
        | "form_input"
        | "matching"
        | "checklist"
        | "decision_tree"
      tesda_source_status:
        | "pending_tesda_validation"
        | "approved"
        | "active"
        | "superseded"
        | "archived"
      user_role: "learner" | "legacy_instructor_admin" | "admin" | "instructor"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      account_status: [
        "active",
        "inactive",
        "suspended",
        "pending",
        "deactivated",
      ],
      activity_delivery_mode: ["practice", "assessment", "both"],
      ai_generation_status: ["requested", "completed", "failed"],
      assignment_status: ["active", "closed"],
      assignment_type: ["practice", "assessment"],
      attempt_status: [
        "in_progress",
        "submitted",
        "evaluated",
        "under_review",
        "finalized",
        "released",
      ],
      class_status: ["active", "archived"],
      competency_status: ["competent", "not_yet_competent"],
      condition_type: [
        "mission_count",
        "coc_completion",
        "streak",
        "score_threshold",
        "time_based",
        "perfect_score",
        "no_mistake",
        "special",
      ],
      content_version_status: ["draft", "published", "retired"],
      criterion_observation: [
        "satisfied",
        "not_satisfied",
        "not_evaluated",
        "requires_review",
      ],
      difficulty_level: ["beginner", "intermediate", "advanced"],
      evaluation_outcome: [
        "pending_tesda_validation",
        "competent",
        "not_yet_competent",
      ],
      leaderboard_type: ["overall", "coc", "mission", "weekly", "monthly"],
      membership_status: ["active", "deactivated"],
      mission_status: ["draft", "published", "archived"],
      mission_type: [
        "identification",
        "drag_and_drop",
        "configuration_form",
        "step_procedure",
        "troubleshooting",
        "checklist",
        "matching",
      ],
      notification_type: [
        "mission",
        "badge",
        "achievement",
        "progress",
        "system",
        "admin_message",
      ],
      progress_status: [
        "locked",
        "not_started",
        "in_progress",
        "completed",
        "failed",
      ],
      quiz_item_origin: ["instructor_authored", "ai_generated_draft"],
      quiz_item_review_status: ["draft", "approved", "rejected"],
      quiz_attempt_status: ["in_progress", "submitted", "completed"],
      quiz_item_type: [
        "multiple_choice",
        "true_false",
        "identification",
        "scenario_based",
      ],
      rating_type: [
        "excellent",
        "very_good",
        "good",
        "needs_improvement",
        "poor",
      ],
      report_type: [
        "individual_learner",
        "class_summary",
        "coc_performance",
        "mission_result",
        "competency_achievement",
        "progress_report",
        "pass_fail_summary",
        "analytics_dashboard",
      ],
      resource_status: ["active", "deleted"],
      rubric_status: [
        "pending_tesda_validation",
        "draft",
        "approved",
        "retired",
      ],
      score_revision_type: [
        "automated_provisional",
        "instructor_adjustment",
        "instructor_final",
      ],
      task_type: [
        "select_image",
        "drag_drop",
        "arrange_sequence",
        "form_input",
        "matching",
        "checklist",
        "decision_tree",
      ],
      tesda_source_status: [
        "pending_tesda_validation",
        "approved",
        "active",
        "superseded",
        "archived",
      ],
      user_role: ["learner", "legacy_instructor_admin", "admin", "instructor"],
    },
  },
} as const
