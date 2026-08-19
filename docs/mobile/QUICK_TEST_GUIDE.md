# 🚀 QUICK TEST GUIDE - LOCAL XP SYSTEM

## Run the App

```bash
flutter clean
flutter pub get
flutter run
```

## Test Scenario 1: First Mission Completion

### Steps:
1. Open the app
2. Go to Progress Page
3. **Expected:** Shows `Level 1, 0 / 100 XP` (or similar)
4. Start Mission 1
5. Complete it with ≥75% score
6. **Watch Console for:**
   ```
   ✅ Mission completion successful!
      XP Awarded: 100
      Total XP: 100
      New Level: 2
   ```
7. Go back to Progress Page
8. **Expected:** Shows `Level 2, 0 / 300 XP` OR `Level 1, 100 / 300 XP`
9. Go to Dashboard
10. **Expected:** Shows same XP value

### ✅ PASS if:
- Progress Page shows XP > 0
- Dashboard shows XP > 0
- Console shows "XP Awarded: 100"

### ❌ FAIL if:
- Still shows 0 XP
- Console shows "already_rewarded: true" on first attempt
- Console shows errors

## Test Scenario 2: App Restart Persistence

### Steps:
1. After completing Mission 1 (from Test 1)
2. **Close the app completely**
3. Reopen the app
4. Go to Progress Page
5. **Expected:** XP is still there (100 XP or Level 2)

### ✅ PASS if:
- XP persists after restart
- Same level as before restart

### ❌ FAIL if:
- XP resets to 0
- Level resets to 1

## Test Scenario 3: Duplicate Prevention

### Steps:
1. After completing Mission 1 (from Test 1)
2. Go back and retry Mission 1
3. Complete it again with ≥75% score
4. **Watch Console for:**
   ```
   ⚠️ Mission already rewarded - no duplicate XP
      already_rewarded: true
   ```
5. Go to Progress Page
6. **Expected:** XP is still 100 (not 200)

### ✅ PASS if:
- XP does not increase on retry
- Console shows "already_rewarded: true"

### ❌ FAIL if:
- XP increases again (becomes 200)
- Unlimited XP farming possible

## Test Scenario 4: Multiple Missions

### Steps:
1. Complete Mission 1 → **Expected:** +100 XP (Total: 100)
2. Complete Mission 2 → **Expected:** +100 XP (Total: 200)
3. Complete Mission 3 → **Expected:** +100 XP (Total: 300)
4. Check Progress Page
5. **Expected:** Shows Level 3 (if 300 XP = Level 3)

### ✅ PASS if:
- Each new mission adds XP
- Total XP is cumulative
- Level increases correctly

## Important Console Logs to Look For

### ✅ Good Signs:
```
💾 ========== SAVING MISSION RESULT LOCALLY ==========
🎮 ========== LOCAL MISSION COMPLETION ==========
✅ Mission completion successful!
   XP Awarded: 100
   Total XP: 100

📊 Progress Page Display (FROM LOCAL):
   Level: 2
   Current XP: 0 / 300
   XP to Next: 200
```

### ❌ Bad Signs:
```
❌ Error saving locally: ...
⚠️ Mission already rewarded - no duplicate XP (on first attempt)
XP Awarded: 0 (when mission passed)
Total XP: 0 (after completion)
```

## Quick Debug Commands

### Check Current Local XP:
```dart
// Add this to any screen temporarily:
final xp = await LocalGamificationService().getTotalXp();
debugPrint('Current XP: $xp');
```

### Reset XP (for testing):
```dart
// Add this to any screen temporarily:
await LocalGamificationService().resetAllGamificationData();
debugPrint('XP reset to 0');
```

## Expected Results Summary

| Action | Expected Result |
|--------|----------------|
| Complete Mission 1 | +100 XP, Level increases |
| Open Progress Page | Shows 100 XP or Level 2 |
| Open Dashboard | Shows 100 XP or Level 2 |
| Restart App | XP persists (still 100) |
| Retry Mission 1 | +0 XP (no duplicate) |
| Complete Mission 2 | +100 XP (total 200) |

## If Something Goes Wrong

1. **Check Console Logs**
   - Copy everything from "SAVING MISSION RESULT LOCALLY"
   - Share with developer

2. **Verify SharedPreferences**
   ```bash
   # Android
   adb shell
   run-as com.yourapp.package
   cd shared_prefs
   cat FlutterSharedPreferences.xml
   ```

3. **Manual Reset**
   ```dart
   await LocalGamificationService().resetAllGamificationData();
   ```

4. **Reinstall App**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

## Success Criteria

✅ All 4 test scenarios pass
✅ Console shows correct logs
✅ No errors in console
✅ XP displays correctly on all screens
✅ XP persists after restart
✅ No duplicate XP farming

---

**If all tests pass → XP system is working correctly! 🎉**
