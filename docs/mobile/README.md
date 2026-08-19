# ByteQuest: Gamified Simulation Platform for CSS NC II

A comprehensive Flutter mobile application for Computer Systems Servicing NC II learners with gamification, automated skill evaluation, and progress tracking.

## ðŸš€ Project Overview

ByteQuest is a complete mobile learning platform that includes:
- **30+ Professional Screens** - Onboarding, Authentication, Dashboard, Courses, Simulations, Progress Tracking
- **Supabase Integration** - Authentication, PostgreSQL Database, Realtime subscriptions
- **Gamification System** - XP, Levels, Badges, Achievements, Streaks, Rankings
- **Automated Skill Evaluation** - Real-time feedback and scoring
- **Progress Tracking** - Comprehensive analytics and performance monitoring
- **Modern SaaS UI** - Neumorphic design, soft shadows, clean cards
- **Level Locking System** - Sequential progression through COC 1-4

## ðŸ“ Project Structure

```
lib/
â”œâ”€â”€ main.dart                    # App entry point
â”œâ”€â”€ core/
â”‚   â”œâ”€â”€ constants/
â”‚   â”‚   â””â”€â”€ app_constants.dart  # App-wide constants
â”‚   â”œâ”€â”€ theme/
â”‚   â”‚   â””â”€â”€ app_theme.dart      # Modern theme configuration
â”‚   â”œâ”€â”€ config/
â”‚   â”‚   â””â”€â”€ supabase_config.dart # Supabase configuration
â”‚   â””â”€â”€ widgets/                 # Reusable UI components
â”œâ”€â”€ models/
â”‚   â”œâ”€â”€ profile_model.dart
â”‚   â”œâ”€â”€ learner_progress_model.dart
â”‚   â”œâ”€â”€ coc_model.dart
â”‚   â””â”€â”€ mission_model.dart
â”œâ”€â”€ services/
â”‚   â”œâ”€â”€ auth_service.dart       # Supabase authentication
â”‚   â”œâ”€â”€ profile_service.dart
â”‚   â”œâ”€â”€ progress_service.dart
â”‚   â””â”€â”€ mission_service.dart
â”œâ”€â”€ screens/
â”‚   â”œâ”€â”€ splash/
â”‚   â”œâ”€â”€ onboarding/
â”‚   â”œâ”€â”€ auth/
â”‚   â”œâ”€â”€ profile_setup/
â”‚   â”œâ”€â”€ dashboard/
â”‚   â”œâ”€â”€ missions/
â”‚   â”œâ”€â”€ simulation/
â”‚   â”œâ”€â”€ progress/
â”‚   â””â”€â”€ leaderboard/
â””â”€â”€ widgets/                     # Reusable components
```

## ðŸ”§ Setup Instructions

### 1. Supabase Setup

**IMPORTANT:** You must set up Supabase before running the app.

