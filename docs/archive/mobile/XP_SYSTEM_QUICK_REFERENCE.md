# XP System - Quick Reference Guide

## 🎮 How to Award XP (For Developers)

### **Automatic XP Award (Current Implementation)**
XP is automatically awarded when a mission is completed through the result screen.

**No manual code needed!** Just ensure:
1. Mission has `xpReward` defined in the model
2. Result screen is shown after mission completion
3. User is logged in

---

## 📊 XP and Level Formulas

### **Level from XP (Fallback Formula)**
```dart
level = floor(sqrt(totalXP / 100)) + 1
```

### **XP Required for Level**
```dart
minXP = (level - 1)² × 100
```

### **Level Requirements Table**
| Level | Min XP | Max XP | XP Range |
|-------|--------|--------|----------|
| 1     | 0      | 99     | 100      |
| 2     | 100    | 399    | 300      |
| 3     | 400    | 899    | 500      |
| 4     | 900    | 1599   | 700      |
| 5     | 1600   | 2499   | 900      |
| 6     | 2500   | 3599   | 1100     |
| 7     | 3600   | 4899   | 1300     |
| 8     | 4900   | 6399   | 1500     |
| 9     | 6400   | 8099   | 1700     |
| 10    | 8100   | 9999   | 1900     |

---

## 🔧 Key Services

### **1. MissionCompletionService**
**Purpose:** Orchestrates mission completion
**Main Method:** `completeMission()`
**What it does:**
- Saves mission result
- Awards XP and points
- Updates progress
- Checks for badges/achievements
- Updates leaderboard

### **2. ProfileService**
**Purpose:** Manages user profiles
**Key Methods:**
- `getProfileByUserId(userId)` - Get profile
- `recalculateAndSyncProfile(userId)` - Recalculate XP from mission results
- `updateProfile(userId, updates)` - Update profile fields

### **3. GamificationService**
**Purpose:** Handles XP, levels, badges
**Key Methods:**
- `awardXP(userId, xpAmount)` - Award XP (usually called internally)
- `getLevelFromDb(totalXp)` - Calculate level from XP
- `getXPProgress(totalXp)` - Get XP progress to next level
- `checkAndAwardBadges(userId)` - Check and award badges

### **4. ResultService**
**Purpose:** Saves mission results
**Key Methods:**
- `saveMissionResult(...)` - Save result to database
- `getUserMissionResults(userId)` - Get all results
- `getBestMissionResult(userId, missionId)` - Get best attempt

---

## 🎯 Mission XP Rewards (Default)

**Standard Mission Rewards:**
- COC 1 Missions: 100 XP each
- COC 2 Missions: 100 XP each
- COC 3 Missions: 100 XP each
- COC 4 Missions: 100 XP each

**Defined in:**
- Mission models have `xpReward` property
- Database `missions` table has `xp_reward` column

**To change rewards:**
1. Update mission model when creating mission
2. Or update database directly in Supabase

---

## 🔒 Duplicate XP Prevention

**Method 1: Database-level**
- `recalculateAndSyncProfile()` groups by unique `mission_id`
- Only counts each mission once
- Takes MAX XP if mission retried

**Method 2: Service-level**
- `MissionCompletionService` checks `learner_progress.status`
- If `status == 'completed'`, doesn't award new XP
- Only updates best score

**Result:**
- First completion: Awards full XP
- Retry attempts: Updates score, NO additional XP

---

## 📱 Where XP is Displayed

### **Dashboard Screen**
```dart
_profile?.totalXp ?? 0  // Current total XP
_profile?.currentLevel ?? 1  // Current level
```

### **Progress Screen**
```dart
_profile.totalXp  // Total XP
_profile.currentLevel  // Level
GamificationService().getXPProgress(totalXp)  // Progress to next level
```

### **Profile Screen**
```dart
profile?.totalXp ?? 0  // Total XP
profile?.currentLevel ?? 1  // Level
```

### **Leaderboard Screen**
```dart
entry.xp  // User's XP from leaderboard entry
entry.rankingPoints  // Calculated: (xp * 10) + (missions * 100)
```

---

## 🐛 Debugging XP Issues

### **Check 1: Is mission completing?**
```dart
debugPrint('✅ Mission result saved: $missionId');
```
Look for this in console after completing mission.

### **Check 2: Is XP being calculated?**
```dart
debugPrint('   XP Earned: ${completionResult['xp_earned']}');
debugPrint('   Total XP: ${completionResult['total_xp']}');
```

