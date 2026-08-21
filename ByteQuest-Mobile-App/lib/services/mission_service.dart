import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mission_model.dart';
import '../data/missions_data.dart';
import '../core/config/supabase_config.dart';
import 'mission_database_service.dart';

/// Mission Service for managing mission state and progress
class MissionService extends ChangeNotifier {
  List<String> _completedMissions = [];
  Map<String, MissionResult> _missionResults = {};
  String? _currentActiveMission;

  List<String> get completedMissions => _completedMissions;
  Map<String, MissionResult> get missionResults => _missionResults;
  String? get currentActiveMission => _currentActiveMission;

  MissionService() {
    _loadProgress();
  }

  /// Sync user progress from Supabase database
  Future<void> loadFromDatabase(String userId) async {
    try {
      // 1. Fetch database missions to map UUIDs to local IDs
      final dbMissions = await MissionDatabaseService().getAllMissions();
      final uuidToLocalId = {
        for (var m in dbMissions)
          m.id: m.missionCode.toLowerCase().replaceAll('-', '_')
      };

      final response = await SupabaseConfig.client
          .from('learner_progress')
          .select('mission_id, status, best_score')
          .eq('user_id', userId);

      final progressList = List<Map<String, dynamic>>.from(response);

      _completedMissions = [];
      _missionResults = {};
      _currentActiveMission = null;

      // Map progressList database UUIDs to local IDs
      final resolvedProgressList = progressList.map((progress) {
        final dbUuid = progress['mission_id'] as String;
        final localId =
            uuidToLocalId[dbUuid] ?? dbUuid; // Fallback to uuid if not found
        return {
          ...progress,
          'mission_id': localId,
        };
      }).toList();

      // Identify completed missions using local IDs
      for (var progress in resolvedProgressList) {
        final missionId = progress['mission_id'] as String;
        final status = progress['status'] as String;
        final bestScore = progress['best_score'] as int? ?? 0;

        if (status == 'completed') {
          _completedMissions.add(missionId);
          _missionResults[missionId] = MissionResult(
            missionId: missionId,
            score: bestScore,
            percentage: bestScore,
            passed: true,
            xpEarned: 0,
            timeSpent: 0,
            rating: '',
            competencyStatus: '',
          );
        }
      }

      // Identify the current active mission (first unlocked and in-progress or not-started) using local IDs
      // Check in-progress first
      for (var progress in resolvedProgressList) {
        final missionId = progress['mission_id'] as String;
        final status = progress['status'] as String;
        if (status == 'in_progress') {
          _currentActiveMission = missionId;
          break;
        }
      }

      // If no in-progress mission, find the first not-started mission that is unlocked using local IDs
      if (_currentActiveMission == null) {
        final allMissions = MissionsData.getAllMissions();
        for (var mission in allMissions) {
          final progress = resolvedProgressList.firstWhere(
            (p) => p['mission_id'] == mission.id,
            orElse: () => {},
          );
          if (progress.isNotEmpty) {
            final status = progress['status'] as String;
            if (status == 'not_started') {
              _currentActiveMission = mission.id;
              break;
            }
          }
        }
      }

      // Fallback to first mission if nothing else works
      _currentActiveMission ??= 'coc1_m1';

      debugPrint(
          '🔄 MissionService sync with Supabase: completed=${_completedMissions.length}, active=$_currentActiveMission');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading progress from database: $e');
    }
  }