#### Step 1: Create Supabase Project
1. Go to [Supabase Dashboard](https://app.supabase.com/)
2. Click "New Project"
3. Name it "ByteQuest" or your preferred name
4. Set a strong database password
5. Choose your region

#### Step 2: Configure Environment Variables
1. Copy `.env.example` to `.env` (if not already created)
2. Add your Supabase credentials:
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

#### Step 3: Set Up Database Schema
1. Go to Supabase Dashboard â†’ SQL Editor
2. Run the database schema setup (create tables for profiles, learner_progress, missions, etc.)
3. Configure Row Level Security (RLS) policies

#### Step 4: Enable Authentication
1. Go to Authentication â†’ Providers
2. Enable "Email" authentication
3. Configure email templates (optional)

### 2. Install Dependencies

```bash
cd C:\Users\Acer\AndroidStudioProjects\CapstoneByteQuest
flutter pub get
```

### 3. Run the App

```bash
# Make sure an Android emulator is running or device is connected
flutter devices

# Run the app
flutter run
```

## ðŸ“± Implemented Screens

### âœ… Completed (Ready to Use)
- [x] Splash Screen (with auth session checking)
- [x] Onboarding (3 pages with smooth indicators)
- [x] Get Started Screen
- [x] Login Screen
- [x] Sign Up Screen
- [x] Forgot Password Screen
- [x] Profile Setup Screen
- [x] Dashboard Screen (with KPIs, progress, missions)
- [x] Missions Screen (COC modules and mission list)
- [x] Mission Detail Screen
- [x] Simulation Screens (drag-drop, identification, configuration)
- [x] Result Screen
- [x] Progress Screen (with XP tracking and achievements)
- [x] Leaderboard Screen
- [x] Profile Screen
- [x] Settings Screen
- [x] Courses Screen (COC 1-4)
- [x] COC Details Screen

### ðŸ”„ Future Enhancements
- [ ] Offline mode support
- [ ] Push notifications
- [ ] Dark mode
- [ ] Multi-language support (Filipino/English)
- [ ] Advanced analytics dashboard
- [ ] Peer-to-peer challenges
- [ ] AR-based simulations

## ðŸŽ¨ Design System

### Colors
- Primary Blue: `#0066FF`
- Secondary Cyan: `#00B8D9`
- Accent Orange: `#FF991F`
- Accent Purple: `#6554C0`
- Accent Green: `#36B37E`

### Typography
- Font Family: Inter (via Google Fonts)
- Display: 24-32px, Bold
- Headline: 16-20px, Semibold
- Body: 14-16px, Regular
- Label: 12-14px, Semibold

### Components
All UI components use:
- Rounded corners (12-20px radius)
- Soft shadows with 0.05-0.15 opacity
- Card-based layout
- Neumorphic-inspired depth
- Clean spacing (8, 16, 24, 32px)

## ðŸ” Authentication Flow

1. **Splash** â†’ Checks for existing Supabase session
   - If logged in â†’ Dashboard
   - If not logged in â†’ Onboarding
2. **Onboarding** â†’ 3-page introduction
3. **Get Started** â†’ Feature overview
4. **Sign Up** â†’ Create account with Supabase
5. **Profile Setup** â†’ Complete learner profile
6. **Dashboard** â†’ Main app interface with auto-login persistence

## ðŸ“Š Data Models

### ProfileModel
- userId, fullName, email, avatarUrl
- learnerId, school, courseSection
- status, createdAt, updatedAt, lastLoginAt

### LearnerProgressModel
- userId, totalXP, currentLevel, currentRank
- completedMissions, totalMissions
- unlockedAchievements, currentStreak
- lastActiveDate

### MissionModel
- missionId, title, description, difficulty
- xpReward, requiredScore, duration
- type (drag-drop, identification, configuration, etc.)
- isLocked, isCompleted

## ðŸŽ® Gamification Features

### XP System
- Earn XP for completing tasks
- Level up every 1000 XP
- Track progress with progress bars

### Badges & Achievements
- Code Starter (Complete first mission)
- Mission Master (Complete 10 missions)
- Streak Keeper (7-day learning streak)
- And more...

### Level Locking
- COC 1 Level 1 unlocked by default
- Practice catalog access is not an official competency progression rule.
- Official passing/competency rules are `PENDING_TESDA_VALIDATION`; no numeric threshold is active.
- Instructor COC bypass may unlock practice access only; it never awards a pass, competency, XP, or points.

## ðŸ› ï¸ Development Guidelines

### Adding New Screens
1. Create screen file in appropriate folder
2. Follow naming convention: `screen_name_screen.dart`
3. Use AppTheme for consistent styling
4. Implement proper navigation
5. Add route in `app_routes.dart`
6. Register in `main.dart` routes

### Creating Reusable Widgets
```dart
// Example: widgets/custom_button.dart
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  
  const CustomButton({
    required this.text,
    required this.onPressed,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Text(text),
    );
  }
}
```

### Implementing Services
Follow the pattern in `auth_service.dart`:
1. Create service class with Supabase client
2. Initialize dependencies
3. Implement CRUD operations using Supabase queries
4. Handle errors with try-catch
5. Use async/await for database calls

## ðŸ§ª Testing

```bash
# Run tests
flutter test

# Run with coverage
flutter test --coverage

# Check for issues
flutter analyze
```

## ðŸ“¦ Building for Release

```bash
# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release

# Output location
# ByteQuest Mobile App/build/app/outputs/flutter-apk/app-release.apk
```

## ðŸŽ¯ Key Features Implemented

### âœ… Session Persistence
- Auto-login after app restart
- Proper logout with session clearing
- Token refresh handling

### âœ… Gamification
- XP and leveling system
- Progress tracking
- Leaderboard with rankings
- Achievement badges

### âœ… Simulation System
- Drag-and-drop missions
- Identification challenges
- Configuration tasks
- Step-by-step procedures
- Real-time feedback

### âœ… Progress Analytics
- Module completion tracking
- XP history
- Performance metrics
- Streak tracking

## ðŸ“š Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Supabase Flutter](https://supabase.com/docs/reference/dart/introduction)
- [Material Design](https://material.io/design)
- [Google Fonts](https://fonts.google.com/)

## ðŸ‘¨â€ðŸ’» Development Team

This project is designed for capstone presentation and demonstrates modern Flutter development practices with Supabase backend integration.

## ðŸ“„ License

This project is created for educational purposes as part of a capstone project for Computer Systems Servicing NC II training.

---

## ðŸš¨ Common Issues & Solutions

### Issue: Supabase not initialized
**Solution:** Make sure `.env` file exists with correct SUPABASE_URL and SUPABASE_ANON_KEY

### Issue: Session not persisting
**Solution:** 
```bash
flutter clean
flutter pub get
# Uninstall app from device
flutter run
```

### Issue: Package not found
**Solution:** Run `flutter pub get` and restart IDE

### Issue: Build failed
**Solution:** 
```bash
flutter clean
flutter pub get
flutter run
```

### Issue: Hot reload not working
**Solution:** Stop the app and run `flutter run` again

---

## ðŸ’¡ Tips for Capstone Presentation

1. **Demo Flow**: Splash â†’ Auto-login â†’ Dashboard â†’ Missions â†’ Simulation â†’ Results
2. **Highlight Features**: Modern UI, Supabase integration, Gamification, Session persistence
3. **Show Code Quality**: Clean architecture, reusable components, service layer
4. **Explain Design**: SaaS style, neumorphism, professional branding
5. **Technical Stack**: Flutter + Dart + Supabase PostgreSQL + Material Design

---

**Created with â¤ï¸ for CSS NC II Learners**

