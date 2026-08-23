import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/simulation/runtime/mission_runtime_models.dart';

abstract interface class MissionRuntimeStore {
  Future<bool> saveMissionRuntime({
    required String userId,
    required MissionRuntimeState state,
  });

  Future<MissionRuntimeState?> loadMissionRuntime({
    required String userId,
    required String missionId,
    required MissionRuntimeMode mode,
    String? assessmentAttemptId,
  });

  Future<bool> clearMissionRuntime({
    required String userId,
    required String missionId,
    required MissionRuntimeMode mode,
    String? assessmentAttemptId,
  });
}

final class SharedPreferencesMissionRuntimeStore
    implements MissionRuntimeStore {
  const SharedPreferencesMissionRuntimeStore();

  @override
  Future<bool> saveMissionRuntime({
    required String userId,
    required MissionRuntimeState state,
  }) {
    return ProgressResumeService.saveMissionRuntime(
      userId: userId,
      state: state,
    );
  }

  @override
  Future<MissionRuntimeState?> loadMissionRuntime({
    required String userId,
    required String missionId,
    required MissionRuntimeMode mode,
    String? assessmentAttemptId,
  }) {
    return ProgressResumeService.loadMissionRuntime(
      userId: userId,
      missionId: missionId,
      mode: mode,
      assessmentAttemptId: assessmentAttemptId,
    );
  }

  @override
  Future<bool> clearMissionRuntime({
    required String userId,
    required String missionId,
    required MissionRuntimeMode mode,
    String? assessmentAttemptId,
  }) {
    return ProgressResumeService.clearMissionRuntime(
      userId: userId,
      missionId: missionId,
      mode: mode,
      assessmentAttemptId: assessmentAttemptId,
    );
  }
}

/// Local-only resume cache. It is convenience state, never an authoritative
/// score, competency decision, class progress record, or reward projection.
class ProgressResumeService {
  static const String _prefix = 'bq_resume_';
  static const String _missionRuntimePrefix = 'bq_mission_runtime_';

  static Future<bool> saveMissionRuntime({
    required String userId,
    required MissionRuntimeState state,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(
        _missionRuntimeKey(
          userId: userId,
          missionId: state.missionId,
          mode: state.mode,
          assessmentAttemptId: state.assessmentAttemptId,
        ),
        jsonEncode(state.toJson()),
      );
    } catch (error) {
      debugPrint('Mission runtime resume save failed: $error');
      return false;
    }
  }

  static Future<MissionRuntimeState?> loadMissionRuntime({
    required String userId,
    required String missionId,
    required MissionRuntimeMode mode,
    String? assessmentAttemptId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_missionRuntimeKey(
        userId: userId,
        missionId: missionId,
        mode: mode,
        assessmentAttemptId: assessmentAttemptId,
      ));
      if (value == null) return null;
      final snapshot = Map<String, dynamic>.from(jsonDecode(value) as Map);
      if (snapshot['schemaVersion'] != MissionRuntimeState.schemaVersion) {
        return null;
      }
      if (snapshot['missionId'] != missionId) return null;
      if (snapshot['mode'] != mode.name) return null;
      if (snapshot['assessmentAttemptId'] != assessmentAttemptId) return null;
      return MissionRuntimeState.fromJson(snapshot);
    } catch (error, stackTrace) {
      debugPrint(
        '[ByteQuest restore] local snapshot load failed: '
        'missionId=$missionId expectedRuntimeStateVersion='
        '${MissionRuntimeState.schemaVersion} error=$error',
      );
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  static Future<bool> clearMissionRuntime({
    required String userId,
    required String missionId,
    required MissionRuntimeMode mode,
    String? assessmentAttemptId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_missionRuntimeKey(
        userId: userId,
        missionId: missionId,
        mode: mode,
        assessmentAttemptId: assessmentAttemptId,
      ));
    } catch (error) {
      debugPrint('Mission runtime resume clear failed: $error');
      return false;
    }
  }

  static String _missionRuntimeKey({
    required String userId,
    required String missionId,
    required MissionRuntimeMode mode,
    String? assessmentAttemptId,
  }) {
    final attemptId = assessmentAttemptId;
    if (mode == MissionRuntimeMode.assessment &&
        (attemptId == null || attemptId.trim().isEmpty)) {
      throw ArgumentError.value(
        attemptId,
        'assessmentAttemptId',
        'is required for an assessment runtime',
      );
    }
    if (mode == MissionRuntimeMode.practice && attemptId != null) {
      throw ArgumentError.value(
        attemptId,
        'assessmentAttemptId',
        'must be null for a practice runtime',
      );
    }
    final scope = mode == MissionRuntimeMode.practice
        ? 'practice'
        : 'assessment_${Uri.encodeComponent(attemptId!)}';
    return '$_missionRuntimePrefix${userId}_${missionId}_$scope';
  }

  static Future<bool> saveState({
    required String userId,
    required String missionId,
    required String cocId,
    required int currentStep,
    required int totalSteps,
    required Map<String, dynamic> stateData,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_prefix${userId}_$missionId';
      await prefs.setString(
          key,
          jsonEncode({
            'userId': userId,
            'missionId': missionId,
            'cocId': cocId,
            'currentStep': currentStep,
            'totalSteps': totalSteps,
            'stateData': stateData,
            'updatedAt': DateTime.now().toIso8601String(),
          }));
      return true;
    } catch (error) {
      debugPrint('Local resume save failed: $error');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> loadState(
      {required String userId, required String missionId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString('$_prefix${userId}_$missionId');
      return value == null
          ? null
          : Map<String, dynamic>.from(jsonDecode(value) as Map);
    } catch (error) {
      debugPrint('Local resume load failed: $error');
      return null;
    }
  }

  static Future<bool> clearState(
      {required String userId, required String missionId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove('$_prefix${userId}_$missionId');
    } catch (error) {
      debugPrint('Local resume clear failed: $error');
      return false;
    }
  }
}