  /// Load progress from local storage
  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _completedMissions = prefs.getStringList('completed_missions') ?? [];
      _currentActiveMission =
          prefs.getString('current_active_mission') ?? 'coc1_m1';
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading mission progress: $e');
    }
  }

  /// Save progress to local storage
  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('completed_missions', _completedMissions);
      if (_currentActiveMission != null) {
        await prefs.setString('current_active_mission', _currentActiveMission!);
      }
    } catch (e) {
      debugPrint('Error saving mission progress: $e');
    }
  }

  /// Get all missions with updated unlock status
  List<Mission> getAllMissions() {
    final missions = MissionsData.getAllMissions();
    return missions.map((mission) {
      return mission.copyWith(
        isUnlocked: isMissionUnlocked(mission.id),
        isCompleted: _completedMissions.contains(mission.id),
        highScore: _missionResults[mission.id]?.score,
      );
    }).toList();
  }

  /// Get missions by COC ID
  List<Mission> getMissionsByCOC(String cocId) {
    return getAllMissions().where((m) => m.cocId == cocId).toList();
  }

  /// Get single mission by ID
  Mission? getMissionById(String missionId) {
    try {
      return getAllMissions().firstWhere((m) => m.id == missionId);
    } catch (e) {
      return null;
    }
  }

  /// Check if mission is unlocked
  bool isMissionUnlocked(String missionId) {
    final mission = MissionsData.getMissionById(missionId);
    if (mission == null) return false;
    // The retained catalog is practice-only. Authoritative access is granted
    // by assignments or an audited COC bypass, never by a client threshold.
    return true;
  }

  /// Complete a mission
  Future<void> completeMission(MissionResult result) async {
    if (result.passed && !_completedMissions.contains(result.missionId)) {
      _completedMissions.add(result.missionId);
      _missionResults[result.missionId] = result;

      // Unlock next mission
      _unlockNextMission(result.missionId);

      await _saveProgress();
      notifyListeners();
    } else if (!result.passed) {
      // Store failed attempt result
      _missionResults[result.missionId] = result;
      notifyListeners();
    }
  }

  /// Unlock next mission
  void _unlockNextMission(String completedMissionId) {
    final completedMission = MissionsData.getMissionById(completedMissionId);
    if (completedMission == null) return;

    final missions = MissionsData.getMissionsByCOC(completedMission.cocId);

    // Find next mission in same COC
    try {
      final nextMission =
          missions.firstWhere((m) => m.order == completedMission.order + 1);
      _currentActiveMission = nextMission.id;
    } catch (e) {
      // No next mission in this COC, try next COC
      final nextCOCId = _getNextCOCId(completedMission.cocId);
      if (nextCOCId != null) {
        final nextCOCMissions = MissionsData.getMissionsByCOC(nextCOCId);
        if (nextCOCMissions.isNotEmpty &&
            isMissionUnlocked(nextCOCMissions.first.id)) {
          _currentActiveMission = nextCOCMissions.first.id;
        }
      }
    }
  }

  /// Get next COC ID
  String? _getNextCOCId(String cocId) {
    switch (cocId) {
      case 'coc1':
        return 'coc2';
      case 'coc2':
        return 'coc3';
      case 'coc3':
        return 'coc4';
      default:
        return null;
    }
  }

  /// Get progress statistics
  Map<String, dynamic> getProgressStats() {
    final allMissions = MissionsData.getAllMissions();
    final totalMissions = allMissions.length;
    final completedCount = _completedMissions.length;
    final percentage = (completedCount / totalMissions * 100).toInt();

    return {
      'total': totalMissions,
      'completed': completedCount,
      'percentage': percentage,
      'coc1': _getCOCStats('coc1'),
      'coc2': _getCOCStats('coc2'),
      'coc3': _getCOCStats('coc3'),
      'coc4': _getCOCStats('coc4'),
    };
  }

  /// Get COC-specific statistics
  Map<String, dynamic> _getCOCStats(String cocId) {
    final missions = MissionsData.getMissionsByCOC(cocId);
    final completed =
        missions.where((m) => _completedMissions.contains(m.id)).length;
    final percentage =
        missions.isEmpty ? 0 : (completed / missions.length * 100).toInt();

    return {
      'total': missions.length,
      'completed': completed,
      'percentage': percentage,
    };
  }

  /// Get total XP earned
  int getTotalXPEarned() {
    return 0;
  }

  /// Get mission result
  MissionResult? getMissionResult(String missionId) {
    return _missionResults[missionId];
  }

  /// Set current active mission
  void setActiveMission(String missionId) {
    _currentActiveMission = missionId;
    _saveProgress();
    notifyListeners();
  }

  /// Reset all progress (for testing)
  Future<void> resetProgress() async {
    _completedMissions.clear();
    _missionResults.clear();
    _currentActiveMission = 'coc1_m1';
    await _saveProgress();
    notifyListeners();
  }
}