### **Check 3: Is profile updating?**
```dart
debugPrint('🔄 Profile synced: XP=$totalXp, Level=$newLevel');
```

### **Check 4: Check database directly**
In Supabase dashboard:
```sql
-- Check mission results
SELECT * FROM mission_results WHERE user_id = 'USER_ID_HERE' ORDER BY completed_at DESC;

-- Check profile
SELECT total_xp, current_level, completed_missions FROM profiles WHERE user_id = 'USER_ID_HERE';

-- Check leaderboard
SELECT * FROM leaderboard_entries WHERE user_id = 'USER_ID_HERE';
```

---

## 🛠️ Common Tasks

### **Task: Get user's current XP and level**
```dart
final userId = SupabaseConfig.currentUserId;
if (userId != null) {
  final profile = await ProfileService().getProfileByUserId(userId);
  final xp = profile?.totalXp ?? 0;
  final level = profile?.currentLevel ?? 1;
}
```

### **Task: Manually recalculate XP from scratch**
```dart
final syncResult = await ProfileService().recalculateAndSyncProfile(userId);
// This will:
// 1. Query all passed mission results
// 2. Sum unique mission XP
// 3. Calculate level
// 4. Update profile
```

### **Task: Check XP progress to next level**
```dart
final xpProgress = GamificationService().getXPProgress(totalXp);
final currentXp = xpProgress['current_xp'];  // XP in current level
final xpNeeded = xpProgress['xp_needed'];  // Total needed for next level
final xpToNext = xpProgress['xp_to_next_level'];  // Remaining XP needed
final progressPct = xpProgress['progress_percentage'];  // 0-100
```

### **Task: Get all missions completed by user**
```dart
final results = await ResultService().getUserMissionResults(userId);
final uniqueMissions = results
    .where((r) => r.passed)
    .map((r) => r.missionId)
    .toSet()
    .length;
```

---

## ⚡ Performance Tips

1. **Cache profile data in StatefulWidget state**
   - Don't fetch profile on every build
   - Use `setState()` to update after changes

2. **Use Provider for global state**
   - ProfileService is available via Provider
   - No need to recreate instances

3. **Batch database operations**
   - MissionCompletionService handles this automatically
   - All updates happen in one transaction flow

4. **Only recalculate when needed**
   - Profile recalculation happens automatically after mission completion
   - No need to manually call recalculate

---

## 🎨 UI Components for XP Display

### **XP Progress Bar**
```dart
LinearProgressIndicator(
  value: (currentXp / targetXp),
  backgroundColor: AppTheme.accentOrange.withOpacity(0.15),
  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentOrange),
)
```

### **Level Badge**
```dart
Container(
  padding: EdgeInsets.all(8),
  decoration: BoxDecoration(
    gradient: AppTheme.primaryGradient,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Column(
    children: [
      Icon(Icons.military_tech, color: Colors.white),
      Text('$level', style: TextStyle(color: Colors.white)),
    ],
  ),
)
```

### **XP Earned Notification**
```dart
Text(
  '+${xpEarned} XP',
  style: TextStyle(
    color: AppTheme.accentOrange,
    fontWeight: FontWeight.bold,
  ),
)
```

---

## 📚 Related Files

**Core Services:**
- `lib/services/mission_completion_service.dart`
- `lib/services/profile_service.dart`
- `lib/services/gamification_service.dart`
- `lib/services/result_service.dart`
- `lib/services/leaderboard_service.dart`

**Models:**
- `lib/models/profile_model.dart`
- `lib/models/mission_model.dart`
- `lib/models/mission_result_model.dart`

**Screens:**
- `lib/screens/simulation/result_screen.dart`
- `lib/screens/dashboard/dashboard_screen.dart`
- `lib/screens/progress/progress_screen.dart`
- `lib/screens/leaderboard/leaderboard_screen.dart`

---

## 🎓 Best Practices

1. ✅ Always check if user is logged in before XP operations
2. ✅ Use the automatic flow (result screen) instead of manual XP award
3. ✅ Don't award XP directly - let MissionCompletionService handle it
4. ✅ Trust the recalculation system for accuracy
5. ✅ Log XP changes for debugging
6. ✅ Handle null cases with fallback values (e.g., `?? 0`)
7. ✅ Show loading states while fetching profile data
8. ✅ Refresh UI after mission completion

---

**Last Updated:** June 8, 2026
