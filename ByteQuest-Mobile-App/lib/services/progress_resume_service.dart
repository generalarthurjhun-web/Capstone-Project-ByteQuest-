import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only resume cache. It is convenience state, never an authoritative
/// score, competency decision, class progress record, or reward projection.
class ProgressResumeService {
  static const String _prefix = 'bq_resume_';

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
      return prefs.remove('$_prefix${userId}_$missionId');
    } catch (error) {
      debugPrint('Local resume clear failed: $error');
      return false;
    }
  }
}
