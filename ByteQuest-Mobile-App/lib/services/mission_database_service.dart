import 'package:flutter/foundation.dart';
import '../core/config/supabase_config.dart';
import '../models/mission_model.dart';
import '../models/coc_model.dart';
import '../models/learner_learning_path_model.dart';

/// Mission Database Service
/// Loads COC modules and missions from Supabase database
class MissionDatabaseService {
  final _supabase = SupabaseConfig.client;

  /// Get all COC modules from database
  Future<List<CocModule>> getAllCocModules() async {
    final response = await _supabase
        .from('coc_modules')
        .select()
        .eq('status', 'published')
        .order('order_index', ascending: true);

    return (response as List).map((json) => CocModule.fromJson(json)).toList();
  }

  /// Returns lifecycle state produced by the trusted database projection.
  /// The client groups already-authorized mission rows; it does not infer an
  /// unlock threshold, competency score, or result authority.
  Future<List<LearnerCocProjection>> getLearnerLearningPath() async {
    final response = await _supabase.rpc('get_learner_learning_path');
    final rows = (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      grouped.putIfAbsent(row['coc_id'] as String, () => []).add(row);
    }
    final result = grouped.values.map((cocRows) {
      final first = cocRows.first;
      return LearnerCocProjection(
        id: first['coc_id'] as String,
        code: (first['coc_code'] as String? ?? '').toLowerCase(),
        title: first['coc_title'] as String? ?? 'COC',
        description: first['coc_description'] as String? ?? '',
        order: first['coc_order'] as int? ?? 0,
        missions: cocRows
            .map(LearnerMissionProjection.fromJson)
            .toList(growable: false),
      );
    }).toList(growable: false)
      ..sort((left, right) => left.order.compareTo(right.order));
    return result;
  }

  /// Get single COC module by code
  Future<CocModule?> getCocByCode(String cocCode) async {
    try {
      final response = await _supabase
          .from('coc_modules')
          .select()
          .eq('coc_code', cocCode)
          .eq('status', 'published')
          .maybeSingle();

      if (response == null) return null;
      return CocModule.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error fetching COC module: $e');
      return null;
    }
  }

  /// Get all missions from database
  Future<List<Mission>> getAllMissions() async {
    try {
      final response = await _supabase
          .from('missions')
          .select('*, coc_modules!inner(*)')
          .eq('status', 'published')
          .order('order_index', ascending: true);

      return (response as List).map((json) => Mission.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error fetching missions: $e');
      return [];
    }
  }

  /// Get missions by COC ID
  Future<List<Mission>> getMissionsByCocId(String cocId) async {
    try {
      final response = await _supabase
          .from('missions')
          .select()
          .eq('coc_id', cocId)
          .eq('status', 'published')
          .order('order_index', ascending: true);

      return (response as List).map((json) => Mission.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error fetching missions by COC: $e');
      return [];
    }
  }

  /// Get missions by COC code
  Future<List<Mission>> getMissionsByCocCode(String cocCode) async {
    try {
      // First get COC module
      final coc = await getCocByCode(cocCode);
      if (coc == null) {
        debugPrint('⚠️ COC not found: $cocCode');
        return [];
      }

      return await getMissionsByCocId(coc.id);
    } catch (e) {
      debugPrint('❌ Error fetching missions by COC code: $e');
      return [];
    }
  }

  /// Get single mission by ID
  Future<Mission?> getMissionById(String missionId) async {
    try {
      final response = await _supabase
          .from('missions')
          .select()
          .eq('id', missionId)
          .eq('status', 'published')
          .maybeSingle();

      if (response == null) return null;
      return Mission.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error fetching mission: $e');
      return null;
    }
  }

  /// Get single mission by code
  Future<Mission?> getMissionByCode(String missionCode) async {
    try {
      final response = await _supabase
          .from('missions')
          .select()
          .eq('mission_code', missionCode)
          .eq('status', 'published')
          .maybeSingle();

      if (response == null) return null;
      return Mission.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error fetching mission by code: $e');
      return null;
    }
  }

  /// Get simulation tasks for a mission
  Future<List<Map<String, dynamic>>> getMissionTasks(String missionId) async {
    try {
      final response = await _supabase
          .from('simulation_tasks')
          .select()
          .eq('mission_id', missionId)
          .order('order_index', ascending: true);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ Error fetching mission tasks: $e');
      return [];
    }
  }

  /// Check mission unlock status based on learner progress
  Future<bool> isMissionUnlocked({
    required String userId,
    required String missionId,
  }) async {
    try {
      // Get mission's learner progress
      final response = await _supabase
          .from('learner_progress')
          .select('status')
          .eq('user_id', userId)
          .eq('mission_id', missionId)
          .maybeSingle();

      if (response == null) {
        // No progress record means mission is locked
        return false;
      }

      final status = response['status'] as String;
      // Mission is unlocked if status is NOT 'locked'
      return status != 'locked';
    } catch (e) {
      debugPrint('❌ Error checking mission unlock status: $e');
      return false;
    }
  }

  /// Get missions with their unlock status for a user
  Future<List<Mission>> getMissionsWithUnlockStatus({
    required String userId,
    String? cocCode,
  }) async {
    try {
      // Get missions
      final missions = cocCode != null
          ? await getMissionsByCocCode(cocCode)
          : await getAllMissions();

      // Get learner progress for all missions
      final progressResponse = await _supabase
          .from('learner_progress')
          .select('mission_id, status, best_score, completion_percentage')
          .eq('user_id', userId);

      final progressMap = <String, Map<String, dynamic>>{};
      for (var progress in progressResponse as List) {
        progressMap[progress['mission_id'] as String] = progress;
      }

      // Update missions with unlock status
      return missions.map((mission) {
        final progress = progressMap[mission.id];
        final isUnlocked = progress != null && progress['status'] != 'locked';
        final isCompleted =
            progress != null && progress['status'] == 'completed';
        final bestScore = progress?['best_score'] as int?;

        return mission.copyWith(
          isUnlocked: isUnlocked,
          isCompleted: isCompleted,
          highScore: bestScore,
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Error fetching missions with unlock status: $e');
      return [];
    }
  }

  /// Get COC completion statistics for a user
  Future<Map<String, dynamic>> getCocCompletionStats({
    required String userId,
    required String cocId,
  }) async {
    try {
      // Get all missions for this COC
      final missions = await getMissionsByCocId(cocId);
      final totalMissions = missions.length;

      // Get completed missions count
      final progressResponse = await _supabase
          .from('learner_progress')
          .select('status')
          .eq('user_id', userId)
          .eq('coc_id', cocId)
          .eq('status', 'completed');

      final completedCount = (progressResponse as List).length;
      final percentage = totalMissions > 0
          ? ((completedCount / totalMissions) * 100).round()
          : 0;

      return {
        'coc_id': cocId,
        'total_missions': totalMissions,
        'completed_missions': completedCount,
        'completion_percentage': percentage,
      };
    } catch (e) {
      debugPrint('❌ Error calculating COC completion stats: $e');
      return {
        'coc_id': cocId,
        'total_missions': 0,
        'completed_missions': 0,
        'completion_percentage': 0,
      };
    }
  }
}
